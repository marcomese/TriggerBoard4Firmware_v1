library IEEE;
use IEEE.std_logic_1164.all;

entity dummyDpcuRegFile is
port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    enable       : in  std_logic;
    writeDataLen : in  std_logic;
    dataReadyOut : out std_logic;
    dpcuBusy     : out std_logic;
    dataLenOut   : out std_logic_vector(31 downto 0)
);
end dummyDpcuRegFile;

architecture architecture_dummyDpcuRegFile of dummyDpcuRegFile is

type state is (idle, busyState0, busyState1, busyState2, busyState3, writeDataLenState);


constant  dataLenVal     : std_logic_vector(31 downto 0) := x"00000048";

signal  currState,
        nextState        : state;

signal  dataLenSig       : std_logic_vector(31 downto 0);

signal  dpcuBusySig,
        dpcuBusySigF,
        wDataLenDpcuSig,
        wDataLenDpcuSigF,
        dataReady        : std_logic;

begin

dataReadyOut <= dataReady;
dataLenOut   <= dataLenSig;
dpcuBusy     <= dpcuBusySig;

regFileProc: process(clk, rst, writeDataLen, wDataLenDpcuSig)
begin
    if rst = '1' then
        dataLenSig <= (others => '0');
    elsif rising_edge(clk) then
        if writeDataLen = '1' then
            dataLenSig <= dataLenVal;
        end if;

        if wDataLenDpcuSig = '1' then
            dataLenSig <= (others => '0');
        end if;

        if dataLenSig = x"00000048" then
            dataReady <= '1';
        else
            dataReady <= '0';
        end if;

    end if;
end process;

--dpcu fsm
syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState       <= idle;
        dpcuBusySig     <= '1';
        wDataLenDpcuSig <= '0';
    elsif rising_edge(clk) then
        if enable = '1' then
            currState       <= nextState;
            dpcuBusySig     <= dpcuBusySigF;
            wDataLenDpcuSig <= wDataLenDpcuSigF;
        end if;
    end if;
end process;

combProc: process(currState, dataReady)
begin
    case currState is
        when idle =>
            if dataReady = '1' and dataLenSig = x"00000048" then
                nextState <= busyState0;
            else
                nextState <= idle;
            end if;

        when busyState0 =>
                nextState <= busyState1;

        when busyState1 =>
                nextState <= busyState2;

        when busyState2 =>
                nextState <= busyState3;

        when busyState3 =>
                nextState <= writeDataLenState;

        when writeDataLenState =>
                nextState <= idle;
        
        when others =>
                nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            dpcuBusySigF     <= '1';
            wDataLenDpcuSigF <= '0';
        when busyState0 =>
            dpcuBusySigF     <= '0';
            wDataLenDpcuSigF <= '0';
        when busyState1 =>
            dpcuBusySigF     <= '0';
            wDataLenDpcuSigF <= '0';
        when busyState2 =>
            dpcuBusySigF     <= '0';
            wDataLenDpcuSigF <= '0';
        when busyState3 =>
            dpcuBusySigF     <= '0';
            wDataLenDpcuSigF <= '0';
        when writeDataLenState =>
            dpcuBusySigF     <= '0';
            wDataLenDpcuSigF <= '1';
    end case;
end process;

end architecture_dummyDpcuRegFile;
