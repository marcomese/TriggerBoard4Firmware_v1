library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity clkDiv2 is
port(
    rst    : in  std_logic;
    clkIn  : in  std_logic;
    clkOut : out std_logic
);
end clkDiv2;

architecture architecture_clkDiv2 of clkDiv2 is

signal  tFF : std_logic;

begin

clkOut <= tFF;

divProc: process(rst, clkIn)
begin
    if rst = '1' then
        tFF <= '0';
    elsif rising_edge(clkIn) then
        tFF <= not tFF;
    end if;
end process;

end architecture_clkDiv2;
