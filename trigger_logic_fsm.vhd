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
    trgInhibit           : in  std_logic;
    debug                : in  std_logic;
    trigger_in_1         : in  std_logic_vector(31 downto 0);
    trigger_in_2         : in  std_logic_vector(31 downto 0);
    PMT_mask_1           : in  std_logic_vector(31 downto 0);
    PMT_mask_2           : in  std_logic_vector(31 downto 0);
    generic_trigger_mask : in  std_logic_vector(31 downto 0);	
    trigger_mask         : in  std_logic_vector(31 downto 0);
    apply_trigger_mask   : in  std_logic;
    apply_PMT_mask       : in  std_logic;

    calibration_state    : in  std_logic;
    acquisition_state    : in  std_logic;
			
    PMT_rate             : out std_logic_vector(1023 downto 0);	
    mask_rate            : out std_logic_vector(175 downto 0);
    mask_grb             : out std_logic_vector(31 downto 0);

    trigger_flag_1       : out std_logic_vector(31 downto 0);	
    trigger_flag_2       : out std_logic_vector(31 downto 0);			

    triggerID            : out std_logic_vector(7 downto 0);

    trgExtIn             : in  std_logic;

    holdoff              : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    rate1SecOut          : out std_logic;

    turrets              : out std_logic_vector(4 downto 0);
    turretsFlags         : out std_logic_vector(7 downto 0);
    turretsCounters      : out std_logic_vector(159 downto 0);

    calibPeriod          : in std_logic_vector(15 downto 0);

    trgNotInhibit        : out std_logic;

    trgValidOut          : out std_logic;

    trgNotValidOut       : out std_logic;

    startPeakDet         : out std_logic  -- attivo alto
);
end TRIGGER_logic_FSM;

architecture Behavioral of TRIGGER_logic_FSM is

component genericSync is
generic(
    sigNum : natural := 4
);
port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sigIn  : in  std_logic_vector(sigNum-1 downto 0);
    sigOut : out std_logic_vector(sigNum-1 downto 0)
);
end component;


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
    planeAnd             : in  std_logic_vector(31 downto 0);

    generic_trigger_mask : in  std_logic_vector(31 downto 0);	
    trigger_mask         : in  std_logic_vector(31 downto 0);

    triggerID            : out std_logic_vector(7 downto 0);

    apply_trigger_mask   : in  std_logic;

    rate_time_sig	     : in  std_logic; --1 secondo	

    rate_5ms             : in  std_logic;

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

    mask_grb             : out std_logic_vector(31 downto 0);

    trgExtIn             : in  std_logic;

    holdoff              : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    trgValidOut          : out std_logic;

    trgNotValidOut       : out std_logic;

    startPeakDet         : out std_logic  -- attivo alto
);
end component;

component counter16BitSload is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(15 downto 0);
    Q      : out   std_logic_vector(15 downto 0)
);
end component;

component counter32BitSload is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(31 downto 0);
    Q      : out   std_logic_vector(31 downto 0)
);
end component;

constant TRG_LENGHT : integer := 9;
constant RATE_TIME  : integer := 200000; -- 1 sec a 200kHz
constant RATE_5MS_TIME : integer := 1000; -- 5 ms a 200kHz

type count_array is array (0 to 31) of std_logic_vector(15 downto 0);

type state_values is
(
    wait_state,   -- sistema in attesa
    trg_state,    -- trg_state = '1'
    idle_state    -- idle per 100 ns
);

signal  pres_state, 
        next_state          : state_values;

signal  trigger_sincro_1,
        trigger_sincro_2,
        plane,
        trigger_PMTmasked_1,
        trigger_PMTmasked_2,
        trigger_PMTmasked_1AND,
        trigger_PMTmasked_2AND,
        PMT_mask_int_1,
        PMT_mask_int_2      : std_logic_vector(31 downto 0);

signal  planeAnd            : std_logic_vector(31 downto 0);

signal  count               : integer range 0 to TRG_LENGHT;

signal  idle,
        idle_i              : std_logic;

signal  time_cnt            : integer range 0 to RATE_TIME;
signal  time_5ms_cnt        : integer range 0 to RATE_5MS_TIME;

signal  calibCount          : std_logic_vector(15 downto 0);

