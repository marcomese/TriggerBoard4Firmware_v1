library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL;
library proasic3l;
use proasic3l.all;

entity TRIGGER_selector is
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
end TRIGGER_selector;

architecture Behavioral of TRIGGER_selector is

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

component prescaler is
generic(
    holdoffBits : natural
);
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(holdoffBits-1 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end component;

component prescaler14Bit is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(13 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end component;

component prescaler18Bit is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(17 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end component;

component trgValidFSM is
generic(
    nTrg        : natural;
    nClk        : natural
);
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    trigger     : in  std_logic;
    extTrg      : in  std_logic;
    veto        : in  std_logic_vector(1 downto 0);
    vetoExtSel  : in  std_logic_vector(7 downto 0);
    trgMasks    : in  std_logic_vector(nTrg-1 downto 0);
    validMasks  : out std_logic_vector(nTrg-1 downto 0);
    trgValid    : out std_logic;
    trgNotValid : out std_logic
);
end component;

constant maskNum                 : natural := 10;

type countArray is array (natural range 1 to maskNum-1) of std_logic_vector(15 downto 0);


signal  trigger,
        rise                     : std_logic_vector(maskNum-1 downto 0);

signal  plane_masked             : std_logic_vector(11 downto 0);

signal  count_0,
        count_grb                : std_logic_vector(31 downto 0);

signal  count_n                  : countArray;

signal  TR1_masked,
        TR2_masked,
        LAT_1_masked,
        LAT_2_masked,
        LAT_3_masked,
        LAT_4_masked,
        EN1_masked,
        EN2_masked,
        BOT_00_masked            : std_logic;


signal  generic_trigger_mask_int,
        trigger_mask_int         : std_logic_vector(31 downto 0);

signal  trigger_int,
        veto_lateral,
        veto_bottom              : std_logic;

signal  trigger_int_vec          : std_logic_vector(concurrentTriggers-1 downto 0);
signal  triggerIntVecSync        : std_logic_vector((concurrentTriggers-prescaledTriggers)-1 downto 0);

signal  trigger_prescaled        : std_logic_vector(prescaledTriggers-1 downto 0);

signal  TR1,
        TR1AND,
        TR2,
        RAN_01,
        RAN_02,
        RAN_03,
        RAN_04,
        RAN_05,
        RAN_06,
        RAN_07,
        RAN_08,
        RAN_09,
        RAN_10,
        RAN_11,
        RAN_12,
        EN1,
        EN2,
        EN1_AND,
        EN2_AND,
        TR1_02,
        TR1_03,
        TR1_04,
        TR2_02,
        TR2_03,
        EN1_2,
        EN2_2,
        LAT_1,
        LAT_2,
        LAT_3,
        LAT_4,
        BOT_00,
        RAN_05AND,
        RAN_06AND,
        RAN_07AND,
        RAN_08AND                : std_logic;

signal  triggerIDSig             : std_logic_vector(7 downto 0);

signal  trgIDStoreSig,
        trgIDStored              : std_logic;

signal  trgVecSig,
        trgVecSR                 : std_logic_vector(concurrentTriggers-1 downto 0);

signal  trgIDSDelay              : std_logic_vector(4 downto 0);

signal  validMasks               : std_logic_vector(maskNum-1 downto 0);

signal  genericSet               : std_logic;

signal  trgValidSig              : std_logic;

begin

trgValidOut <= trgValidSig;

startPeakDet <= trigger_int;

triggerID <= triggerIDSig;

TR1    <= plane(0) or plane(1) or plane(2) or plane(3) or plane(4);
TR2    <= plane(5) or plane(6) or plane(7) or plane(8);
RAN_01 <= plane(9);
RAN_02 <= plane(10);
RAN_03 <= plane(11);
RAN_04 <= plane(12);
RAN_05 <= plane(13);
RAN_06 <= plane(14);
RAN_07 <= plane(15);
RAN_08 <= plane(16);
RAN_09 <= plane(17);
RAN_10 <= plane(18);
RAN_11 <= plane(19);
RAN_12 <= plane(20);
EN1    <= plane(21) or plane(22) or plane(23);
EN2    <= plane(24) or plane(25) or plane(26);
TR1_02 <= plane(1);
TR1_03 <= plane(2);
TR1_04 <= plane(3);
TR2_02 <= plane(6);
TR2_03 <= plane(7);
EN1_2  <= plane(22);
EN2_2  <= plane(25);
BOT_00 <= plane(27);
LAT_1  <= plane(28);
LAT_2  <= plane(29);
LAT_3  <= plane(30);
LAT_4  <= plane(31);

TR1AND    <= planeAnd(0) or planeAnd(1) or planeAnd(2) or planeAnd(3) or planeAnd(4);
EN1_AND   <= planeAnd(21) or planeAnd(22) or planeAnd(23);
EN2_AND   <= planeAnd(24) or planeAnd(25) or planeAnd(26);
RAN_05AND <= planeAnd(13);
RAN_06AND <= planeAnd(14);
RAN_07AND <= planeAnd(15);
RAN_08AND <= planeAnd(16);

internal_values: process(reset, clock, apply_trigger_mask)
begin
    if reset='1' then
        genericSet <= '0';
        generic_trigger_mask_int <= (others=> '0');
        trigger_mask_int <= X"00000000";
    elsif rising_edge(clock) then
        genericSet <= '1' when unsigned(generic_trigger_mask_int(20 downto 0)) /= 0 else '0';

        if apply_trigger_mask = '1' then
            generic_trigger_mask_int <= generic_trigger_mask;
            trigger_mask_int <= trigger_mask;
        end if;
    end if;
end process;

-------------------- Costruzione delle configurazioni di trigger --------------------------------
veto_lateral <= LAT_1 or LAT_2 or LAT_3 or LAT_4;

veto_bottom  <= BOT_00;

trigger(0)   <= TR1AND;

trigger(1)   <= (TR1 and TR2);

trigger(2)   <= (TR1 and TR2) and RAN_01;

trigger(3)   <= (TR1 and TR2) and RAN_02;

trigger(4)   <= veto_lateral and not (TR1 or veto_bottom);

trigger(5)   <= TR1 and TR2 and RAN_12;

trigger(6)   <= veto_bottom and EN1 and EN2 and not (TR1 or TR2 or veto_lateral);

trigger(7)   <= (RAN_05AND or RAN_06AND or RAN_07AND or RAN_08AND) and not (TR1 or TR2 or
                                                                            veto_lateral or veto_bottom or
                                                                            EN1 or EN2);

trigger(8)   <= (EN1_AND or EN2_AND) and not (TR1 or TR2 or veto_lateral or veto_bottom);

trigger(9)   <= genericSet and (TR1_masked and TR2_masked and
                plane_masked(0) and plane_masked(1) and plane_masked(2) and plane_masked(3) and
                plane_masked(4) and plane_masked(5) and plane_masked(6) and plane_masked(7) and
                plane_masked(8) and plane_masked(9) and plane_masked(10) and plane_masked(10) and plane_masked(11) and
                EN1_masked and EN2_masked and
                LAT_1_masked and LAT_2_masked and LAT_3_masked and LAT_4_masked and
                BOT_00_masked);

TR1_masked <= TR1 or (not generic_trigger_mask_int(0));
TR2_masked <= TR2 or (not generic_trigger_mask_int(1));

mask_12_piani : for i in 0 to 11  generate
begin
    plane_masked(i) <= plane(i+9) or (not generic_trigger_mask_int(i+2));
end generate;

EN1_masked    <= EN1    or (not generic_trigger_mask_int(14));
EN2_masked    <= EN2    or (not generic_trigger_mask_int(15));
LAT_1_masked  <= LAT_1  or (not generic_trigger_mask_int(16));
LAT_2_masked  <= LAT_2  or (not generic_trigger_mask_int(17));
LAT_3_masked  <= LAT_3  or (not generic_trigger_mask_int(18));
LAT_4_masked  <= LAT_4  or (not generic_trigger_mask_int(19));
BOT_00_masked <= BOT_00 or (not generic_trigger_mask_int(20));

sincronizzatore : for i in 0 to maskNum-1 generate
begin
    edge_trigger_i: edgeDetector
    generic map(
        edge      => '1'
    )
    port map(
        clk       => clock,
        rst       => reset,
        signalIn  => trigger(i),
        signalOut => rise(i)
    );
end generate sincronizzatore;

countPresc_NInst: counter32BitSload
port map(
    Aclr   => swRst,
    Sload  => rate_time_sig,
    Clock  => clock,
    Enable => validMasks(0),
    Data   => (others => '0'),
    Q      => count_0
);

maskCounterGen: for i in 1 to maskNum-1 generate
begin
    count_NInst: counter16BitSload
    port map(
        Aclr   => swRst,
        Sload  => rate_time_sig,
        Clock  => clock,
        Enable => validMasks(i),
        Data   => (others => '0'),
        Q      => count_n(i)
    );
end generate;

countGRBRAN_NInst: counter16BitSload
port map(
    Aclr   => swRst,
    Sload  => rate_5ms,
    Clock  => clock,
    Enable => validMasks(7),
    Data   => (others => '0'),
    Q      => count_grb(15 downto 0)
);

countGRBLYSO_NInst: counter16BitSload
port map(
    Aclr   => swRst,
    Sload  => rate_5ms,
    Clock  => clock,
    Enable => validMasks(8),
    Data   => (others => '0'),
    Q      => count_grb(31 downto 16)
);

time_register: process(swRst, clock, rate_time_sig, count_n)
begin
    if swRst='1' then
        mask_rate_0 <= (others=> '0');
        mask_rate_1 <= (others=> '0');
        mask_rate_2 <= (others=> '0');
        mask_rate_3 <= (others=> '0');
        mask_rate_4 <= (others=> '0');
        mask_rate_5 <= (others=> '0');
        mask_rate_6 <= (others=> '0');
        mask_rate_7 <= (others=> '0');
        mask_rate_8 <= (others=> '0');
        mask_rate_9 <= (others=> '0');
    elsif rising_edge(clock) then
        if rate_time_sig = '1' then
            mask_rate_0 <= count_0;
            mask_rate_1 <= count_n(1);
            mask_rate_2 <= count_n(2);
            mask_rate_3 <= count_n(3);
            mask_rate_4 <= count_n(4);
            mask_rate_5 <= count_n(5);
            mask_rate_6 <= count_n(6);
            mask_rate_7 <= count_n(7);
            mask_rate_8 <= count_n(8);
            mask_rate_9 <= count_n(9);
        end if;
    end if;
end process;

time_5ms_register: process(swRst, clock, rate_5ms, count_grb)
begin
    if swRst = '1' then
        mask_grb <= (others => '0');
    elsif rising_edge(clock) then
        if rate_5ms = '1' then
            mask_grb <= count_grb;
        end if;
    end if;
end process;

mux_trgN_gen: for i in 0 to concurrentTriggers-1 generate
begin
    mux_triggerN:process(trigger_mask_int, rise)
    begin
        case trigger_mask_int((i*4)+3 downto (i*4)) is
            when X"0"  =>  trigger_int_vec(i) <= '0';
            when X"1"  =>  trigger_int_vec(i) <= rise(0);
            when X"2"  =>  trigger_int_vec(i) <= rise(1);
            when X"3"  =>  trigger_int_vec(i) <= rise(2);
            when X"4"  =>  trigger_int_vec(i) <= rise(3);
            when X"5"  =>  trigger_int_vec(i) <= rise(4);
            when X"6"  =>  trigger_int_vec(i) <= rise(5);
            when X"7"  =>  trigger_int_vec(i) <= rise(6);
            when X"8"  =>  trigger_int_vec(i) <= rise(7);
            when X"9"  =>  trigger_int_vec(i) <= rise(8);
            when X"A"  =>  trigger_int_vec(i) <= rise(9);
            when others => trigger_int_vec(i) <= '0';
        end case;
    end process;
end generate;

presc18BitInst: prescaler18Bit
port map(
    clk         => clock,
    rst         => swRst,
    holdoff     => holdoff(17 downto 0),
    triggerIn   => trigger_int_vec(0),
    triggerOut  => trigger_prescaled(0)
);

presc14BitInst: prescaler14Bit
port map(
    clk         => clock,
    rst         => swRst,
    holdoff     => holdoff(31 downto 18),
    triggerIn   => trigger_int_vec(1),
    triggerOut  => trigger_prescaled(1)
);

prescGen: for i in 2 to prescaledTriggers-1 generate
begin
    prescInst: prescaler
    generic map(
        holdoffBits => holdOffBits
    )
    port map(
        clk         => clock,
        rst         => swRst,
        holdoff     => holdoff((i*holdOffBits)+(holdOffBits-1) downto (i*holdOffBits)),
        triggerIn   => trigger_int_vec(i),
        triggerOut  => trigger_prescaled(i)
    );
end generate;

trgIntVecSyncInst: process(clock, reset, trigger_int_vec)
begin
    if reset = '1' then
        triggerIntVecSync <= (others => '0');
    elsif rising_edge(clock) then
        triggerIntVecSync <= trigger_int_vec(concurrentTriggers-1 downto prescaledTriggers);
    end if;
end process;

trgVecSig <= triggerIntVecSync & trigger_prescaled;

trigger_int <= '1' when unsigned(trgVecSig) /= 0 else '0';

trgIDStrSigInst: process(clock, reset, trgValidSig)
begin
    if reset = '1' then
        trgIDStoreSig <= '0';
    elsif rising_edge(clock) then
        trgIDStoreSig  <= trgValidSig;
    end if;
end process;

trgVecSRInst: for i in 0 to 5 generate
begin
    trgVecSRFF: process(clock, swRst, trgVecSig(i), trgIDStored)
    begin
        if swRst = '1' then
            trgVecSR(i) <= '0';
        elsif rising_edge(clock) then
            if trgVecSig(i) = '1' and trgIDStored = '0' then
                trgVecSR(i) <= '1';
            elsif trgVecSig(i) = '0' and trgIDStored = '1' then
                trgVecSR(i) <= '0';
            else
                trgVecSR(i) <= trgVecSR(i);
            end if;
        end if;
    end process;
end generate;

triggerIDSig(7 downto 6) <= (others => '0');

trgIDSigReg: process(clock, swRst, trgIDStoreSig)
begin
    if swRst = '1' then
        triggerIDSig(5 downto 0) <= (others => '0');
        trgIDStored              <= '0';
    elsif rising_edge(clock) then
        if trgIDStoreSig = '1' then
            triggerIDSig(5 downto 0) <= trgVecSR;
            trgIDStored              <= '1';
        else
            triggerIDSig(5 downto 0) <= triggerIDSig(5 downto 0);
            trgIDStored              <= '0';
        end if;
    end if;
end process;

trgValidFSMInst: trgValidFSM
generic map(
    nTrg        => maskNum,
    nClk        => 3
)
port map(
    clk         => clock,
    rst         => swRst,
    trigger     => trigger_int,
    extTrg      => trgExtIn,
    veto        => veto_bottom & veto_lateral,
    vetoExtSel  => trigger_mask_int(31 downto 24),
    trgMasks    => trigger,
    validMasks  => validMasks,
    trgValid    => trgValidSig,
    trgNotValid => trgNotValidOut
);

end Behavioral;