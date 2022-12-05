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

component counter16BitSload is
port(
    Aclr   : in  std_logic;
    Sload  : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Data   : in   std_logic_vector(15 downto 0);
    Q      : out std_logic_vector(15 downto 0)
);
end component;

constant maxHoldoff      : natural := natural(2**holdoffBits-1);

signal   holdoffCount    : natural range 0 to maxHoldoff-1;

signal   holdoffCountVec : std_logic_vector(holdoffBits-1 downto 0);

signal   clearCount      : std_logic;

begin

triggerOut <= clearCount;

holdoffCount <= to_integer(unsigned(holdoffCountVec));

clearSyncInst: process(clk, rst)
begin
    if rst = '1' then
        clearCount <= '1';
    elsif rising_edge(clk) then
        clearCount <= '1' when (holdoffCount /= 0 and holdoffCount = unsigned(holdoff)) else '0';
    end if;
end process;

-- per migliorare il timing uso un contatore look-ahead!!!

holdoffCounterInst: counter16BitSload
port map(
    Aclr   => rst,
    Sload  => clearCount,
    Clock  => clk,
    Enable => triggerIn,
    Data   => (others => '0'),
    Q      => holdOffCountVec
);

end architecture_prescaler;
