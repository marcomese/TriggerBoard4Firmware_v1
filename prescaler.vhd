library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescaler is
generic(
    holdoffBits : natural := 16
);
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(holdoffBits-1 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end prescaler;

architecture architecture_prescaler of prescaler is

component counter16Bit is
port(
    Aclr   : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Q      : out std_logic_vector(15 downto 0)
);
end component;

--constant maxHoldoff        : natural := natural(2**holdoffBits-1);
--
--signal   holdoffCount      : natural range 0 to maxHoldoff-1;

signal  holdoffCount : std_logic_vector(holdoffBits-1 downto 0);

signal  enableCount,
        clearCount   : std_logic; 

begin

-- per migliorare il timing uso un contatore look-ahead!!!

clearCount <= '1' when holdoffCount = holdoff else '0';

holdoffCounterInst: counter16Bit
port map(
    Aclr   => clearCount,
    Clock  => clk,
    Enable => triggerIn,
    Q      => holdOffCount
);

--holdoffProc: process(clk, rst, triggerIn)
--begin
    --if rst = '1' then
        --holdoffCount <= 0;
        --triggerOut   <= '0';
    --elsif rising_edge(clk) then
        --if holdoffCount = unsigned(holdoff) then
            --holdoffCount <= 0;
            --triggerOut <= '1';
        --elsif triggerIn = '1' then
            --holdoffCount <= holdoffCount + 1;
            --triggerOut <= '0';
        --elsif triggerIn = '0' then
            --holdoffCount <= holdoffCount;
            --triggerOut  <= '0';
        --end if;
    --end if;
--end process;

end architecture_prescaler;
