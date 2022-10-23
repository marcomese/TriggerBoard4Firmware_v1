library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity pulseExt is
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
end pulseExt;

architecture architecture_pulseExt of pulseExt is

type state is (idle, highState);

constant pulseCountVal   : natural := natural(clkFreq*pulseWidth);

signal   pulseCount      : natural range 0 to pulseCountVal;

signal   sigO, sigOF,
         cntEn, cntEnF,
         cntRst, cntRstF : std_logic;

signal   currState,
         nextState       : state;

begin

sigOut <= sigO;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState <= idle;
        sigO      <= '0';
        cntEn     <= '0';
        cntRst    <= '1';
    elsif rising_edge(clk) then
        currState <= nextState;
        sigO      <= sigOF;
        cntEn     <= cntEnF;
        cntRst    <= cntRstF;
    end if;
end process;

combProc: process(currState, sigIn, pulseCount)
begin
    case currState is
        when idle =>
            if sigIn = '1' then
                nextState <= highState;
            else
                nextState <= idle;
            end if;

        when highState =>
            if pulseCount = pulseCountVal-1 then
                nextState <= idle;
            else
                nextState <= highState;
            end if;

        when others =>
            nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            sigOF   <= '0';
            cntEnF  <= '0';
            cntRstF <= '1';

        when highState =>
            sigOF   <= '1';
            cntEnF  <= '1';
            cntRstF <= '0';

        when others =>
            sigOF   <= '0';
            cntEnF  <= '0';
            cntRstF <= '1';

    end case;
end process;

pulseCounterInst: process(clk, rst, cntEn, cntRst)
begin
    if rst = '1' then
        pulseCount <= 0;
    elsif rising_edge(clk) then
        if cntRst = '1' then
            pulseCount <= 0;
        elsif cntEn = '1' and pulseCount < pulseCountVal then
            pulseCount <= pulseCount + 1;
        else
            pulseCount <= 0;
        end if;
    end if;
end process;

end architecture_pulseExt;
