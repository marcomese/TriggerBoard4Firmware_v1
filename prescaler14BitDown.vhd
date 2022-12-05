library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity prescaler14BitDown is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    holdoff     : in  std_logic_vector(13 downto 0);
    triggerIn   : in  std_logic;
    triggerOut  : out std_logic
);
end prescaler14BitDown;

architecture architecture_prescaler14BitDown of prescaler14BitDown is

component counter14BitSloadDown is
port(
    Aclr   : in  std_logic;
    Sload  : in  std_logic;
    Clock  : in  std_logic;
    Enable : in  std_logic;
    Data   : in  std_logic_vector(13 downto 0);
    Tcnt   : out std_logic; 
    Q      : out std_logic_vector(13 downto 0)
);
end component;

signal   loadHoldoff,
         TcntSig         : std_logic;

begin

triggerOut <= TcntSig;

-- per migliorare il timing uso un contatore look-ahead!!!

holdoffCounterInst: counter14BitSloadDown
port map(
    Aclr   => rst,
    Sload  => TcntSig,
    Clock  => clk,
    Enable => triggerIn,
    Data   => holdoff,
    Tcnt   => TcntSig,
    Q      => open
);

end architecture_prescaler14BitDown;
