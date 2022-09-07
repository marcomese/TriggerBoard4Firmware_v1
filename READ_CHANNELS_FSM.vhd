--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: READ_CHANNELS_FSM.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;
-------------------------------------


entity READ_CHANNELS_FSM is
          port (
                reset           : in std_logic;
				clock           : in std_logic;   
                clock200        : in std_logic;   -- clock a 200 kHz
				read_command    : in std_logic;

				fineconv        : in std_logic;   -- 04 03 2016

                hold_B          : out std_logic;  -- attivo ALTO
                                                  -- ATTENZIONE: è diverso da EASIROC
				CLK_READ        : out std_logic;  -- attivo sul fronte di salita
                SR_IN_READ      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                                  -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
				RST_B_READ      : out std_logic;  -- attivo basso 
                                                  -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
                
                data_ready      : out std_logic;
                enable_ADC      : out std_logic;
                ext_channels_nr : out std_logic_vector(4 downto 0)
				);
end READ_CHANNELS_FSM;

architecture Behavioral of READ_CHANNELS_FSM is

type state_values is (       wait_state,                -- hold = '0'
                                                        -- sistema in attesa
                             hold_state,                -- hold = '1'
                                                        -- inizia il processo di lettura, stato di transizione
                             reset_state,               -- hold = '1'
                                                        -- per iniziare l'acquisizione bisogna resettare il registo di read
                             start_read_state,          -- hold = '1'
                                                        -- SR_IN deve andare a '1' per un colpo di CLK_READ: 
                                                        -- sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
                             read_state,                -- hold = '1'
                                                        -- 31 colpi di clock, fino a quando SR_OUT non va a '1'
                             store_state                -- hold = '1'
                                                        -- stato di transizione in cui ci memorizza il dato							 
                    );
signal pres_state, next_state: state_values;

constant RESET_LENGHT : integer := 6; -- Lenght of the reset to EASIROC READ register (number of 200 KHz clock cycles)
constant TOTAL_CHANNELS_NR : integer := 32; -- Number of channels

signal channels_nr : integer range 0 to TOTAL_CHANNELS_NR - 1 := 0;
signal reset_cnt : integer range 0 to RESET_LENGHT := 0;

signal SR_IN_READ_sig, CLK_READ_sig, SR_IN_READ_i, CLK_READ_i, store_sig, store_sig_i, enable_ADC_sig, enable_ADC_i: std_logic := '0';
signal RST_B_READ_sig, hold_b_i, RST_B_READ_i : std_logic := '1';


begin

-- FSM register

SYNC_PROC: process (clock,reset)
   begin
    	if reset='1' then 

			pres_state <= wait_state;

            hold_B        <= '0' ;  -- attivo ALTO
			CLK_READ_sig  <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_sig <= '0' ; -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                    -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_sig  <= '1' ;  -- attivo basso 
                                    -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig <= '0';
            enable_ADC_sig <= '0';

		elsif clock'event and clock='1' then
            
            pres_state <= next_state;
			
            hold_B     <= hold_B_i ;
			CLK_READ_sig   <= CLK_READ_i ;    
            SR_IN_READ_sig <= SR_IN_READ_i;
			RST_B_READ_sig <= RST_B_READ_i ;  
            store_sig <= store_sig_i;            
            enable_ADC_sig <= enable_ADC_i;

        end if;
end process;

			RST_B_READ <= RST_B_READ_sig;
            SR_IN_READ <= SR_IN_READ_sig;
  
            data_ready <= store_sig;
            enable_ADC <= enable_ADC_sig;


-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process (pres_state, reset_cnt, channels_nr, read_command, fineconv) 
begin
	
next_state <= pres_state;

case pres_state is

when wait_state => -- hold = '0'
                   -- sistema in attesa
		if read_command = '1' then
            next_state <= hold_state;
		else
			next_state <= wait_state;
		end if;

when hold_state => -- hold = '1'
                   -- inizia il processo di lettura, stato di transizione
		next_state <= reset_state;

when reset_state => -- hold = '1'
                   -- per iniziare l'acquisizione bisogna resettare il registro di read
		if reset_cnt < RESET_LENGHT-2 then
            next_state <= reset_state;
		else
			next_state <= start_read_state;
		end if;

