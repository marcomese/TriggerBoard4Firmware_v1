library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;
library proasic3l;
use proasic3l.all;

entity TRIGGER_logic_FSM is
generic(
    concurrentTriggers   : natural;
    prescaledTriggers    : natural;
    holdOffBits          : natural
);
port(
    reset                : in  std_logic;
    swRst                : in  std_logic;
    clock                : in  std_logic;  
    clock200k            : in  std_logic;  
    debug                : in  std_logic;
    trigger_in_1         : in  std_logic_vector(31 downto 0);
    trigger_in_2         : in  std_logic_vector(31 downto 0);
    PMT_mask_1           : in  std_logic_vector(31 downto 0);
    PMT_mask_2           : in  std_logic_vector(31 downto 0);
    generic_trigger_mask : in  std_logic_vector(31 downto 0);	
    trigger_mask         : in  std_logic_vector(31 downto 0);
    apply_trigger_mask   : in  std_logic;
    apply_PMT_mask       : in  std_logic;
    start_readers        : in  std_logic;

    calibration_state    : in  std_logic;
    acquisition_state    : in  std_logic;
			
    PMT_rate             : out std_logic_vector(1023 downto 0);	
    mask_rate            : out std_logic_vector(319 downto 0);

    trigger_flag_1       : out std_logic_vector(31 downto 0);	
    trigger_flag_2       : out std_logic_vector(31 downto 0);			

    triggerID            : out std_logic_vector(7 downto 0);

    trgExtIn             : in  std_logic;

    holdoff              : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    rate1SecOut          : out std_logic;

    turrets              : out std_logic_vector(4 downto 0);
    turretsFlags         : out std_logic_vector(7 downto 0);
    turretsCounters      : out std_logic_vector(159 downto 0);

    trg_to_DAQ_EASI      : out std_logic  -- attivo alto
);
end TRIGGER_logic_FSM;

architecture Behavioral of TRIGGER_logic_FSM is

component edgeDetector is
generic(
    edge      : std_logic := '0' -- '0' falling, '1' rising
);
port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    signalIn  : in  std_logic;
    signalOut : out std_logic
);
end component;

component trigger_extender_100ns is
port(
    clock       : in  STD_LOGIC;
    reset       : in  STD_LOGIC;
    trigger_in  : in  STD_LOGIC;
    trigger_out : out STD_LOGIC
);
end component;

component TRIGGER_selector is
generic(
    concurrentTriggers   : natural;
    prescaledTriggers    : natural;
    holdOffBits          : natural
);
port(
    reset                : in  std_logic;
    swRst                : in  std_logic;
    clock                : in  std_logic;  

    plane                : in  std_logic_vector(31 downto 0);
    planeT1And           : in  std_logic_vector(4 downto 0);

    generic_trigger_mask : in  std_logic_vector(31 downto 0);	
    trigger_mask         : in  std_logic_vector(31 downto 0);

    triggerID            : out std_logic_vector(7 downto 0);

    apply_trigger_mask   : in  std_logic;

    rate_time_sig	     : in  std_logic; --1 secondo	

    mask_rate_0          : out std_logic_vector(31 downto 0);
    mask_rate_1          : out std_logic_vector(15 downto 0);
    mask_rate_2          : out std_logic_vector(15 downto 0);
    mask_rate_3          : out std_logic_vector(15 downto 0);
    mask_rate_4          : out std_logic_vector(15 downto 0);
    mask_rate_5          : out std_logic_vector(15 downto 0);
    mask_rate_6          : out std_logic_vector(15 downto 0);
    mask_rate_7          : out std_logic_vector(15 downto 0);
    mask_rate_8          : out std_logic_vector(15 downto 0);
    mask_rate_9          : out std_logic_vector(15 downto 0);

    trgExtIn             : in  std_logic;

    holdoff              : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    trg_int              : out std_logic  -- attivo alto
);
end component;

component counter16Bit is
port(
    Aclr   : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Q      : out   std_logic_vector(15 downto 0)
);
end component;

component counter32Bit is
port(
    Aclr   : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Q      : out   std_logic_vector(31 downto 0)
);
end component;

constant TRG_LENGHT : integer := 19; -- Number of clock cycles 200MHz
--constant TRG_LENGHT : integer := 18; -- Number of clock cycles 192MHz
--constant TRG_LENGHT : integer := 9; -- Number of clock cycles 96MHz
--constant TRG_LENGHT : integer := 4; -- Number of clock cycles 48MHz
constant RATE_TIME  : integer := 200000; -- 1 sec a 200kHz

