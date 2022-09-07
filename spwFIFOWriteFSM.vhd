library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity spwFIFOWriteFSM is
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
end spwFIFOWriteFSM;

architecture arch_spwFIFOWriteFSM of spwFIFOWriteFSM is

type stato is (idle, writingLocs, waitWAck, waitLastWack, writeCmplt);

signal  statoAttuale,
        statoFuturo    : stato;

signal  writeEnSig,
        writeEnSigF,
        locsCntEnSig,
        locsCntEnSigF,
        dataReadySig,
        dataReadySigF  : std_logic;

signal  locsCnt        : natural range 0 to nLocs-1;

--attribute syn_preserve : boolean;
--attribute syn_keep     : boolean;
--
--attribute syn_preserve of writeEnSig   : signal is true;
--attribute syn_preserve of dataReadySig : signal is true;
--attribute syn_keep     of writeEnSig   : signal is true;
--attribute syn_keep     of dataReadySig : signal is true;

begin

writeEn   <= writeEnSig;
locSel    <= locsCnt;
dataReady <= dataReadySig;

------------- spwFIFO Write FSM
reg: process(rst, clk)
begin
	if rst='1' then
		statoAttuale <= idle;
        writeEnSig   <= '0';
        locsCntEnSig <= '0';
        dataReadySig <= '0';
	elsif rising_edge(clk) then
		statoAttuale <= statoFuturo;
        writeEnSig   <= writeEnSigF;
        locsCntEnSig <= locsCntEnSigF;
        dataReadySig <= dataReadySigF;
	end if;
end process;

comb: process(statoAttuale, startWrite, locsCnt, writeAck)
begin
	case statoAttuale is
		when idle =>
			if startWrite='1' then
                statoFuturo <= writingLocs;
			else
				statoFuturo <= idle;
			end if;

        when writingLocs =>
            if locsCnt=nLocs-1 then
                statoFuturo <= waitLastWack;
            else
                statoFuturo <= waitWack;
            end if;

        when waitWack =>
            if writeAck='1' then
                statoFuturo <= writingLocs;
            else
                statoFuturo <= waitWack;
            end if;

        when waitLastWack =>
            if writeAck='1' then
                statoFuturo <= writeCmplt;
            else
                statoFuturo <= waitLastWack;
            end if;

        when writeCmplt =>
                statoFuturo <= idle;

        when others =>
                statoFuturo <= idle;

	end case;
end process;

uscite: process(all)
begin
	case statoFuturo is
		when idle =>
            writeEnSigF   <= '0';
            locsCntEnSigF <= '0';
            dataReadySigF <= '0';

        when writingLocs =>
            writeEnSigF   <= '1';
            locsCntEnSigF <= '1';
            dataReadySigF <= '0';

        when waitWack =>
            writeEnSigF   <= '0';
            locsCntEnSigF <= '1';
            dataReadySigF <= '0';

        when waitLastWack =>
            writeEnSigF   <= '0';
            locsCntEnSigF <= '0';
            dataReadySigF <= '0';

        when writeCmplt =>
            writeEnSigF   <= '0';
            locsCntEnSigF <= '0';
            dataReadySigF <= '1';

        when others =>
            writeEnSigF   <= '0';
            locsCntEnSigF <= '0';
            dataReadySigF <= '0';
	end case;
end process;

locsCounter: process(all)
begin
    if rst='1' or dataReadySig='1' then
        locsCnt <= 0;
    elsif rising_edge(clk) then
        if writeAck='1' and locsCntEnSig='1' then
            locsCnt <= locsCnt + 1;
        end if;
    end if;
end process;

end arch_spwFIFOWriteFSM;
