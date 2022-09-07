library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pulseExpand is
port(
    clkOrig  : in  std_logic;
    clkDest  : in  std_logic;
    rst      : in  std_logic;
    pulseIN  : in  std_logic;
    pulseOUT : out std_logic
);
end pulseExpand;

architecture Behavioral of pulseExpand is

type stateOrig is (idle, startPulse);
type stateDest is (idle, pulseOn);

signal origStP, origStF : stateOrig;
signal destStP, destStF : stateDest;

signal  startPulseP,
        startPulseF,
        stopPulseP,
        stopPulseF      : std_logic;

--attribute syn_preserve : boolean;

--attribute syn_preserve of startPulseP : signal is True;
--attribute syn_preserve of stopPulseP  : signal is True;

begin

pulseOUT <= stopPulseP;

origSeqProc: process(clkOrig,rst)
begin
    if rst = '1' then
        origStP <= idle;
        
        startPulseP <= '0';
    elsif rising_edge(clkOrig) then
        origStP <= origStF;
        
        startPulseP <= startPulseF;
    end if;
end process;

origCombProc: process(origStP,stopPulseP,pulseIN)
begin
    case origStP is
        when idle =>
            if pulseIN = '1' then
                origStF <= startPulse;
            else
                origStF <= idle;
            end if;

        when startPulse =>
            if stopPulseP = '1' then
                origStF <= idle;
            else
                origStF <= startPulse;
            end if;

        when others =>
                origStP <= idle;
    end case;
end process;

origOutProc: process(origStF)
begin
    case origStF is
        when idle =>
            startPulseF <= '0';
        
        when startPulse =>
            startPulseF <= '1';

        when others =>
            startPulseF <= '0';
    end case;
end process;

destSeqProc: process(clkDest,rst)
begin
    if rst = '1' then
        destStP <= idle;
        
        stopPulseP <= '0';
    elsif rising_edge(clkDest) then
        destStP <= destStF;
        
        stopPulseP <= stopPulseF;
    end if;
end process;

destCombProc: process(destStP, startPulseP)
begin
    case destStP is
        when idle =>
            if startPulseP = '1' then
                destStF <= pulseOn;
            else
                destStF <= idle;
            end if;

        when pulseOn =>
                destStF <= idle;

        when others =>
                destStF <= idle;
    end case;
end process;

destOutProc: process(destStF)
begin
    case destStF is
        when idle =>
            stopPulseF <= '0';
        
        when pulseOn =>
            stopPulseF <= '1';

        when others =>
            stopPulseF <= '0';
    end case;
end process;

end Behavioral;
