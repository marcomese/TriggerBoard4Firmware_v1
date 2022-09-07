library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity genericSync is
generic(
    sigNum : natural := 4
);
port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sigIn  : in  std_logic_vector(sigNum-1 downto 0);
    sigOut : out std_logic_vector(sigNum-1 downto 0)
);
end genericSync;

architecture architecture_genericSync of genericSync is

signal  ffQ1,
        ffQ2 : std_logic_vector(sigNum-1 downto 0);

begin

sigOut <= ffQ2;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        ffQ1 <= (others => '0');
        ffQ2 <= (others => '0');
    elsif rising_edge(clk) then
        ffQ1 <= sigIn;
        ffQ2 <= ffQ1;
    end if;
end process;

end architecture_genericSync;
