library IEEE;
use IEEE.std_logic_1164.all;

entity antiGlitch is
generic(
    nClk   : natural
);
port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sigIn  : in  std_logic;
    sigOut : out std_logic
);
end antiGlitch;

architecture architecture_antiGlitch of antiGlitch is

type   state is (idle, clkCount, checkSig, sigValid);

signal currState,
       nextState                    : state;

signal clkCounter                   : natural range 0 to nClk;

signal sigOutSig, sigOutSigF,
       enClkCntSig, enClkCntSigF,
       rstClkCntSig, rstClkCntSigF  : std_logic;

begin

sigOut <= sigOutSig;

clkProc: process(clk, rst)
begin
    if rst = '1' then
        currState    <= idle;
        sigOutSig    <= '0';
        enClkCntSig  <= '0';
        rstClkCntSig <= '1';
    elsif rising_edge(clk) then
        currState    <= nextState;
        sigOutSig    <= sigOutSigF;
        enClkCntSig  <= enClkCntSigF;
        rstClkCntSig <= rstClkCntSigF;
    end if;
end process;

combProc: process(currState, sigIn, clkCounter)
begin
    case currState is
        when idle =>
            if sigIn = '1' then
                nextState <= clkCount;
            else
                nextState <= idle;
            end if;

        when clkCount =>
            if clkCounter = nClk-1 then
                nextState <= checkSig;
            elsif sigIn = '0' then
                nextState <= idle;
            else
                nextState <= clkCount;
            end if;

        when checkSig =>
            if sigIn = '0' then
                nextState <= idle;
            elsif sigIn = '1' then
                nextState <= sigValid;
            end if;

        when sigValid =>
            nextState <= idle;

        when others =>
            nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            sigOutSigF    <= '0';
            enClkCntSigF  <= '0';
            rstClkCntSigF <= '1';

        when clkCount =>
            sigOutSigF    <= '0';
            enClkCntSigF  <= '1';
            rstClkCntSigF <= '0';

        when checkSig =>
            sigOutSigF    <= '0';
            enClkCntSigF  <= '0';
            rstClkCntSigF <= '0';

        when sigValid =>
            sigOutSigF    <= '1';
            enClkCntSigF  <= '0';
            rstClkCntSigF <= '1';

        when others =>
            sigOutSigF    <= '0';
            enClkCntSigF  <= '0';
            rstClkCntSigF <= '1';
    end case;
end process;

clkCounterProc: process(clk, rst, enClkCntSig, rstClkCntSig)
begin
    if rst = '1' then
        clkCounter <= 0;
    elsif rising_edge(clk) then
        if rstClkCntSig = '1' then
            clkCounter <= 0;
        elsif enClkCntSig = '1' then
            clkCounter <= clkCounter + 1;
        else
            clkCounter <= clkCounter;
        end if;
    end if;
end process;

end architecture_antiGlitch;
