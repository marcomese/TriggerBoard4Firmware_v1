library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trgValidFSM is
generic(
    nTrg        : natural;
    nClk        : natural
);
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    trigger     : in  std_logic;
    extTrg      : in  std_logic;
    veto        : in  std_logic_vector(1 downto 0);
    vetoExtSel  : in  std_logic_vector(7 downto 0);
    trgMasks    : in  std_logic_vector(nTrg-1 downto 0);
    validMasks  : out std_logic_vector(nTrg-1 downto 0);
    trgValid    : out std_logic;
    trgNotValid : out std_logic
);
end trgValidFSM;

architecture architecture_trgValidFSM of trgValidFSM is

type    state is (idle, waitNclk, checkTriggers, trgValidState, trgInvalidState);

signal  currState,
        nextState                      : state;

signal  validMasksSig, validMasksSigF  : std_logic_vector(nTrg-1 downto 0);

signal  vetoSig, extTrgSig,
        trgValidSig, trgValidSigF,
        trgInvalidSig, trgInvalidSigF,
        enClkCntSig, enClkCntSigF,
        rstClkCntSig, rstClkCntSigF    : std_logic;

signal  clkCounter                     : natural range 0 to nClk;

begin

validMasks  <= validMasksSig;

trgValid    <= trgValidSig;

trgNotValid <= trgInvalidSig;

extTrgSig <= extTrg and vetoExtSel(2);

vetoSig   <= (veto(1) and vetoExtSel(1)) or (veto(0) and vetoExtSel(0));

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState     <= idle;
        validMasksSig <= (others => '0');
        trgValidSig   <= '0';
        trgInvalidSig <= '0';
        enClkCntSig   <= '0';
        rstClkCntSig  <= '1';
    elsif rising_edge(clk) then
        currState     <= nextState;
        validMasksSig <= validMasksSigF;
        trgValidSig   <= trgValidSigF;
        trgInvalidSig <= trgInvalidSigF;
        enClkCntSig   <= enClkCntSigF;
        rstClkCntSig  <= rstClkCntSigF;
    end if;
end process;

combProc: process(currState, trgMasks, trigger, clkCounter, extTrgSig, vetoSig)
begin
    case currState is
        when idle =>
            if trigger = '1' then
                nextState <= waitNclk;
            elsif extTrgSig = '1' then
                nextState <= trgValidState;
            else
                nextState <= idle;
            end if;

        when waitNclk =>
            if clkCounter = nClk-1 then
                nextState <= checkTriggers;
            else
                nextState <= waitNclk;
            end if;

        when checkTriggers =>
            if unsigned(trgMasks) /= 0 and vetoSig = '0' then
                nextState <= trgValidState;
            else
                nextState <= trgInvalidState;
            end if;

        when trgValidState =>
            nextState <= idle;

        when trgInvalidState =>
            nextState <= idle;

        when others =>
            nextState <= idle;
    end case;
end process;

outProc: process(nextState, trgMasks)
begin
    case nextState is
        when idle =>
            trgValidSigF   <= '0';
            validMasksSigF <= (others => '0');
            trgInvalidSigF <= '0';
            enClkCntSigF   <= '0';
            rstClkCntSigF  <= '1';

        when waitNclk =>
            trgValidSigF   <= '0';
            validMasksSigF <= (others => '0');
            trgInvalidSigF <= '0';
            enClkCntSigF   <= '1';
            rstClkCntSigF  <= '0';

        when checkTriggers =>
            trgValidSigF   <= '0';
            validMasksSigF <= (others => '0');
            trgInvalidSigF <= '0';
            enClkCntSigF   <= '0';
            rstClkCntSigF  <= '0';

        when trgValidState =>
            trgValidSigF   <= '1';
            validMasksSigF <= trgMasks;
            trgInvalidSigF <= '0';
            enClkCntSigF   <= '0';
            rstClkCntSigF  <= '1';

        when trgInvalidState =>
            trgValidSigF   <= '0';
            validMasksSigF <= trgMasks;
            trgInvalidSigF <= '1';
            enClkCntSigF   <= '0';
            rstClkCntSigF  <= '1';

        when others =>
            trgValidSigF   <= '0';
            validMasksSigF <= (others => '0');
            trgInvalidSigF <= '0';
            enClkCntSigF   <= '0';
            rstClkCntSigF  <= '1';
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

end architecture_trgValidFSM;