type count_array is array (0 to 31) of std_logic_vector(15 downto 0);

type state_values is
(
    wait_state,   -- sistema in attesa
    trg_state,    -- trg_state = '1'
    idle_state    -- idle per 100 ns
);

signal pres_state, next_state: state_values;

signal  trg_to_DAQ_EASI_i   : std_logic;

signal  trigger_sincro_1,
        trigger_sincro_2,
        plane,
        trigger_PMTmasked_1,
        trigger_PMTmasked_2,
        PMT_mask_int_1,
        PMT_mask_int_2      : std_logic_vector(31 downto 0);

signal  planeT1And : std_logic_vector(4 downto 0);

signal  count   : integer range 0 to TRG_LENGHT;

signal  idle,
        idle_i,
        trigger : std_logic;

signal  time_cnt : integer range 0 to RATE_TIME;

signal  rate_time_sig, rise_rate, reset_counter : std_logic;

signal  mask_rate_0_sig : std_logic_vector(31 downto 0);

signal  mask_rate_1_sig,
        mask_rate_2_sig,
        mask_rate_3_sig,
        mask_rate_4_sig,
        mask_rate_5_sig,
        mask_rate_6_sig,
        mask_rate_7_sig,
        mask_rate_8_sig,
        mask_rate_9_sig : std_logic_vector(15 downto 0);

signal  count_pmt_1,
        count_pmt_2,
        pmt_rate_1,
        pmt_rate_2      : count_array;

signal  rise_1, rise_2  : std_logic_vector(31 downto 0);

signal  s_trgExtPulse,
        s_trgExt100ns   : std_logic;

signal  turretsFlagsSig    : std_logic_vector(7 downto 0);

signal  turretsCountersVal : std_logic_vector(159 downto 0);

signal  turretsCntEn       : std_logic_vector(4 downto 0);

signal  trgFlag1,
        trgFlag2           : std_logic_vector(31 downto 0);

signal  turrFlag           : std_logic_vector(4 downto 0);

signal  flagsRst           : std_logic;

attribute syn_replicate : boolean;

attribute syn_replicate of reset_counter : signal is false;

begin

rate1SecOut <= rate_time_sig;

turrets(4 downto 0) <= plane(4 downto 0);

turretsFlags <= turretsFlagsSig;

sincronizzatore1 : for i in 0 to 31 generate
begin
    edge_trigger_i: process(reset, clock, trigger_in_1)
    variable resync_i : std_logic_vector(1 to 3);
    begin
        if reset='1' then
            rise_1(i) <= '0';
            resync_i  := (others => '0');
        elsif rising_edge(clock) then
            rise_1(i) <= resync_i(2) and not resync_i(3);
            resync_i  := trigger_in_1(i) & resync_i(1 to 2);
        end if;
    end process;
end generate sincronizzatore1;

sincronizzatore2 : for i in 0 to 31 generate
begin
    edge_trigger_i: process(reset, clock, trigger_in_2)
    variable resync_i : std_logic_vector(1 to 3);
    begin
       if reset='1' then
            rise_2(i) <= '0';
            resync_i  := (others => '0');
       elsif rising_edge(clock) then
            rise_2(i) <= resync_i(2) and not resync_i(3);
            resync_i  := trigger_in_2(i) & resync_i(1 to 2);
       end if;
    end process;
end generate sincronizzatore2;

sincroExt: process(reset, clock, trgExtIn)
variable ffQ : std_logic_vector(1 to 3);
begin
    if reset='1' then
        s_trgExtPulse <= '0';
        ffQ           := (others => '0');
    elsif rising_edge(clock) then
        s_trgExtPulse <= ffQ(2) and not ffQ(3);
        ffQ           := trgExtIn & ffQ(1 to 2);
    end if;
end process;

trigger_sampler_process_1 : for i in 0 to 31 generate
begin
    trigger_i: trigger_extender_100ns 
    port map(
        clock => clock,
        reset => reset, 
        trigger_in => rise_1(i),
        trigger_out  => trigger_sincro_1(i)
    );
end generate trigger_sampler_process_1;

trigger_sampler_process_2 : for i in 0 to 31 generate
begin
    trigger_i: trigger_extender_100ns 
    port map(
        clock => clock,
        reset => reset, 
        trigger_in => rise_2(i),
        trigger_out  => trigger_sincro_2(i)
);
end generate trigger_sampler_process_2;

extTrgExtended: trigger_extender_100ns
port map(
    clock       => clock,
    reset       => reset, 
    trigger_in  => s_trgExtPulse,
    trigger_out => s_trgExt100ns
);

