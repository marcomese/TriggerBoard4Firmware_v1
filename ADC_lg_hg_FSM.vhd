library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library proasic3l;
use proasic3l.all;

entity ADC_lg_hg_FSM is
port(
    reset           : in std_logic;
    clock           : in std_logic;   
    enable_ADC      : in std_logic;
    ext_channels_nr : in std_logic_vector(4 downto 0);
    RST_B_READ      : in std_logic; 

    SDATA_hg        : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg        : in std_logic;    -- 2 leading '0' + 12 dati
            
    CS              : out std_logic;  -- attivo sul fronte di discesa
    SCLK            : out std_logic;  -- il dato cambia sul fronte di discesa

    hg_data_out     : out std_logic_vector(383 downto 0);
    lg_data_out     : out std_logic_vector(383 downto 0);
    fineconv        : out std_logic
);
end ADC_lg_hg_FSM;

architecture Behavioral of ADC_lg_hg_FSM is

type state_values is (
    wait_state,   -- sistema in attesa
    start_read_state,
    read_state,   -- inizia il processo di lettura, stato di transizione 14 colpi di clock
    store_state   -- stato di memorizzazione
							 );
signal pres_state, next_state: state_values;

constant ADC_BIT_NR : integer :=   14; -- Number of ADC bit + 2 leading '0'
constant TOTAL_CHANNELS_NR : integer := 32; -- Number of channels

signal channels_nr : integer range 0 to TOTAL_CHANNELS_NR - 1;
signal integer_channels_nr : integer range 0 to TOTAL_CHANNELS_NR - 1;

signal bit_nr : integer range 0 to ADC_BIT_NR - 1;

signal SCLK_i, SCLK_sig, store_sig, store_sig_i, fineconv_sig: std_logic;
signal CS_i, CS_sig : std_logic;
signal hg_data, lg_data : std_logic_vector(11 downto 0);

--signal lock_sig, clk48, clr_ODDR : std_logic := '0';

component sincro is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
end component;

COMPONENT ODDR2 is
    port( DataR : in    std_logic;
          DataF : in    std_logic;
          CLR   : in    std_logic;
          CLK   : in    std_logic;
          PAD   : out   std_logic
        );
end COMPONENT;

begin

-- FSM register

SYNC_PROC: process (clock,reset)
   begin
    	if reset='1' then 

			pres_state <= wait_state;

            CS_sig    <= '1' ;  -- attivo basso
--			SCLK_sig  <= '0' ;  -- attivo sul fronte di salita
            SCLK_sig  <= '1' ;  -- pilota l'ingresso CLR di DDR_OUT quindi è attivo basso
            store_sig <= '0' ;

		elsif clock'event and clock='1' then
            
            pres_state <= next_state;
			
            CS_sig     <= CS_i ;
			SCLK_sig   <= SCLK_i ;    
            store_sig  <= store_sig_i;

        end if;
end process;

    CS <= CS_sig;

-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process (pres_state, bit_nr, enable_ADC, integer_channels_nr, channels_nr) 
begin
	
case pres_state is

when wait_state => -- sistema in attesa
		if enable_ADC = '1' then
            if channels_nr = integer_channels_nr then
                next_state <= start_read_state;
            else
			    next_state <= wait_state;
            end if;
		else
			next_state <= wait_state;
		end if;

when start_read_state =>
	next_state <= read_state;

when read_state => -- 14 colpi di clock
        if bit_nr = ADC_BIT_NR - 1 then
             next_state <= store_state;
        else
			 next_state <= read_state; 
        end if;

when store_state =>
	next_state <= wait_state;

when others =>
	next_state <= wait_state;

end case;

end process;

OUTPUT_DECODE: process (next_state)

begin

if next_state = wait_state then --  sistema in attesa

            CS_i        <= '1' ;  -- attivo basso
--			SCLK_i      <= '0' ;  -- attivo sul fronte di salita
			SCLK_i      <= '1' ;  -- attivo basso
            store_sig_i <= '0' ;

