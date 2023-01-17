library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescaler14Bit is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(13 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end prescaler14Bit;

architecture architecture_prescaler14Bit of prescaler14Bit is

component counter14Bit is
port(
    Aclr   : in  std_logic;
    Sload  : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Data   : in  std_logic_vector(13 downto 0);
    Q      : out std_logic_vector(13 downto 0)
);
end component;

constant holdoffBits     : natural := 14;

constant maxHoldoff      : natural := natural(2**holdoffBits-1);

signal   holdoffCount    : natural range 0 to maxHoldoff-1;

signal   holdoffCountVec : std_logic_vector(holdoffBits-1 downto 0);

signal   clearCount      : std_logic;

signal   trgOutSig       : std_logic;

begin

trgOutFF: process(clk, rst, trgOutSig)
begin
    if rst = '1' then
        triggerOut <= '0';
    elsif rising_edge(clk) then
        if trgOutSig = '1' then
            triggerOut <= triggerIn;
        else
            triggerOut <= '0';
        end if;
    end if;
end process;

holdoffCount <= to_integer(unsigned(holdoffCountVec));

trgOutSig <= '1' when (holdoffCount = unsigned(holdoff) - 1) else '0';

clearSyncInst: process(clk, rst)
begin
    if rst = '1' then
        clearCount <= '1';
    elsif rising_edge(clk) then
        clearCount <= trgOutSig and triggerIn;
    end if;
end process;

-- per migliorare il timing uso un contatore look-ahead!!!

holdoffCounterInst: counter14Bit
port map(
    Aclr   => rst,
    Sload  => clearCount,
    Clock  => clk,
    Enable => triggerIn,
    Data   => (others => '0'),
    Q      => holdOffCountVec
);

end architecture_prescaler14Bit;
