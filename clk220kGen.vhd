library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity clk220kGen is
port(
    rst    : in  std_logic;
    clkIn  : in  std_logic;
    clkOut : out std_logic
);
end clk220kGen;

architecture architecture_clk220kGen of clk220kGen is

type state is (s0,s1);

signal curr_state, next_state: state;

signal clk200k_int_i, clk200k_int : STD_LOGIC;

signal count : integer range 0 to 120;

begin

clkOut <= clk200k_int;

SYNC_PROC: process(clkIn, rst)
begin
    if rst='1' then 
        curr_state<=s0;
        clk200k_int<='0';
    elsif rising_edge(clkIn) then
        curr_state <= next_state;
        clk200k_int <= clk200k_int_i;
  end if;
end process;

NEXT_STATE_DECODE: process(curr_state, count)
begin	 
    next_state <= curr_state;

    case curr_state is 
        when s0 => 
            if count=59 then
                next_state<= s1;
            else 
                next_state <= s0;
            end if;

         when s1 => 
            if count=119 then
                next_state<= s0;
            else 
                next_state <= s1;
            end if;
            
        when others =>
            next_state <= s0;
    end case;
end process;

	
OUTPUT_DECODE: process(next_state)
begin
    if next_state = s1 then
        clk200k_int_i <= '1';
    elsif next_state=s0 then
        clk200k_int_i <= '0';
    else 
        clk200k_int_i <= '0';
    end if;
end process;

-- contatore durata segnale

sigWidthCounter: process(rst, clkIn, count)
begin
    if rst = '1' then 
        count <= 0;
    elsif rising_edge(clkIn) then
        if count = 119 then
            count <= 0;
        else
            count <= count + 1;
        end if;
    end if;
end process;


end architecture_clk220kGen;