elsif next_state = start_read_state then -- 1 colpo di clock

            CS_i        <= '1' ;  -- attivo basso
--			SCLK_i      <= '1' ;  -- attivo sul fronte di salita
			SCLK_i      <= '0' ;  -- attivo basso
            store_sig_i <= '0' ;            

elsif next_state = read_state then -- 14 colpi di clock

            CS_i        <= '0' ;  -- attivo basso
--			SCLK_i      <= '1' ;  -- attivo sul fronte di salita
			SCLK_i      <= '0' ;  -- attivo basso
            store_sig_i <= '0' ;

elsif next_state = store_state then 

            CS_i        <= '1' ;  -- attivo basso -----------------------------corretto????????
--			SCLK_i      <= '0' ;  -- attivo sul fronte di salita
			SCLK_i      <= '1' ;  -- attivo basso
            store_sig_i <= '1' ;

else

            CS_i        <= '1' ;  -- attivo basso
--			SCLK_i      <= '0' ;  -- attivo sul fronte di salita
			SCLK_i      <= '1' ;  -- attivo basso
            store_sig_i <= '0' ;

end if; 
end process;

-- ADC data register
    process (clock, reset)
    begin
        if reset = '1' then
				hg_data(11 downto 0) <= (others => '0');
				lg_data(11 downto 0) <= (others => '0');
		  elsif (clock'event and clock='1') then
            if CS_sig = '1' then
					hg_data(11 downto 0) <= (others => '0');
					lg_data(11 downto 0) <= (others => '0');
			elsif CS_sig = '0' then
					if bit_nr > 1 then
						hg_data(ADC_BIT_NR - 1 - bit_nr) <= SDATA_hg;
						lg_data(ADC_BIT_NR - 1 - bit_nr) <= SDATA_lg;
					end if;
			end if;
        end if;
    end process;

-- ADC data OUTPUT register
    process (clock, reset)
    begin
        if reset = '1' then
				hg_data_out(383 downto 0) <= (others => '0');
				lg_data_out(383 downto 0) <= (others => '0');
		elsif (clock'event and clock='1') then
            if store_sig ='1' then
				hg_data_out(11+channels_nr*12 downto 0+channels_nr*12) <= hg_data(11 downto 0); -- da invertire
				lg_data_out(11+channels_nr*12 downto 0+channels_nr*12) <= lg_data(11 downto 0); -- da invertire
			end if;
        end if;
    end process;


-- contatore canali
process (clock, reset) 
begin
   if reset='1' then 
      channels_nr <= 0;
      fineconv_sig <= '0';
   elsif (clock = '1' and clock'event) then
			if (RST_B_READ = '0') then -- il contatore viene resettato ogni volta che si resetta il registro
				channels_nr <= 0;	
                fineconv_sig <= '0';
			elsif (store_sig = '1') then   -- il contatore conta le conversioni dell'ADC
				if channels_nr < TOTAL_CHANNELS_NR - 1  then
					channels_nr <= channels_nr + 1;
                    fineconv_sig <= '0';
				elsif channels_nr = TOTAL_CHANNELS_NR - 1  then
					channels_nr <= 0;
                    fineconv_sig <= '1';				
                end if;
			end if;
	end if;
end process;

fineconv <= fineconv_sig;

-- contatore bit
process (clock, reset) 
begin
   if reset='1' then 
      bit_nr <= 0;
   elsif (clock = '1' and clock'event) then
			if (CS_sig = '1') then -- il contatore viene resettato ogni volta che si resetta il registro
				bit_nr <= 0;	
			elsif (CS_sig = '0') then -- il contatore è abilitato solo nello stato di lettura 
				if bit_nr < ADC_BIT_NR - 1  then
					bit_nr <= bit_nr + 1;
				end if;
			end if;
	end if;
end process;


SCLK <= SCLK_sig;

integer_channels_nr <= conv_integer(ext_channels_nr);

end Behavioral;
