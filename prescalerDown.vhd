library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescalerDown is
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
end prescalerDown;

architecture architecture_prescalerDown of prescalerDown is

component counter16BitSloadDown is
port(
    Aclr   : in  std_logic;
    Sload  : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Data   : in  std_logic_vector(15 downto 0);
    Tcnt   : out std_logic; 
    Q      : out std_logic_vector(15 downto 0)
);
end component;

signal   loadHoldoff,
         TcntSig         : std_logic;

begin

triggerOut <= TcntSig;

-- per migliorare il timing uso un contatore look-ahead!!!

holdoffCounterInst: counter16BitSloadDown
port map(
    Aclr   => rst,
    Sload  => TcntSig,
    Clock  => clk,
    Enable => triggerIn,
    Data   => holdoff,
    Tcnt   => TcntSig,
    Q      => open
);

end architecture_prescalerDown;