signal  calibSig,
        calibRise           : std_logic;

signal  rate_time_sig,
        rise_rate,
        reset_counter,
        rise_rate_5ms,
        rate_5ms_sig        : std_logic;

signal  mask_rate_0_sig     : std_logic_vector(31 downto 0);

signal  mask_rate_1_sig,
        mask_rate_2_sig,
        mask_rate_3_sig,
        mask_rate_4_sig,
        mask_rate_5_sig,
        mask_rate_6_sig,
        mask_rate_7_sig,
        mask_rate_8_sig,
        mask_rate_9_sig     : std_logic_vector(15 downto 0);

signal  count_pmt_1,
        count_pmt_2,
        pmt_rate_1,
        pmt_rate_2          : count_array;

signal  rise_1, rise_2      : std_logic_vector(31 downto 0);

signal  s_trgExtPulse       : std_logic;

signal  turretsFlagsSig     : std_logic_vector(7 downto 0);

signal  turrRise,
        turrGate,
        turretsCntEn        : std_logic_vector(4 downto 0);

signal  fallingTrg1, 
        fallingTrg2,
        trigger_in_sync_1,
        trigger_in_sync_2   : std_logic_vector(31 downto 0);

signal  startPeakDetSig,
        trgValidSig,
        trgValidOutF        : std_logic;

begin

startPeakDet <= startPeakDetSig or calibRise or debug or trgExtIn;

rate1SecOut <= rate_time_sig;

turrets(4 downto 0) <= plane(4 downto 0);

turretsFlags <= turretsFlagsSig;

trgNotInhibit <= trgValidSig;

fallingSync1: process(clock, reset, trigger_in_1)
begin
    if reset = '1' then
        fallingTrg1 <= (others => '0');
    elsif falling_edge(clock) then
        fallingTrg1 <= trigger_in_1;
    end if;
end process;

risingSync1: process(clock, reset, fallingTrg1)
begin
    if reset = '1' then
        trigger_in_sync_1 <= (others => '0');
    elsif rising_edge(clock) then
        trigger_in_sync_1 <= fallingTrg1;
    end if;
end process;

fallingSync2: process(clock, reset, trigger_in_2)
begin
    if reset = '1' then
        fallingTrg2 <= (others => '0');
    elsif falling_edge(clock) then
        fallingTrg2 <= trigger_in_2;
    end if;
end process;

risingSync2: process(clock, reset, fallingTrg2)
begin
    if reset = '1' then
        trigger_in_sync_2 <= (others => '0');
    elsif rising_edge(clock) then
        trigger_in_sync_2 <= fallingTrg2;
    end if;
end process;

rise1Gen: for i in 0 to 31 generate
    rise1Inst: edgeDetector
    generic map(
        edge      => '1'
    )
    port map(
        clk       => clock,
        rst       => reset,
        signalIn  => trigger_in_sync_1(i),
        signalOut => rise_1(i)
    );
end generate;

rise2Gen: for i in 0 to 31 generate
    rise1Inst: edgeDetector
    generic map(
        edge      => '1'
    )
    port map(
        clk       => clock,
        rst       => reset,
        signalIn  => trigger_in_sync_2(i),
        signalOut => rise_2(i)
    );
end generate;

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
        trigger_in => trigger_in_sync_1(i),--rise_1(i),
        trigger_out  => trigger_sincro_1(i)
    );
end generate trigger_sampler_process_1;

trigger_sampler_process_2 : for i in 0 to 31 generate
begin
    trigger_i: trigger_extender_100ns
    port map(
        clock => clock,
        reset => reset, 
        trigger_in => trigger_in_sync_2(i),--rise_2(i),
        trigger_out  => trigger_sincro_2(i)
);
end generate trigger_sampler_process_2;

PMT_counter_process1 : for i in 0 to 31 generate
begin
    counter1_trigger_i: counter16BitSload
    port map(
        Aclr   => reset,
        Sload  => reset_counter,
        Clock  => clock,
        Enable => rise_1(i),
        Data   => (others => '0'),
        Q      => count_pmt_1(i)
    );
end generate PMT_counter_process1;

PMT_counter_process2 : for i in 0 to 31 generate
begin
    counter2_trigger_i: counter16BitSload
    port map(
        Aclr   => reset,
        Sload  => reset_counter,
        Clock  => clock,
        Enable => rise_2(i),
        Data   => (others => '0'),
        Q      => count_pmt_2(i)
    );