PMT_counter_process1 : for i in 0 to 31 generate
begin
    counter1_trigger_i: counter16Bit
    port map(
        Aclr   => reset_counter,
        Clock  => clock,
        Enable => rise_1(i),
        Q      => count_pmt_1(i)
    );
end generate PMT_counter_process1;

PMT_counter_process2 : for i in 0 to 31 generate
begin
    counter2_trigger_i: counter16Bit
    port map(
        Aclr   => reset_counter,
        Clock  => clock,
        Enable => rise_2(i),
        Q      => count_pmt_2(i)
    );
end generate PMT_counter_process2;

turretsCntEnEdge: for i in 0 to 4 generate
begin
    turrCntEdge_i: edgeDetector
    generic map(
        edge      => '1'
    )
    port map(
        clk       => clock,
        rst       => reset,
        signalIn  => plane(i),
        signalOut => turretsCntEn(i)
    );
end generate;

turretsCountersInst: for i in 0 to 4 generate
begin
    turretsCounter_i: counter32Bit
    port map(
        Aclr   => reset_counter,
        Clock  => clock,
        Enable => turretsCntEn(i),
        Q      => turretsCountersVal(31+(i*32) downto i*32)
    );
end generate;

PMT_reg_process : for i in 0 to 31 generate
begin
    reg_counter_trigger_i: process(reset, clock, rise_rate)
    begin
        if reset='1' then
            PMT_rate_1(i)   <= (others => '0');
            PMT_rate_2(i)   <= (others => '0');
            turretsCounters <= (others => '0');
        elsif rising_edge(clock) then
            if rise_rate = '1' then
                PMT_rate_1(i)(15 downto 0) <= count_pmt_1(i)(15 downto 0);
                PMT_rate_2(i)(15 downto 0) <= count_pmt_2(i)(15 downto 0);
                turretsCounters            <= turretsCountersVal;
            end if;
        end if;
    end process;
 end generate PMT_reg_process;

reset_counter_register: process(swRst, clock)
begin
   if swRst='1' then
       reset_counter <= '1';
   elsif rising_edge(clock) then
       reset_counter <= rise_rate;
   end if;
end process;

PMT_rate <= PMT_rate_2(31) & PMT_rate_2(30) & PMT_rate_2(29) & PMT_rate_2(28) & PMT_rate_2(27) &
            PMT_rate_2(26) & PMT_rate_2(25) & PMT_rate_2(24) & PMT_rate_2(23) & PMT_rate_2(22) &
            PMT_rate_2(21) & PMT_rate_2(20) & PMT_rate_2(19) & PMT_rate_2(18) & PMT_rate_2(17) &
            PMT_rate_2(16) & PMT_rate_2(15) & PMT_rate_2(14) & PMT_rate_2(13) & PMT_rate_2(12) &
            PMT_rate_2(11) & PMT_rate_2(10) & PMT_rate_2(9)  & PMT_rate_2(8)  & PMT_rate_2(7)  &
            PMT_rate_2(6)  & PMT_rate_2(5)  & PMT_rate_2(4)  & PMT_rate_2(3)  & PMT_rate_2(2)  &
            PMT_rate_2(1)  & PMT_rate_2(0)  & 
            PMT_rate_1(31) & PMT_rate_1(30) & PMT_rate_1(29) & PMT_rate_1(28) & PMT_rate_1(27) &
            PMT_rate_1(26) & PMT_rate_1(25) & PMT_rate_1(24) & PMT_rate_1(23) & PMT_rate_1(22) &
            PMT_rate_1(21) & PMT_rate_1(20) & PMT_rate_1(19) & PMT_rate_1(18) & PMT_rate_1(17) &
            PMT_rate_1(16) & PMT_rate_1(15) & PMT_rate_1(14) & PMT_rate_1(13) & PMT_rate_1(12) &
            PMT_rate_1(11) & PMT_rate_1(10) & PMT_rate_1(9)  & PMT_rate_1(8)  & PMT_rate_1(7)  &
            PMT_rate_1(6)  & PMT_rate_1(5)  & PMT_rate_1(4)  & PMT_rate_1(3)  & PMT_rate_1(2)  &
            PMT_rate_1(1)  & PMT_rate_1(0);

internal_values: process(reset, clock)
begin
   if reset='1' then
        PMT_mask_int_1 <= (others => '1');
        PMT_mask_int_2 <= (others => '1');
   elsif rising_edge(clock) then
        if apply_PMT_mask = '1' then
            PMT_mask_int_1 <= PMT_mask_1;
            PMT_mask_int_2 <= PMT_mask_2;
        end if;
   end if;
