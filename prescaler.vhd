library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
    Sload  : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Data   : in  std_logic_vector(15 downto 0);
    Q      : out std_logic_vector(15 downto 0)
);
end component;

signal   holdoffCount : std_logic_vector(holdoffBits-1 downto 0);

signal   clearCount   : std_logic;

begin

triggerOut <= clearCount;

clearCount <= '1' when (unsigned(holdoffCount) /= 0 and holdoffCount = holdoff) else '0';

holdoffCounterInst: counter16Bit
port map(
    Aclr   => rst,
    Sload  => clearCount,
    Clock  => clk,
    Enable => triggerIn,
    Data   => (others => '0'),
    Q      => holdOffCount
);

end architecture_prescaler;