when start_read_state => -- hold = '1'
                         -- SR_IN deve andare a '1' per un colpo di CLK_READ: sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
		if reset_cnt < RESET_LENGHT then
            next_state <= start_read_state;
		else
			next_state <= read_state;
		end if;

when read_state => -- hold = '1'
                   -- 31 colpi di clock, fino a quando SR_OUT non va a '1'
        if channels_nr = TOTAL_CHANNELS_NR - 1 then
            if fineconv = '1' then
                next_state <= store_state;
            else
                next_state <= read_state; 
            end if;
        else
			 next_state <= read_state; 
        end if;

when store_state => -- hold = '1'
                    -- stato di transizione in cui ci memorizza il dato							 
        next_state <= wait_state;

when others =>
	next_state <= wait_state;

end case;

end process;

OUTPUT_DECODE: process (next_state)

begin

if next_state = wait_state then -- hold = '0'
                            -- sistema in attesa

            hold_B_i        <= '0' ;  -- attivo ALTO
			CLK_READ_i      <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i    <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '0';

elsif next_state = hold_state then -- hold = '1'
                                   -- inizia il processo di lettura, stato di transizione

            hold_B_i        <= '1' ;  -- attivo ALTO
			CLK_READ_i      <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i      <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '0';

elsif next_state = reset_state then -- hold = '1'
                                    -- per iniziare l'acquisizione bisogna resettare il registo di read

            hold_B_i        <= '1' ;  -- attivo ALTO
			CLK_READ_i      <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i      <= '0' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '0';

elsif next_state = start_read_state then -- hold = '1'
                                         -- SR_IN deve andare a '1' per un colpo di CLK_READ: sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output

            hold_B_i        <= '1' ;  -- attivo ALTO
			CLK_READ_i      <= '1' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '1' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i    <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '0';

elsif next_state = read_state then -- hold = '1'
                                   -- 31 colpi di clock, fino a quando SR_OUT non va a '1'

            hold_B_i        <= '1' ;  -- attivo ALTO
			CLK_READ_i      <= '1' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i    <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '1';

elsif next_state = store_state then -- hold = '1'
                                    -- stato di transizione in cui ci memorizza il dato							 

            hold_B_i        <= '1' ;  -- attivo ALTO
			CLK_READ_i      <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i      <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '1';
            enable_ADC_i    <= '0';

else

            hold_B_i        <= '0' ;  -- attivo ALTO
			CLK_READ_i      <= '0' ;  -- attivo sul fronte di salita
            SR_IN_READ_i    <= '0' ;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                      -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
			RST_B_READ_i      <= '1' ;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
            store_sig_i     <= '0';
            enable_ADC_i    <= '0';

end if; 
end process;

-- contatore durata reset

process (clock200, reset) -- usa come clock lo stesso clock usato dalla memoria e per la configurazione della easiroc
begin
   if reset='1' then 
      reset_cnt <= 0;
   elsif (clock200 = '1' and clock200'event) then
			if RST_B_READ_sig = '0' or SR_IN_READ_sig = '1' then -- il contatore è abilitato solo negli stati di reset e start_read
				reset_cnt <= reset_cnt + 1;		
            else 
                reset_cnt <= 0;
			end if;
	end if;
end process;

-- contatore canali

process (clock200, reset) 
begin
   if reset='1' then 
      channels_nr <= 0;
   elsif (clock200 = '1' and clock200'event) then
			if (SR_IN_READ_sig = '1') then -- il contatore viene resettato ogni volta che si inizia la lettura
                                           -- SR_IN_READ è alto solo nello stato START_READ
				channels_nr <= 0;	
			elsif (enable_ADC_sig = '1') then -- il contatore conta le conversioni dell'ADC
				if channels_nr < TOTAL_CHANNELS_NR - 1  then
					channels_nr <= channels_nr + 1;
				end if;
			end if;
	end if;
end process;

ext_channels_nr(4 downto 0) <= std_logic_vector(to_unsigned(channels_nr,5));


CLK_READ <= CLK_READ_sig;

end Behavioral;