end process;

PMT_mask_plane_gen: for i in 0 to 31 generate
begin
    --syncProc: process(clock, reset)
    --begin
        --if reset = '1' then
            --trigger_PMTmasked_1(i) <= '0';
            --trigger_PMTmasked_2(i) <= '0';
            --plane(i) <= '0';
        --elsif rising_edge(clock) then
            trigger_PMTmasked_1(i) <= trigger_sincro_1(i) and PMT_mask_int_1(i);
            trigger_PMTmasked_2(i) <= trigger_sincro_2(i) and PMT_mask_int_2(i);
            plane(i) <= trigger_PMTmasked_1(i) or trigger_PMTmasked_2(i);
        --end if;
    --end process;
end generate PMT_mask_plane_gen;

planeT1MaskGen: for i in 0 to 4 generate
begin
    --planeT1MaskProc: process(clock, reset)
    --begin
        --if reset = '1' then
            --planeT1And(i) <= '0';
        --elsif rising_edge(clock) then
            planeT1And(i) <= trigger_PMTmasked_1(i) and trigger_PMTmasked_2(i);
        --end if;
    --end process;
end generate;

trigger_selector_component : TRIGGER_selector
generic map(
    concurrentTriggers   => concurrentTriggers,
    prescaledTriggers    => prescaledTriggers,
    holdOffBits          => holdOffBits
)
port map(
    clock => clock,
    reset => reset,
    swRst => swRst,

    plane  => plane,
    planeT1And => planeT1And,

    generic_trigger_mask => generic_trigger_mask,
    trigger_mask => trigger_mask,

    triggerID => triggerID,

    apply_trigger_mask => apply_trigger_mask,

    rate_time_sig	=> rise_rate,

    mask_rate_0 => mask_rate_0_sig,
    mask_rate_1 => mask_rate_1_sig,
    mask_rate_2 => mask_rate_2_sig,
    mask_rate_3 => mask_rate_3_sig,
    mask_rate_4 => mask_rate_4_sig,
    mask_rate_5 => mask_rate_5_sig,
    mask_rate_6 => mask_rate_6_sig,
    mask_rate_7 => mask_rate_7_sig,
    mask_rate_8 => mask_rate_8_sig,
    mask_rate_9 => mask_rate_9_sig,

    trgExtIn => s_trgExt100ns,

    holdoff => holdoff,

    trg_int => trigger
);

mask_rate <= X"0009" & mask_rate_9_sig &
             X"0008" & mask_rate_8_sig &
             X"0007" & mask_rate_7_sig &
             X"0006" & mask_rate_6_sig &
             X"0005" & mask_rate_5_sig &
             X"0004" & mask_rate_4_sig &
             X"0003" & mask_rate_3_sig &
             X"0002" & mask_rate_2_sig &
             X"0001" & mask_rate_1_sig &
             mask_rate_0_sig;

turretsFlagsSig(7 downto 5) <= (others => '0');

trgFlag1Gen: for i in 0 to 31 generate
begin
    trgFlag1Inst: process(clock, swRst, trigger_PMTmasked_1(i), flagsRst)
    begin
        if swRst = '1' then
            trgFlag1(i) <= '0';
        elsif rising_edge(clock) then
            if acquisition_state = '0' then
                trgFlag1(i) <= '0';
            else
                if trigger_PMTmasked_1(i) = '1' and flagsRst = '0' then
                    trgFlag1(i) <= '1';
                elsif flagsRst = '1' then
                    trgFlag1(i) <= '0';
                else
                    trgFlag1(i) <= trgFlag1(i);
                end if;
            end if;
        end if;
    end process;
end generate;

trgFlag2Gen: for i in 0 to 31 generate
begin
    trgFlag2Inst: process(clock, swRst, trigger_PMTmasked_2(i), flagsRst)
    begin
        if swRst = '1' then
            trgFlag2(i) <= '0';
        elsif rising_edge(clock) then
            if acquisition_state = '0' then
                trgFlag2(i) <= '0';
            else
                if trigger_PMTmasked_2(i) = '1' and flagsRst = '0' then
                    trgFlag2(i) <= '1';
                elsif flagsRst = '1' then
                    trgFlag2(i) <= '0';
                else
                    trgFlag2(i) <= trgFlag2(i);
                end if;
            end if;
        end if;
    end process;
end generate;