end generate PMT_counter_process2;

turrRiseGen: for i in 0 to 4 generate
begin
    turrRiseInst: edgeDetector
    generic map(
        edge      => '1'
    )
    port map(
        clk       => clock,
        rst       => reset,
        signalIn  => plane(i),
        signalOut => turrRise(i)
    );
end generate;

turrCntGateGen: for i in 0 to 4 generate
begin
    turrCntGate_n: process(clock, swRst, turrRise(i), trgValidSig)
    begin
        if swRst = '1' then
            turrGate(i) <= '0';
        elsif rising_edge(clock) then
            if turrRise(i) = '1' and trgValidSig = '0' then
                turrGate(i) <= '1';
            elsif trgValidSig = '1' then
                turrGate(i) <= '0';
            else
                turrGate(i) <= turrGate(i);
            end if;
         end if;
    end process;
end generate;

turretsCntEnEdge: for i in 0 to 4 generate
begin
    turrCntInst: process(clock, swRst, turrGate(i), trgValidSig)
    begin
        if swRst = '1' then
            turretsCntEn(i) <= '0';
        elsif rising_edge(clock) then
            if turrGate(i) = '1' and trgValidSig = '1' then
                turretsCntEn(i) <= '1';
            else
                turretsCntEn(i) <= '0';
            end if;
        end if;
    end process;
end generate;

turretsCountersInst: for i in 0 to 4 generate
begin
    turretsCounter_i: counter32BitSload
    port map(
        Aclr   => reset,
        Sload  => swRst,
        Clock  => clock,
        Enable => turretsCntEn(i),
        Data   => (others => '0'),
        Q      => turretsCounters(31+(i*32) downto i*32)
    );
end generate;

PMT_reg_process : for i in 0 to 31 generate
begin
    reg_counter_trigger_i: process(reset, clock, rise_rate)
    begin
        if reset='1' then
            PMT_rate_1(i)   <= (others => '0');
            PMT_rate_2(i)   <= (others => '0');
        elsif rising_edge(clock) then
            if rise_rate = '1' then
                PMT_rate_1(i)(15 downto 0) <= count_pmt_1(i)(15 downto 0);
                PMT_rate_2(i)(15 downto 0) <= count_pmt_2(i)(15 downto 0);
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

trigger_PMTmasked_1 <= trigger_sincro_1 and PMT_mask_int_1;
trigger_PMTmasked_2 <= trigger_sincro_2 and PMT_mask_int_2;

trigger_PMTmasked_1AND   <= trigger_sincro_1 or not PMT_mask_int_1;
trigger_PMTmasked_2AND   <= trigger_sincro_2 or not PMT_mask_int_2;

PMT_mask_plane_gen: for i in 0 to 31 generate
begin
    plane(i) <= trigger_PMTmasked_1(i) or trigger_PMTmasked_2(i);
end generate PMT_mask_plane_gen;

planeT1MaskGen: for i in 0 to 31 generate
begin
    planeAnd(i) <= trigger_PMTmasked_1AND(i) and trigger_PMTmasked_2AND(i);
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
    planeAnd => planeAnd,

    generic_trigger_mask => generic_trigger_mask,
    trigger_mask => trigger_mask,

    triggerID => triggerID,

    apply_trigger_mask => apply_trigger_mask,

    rate_time_sig	=> reset_counter,

    rate_5ms => rise_rate_5ms,

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

    mask_grb    => mask_grb,

    trgExtIn => s_trgExtPulse,

    holdoff => holdoff,

    trgValidOut => trgValidSig,

    trgNotValidOut => trgNotValidOut,

    startPeakDet => startPeakDetSig
);

mask_rate <= mask_rate_9_sig &  -- 175 -> 160
             mask_rate_8_sig &  -- 159 -> 144
             mask_rate_7_sig &  -- 143 -> 128
             mask_rate_6_sig &  -- 127 -> 112
             mask_rate_5_sig &  -- 111 -> 96
             mask_rate_4_sig &  --  95 -> 80
             mask_rate_3_sig &  --  79 -> 64
             mask_rate_2_sig &  --  63 -> 48
             mask_rate_1_sig &  --  47 -> 32
             mask_rate_0_sig;   --  31 -> 0

