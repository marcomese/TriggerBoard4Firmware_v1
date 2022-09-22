library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tempSensorRead is
generic(
    clkFreq      : real;
    sclkFreq     : real;
    sDataWidth   : natural;
    tempWidth    : natural
);
port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    enableIn     : in  std_logic;
    startConvIn  : in  std_logic;
    sDataIn      : in  std_logic;
    dataReadyOut : out std_logic;
    sclkOut      : out std_logic;
    csOut        : out std_logic;
    dataOut      : out std_logic_vector(tempWidth-1 downto 0)
);
end tempSensorRead;

architecture Behavioral of tempSensorRead is

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

type state is (idle, selectSensor, readData, endConv);

constant sclkHCountVal               : natural := natural(ceil(clkFreq/(2.0*sclkFreq)));
constant sclkLCountVal               : natural := natural(ceil(clkFreq/sclkFreq));

signal   sclkCounter                 : natural range 0 to sclkLCountVal;

signal   bitCounter                  : natural range 0 to sDataWidth+1;

signal   currState,
         nextState                   : state;

signal   sclkSig, sclkUpdate, sclkRise,
         enBitCntSig, enBitCntSigF,
         rstBitCntSig, rstBitCntSigF,
         sclkEnSig, sclkEnSigF,
         csSig, csSigF,
         loadBitSig, loadBitSigF,
         clearTRegSig, clearTRegSigF,
         dataReadySig, dataReadySigF : std_logic;

signal   tempData                    : std_logic_vector(sDataWidth downto 0);

begin

dataReadyOut <= dataReadySig;
csOut        <= csSig   when enableIn = '1' else '0';
sclkOut      <= sclkSig when enableIn = '1' else '0';

sclkUpdate   <= '1' when (sclkCounter = sclkHCountVal) or (sclkCounter = sclkLCountVal) else '0';

sclkGenInst: process(clk, rst, sclkEnSig, sclkUpdate)
begin
    if rst = '1' then
        sclkSig <= '1';
    elsif rising_edge(clk) then
        if sclkEnSig = '1' and sclkUpdate = '1' then
            sclkSig <= not sclkSig;
        else
            sclkSig <= sclkSig;
        end if;
    end if;
end process;

sclkCounterInst: process(clk, rst, sclkEnSig, sclkCounter)
begin
    if rst = '1' then
        sclkCounter <= 0;
    elsif rising_edge(clk) then
        if sclkCounter = sclkLCountVal then
            sclkCounter <= 0;
        elsif sclkEnSig = '1' then
            sclkCounter <= sclkCounter + 1;
        else
            sclkCounter <= sclkCounter;
        end if;
    end if;
end process;

sclkRising: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => clk,
    rst       => rst,
    signalIn  => sclkSig,
    signalOut => sclkRise
);

-- il primo bit è sempre uno zero quindi non lo considero
dataOutReverse: for i in 1 to tempWidth generate
begin
    dataOut(tempWidth-i) <= tempData(i);
end generate;

tempDataReg: process(clk, rst,loadBitSig, clearTRegSig, sDataIn, bitCounter)
begin
    if rst = '1' then
        tempData <= (others => '0');
    elsif rising_edge(clk) then
        if clearTRegSig = '1' then
            tempData <= (others => '0');
        elsif loadBitSig = '1' then
            tempData(bitCounter) <= sDataIn;
        else
            tempData <= tempData;
        end if;
    end if;
end process;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState    <= idle;
        enBitCntSig  <= '0';
        rstBitCntSig <= '0';
        csSig        <= '1';
        sclkEnSig    <= '0';
        loadBitSig   <= '0';
        dataReadySig <= '0';
        clearTRegSig <= '0';
    elsif rising_edge(clk) then
        currState    <= nextState;
        enBitCntSig  <= enBitCntSigF;
        rstBitCntSig <= rstBitCntSigF;
        csSig        <= csSigF;
        sclkEnSig    <= sclkEnSigF;
        loadBitSig   <= loadBitSigF;
        dataReadySig <= dataReadySigF;
        clearTRegSig <= clearTRegSigF;
    end if;
end process;

combProc: process(currState, startConvIn, bitCounter)
begin
    case currState is
        when idle =>
            if startConvIn = '1' then
                nextState <= selectSensor;
            else
                nextState <= idle;
            end if;

        when selectSensor =>
                nextState <= readData;

        when readData =>
            if bitCounter = sDataWidth then
                nextState <= endConv;
            else
                nextState <= readData;
            end if;

        when endConv =>
            nextState <= idle;

        when others =>
            nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            enBitCntSigF  <= '0';
            rstBitCntSigF <= '0';
            csSigF        <= '1';
            sclkEnSigF    <= '0';
            loadBitSigF   <= '0';
            clearTRegSigF <= '0';
            dataReadySigF <= '0';

        when selectSensor =>
            enBitCntSigF  <= '0';
            rstBitCntSigF <= '0';
            csSigF        <= '0';
            sclkEnSigF    <= '0';
            loadBitSigF   <= '0';
            clearTRegSigF <= '1';
            dataReadySigF <= '0';

        when readData =>
            enBitCntSigF  <= '1';
            rstBitCntSigF <= '0';
            csSigF        <= '0';
            sclkEnSigF    <= '1';
            loadBitSigF   <= '1';
            clearTRegSigF <= '0';
            dataReadySigF <= '0';

        when endConv =>
            enBitCntSigF  <= '0';
            rstBitCntSigF <= '1';
            csSigF        <= '1';
            sclkEnSigF    <= '0';
            loadBitSigF   <= '0';
            clearTRegSigF <= '0';
            dataReadySigF <= '1';

        when others =>
            enBitCntSigF  <= '0';
            rstBitCntSigF <= '0';
            csSigF        <= '1';
            sclkEnSigF    <= '0';
            loadBitSigF   <= '0';
            clearTRegSigF <= '0';
            dataReadySigF <= '0';
    end case;
end process;

bitCounterProc: process(clk, rst, enBitCntSig, rstBitCntSig)
begin
    if rst = '1' then
        bitCounter <= 0;
    elsif rising_edge(clk) then
        if rstBitCntSig = '1' then
            bitCounter <= 0;
        elsif enBitCntSig = '1' and sclkRise = '1' then
            bitCounter <= bitCounter + 1;
        else
            bitCounter <= bitCounter;
        end if;
    end if;
end process;

end Behavioral;
