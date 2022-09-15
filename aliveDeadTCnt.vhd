library IEEE;
use IEEE.std_logic_1164.all;

entity aliveDeadTCnt is
port(
    clock      : in  std_logic;
    clock200k  : in  std_logic;
    reset      : in  std_logic;
    trgInhibit : in  std_logic;
    acqState   : in  std_logic;
    trigger    : in  std_logic;
    aliveCount : out std_logic_vector(31 downto 0);
    deadCount  : out std_logic_vector(31 downto 0);
    lostCount  : out std_logic_vector(15 downto 0)
);
end aliveDeadTCnt;

architecture architecture_aliveDeadTCnt of aliveDeadTCnt is

signal  ALIVE_TIME_count,
        DEAD_TIME_count,
        trigger_count     : std_logic_vector(31 downto 0);

signal  lost_count        : std_logic_vector(15 downto 0);

begin

aliveCount <= ALIVE_TIME_count;

deadCount  <= DEAD_TIME_count;

lostCount  <= lost_count;

LIVE_dead_register: process(clock, reset, acqStateIn, trgInhibit, trgIn)
begin
    if reset = '1' then
        live <= '0';
        dead <= '0';
    elsif rising_edge(clock) then
        if acqStateIn = '1' then
            if trgInhibit = '1' then
                live <= '0';
                dead <= '1';
            elsif trgInhibit = '0' and trgIn = '1' then 
                live <= '1';
                dead <= '0';
            else
                live <= '0';
                dead <= '0';                    
            end if;
        end if;
    end if;
end process;

ALIVE_COUNTER: process (clock200k, reset, trgInhibit) 
begin
   if reset= '1' then 
      ALIVE_TIME_count <= (OTHERS => '0');
    elsif rising_edge(clock200k) then
        if live = '1' and dead = '0' then 
            ALIVE_TIME_count <= ALIVE_TIME_count + 1;
        end if;       
   end if;
end process;

DEAD_counter: process (clock200k, reset, trgInhibit, trigger) 
begin
   if reset= '1' or (trgInhibit = '0' and trigger = '1') then 
      DEAD_TIME_count <= (OTHERS => '0');
    elsif rising_edge(clock200k) then
        if trgInhibit = '1' then 
            DEAD_TIME_count <= DEAD_TIME_count + 1;  
        end if;       
   end if;
end process;

alive_time_register: process(clock, reset)
    begin
        if reset='1' then
            ALIVE_TIME <= (OTHERS => '0');
    elsif rising_edge(clock) then
            if trigger = '1' then
                ALIVE_TIME <= ALIVE_TIME_count;
            end if;
        end if;
    end process;

dead_time_register: process(clock, reset)
    begin
        if reset='1' then
            lost <= (OTHERS => '0');
            DEAD_TIME <= (OTHERS => '0');
    elsif rising_edge(clock) then
            if DAQ_HOLD_N_rise = '1' then
                DEAD_TIME <= DEAD_TIME_count;
                lost <= lost_count;
            end if;
        end if;
    end process;

lost_trg_counter: process(clock, reset, trgInhibit, trigger) 
begin
   if reset= '1' or (trgInhibit = '0' and trigger = '1') then 
      lost_count <= (OTHERS => '0');
    elsif rising_edge(clock) then
        if acqStateIn = '1'and dead = '1' and trigger = '1' then 
            lost_count <= lost_count + 1;
        else
            lost_count <= (OTHERS => '0');
        end if;       
   end if;
end process;

end architecture_aliveDeadTCnt;