turretsFlagsSig(7 downto 5) <= (others => '0');

trigger_flag_register: process(swRst, clock, acquisition_state, calibration_state, trgValidSig)
begin
    if swRst='1' then
        trigger_flag_1              <= (others=> '0');
        trigger_flag_2              <= (others=> '0');
        turretsFlagsSig(4 downto 0) <= (others => '0');
    elsif rising_edge(clock) then
        if (acquisition_state = '1' or calibration_state = '1') and trgValidSig = '1' then
            trigger_flag_1              <= trigger_PMTmasked_1;
            trigger_flag_2              <= trigger_PMTmasked_2;
            turretsFlagsSig(4 downto 0) <= plane(4 downto 0);
        end if;
    end if;
end process;

calibCounter: process(reset, clock200k, calibCount, calibration_state)
begin
    if reset = '1' then
        calibCount <= (others => '0');
        calibSig   <= '0';
    elsif rising_edge(clock200k) then
        if calibration_state = '1' and calibPeriod /= x"0000" then 
            if calibCount = calibPeriod then
                calibCount <= (others => '0');
                calibSig   <= '1';
            else
                calibCount <= std_logic_vector(unsigned(calibCount) + 1);
                calibSig   <= '0';
            end if;
        else
            calibCount <= (others => '0');
            calibSig   <= '0';
        end if;
    end if;
end process;

calibRisingInst: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => clock,
    rst       => reset,
    signalIn  => calibSig,
    signalOut => calibRise
);

-- TRIGGER FSM

SYNC_PROC: process(reset, clock)
begin
    if reset='1' then 
        pres_state      <= wait_state;
        trgValidOut     <= '0' ;
        idle            <= '0' ;
    elsif rising_edge(clock) then
        pres_state      <= next_state;
        trgValidOut     <= trgValidOutF;
        idle            <= idle_i;
    end if;
end process;

-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process(pres_state, debug, trgInhibit, acquisition_state, trgValidSig, debug, count, calibRise)
begin
    next_state <= pres_state;

    case pres_state is
        when wait_state => -- sistema in attesa
            if trgInhibit = '1' then
                next_state <= wait_state;
            elsif debug = '1' or (calibRise = '1' and trgValidSig = '0') or (acquisition_state = '1' and trgValidSig = '1') then
                next_state <= trg_state;
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
        trgValidOutF      <= '0' ;
        idle_i            <= '0' ;
    elsif next_state = trg_state then 
        trgValidOutF      <= '1' ;
        idle_i            <= '0' ;
    elsif next_state = idle_state then 
        trgValidOutF      <= '0' ;
        idle_i            <= '1' ;
    else
        trgValidOutF      <= '0' ;
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
counter1s: process(reset, clock200k, time_cnt)
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

counter5ms: process(reset, clock200k, time_5ms_cnt)
begin
    if reset = '1' then
        time_5ms_cnt <= 0;
        rate_5ms_sig <= '0';
    elsif rising_edge(clock200k) then
        if time_5ms_cnt = RATE_5MS_TIME-1 then
            time_5ms_cnt <= 0;
            rate_5ms_sig <= '1';
        else
            time_5ms_cnt <= time_5ms_cnt + 1;
            rate_5ms_sig <= '0';
        end if;
    end if;
end process;

sincronizzatore_rate : process(reset, clock, rate_time_sig)
variable resync : std_logic_vector(1 to 3):=(others=> '0');
begin
   if reset='1' then
        rise_rate <= '0';
        resync := (others => '0');
   elsif rising_edge(clock) then
        rise_rate <= resync(2) and not resync(3);
        resync := rate_time_sig & resync(1 to 2);
   end if;
end process;

sincronizzatore_rate_5ms : process(reset, clock, rate_5ms_sig)
variable resync : std_logic_vector(1 to 3):=(others=> '0');
begin
   if reset='1' then
        rise_rate_5ms <= '0';
        resync := (others => '0');
   elsif rising_edge(clock) then
        rise_rate_5ms <= resync(2) and not resync(3);
        resync := rate_5ms_sig & resync(1 to 2);
   end if;
end process;

end Behavioral;