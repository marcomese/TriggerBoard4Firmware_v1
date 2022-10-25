library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity aliveDeadTCnt is
port(
    clock      : in  std_logic;
    clock200k  : in  std_logic;
    reset      : in  std_logic;
    busyState  : in  std_logic;
    acqState   : in  std_logic;
    trigger    : in  std_logic;
    aliveCount : out std_logic_vector(31 downto 0);
    deadCount  : out std_logic_vector(31 downto 0);
    lostCount  : out std_logic_vector(15 downto 0)
);
end aliveDeadTCnt;

architecture architecture_aliveDeadTCnt of aliveDeadTCnt is

signal  ALIVE_TIME_count,
        DEAD_TIME_count,
        ALIVE_TIME,
        DEAD_TIME         : std_logic_vector(31 downto 0);

signal  lost,
        lost_count        : std_logic_vector(15 downto 0);

signal  triggerRise,
        trigger200k       : std_logic;

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

component pulseExt is
generic(
    clkFreq    : real;
    pulseWidth : real
);
port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    sigIn      : in  std_logic;
    sigOut     : out std_logic
);
end component;

component counterLostTrg is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(15 downto 0);
    Q      : out   std_logic_vector(15 downto 0)
);
end component;

component counterLiveDead is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(31 downto 0);
    Q      : out   std_logic_vector(31 downto 0)
);
end component;

begin

aliveCount <= ALIVE_TIME;

deadCount  <= DEAD_TIME;

lostCount  <= lost;

triggerRisingInst: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => clock,
    rst       => reset,
    signalIn  => trigger,
    signalOut => triggerRise
);

aliveRstInst: pulseExt
generic map(
    clkFreq    => 48.0e6,
    pulseWidth => 5.0e-6
)
port map(
    clk        => clock,
    rst        => reset,
    sigIn      => triggerRise,
    sigOut     => trigger200k
);

aliveCounter: counterLiveDead
port map(
    Aclr   => reset,
    Sload  => trigger200k,
    Clock  => clock200k,
    Enable => not busyState,
    Data   => (others => '0'),
    Q      => ALIVE_TIME_count
);

deadCounter: counterLiveDead
port map(
    Aclr   => reset,
    Sload  => trigger200k,
    Clock  => clock200k,
    Enable => busyState,
    Data   => (others => '0'),
    Q      => DEAD_TIME_count
);

lostCounterInst: counterLostTrg
port map(
    Aclr   => reset,
    Sload  => trigger200k,
    Clock  => clock,
    Enable => acqState and busyState and trigger,
    Data   => (others => '0'),
    Q      => lost_count
);

alive_time_register: process(clock, reset, triggerRise)
begin
    if reset='1' then
        ALIVE_TIME <= (OTHERS => '0');
        DEAD_TIME  <= (OTHERS => '0');
        lost       <= (others => '0');
    elsif rising_edge(clock) then
        if triggerRise = '1' then
            ALIVE_TIME <= ALIVE_TIME_count;
            DEAD_TIME <= DEAD_TIME_count;
            lost <= lost_count;
        else
            ALIVE_TIME <= ALIVE_TIME;
            DEAD_TIME <= DEAD_TIME;
            lost <= lost;
        end if;
    end if;
end process;

end architecture_aliveDeadTCnt;