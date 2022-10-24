library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity spwFIFOInterface is
generic(
    fifoWidth           : natural;
    fifoDepth           : natural;
    acqDataLen          : natural;
    writeMuxPadding     : std_logic := '0';
    writeMuxPaddingLeft : boolean   := false
);
port(
    clk                 : in  std_logic;
    rst                 : in  std_logic;

    adcDataReady        : in  std_logic;
    acqData             : in  std_logic_vector(acqDataLen-1 downto 0);

    pcktCounter         : out natural;

    regAcqData          : out std_logic_vector(acqDataLen-1 downto 0);
    writeDataLen        : out std_logic;
    dataReadyIn         : in  std_logic;

    dpcuBusyIn          : in  std_logic;

    dataWrittenInFIFO   : out std_logic;

    fifoDATA            : out std_logic_vector(fifoWidth-1 downto 0);
    fifoQ               : in  std_logic_vector(fifoWidth-1 downto 0);
    fifoWE              : out std_logic;
    fifoRE              : out std_logic;
    fifoAFULL           : in  std_logic;
    fifoEMPTY           : in  std_logic;
    fifoWACK            : in  std_logic;
    fifoDVLD            : in  std_logic
);
end spwFIFOInterface;

architecture arch_spwFIFOInterface of spwFIFOInterface is

constant nLocs           : natural := natural(ceil(real(acqData'length)/real(fifoWidth)));
constant wordsInLoc      : natural := natural(ceil(real(fifoWidth)/32.0));
constant maxPcktsInFIFO  : natural := natural(ceil(real(fifoDepth)/real(nLocs)));
constant pcktCntBits     : natural := natural(ceil(log2(real(maxPcktsInFIFO-1))));

component spwFIFOWriteFSM is
generic(
    nLocs          : natural
);
port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    startWrite     : in  std_logic;
    writeAck       : in  std_logic;
    writeEn        : out std_logic;
    dataReady      : out std_logic;
    locSel         : out natural
);
end component;

component spwFIFOReadFSM is
generic(
    dataInWidth  : natural;
    dataOutWidth : natural
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
end component;

component genericMUX is
generic(
    padding      : std_logic := '0';
    paddingLeft  : boolean   := false
);
port(
    dataIn       : in  std_logic_vector;
    dataOut      : out std_logic_vector;
    dataSel      : in  natural
);
end component;

component edgeDetector is
generic(
    edge      : std_logic
);
port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    signalIn  : in  std_logic;
    signalOut : out std_logic
);
end component;

signal   writeLocSel        : natural range 0 to nLocs;
signal   pcktCnt            : natural range 0 to maxPcktsInFIFO;

signal   pckPres,
         fifoDataReady,
         startWriteSig,
         dpcuBusyRising,
         buffDataReady,
         readDoneSig,
         readEn             : std_logic;

signal   acqDataOutSig      : std_logic_vector(acqDataLen-1 downto 0);

begin

pcktCounter       <= pcktCnt;

pckPres           <= or_reduce(std_logic_vector(to_unsigned(pcktCnt,pcktCntBits)));

startWriteSig     <= adcDataReady and (not fifoAFULL);

regAcqData        <= acqDataOutSig;

readEn            <= dpcuBusyIn and (not dataReadyIn) and (not fifoEmpty);

readDoneSig       <= dpcuBusyRising and (not dataReadyIn);

writeDataLen      <= buffDataReady;

dataWrittenInFIFO <= fifoDataReady;

dpcuBusyRisingEdgeInst: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => clk,
    rst       => rst,
    signalIn  => dpcuBusyIn,
    signalOut => dpcuBusyRising
);

fifoPacketCounter: process(rst, clk, fifoDataReady, readDoneSig, pcktCnt)
begin
    if rst='1' then
        pcktCnt <= 0;
    elsif rising_edge(clk) then
        if fifoDataReady='1' and readDoneSig='0' then
            pcktCnt <= pcktCnt + 1;
        elsif fifoDataReady='0' and readDoneSig='1' and pcktCnt /= 0 then
            pcktCnt <= pcktCnt - 1;
        else
            pcktCnt <= pcktCnt;
        end if;
    end if;
end process;

spwFIFOWriteInst: spwFIFOWriteFSM
generic map(
    nLocs          => nLocs
)
port map(
    clk            => clk,
    rst            => rst,
    startWrite     => startWriteSig,
    writeAck       => fifoWACK,
    writeEn        => fifoWE,
    dataReady      => fifoDataReady,
    locSel         => writeLocSel
);

writeMUXInst: genericMux
generic map(
    padding     => writeMuxPadding,
    paddingLeft => writeMuxPaddingLeft
)
port map(
    dataIn      => acqData,
    dataOut     => fifoDATA,
    dataSel     => writeLocSel
);

spwFIFOReadInst: spwFIFOReadFSM
generic map(
    dataInWidth  => fifoWidth,
    dataOutWidth => acqDataLen
)
port map(
    clk          => clk,
    rst          => rst,
    load         => pckPres,
    enable       => readEn,
    dataReady    => buffDataReady,
    wordReady    => fifoDVLD,
    nextWord     => fifoRE,
    dataLenAck   => dataReadyIn,
    dataIn       => fifoQ,
    dataOut      => acqDataOutSig
);

end arch_spwFIFOInterface;
