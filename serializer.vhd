library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serializer is
generic(
    parallelWidth   : natural;
    resetValue      : std_logic_vector(parallelWidth-1 downto 0);
    shiftBits       : natural := 1;
    shiftDirection  : bit     := '0' -- 0 sinistra, 1 destra
);
port(
    clk             : in  std_logic;
    rst             : in  std_logic;
    clear           : in  std_logic;
    load            : in  std_logic;
    shift           : in  std_logic;
    parallelIN      : in  std_logic_vector(parallelWidth-1 downto 0);
    serialIN        : in  std_logic;
    serialOUT       : out std_logic;
    shiftDone       : out std_logic
);
end serializer;

architecture Behavioral of serializer is

type fsmState is (idle,
                  shiftState,
                  lastBit,
                  endState);

signal  dataSig                           : std_logic_vector(parallelWidth-1 downto 0);

signal  bitCountSig                       : std_logic_vector(4 downto 0);

signal  shiftDoneSignal, shiftDoneSignalF,
        bitCounterRst, bitCounterRstF,
        shiftSig, shiftSigF               : std_logic;

signal  currState, nextState              : fsmState;

component counter5Bit is
    port( Aclr   : in    std_logic;
          Sload  : in    std_logic;
          Clock  : in    std_logic;
          Data   : in    std_logic_vector(4 downto 0);
          Enable : in    std_logic;
          Q      : out   std_logic_vector(4 downto 0)
        );
end component;

begin

shiftDone <= shiftDoneSignal;

serialOUT <= dataSig(dataSig'length-1) when shiftDirection = '0' else dataSig(0);

bitCountFSMregs: process(clk, rst)
begin
    if rst = '1' then
        currState       <= idle;
        shiftDoneSignal <= '0';
        bitCounterRst   <= '1';
        shiftSig        <= '0';
    elsif rising_edge(clk) then
        currState       <= nextState;
        shiftDoneSignal <= shiftDoneSignalF;
        bitCounterRst   <= bitCounterRstF;
        shiftSig        <= shiftSigF;
    end if;
end process;

bitCountFSMcomb: process(currState, shift, bitCountSig)
begin
    case currState is   
        when idle =>
            if shift = '1' then
                nextState <= shiftState;
            else
                nextState <= idle;
            end if;

        when shiftState =>
            if unsigned(bitCountSig) = shiftBits-2 then
                nextState <= lastBit;
            else
                nextState <= shiftState;
            end if;

        when lastBit =>
                nextState <= endState;

        when endState =>
            if shift = '1' then
                nextState <= shiftState;
            else
                nextState <= idle;
            end if;

        when others =>
                nextState <= idle;
    end case;
end process;

bitCountFSMout: process(nextState)
begin
    case nextState is   
        when idle =>
            shiftDoneSignalF <= '0';
            bitCounterRstF   <= '0';
            shiftSigF        <= '0';

        when shiftState =>
            shiftDoneSignalF <= '0';
            bitCounterRstF   <= '0';
            shiftSigF        <= '1';

        when lastBit =>
            shiftDoneSignalF <= '1';
            bitCounterRstF   <= '1';
            shiftSigF        <= '1';

        when endState =>
            shiftDoneSignalF <= '0';
            bitCounterRstF   <= '0';
            shiftSigF        <= '0';

        when others =>
            shiftDoneSignalF <= '0';
            bitCounterRstF   <= '0';
            shiftSigF        <= '0';
    end case;
end process;

bitCounter: counter5Bit
port map(
    Aclr   => rst,
    Sload  => clear or bitCounterRst,
    Clock  => clk,
    Data   => (others => '0'),
    Enable => shiftSig,
    Q      => bitCountSig
);

memory: process(clk, rst, clear, load, shiftSig)
begin
    if rst = '1' then
        dataSig <= resetValue;
    elsif clk = '1' and clk'event then
        if clear = '1' then
            dataSig <= resetValue;
        elsif load = '1' then
            dataSig <= parallelIN;
        elsif shiftSig = '1' and shiftDirection = '0' then
            dataSig <= dataSig(dataSig'length-2 downto 0) & serialIN;
        elsif shiftSig = '1' and shiftDirection = '1' then
            dataSig <=  serialIN & dataSig(dataSig'length-1 downto 1);
        end if;
    end if;
end process;

end Behavioral;
