library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity aliveDeadTCnt is
port(
    clock      : in  std_logic;
    clock200k  : in  std_logic;
    reset      : in  std_logic;
    trgInhibit : in  std_logic;
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

signal  live,
        dead,
        liveCntRst,
        deadCntRst,
        lostCntRst,
        liveCntStored,
        deadCntStored,
        triggerRise,
        trgInhibFall      : std_logic;

--attribute syn_replicate : boolean;
--
--attribute syn_replicate of liveCntRst : signal is false;
--attribute syn_replicate of deadCntRst : signal is false;
--attribute syn_replicate of lostCntRst : signal is false;

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
--    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
--    Data   : in    std_logic_vector(31 downto 0);
    Q      : out   std_logic_vector(31 downto 0)
);
end component;

begin

aliveCount <= ALIVE_TIME;

deadCount  <= DEAD_TIME;

lostCount  <= lost;

liveCntRst <= reset or deadCntStored;--liveCntStored;--reset or liveCntStored;

deadCntRst <= reset or liveCntStored;--deadCntStored;--reset or deadCntStored;

lostCntRst <= not trgInhibit;--reset or not trgInhibit;

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

trgInhibFallingInst: edgeDetector
generic map(
    edge      => '0'
)
port map(
    clk       => clock,
    rst       => reset,
    signalIn  => trgInhibit,
    signalOut => trgInhibFall
);

LIVE_dead_register: process(clock, reset, acqState, trgInhibFall, trigger)
begin
    if reset = '1' then
        live <= '0';
        dead <= '0';
    elsif rising_edge(clock) then
        if acqState = '1' then
            if triggerRise = '1' then
                live <= '0';
                dead <= '1';
            elsif trgInhibFall = '1' then 
                live <= '1';
                dead <= '0';
            else
                live <= live;
                dead <= dead;
            end if;
        else
            live <= '0';
            dead <= '0';
        end if;
    end if;
end process;

aliveCounter: counterLiveDead
port map(
    Aclr   => reset,
--    Sload  => liveCntRst,
    Clock  => clock200k,
    Enable => live,
--    Data   => (others => '0'),
    Q      => ALIVE_TIME_count
);

deadCounter: counterLiveDead
port map(
    Aclr   => reset,
--    Sload  => deadCntRst,
    Clock  => clock200k,
    Enable => dead,
--    Data   => (others => '0'),
    Q      => DEAD_TIME_count
);

alive_time_register: process(clock, reset)
begin
    if reset='1' then
        ALIVE_TIME <= (OTHERS => '0');
        liveCntStored <= '0';
    elsif rising_edge(clock) then
        if triggerRise = '1' then
            ALIVE_TIME <= ALIVE_TIME_count;
            liveCntStored <= '1';
        else
            ALIVE_TIME <= ALIVE_TIME;
            liveCntStored <= '0';
        end if;
    end if;
end process;

dead_time_register: process(clock, reset)
begin
    if reset='1' then
        lost <= (OTHERS => '0');
        DEAD_TIME <= (OTHERS => '0');
        deadCntStored <= '0';
    elsif rising_edge(clock) then
        if trgInhibFall = '1' then
            DEAD_TIME <= DEAD_TIME_count;
            lost <= lost_count;
            deadCntStored <= '1';
        else
            DEAD_TIME <= DEAD_TIME;
            lost <= lost;
            deadCntStored <= '0';
        end if;
    end if;
end process;

lostCounterInst: counterLostTrg
port map(
    Aclr   => reset,
    Sload  => lostCntRst,
    Clock  => clock,
    Enable => acqState and (not live) and trigger,
    Data   => (others => '0'),
    Q      => lost_count
);

end architecture_aliveDeadTCnt;