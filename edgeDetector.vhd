library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edgeDetector is
generic(
    edge      : std_logic := '0' -- '0' falling, '1' rising
);
port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    signalIn  : in  std_logic;
    signalOut : out std_logic
);
end edgeDetector;

architecture Behavioral of edgeDetector is

signal ff1,
       ff2 : std_logic;

begin

risingEdgeGen: if edge = '1' generate
    signalOut <= ff1 and not ff2;
end generate;

fallingEdgeGen: if edge = '0' generate
    signalOut <= not ff1 and ff2;
end generate;

edgeProc: process(clk,rst)
begin
    if rst = '1' then
        ff1 <= '0';
        ff2 <= '0';
    elsif rising_edge(clk) then
        ff1 <= signalIn;
        ff2 <= ff1;
    end if;
end process;

end Behavioral;
