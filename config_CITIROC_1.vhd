library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library proasic3l;
use proasic3l.all;

entity config_CITIROC_1 is
port(
    clk200k           : in std_logic;
    reset             : in std_logic;

    enable            : in std_logic;

    configure_command : in std_logic;
    config_vector     : in std_logic_vector(1143 downto 0);

    idle              : out std_logic;
    load              : out std_logic;
            
    select_reg        : out std_logic;  

    SR_IN_SR          : out std_logic;  
    RST_B_SR          : out std_logic;  
    CLK_SR            : out std_logic
);
end config_CITIROC_1 ;

architecture Behavioral of config_CITIROC_1 is

type state_values is (
    power_off,
    state0,
    reset_select0,
    reset_select1,
    config_state,    
    config_to_idle1, -- stato di transizione con clk200k abilitato
    config_to_idle2, -- stato di transizione con clk200k non abilitato e load = '0'
    load_state,      -- load = '1'
    probe_state,
    load_to_probe,
    probe_to_idle,
    idle_state
);

constant DATA_WIDTH : integer :=   1144; -- Width of command word
constant PROBE_WIDTH : integer :=   256; -- Width of probe word
constant RESET_LENGHT : integer :=   3; -- Lenght of the reset to CITIROC registers (number of 200 KHz clk200k cycles)

signal pres_state, next_state: state_values;

signal SR_IN_SR_i : std_logic;
signal select_reg_i, RST_B_SR_i, CLK_SR_i, CLK_SR_sig, idle_i, load_i: std_logic;
signal RST_B_SR_sig, select_reg_sig, state0_sig, state0_sig_i : std_logic;

signal bit_nr : integer range 0 to DATA_WIDTH - 1;
signal probe_bit_nr : integer range 0 to PROBE_WIDTH - 1;
signal reset_cnt : integer range 0 to 2*RESET_LENGHT + 1;
signal state0_cnt : integer range 0 to 100003;

signal Data_Conf: std_logic_vector(1143 downto 0);
signal PROBE_reg: std_logic_vector(255 downto 0);

--attribute syn_preserve : boolean;
--attribute syn_keep     : boolean;
--
--attribute syn_preserve of idle_i : signal is true;
--attribute syn_keep     of idle_i : signal is true;
--attribute syn_preserve of load_i : signal is true;
--attribute syn_keep     of load_i : signal is true;

begin

RST_B_SR <= RST_B_SR_sig;
select_reg <= select_reg_sig;

Data_Conf <= config_vector;
PROBE_reg <= (others => '0');

CLK_SR <= CLK_SR_sig;

SYNC_PROC: process(reset, clk200k)
begin
    if reset='1' then 
        pres_state     <= power_off;
        select_reg_sig <= '0';
        SR_IN_SR       <= '1'; 
        RST_B_SR_sig   <= '1'; -- attivo basso
--        CLK_SR_sig     <= '0'; -- attivo sul fronte di salita 
        CLK_SR_sig     <= '1'; -- pilota l'ingresso CLR di DDR_OUT quindi è attivo basso
        state0_sig     <= '1';
        idle           <= '0';
        load           <= '0';
    elsif rising_edge(clk200k) then
        pres_state     <= next_state;
        SR_IN_SR       <= SR_IN_SR_i;
        select_reg_sig <= select_reg_i;
        RST_B_SR_sig   <= RST_B_SR_i;
        CLK_SR_sig     <= CLK_SR_i;
        state0_sig     <= state0_sig_i;
        idle           <= idle_i;
        load           <= load_i;
    end if;
end process;

fsm: process(pres_state, reset_cnt, bit_nr, probe_bit_nr, configure_command, state0_cnt, enable)
begin
    next_state <= pres_state;

    case pres_state is
        when power_off =>
            if enable = '1' then
                next_state <= state0;
            else
                next_state <= power_off;
            end if;

        when state0 =>
            if state0_cnt < 100000 then 
                next_state <= state0;
            else
                next_state <= reset_select0;
            end if;

        when reset_select0 =>
            if reset_cnt < RESET_LENGHT then
                next_state <= reset_select0;
            else
                next_state <= reset_select1;
            end if;

        when reset_select1 =>
            if reset_cnt < 2*RESET_LENGHT then
                next_state <= reset_select1;
            else
                next_state <= config_state;
            end if;
                        
        when config_state =>
            if bit_nr = DATA_WIDTH - 1 then
                next_state <= config_to_idle1;
            else
                next_state <= config_state; 
            end if;

        when config_to_idle1 =>
            next_state <= config_to_idle2;
                  
        when config_to_idle2 =>
            next_state <= load_state;
                    
        when load_state =>
            next_state <= load_to_probe;

        when load_to_probe =>
            next_state <= probe_state;

        when probe_state =>
            if probe_bit_nr = PROBE_WIDTH -1 then
                next_state <= probe_to_idle;
            else
                next_state <= probe_state; 
            end if;	

        when probe_to_idle =>
            next_state <= idle_state;

        when idle_state =>
            if enable = '0' then
                next_state <= power_off;
            elsif (enable = '1' and configure_command = '1') then
                next_state <= state0;
            else 
                next_state <= idle_state;
            end if;

        when others =>
            next_state <= power_off;
    end case;
