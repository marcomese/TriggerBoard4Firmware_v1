library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity citirocPwrCtrl is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    pwrStateIn  : in  std_logic;
    enPwrDigOut : out std_logic;
    enPwrAnaOut : out std_logic;
    pGoodDigIn  : in  std_logic;
    pGoodAnaIn  : in  std_logic
);
end citirocPwrCtrl;

architecture architecture_citirocPwrCtrl of citirocPwrCtrl is

type state is (idle, pwrOnDig, pwrOnAna, pwrOk);

signal  currState,
        nextState                       : state;

signal  enPwrDigOutSig, enPwrDigOutSigF,
        enPwrAnaOutSig, enPwrAnaOutSigF : std_logic;

begin

enPwrDigOut <= enPwrDigOutSig;
enPwrAnaOut <= enPwrAnaOutSig;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState      <= idle;
        enPwrDigOutSig <= '0';
        enPwrAnaOutSig <= '0';
    elsif rising_edge(clk) then
        currState      <= nextState;
        enPwrDigOutSig <= enPwrDigOutSigF;
        enPwrAnaOutSig <= enPwrAnaOutSigF;
    end if;
end process;

combProc: process(currState, pwrStateIn, pGoodDigIn, pGoodAnaIn)
begin
    case currState is
        when idle =>
            if pwrStateIn = '1' then
                nextState <= pwrOnDig;
            else
                nextState <= idle;
            end if;

        when pwrOnDig =>
            if pGoodDigIn = '1' then
                nextState <= pwrOnAna;
            else
                nextState <= pwrOnDig;
            end if;

        when pwrOnAna =>
            if pGoodAnaIn = '1' then
                nextState <= pwrOk;
            else
                nextState <= pwrOnAna;
            end if;

        when pwrOk =>
            if pwrStateIn = '1' then
                nextState <= pwrOk;
            else
                nextState <= idle;
            end if;
        when others =>
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            enPwrDigOutSigF <= '0';
            enPwrAnaOutSigF <= '0';

        when pwrOnDig =>
            enPwrDigOutSigF <= '1';
            enPwrAnaOutSigF <= '0';

        when pwrOnAna =>
            enPwrDigOutSigF <= '1';
            enPwrAnaOutSigF <= '1';

        when pwrOk =>
            enPwrDigOutSigF <= '1';
            enPwrAnaOutSigF <= '1';

        when others =>
            enPwrDigOutSigF <= '0';
            enPwrAnaOutSigF <= '0';
    end case;
end process;

end architecture_citirocPwrCtrl;
