library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity spwFIFOReadFSM is
generic(
    dataLenVal   : std_logic_vector(31 downto 0) := x"00000048";
    dataInWidth  : natural := 8;
    dataOutWidth : natural := 32
);
port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    load         : in  std_logic;
    enable       : in  std_logic;
    dataReady    : out std_logic;
    wordReady    : in  std_logic;
    nextWord     : out std_logic;
    dataLenAck   : in  std_logic;
    dataIn       : in  std_logic_vector(dataInWidth-1 downto 0);
    dataOut      : out std_logic_vector(dataOutWidth-1 downto 0)
);
end spwFIFOReadFSM;

architecture Behavioral of spwFIFOReadFSM is

constant nLocs : natural := natural(ceil(real(dataOutWidth)/real(dataInWidth)));

type mem_t is array (natural range 0 to nLocs-1) of std_logic_vector(dataInWidth-1 downto 0);

type state is (idle, readWord, waitWordReady, loadBuff, incrWord, loadLastWord, writeDataLenState, waitDataLenWriteAck);

signal  currState, 
        nextState          : state;

signal  buff               : mem_t;

signal  dataOutSig         : std_logic_vector(dataOutWidth-1 downto 0);

signal  locsCounter        : natural range 0 to nLocs-1;

signal  locsCounterRstSig,
        locsCounterRstSigF,
        locsCounterEnSig,
        locsCounterEnSigF,
        loadBuffSig,
        loadBuffSigF,
        nextWordSig,
        nextWordSigF,
        dataReadySig,
        dataReadySigF      : std_logic;

begin

nextWord  <= nextWordSig;

dataReady <= dataReadySig;

dataInBuff: process(clk, rst, loadBuffSig)
begin
    if rst = '1' then
            buff <= (others => (others => '0'));
    elsif rising_edge(clk) then
        if loadBuffSig = '1' then
            buff(locsCounter) <= dataIn;
        end if;
    end if;
end process;

dataOutSigConcat: for i in 0 to nLocs-1 generate
    dataOutSig(((i+1)*dataInWidth)-1 downto i*dataInWidth) <= buff((nLocs-1)-i);
end generate;

dataOutProc: process(clk, rst, dataReadySig)
begin
    if rst = '1' then
            dataOut <= (others => '0');
    elsif rising_edge(clk) then
        if dataReadySig = '1' then
            dataOut <= dataOutSig;
        end if;
    end if;
end process;

-- data processing FSM
syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState         <= idle;
        locsCounterRstSig <= '0';
        locsCounterEnSig  <= '0';
        loadBuffSig       <= '0';
        nextWordSig       <= '0';
        dataReadySig      <= '0';
    elsif rising_edge(clk) then
        currState         <= nextState;
        locsCounterRstSig <= locsCounterRstSigF;
        locsCounterEnSig  <= locsCounterEnSigF;
        loadBuffSig       <= loadBuffSigF;
        nextWordSig       <= nextWordSigF;
        dataReadySig      <= dataReadySigF;
    end if;
end process;

combProc: process(currState, enable, load, locsCounter, wordReady, dataLenAck)
begin
    case currState is
        when idle =>
            if enable = '1' and load = '1' then
                nextState <= readWord;
            else
                nextState <= idle;
            end if;

        when readWord =>
                nextState <= waitWordReady;

        when waitWordReady =>
            if wordReady = '1' and locsCounter /= nLocs-1 then
                nextState <= loadBuff;
            elsif wordReady = '1' and locsCounter = nLocs-1 then
                nextState <= loadLastWord;
            else
                nextState <= waitWordReady;
            end if;

        when loadBuff =>
                nextState <= incrWord;

        when incrWord =>
                nextState <= readWord;

        when loadLastWord =>
                nextState <= writeDataLenState;

        when writeDataLenState =>
                nextState <= waitDataLenWriteAck;

        when waitDataLenWriteAck =>
                if dataLenAck = '1' then
                    nextState <= idle;
                else
                    nextState <= waitDataLenWriteAck;
                end if;

        when others =>
                nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';

        when readWord =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '1';
            dataReadySigF      <= '0';

        when waitWordReady =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';

        when loadBuff =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '1';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';

        when incrWord =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '1';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';

        when loadLastWord =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '1';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';

        when writeDataLenState =>
            locsCounterRstSigF <= '1';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '1';

        when waitDataLenWriteAck =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '1';

        when others =>
            locsCounterRstSigF <= '0';
            locsCounterEnSigF  <= '0';
            loadBuffSigF       <= '0';
            nextWordSigF       <= '0';
            dataReadySigF      <= '0';
    end case;
end process;

locsCountProc: process(clk, rst)
begin
    if rst = '1' then
            locsCounter <= 0;
    elsif rising_edge(clk) then
        if locsCounterRstSig = '1' then
            locsCounter <= 0;
        elsif locsCounterEnSig = '1' then
            locsCounter <= locsCounter + 1;
        end if;
    end if;
end process;

end Behavioral;