end process;

OUTPUT_DECODE: process(next_state, Data_Conf, PROBE_reg, bit_nr, probe_bit_nr)
begin
    if next_state = power_off then
        select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '1';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = state0 then
        select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '1';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = reset_select0 then
        select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '0'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = reset_select1 then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '0'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = config_state then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= Data_Conf(bit_nr); ------------------------------------------------------------
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '1'; ---------------------------------------------------------------- -- attivo sul fronte di salita 
        CLK_SR_i           <= '0'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = config_to_idle1 then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '1'; -- attivo sul fronte di salita ------------------------------------------------
        CLK_SR_i           <= '0'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = config_to_idle2 then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita ------------------------------------------------
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = load_state then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '1';

    elsif next_state = probe_state then
        select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg !!!!!!!!!!!!!!!!!!!!!!
        SR_IN_SR_i         <= PROBE_reg(probe_bit_nr); 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '1'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '0'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = load_to_probe then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg 
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita !!!!!!!!!!!!!!!!!!!!!! ancora abilitato
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = probe_to_idle then
        select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= PROBE_reg(probe_bit_nr); 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '1'; -- attivo sul fronte di salita ------------------------------------------------
        CLK_SR_i           <= '0'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';

    elsif next_state = idle_state then
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '1';
        load_i             <= '0';

    else 			
        select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
        SR_IN_SR_i         <= '1'; 
        RST_B_SR_i         <= '1'; -- attivo basso
--        CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
        CLK_SR_i           <= '1'; -- attivo basso
        state0_sig_i       <= '0';
        idle_i             <= '0';
        load_i             <= '0';
    end if;
end process;

-- contatore durata stato iniziale

initStateCounter: process(reset, idle_i, clk200k, state0_sig, state0_cnt, enable) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
    if reset='1' then 
        state0_cnt <= 0;
    elsif rising_edge(clk200k) then
        if idle_i = '1' or enable = '0' then
            state0_cnt <= 0;
        elsif state0_sig = '1' then -- il contatore è abilitato solo nello stato iniziale
            state0_cnt <= state0_cnt + 1;		
        end if;
    end if;
end process;

-- contatore durata reset

rstWidthCounter: process(reset, clk200k, RST_B_SR_sig, reset_cnt, idle_i, enable) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
    if reset='1' then 
        reset_cnt <= 0;
    elsif rising_edge(clk200k) then
        if idle_i = '1' or enable = '0' then
            reset_cnt <= 0;
        elsif RST_B_SR_sig = '0' then -- il contatore è abilitato solo negli stati di reset (config_state)
            reset_cnt <= reset_cnt + 1;		
        end if;
    end if;
end process;

-- contatore bit di configurazione

confBitCounter: process(reset, clk200k, RST_B_SR_sig, CLK_SR_sig, select_reg_sig, bit_nr, enable)
begin
    if reset='1' then 
        bit_nr <= 0;
    elsif rising_edge(clk200k) then
        if (RST_B_SR_sig = '0' or enable = '0') then -- il contatore viene resettato ogni volta che si resettano i registri
            bit_nr <= 0;	
        --elsif (CLK_SR_sig = '1' and select_reg_sig = '1') then -- il contatore è abilitato solo nello stato di configurazione e limitrofi (config_state, config_to_idle)
        -- cambiando la polarità di CLK_SR_sig anche questo va cambiato
        elsif (CLK_SR_sig = '0' and select_reg_sig = '1') then -- il contatore è abilitato solo nello stato di configurazione e limitrofi (config_state, config_to_idle)
            if bit_nr < DATA_WIDTH - 1  then
                bit_nr <= bit_nr + 1;
            end if;
        end if;
    end if;
end process;

-- contatore bit di probe

probeBitCounter: process(reset, clk200k, RST_B_SR_sig, CLK_SR_sig, probe_bit_nr, select_reg_sig, enable) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
    if reset='1' then 
        probe_bit_nr <= 0;
    elsif rising_edge(clk200k) then
        if (RST_B_SR_sig = '0' or enable = '0') then -- il contatore viene resettato ogni volta che si resettano i registri
            probe_bit_nr <= 0;
        --elsif (CLK_SR_sig = '1' and select_reg_sig = '0') then -- il contatore è abilitato solo nello stato di probe (probe_state)
        -- cambiando la polarità di CLK_SR_sig anche questo va cambiato
        elsif (CLK_SR_sig = '0' and select_reg_sig = '0') then -- il contatore è abilitato solo nello stato di probe (probe_state)
            if probe_bit_nr < PROBE_WIDTH - 1  then
                probe_bit_nr <= probe_bit_nr + 1;
            end if;
        end if;
    end if;
end process;

end Behavioral;
