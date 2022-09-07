library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity powerOnResetFSM is
generic(
    rstTime : natural := 48
);
port (
	clk     : in  std_logic;
    rstIN   : in  std_logic;
    rstOUT  : out std_logic
);
end powerOnResetFSM;

architecture architecture_powerOnResetFSM of powerOnResetFSM is

type FSMstates is (idle,
                   waitPwrOn,
                   endRST);

signal  currState, 
        nextState       : FSMstates;

signal  pwrOnResetCount : natural range 0 to rstTime;

signal  rstOUTSig,
        rstOUTSigNext,
        pwrOKSig,
        pwrOKSigNext    : std_logic;

begin

rstOUT <= rstOUTSig;

seqProc: process(rstIN, clk)
begin
    if rstIN = '1' then
        currState <= idle;
        rstOUTSig <= '1';
        pwrOKSig  <= '0';
    elsif rising_edge(clk) then
        currState <= nextState;
        rstOUTSig <= rstOUTSigNext;
        pwrOKSig  <= pwrOKSigNext;
    end if;
end process;

combProc: process(currState, rstIN, pwrOnResetCount)
begin
    case currState is
        when idle =>
            if rstIN = '0' then
                nextState <= waitPwrON;
            else
                nextState <= idle;
            end if;

        when waitPwrON =>
            if pwrOnResetCount = rstTime-1 then
                nextState <= endRST;
            else
                nextState <= waitPwrON;
            end if;
        
        when endRST =>
                nextState <= endRST;

        when others =>
                nextState <= endRST;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            rstOUTSigNext <= '1';
            pwrOKSigNext  <= '0';

        when waitPwrON =>
            rstOUTSigNext <= '1';
            pwrOKSigNext  <= '0';

        when endRST =>
            rstOUTSigNext <= '0';
            pwrOKSigNext  <= '1';

        when others =>
            rstOUTSigNext <= '0';
            pwrOKSigNext  <= '1';
    end case;
end process;

powerOnResetCounter: process(clk, rstIn, pwrOKSig, pwrOnResetCount)
begin
    if rstIN = '1' or pwrOKSig = '1' then
        pwrOnResetCount  <= 0;
    elsif rising_edge(clk) then
        pwrOnResetCount  <= pwrOnResetCount + 1;
    end if;
end process;

end architecture_powerOnResetFSM;