turrFlagGen: for i in 0 to 4 generate
begin
    turrFlagInst: process(clock, swRst, turretsFlagsSig(i), flagsRst)
    begin
        if swRst = '1' then
            turrFlag(i) <= '0';
        elsif rising_edge(clock) then
            if acquisition_state = '0' then
                turrFlag(i) <= '0';
            else
                if plane(i) = '1' and flagsRst = '0' then
                    turrFlag(i) <= '1';
                elsif flagsRst = '1' then
                    turrFlag(i) <= '0';
                else
                    turrFlag(i) <= turrFlag(i);
                end if;
            end if;
        end if;
    end process;
end generate;

trigger_flag_register: process(swRst, clock, acquisition_state, calibration_state, trigger)
begin
    if swRst='1' then
        trigger_flag_1              <= (others=> '0');
        trigger_flag_2              <= (others=> '0');
        turretsFlagsSig(4 downto 0) <= (others => '0');
        flagsRst                    <= '0';
    elsif rising_edge(clock) then
        if (acquisition_state = '1' or calibration_state = '1') and trigger = '1' then
            trigger_flag_1              <= trgFlag1;
            trigger_flag_2              <= trgFlag2;
            turretsFlagsSig(4 downto 0) <= turrFlag;
            flagsRst                    <= '1';
        else
            trigger_flag_1              <= trigger_flag_1;
            trigger_flag_2              <= trigger_flag_2;
            turretsFlagsSig(4 downto 0) <= turretsFlagsSig(4 downto 0);
            flagsRst                    <= '0';
        end if;
    end if;
end process;

-- TRIGGER FSM

SYNC_PROC: process(reset, clock)
begin
    if reset='1' then 
        pres_state      <= wait_state;
        trg_to_DAQ_EASI <= '0' ;
        idle            <= '0' ;
    elsif rising_edge(clock) then
        pres_state      <= next_state;
        trg_to_DAQ_EASI <= trg_to_DAQ_EASI_i;
        idle            <= idle_i;
    end if;
end process;

-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process(pres_state, debug, start_readers, acquisition_state, calibration_state, trigger, debug, count)
begin
    next_state <= pres_state;

    case pres_state is
        when wait_state => -- sistema in attesa
            if debug = '1' then
                next_state <= trg_state;
            elsif start_readers= '1' then
                if (calibration_state = '1' and trigger = '0') or debug = '1' then
                    next_state <= trg_state;
                elsif (acquisition_state = '1' and trigger = '1') or debug = '1' then
                    next_state <= trg_state;
                else
                    next_state <= wait_state;
                end if;
            else
                next_state <= wait_state;
            end if;

        when trg_state => 
            next_state <= idle_state;

        when idle_state => 
            if count = TRG_LENGHT then
                next_state <= wait_state;
            else
                next_state <= idle_state;
            end if;

        when others =>
            next_state <= wait_state;
    end case;
end process;

OUTPUT_DECODE: process(next_state)
begin
    if next_state = wait_state then --  sistema in attesa
        trg_to_DAQ_EASI_i <= '0' ;
        idle_i            <= '0' ;
    elsif next_state = trg_state then 
        trg_to_DAQ_EASI_i <= '1' ;
        idle_i            <= '0' ;
    elsif next_state = idle_state then 
        trg_to_DAQ_EASI_i <= '0' ;
        idle_i            <= '1' ;
    else
        trg_to_DAQ_EASI_i <= '0' ;
        idle_i            <= '0' ;
    end if; 
end process;

-- contatore bit
bitCounter: process(reset, clock, idle, count)
begin
    if reset='1' then 
      count <= 0;
    elsif rising_edge(clock) then
        if (idle = '1') then -- il contatore e' abilitato solo nello stato idle 
            if count < TRG_LENGHT then
                count <= count + 1;
            else
                count <= 0;
            end if;
        end if;
	end if;
end process;

-- contatore 1 secondo
counter100ms: process(reset, clock200k, time_cnt)
begin
   if reset= '1' then 
      time_cnt <= 0;
      rate_time_sig <= '0';
   elsif rising_edge(clock200k) then
        if time_cnt = RATE_TIME-1 then
            time_cnt <= 0;  
            rate_time_sig <= '1';
        else
            time_cnt <= time_cnt + 1;    
            rate_time_sig <= '0';
        end if;       
   end if;
end process;

sincronizzatore_rate : process(reset, clock, rate_time_sig)
variable resync : std_logic_vector(1 to 3):=(others=> '0');
begin
   if reset='1' then
        rise_rate <= '0';
   elsif rising_edge(clock) then
        rise_rate <= resync(2) and not resync(3);
        resync := rate_time_sig & resync(1 to 2);
   end if;
end process;

end Behavioral;