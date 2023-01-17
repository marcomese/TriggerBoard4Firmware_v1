library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trigger_extender_100ns_falling is
port(
    clock       : in  STD_LOGIC;
    reset       : in  STD_LOGIC;
    trigger_in  : in  STD_LOGIC;
    trigger_out : out  STD_LOGIC
);
end trigger_extender_100ns_falling;

architecture Behavioral of trigger_extender_100ns_falling is

constant TRG_LENGHT : integer := 10; -- Number of clock cycles 100MHz
--constant TRG_LENGHT : integer := 20; -- Number of clock cycles 200MHz
--constant TRG_LENGHT : integer := 19; -- Number of clock cycles 192MHz
--constant TRG_LENGHT : integer := 10; -- Number of clock cycles 96MHz
--constant TRG_LENGHT : integer := 5; -- Number of clock cycles 48MHz

--signal count : integer range 0 to TRG_LENGHT;

signal count : std_logic_vector(4 downto 0);

signal  trg_i, trg : std_logic;

--attribute syn_preserve : boolean;
--attribute syn_keep : boolean;
--
--attribute syn_preserve of trg_i : signal is true;
--attribute syn_keep     of trg_i : signal is true;

type state_values is (
    wait_state,   -- sistema in attesa
    trg_state     -- trg_state = '1'
);

signal pres_state, next_state: state_values;

signal counterRst, counterRstF : std_logic;

component counter5BitFalling is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(4 downto 0);
    Q      : out   std_logic_vector(4 downto 0)
);
end component;

begin

trigger_OUT <= trg;

SYNC_PROC: process(reset, clock)
begin
    if reset='1' then 
        pres_state  <= wait_state;
        trg <= '0' ;
        counterRst  <= '1';
    elsif falling_edge(clock) then
        pres_state  <= next_state;
        trg <= trg_i;
        counterRst  <= counterRstF;
    end if;
end process;
  	
fsm: process(pres_state, trigger_in, count)
begin
    case pres_state is
        when wait_state => -- sistema in attesa
            if trigger_in = '1' then
                next_state <= trg_state;
            else
                next_state <= wait_state;
            end if;
        when trg_state => 
            if unsigned(count) = TRG_LENGHT then
                next_state <= wait_state;
            else
                next_state <= trg_state;
            end if;

        when others =>
            next_state <= wait_state;
    end case;
end process;

OUTPUT_DECODE: process(next_state)
begin
    if next_state = wait_state then --  sistema in attesa
        trg_i <= '0' ;
        counterRstF <= '1';
    elsif next_state = trg_state then 
        trg_i <= '1' ;
        counterRstF <= '0';
    else
        trg_i <= '0' ;
        counterRstF <= '1';
    end if;
end process;

trgLenCounterInst: counter5BitFalling
port map(
    Aclr   => reset,
    Sload  => counterRst,
    Clock  => clock,
    Enable => trg,
    Data   => (others => '0'),
    Q      => count
);

-- contatore durata trigger
--trgWidthCounter: process(reset, clock, trg_i, count)
--begin
    --if reset='1' then 
        --count <= 0;
    --elsif rising_edge(clock) then
        --if (trg_i = '1') then -- il contatore è abilitato solo nello stato trg 
            --if count < TRG_LENGHT  then
                --count <= count + 1;
            --end if;
        --else 
            --count <= 0;                        
        --end if;
    --end if;
--end process;

end Behavioral;
