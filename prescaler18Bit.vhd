library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescaler18Bit is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(17 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end prescaler18Bit;

architecture architecture_prescaler18Bit of prescaler18Bit is

component counter18Bit is
port(
    Aclr   : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Q      : out std_logic_vector(17 downto 0)
);
end component;

constant holdoffBits     : natural := 18;

constant maxHoldoff      : natural := natural(2**holdoffBits-1);

signal   holdoffCount    : natural range 0 to maxHoldoff-1;

signal   holdoffCountVec : std_logic_vector(holdoffBits-1 downto 0);

signal   clearCount      : std_logic;

begin

triggerOut <= clearCount;

holdoffCount <= to_integer(unsigned(holdoffCountVec));

clearProc: process(clk, rst, holdoffCount, holdoff)
begin
    if rst = '1' then
        clearCount <= '0';
    elsif rising_edge(clk) then
        if holdoffCount /= 0 and holdoffCount = unsigned(holdoff) then
            clearCount <= '1';
        else
            clearCount <= '0';
        end if;
    end if;
end process;

-- per migliorare il timing uso un contatore look-ahead!!!

holdoffCounterInst: counter18Bit
port map(
    Aclr   => rst or clearCount,
    Clock  => clk,
    Enable => triggerIn,
    Q      => holdOffCountVec
);

end architecture_prescaler18Bit;
