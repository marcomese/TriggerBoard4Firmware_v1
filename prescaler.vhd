library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescaler is
generic(
    holdoffBits : natural := 10
);
port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    holdoff    : in  std_logic_vector(holdoffBits-1 downto 0);
    triggerIn  : in  std_logic;
    triggerOut : out std_logic
);
end prescaler;

architecture architecture_prescaler of prescaler is

constant maxHoldoff        : natural := natural(2**holdoffBits-1);

signal   holdoffCount      : natural range 0 to maxHoldoff-1;

begin

--triggerOut <= not or_reduce(std_logic_vector(to_unsigned(holdoffCount,holdoffBits)) xor holdoff);

holdoffProc: process(clk, rst, triggerIn)
begin
    if rst = '1' then
        holdoffCount <= 0;
    elsif rising_edge(clk) then
        if holdoffCount = unsigned(holdoff) then
            holdoffCount <= 0;
            triggerOut <= '1';
        elsif triggerIn = '1' then
            holdoffCount <= holdoffCount + 1;
            triggerOut <= '0';
        elsif triggerIn = '0' then
            holdoffCount <= holdoffCount;
            triggerOut  <= '0';
        end if;
    end if;
end process;

end architecture_prescaler;
