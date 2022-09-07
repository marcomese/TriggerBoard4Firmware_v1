library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity watchDogCtrl is
generic(
    clkFreq   : real;
    wdiHWidth : real;
    wdiLWidth : real
);
port(
    clk : in  std_logic;
    rst : in  std_logic;
    wdi : out std_logic
);
end watchDogCtrl;

architecture architecture_watchDogCtrl of watchDogCtrl is

constant wdiHCount : natural := natural(ceil(wdiHWidth*clkFreq));
constant wdiLCount : natural := natural(ceil(wdiLWidth*clkFreq));

type state is (idle, wdiH, wdiL);

signal  currState,
        nextState               : state;

signal  wdiSig,     wdiSigF,
        wdiHEnSig,  wdiHEnSigF,
        wdiLEnSig,  wdiLEnSigF,
        wdiHRstSig, wdiHRstSigF,
        wdiLRstSig, wdiLRstSigF : std_logic;

signal  wdiHCounter             : natural range 0 to wdiHCount;
signal  wdiLCounter             : natural range 0 to wdiLCount;

begin

wdi <= wdiSig;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState  <= idle;
        wdiSig     <= '0';
        wdiHEnSig  <= '0';
        wdiLEnSig  <= '0';
        wdiHRstSig <= '1';
        wdiLRstSig <= '1';
    elsif rising_edge(clk) then
        currState  <= nextState;
        wdiSig     <= wdiSigF;
        wdiHEnSig  <= wdiHEnSigF;
        wdiLEnSig  <= wdiLEnSigF;
        wdiHRstSig <= wdiHRstSigF;
        wdiLRstSig <= wdiLRstSigF;
    end if;
end process;

combProc: process(currState, wdiHCounter, wdiLCounter)
begin
    case currState is
        when idle =>
                nextState <= wdiH;

        when wdiH =>
            if wdiHCounter = wdiHCount-1 then
                nextState <= wdiL;
            else
                nextState <= wdiH;
            end if;

        when wdiL =>
            if wdiLCounter = wdiLCount-1 then
                nextState <= wdiH;
            else
                nextState <= wdiL;
            end if;

        when others =>
                nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            wdiSigF     <= '0';
            wdiHEnSigF  <= '0';
            wdiLEnSigF  <= '0';
            wdiHRstSigF <= '1';
            wdiLRstSigF <= '1';

        when wdiH =>
            wdiSigF     <= '1';
            wdiHEnSigF  <= '1';
            wdiLEnSigF  <= '0';
            wdiHRstSigF <= '0';
            wdiLRstSigF <= '1';

        when wdiL =>
            wdiSigF     <= '0';
            wdiHEnSigF  <= '0';
            wdiLEnSigF  <= '1';
            wdiHRstSigF <= '1';
            wdiLRstSigF <= '0';

        when others =>
            wdiSigF     <= '0';
            wdiHEnSigF  <= '0';
            wdiLEnSigF  <= '0';
            wdiHRstSigF <= '1';
            wdiLRstSigF <= '1';
    end case;
end process;

wdiHCounterInst: process(clk, rst)
begin
    if rst = '1' then
        wdiHCounter <= 0;
    elsif rising_edge(clk) then
        if wdiHRstSig = '1' then
            wdiHCounter <= 0;
        elsif wdiHEnSig = '1' then
            wdiHCounter <= wdiHCounter + 1;
        end if;
    end if;
end process;

wdiLCounterInst: process(clk, rst)
begin
    if rst = '1' then
        wdiLCounter <= 0;
    elsif rising_edge(clk) then
        if wdiLRstSig = '1' then
            wdiLCounter <= 0;
        elsif wdiLEnSig = '1' then
            wdiLCounter <= wdiLCounter + 1;
        end if;
    end if;
end process;

end architecture_watchDogCtrl;
