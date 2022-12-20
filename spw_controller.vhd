--!----------------------------------------------------------------------------
--! $Product: $ GeminiX-Cores (C)
--! $Company: $ Neat s.r.l.
--!
--! $Author: fiorelli $ 
--! $Revision: 11895 $ 
--! $Date: 2021-02-08 14:18:42 +0100 (lun, 08 feb 2021) $ 
--!
--! $Id: spw_regfile.vhd 11895 2021-02-08 13:18:42Z fiorelli $
--!
--! History:
--!
--! Version  Date        Author         Change Description
--!
--!  x.y.z   dd/mm/aaaa  NEAT S.r.l.    First issue
--!
--!----------------------------------------------------------------------------

-------------------------------------------------------------------------------
--! Libraries declaration
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.hepd_gmx_pkg.all;
-------------------------------------------------------------------------------
--! Entity declaration
-------------------------------------------------------------------------------
entity spw_controller is

  generic (
  
    g_spw_addr_width  : integer := 16; --! spw address width generic parameter
    g_spw_data_width  : integer := 32; --! spw data width generic parameter
    g_spw_addr_offset : unsigned := x"0000";     --! component address offset generic parameter
    g_spw_num        : integer := 32; --! spw number generic parameter
    g_spw_idx        : unsigned(7 downto 0) := x"00"  --! unique ID index generic parameter
    
  );

  port (

    i_spw_clk           : in    std_logic;  --! system clock
    i_reset             : in    std_logic;  --! master active low reset
  
    --regfile interface
    i_data_in           : in    std_logic_vector(g_spw_data_width - 1 downto 0);  --! spw address from cpu
    o_data_out          : out    std_logic_vector(g_spw_data_width - 1 downto 0);     --! spw write data from cpu
    o_we                : out   std_logic;                                           --! spw enable from cpu
    o_addr              : out   std_logic_vector(g_spw_addr_width - 1 downto 0);                                           --! spw write enable from cpu    
    i_write_done        : in    std_logic;
    o_busy              : out  std_logic;

    --SPW interface
    i_txrdy             : in  std_logic;
    i_rxvalid           : in  std_logic;
    i_rxflag            : in  std_logic;
    i_rxdata            : in  std_logic_vector(7 downto 0);
    o_rxread            : out std_logic;
    o_txwrite           : out std_logic;
    o_txflag            : out std_logic;
    o_txdata            : out std_logic_vector(7 downto 0)


  );

end entity spw_controller;

-------------------------------------------------------------------------------
--! Architecture declaration
-------------------------------------------------------------------------------

architecture spw_controller_arch of spw_controller is

  
-------------------------------------------------------------------------------
-- Type Declaration
-------------------------------------------------------------------------------

type word_to_byte_t is array (natural range <>) of std_logic_vector(7 downto 0);
type register_mode_t is (RW, RO);
type mem_t is array (natural range <>) of std_logic_vector(g_spw_data_width - 1 downto 0);
--type addr_t is 
  --record
      --addr        : unsigned(g_spw_addr_width - 1 downto 0);
      --modeLocal   : register_mode_t;
      --modeRemote  : register_mode_t;
  --end record;
--type addr_vector_t is array (natural range <>) of addr_t;

-------------------------------------------------------------------------------
-- Constants Definitions
-------------------------------------------------------------------------------
  constant c_register_file_length    : integer := 20;

  --constant c_spw_ctrl_reg_address    : unsigned((g_spw_addr_width - 1) downto 0) := c_spw_ba + to_unsigned(1,g_spw_addr_width);

  constant c_spw_id_reg_data         : std_logic_vector((g_spw_data_width - 1) downto 0) := std_logic_vector(x"73707730" + g_spw_idx);
  constant c_spw_def_data            : std_logic_vector((g_spw_data_width - 1) downto 0) := c_spw_id_reg_data;
   
  constant c_spw_address_rst            : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"BADCACCA"; --! spw mismatch data register reset value @MMAP:rst     
  constant c_spw_write_data_rst         : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"BADCACCA"; --! spw mismatch address register reset value @MMAP:rst
  constant c_spw_read_data_rst          : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"BADCACCA"; --! spw reset interrupt register reset value @MMAP:rst   
  constant c_spw_start_command_rst      : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"BADCACCA"; --! spw reset interrupt register reset value @MMAP:rst   
  constant c_spw_status_rst             : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"BADCACCA"; --! spw reset interrupt register reset value @MMAP:rst   
  constant c_burst_count_rst            : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"00000001"; --! spw reset interrupt register reset value @MMAP:rst   
  constant c_spw_reset_rst              : std_logic_vector( (g_spw_data_width - 1) downto 0) := x"FFFFFFFF"; --! spw reset interrupt register reset value @MMAP:rst   

  constant c_eop : std_logic_vector(7 downto 0) := x"00";
  constant c_eep : std_logic_vector(7 downto 0) := x"01";
  constant c_write_command  : std_logic_vector(7 downto 0) := x"0C";    
  constant c_read_command   : std_logic_vector(7 downto 0) := x"03";    

  constant c_idle_tx          : std_logic_vector(2 downto 0) := "000";
  constant c_ready            : std_logic_vector(2 downto 0) := "001";
  constant c_sending_address  : std_logic_vector(2 downto 0) := "010";
  constant c_sending_data     : std_logic_vector(2 downto 0) := "011";
  constant c_closing          : std_logic_vector(2 downto 0) := "100";
  constant c_closed           : std_logic_vector(2 downto 0) := "101";

  constant c_idle               : std_logic_vector(3 downto 0) := "0000";
  constant c_get_address        : std_logic_vector(3 downto 0) := "0001";
  constant c_get_data           : std_logic_vector(3 downto 0) := "0010";
  constant c_wait_eop           : std_logic_vector(3 downto 0) := "0011";
  constant c_finish_rx          : std_logic_vector(3 downto 0) := "0100";
  constant c_execute_command    : std_logic_vector(3 downto 0) := "0101";
  constant c_reply              : std_logic_vector(3 downto 0) := "0110";
  constant c_wait_burst         : std_logic_vector(3 downto 0) := "0111";
  constant c_refresh_addr       : std_logic_vector(3 downto 0) := "1000";
  constant c_refresh_data       : std_logic_vector(3 downto 0) := "1001";

  constant c_spacewire_free_cmd       : std_logic_vector(7 downto 0) := x"00";
  constant c_spacewire_read_cmd       : std_logic_vector(7 downto 0) := x"03";
  constant c_spacewire_write_cmd      : std_logic_vector(7 downto 0) := x"0C";
  constant c_spacewire_post_write_cmd : std_logic_vector(7 downto 0) := x"30";
  constant c_spacewire_undef_cmd      : std_logic_vector(7 downto 0) := x"FF";
  constant c_read_burst_command       : std_logic_vector(7 downto 0) := x"EE";   

  constant c_sm_busy                   : std_logic_vector(31 downto 0) := x"62757379";
  constant c_sm_idle                   : std_logic_vector(31 downto 0) := x"69646c65";
  constant c_reset_cmd                 : std_logic_vector(31 downto 0) := x"69696969";

  constant c_burst_count_special_address : std_logic_vector(31 downto 0) := x"00000000";
-------------------------------------------------------------------------------
-- Signals Definitions
-------------------------------------------------------------------------------
  -- signals to drive the spw module

  signal s_data_to_send             : word_to_byte_t(3 downto 0);
  signal s_addr_to_send             : word_to_byte_t(3 downto 0);

  signal s_tx_data                  :   std_logic_vector(7 downto 0);
  signal s_tx_write                 :   std_logic;
  signal s_tx_flag                  :   std_logic;
  signal s_tx_rdy                   :   std_logic;

  signal s_command_received : std_logic_vector(7 downto 0);
  signal s_rx_address_byte  : word_to_byte_t(3 downto 0);
  signal s_rx_data_byte     : word_to_byte_t(3 downto 0);
  signal s_counter_rx : integer range 0 to 3;
  
  signal s_counter : integer range 0 to 3;
  signal s_command : std_logic_vector(7 downto 0);

  signal s_sm_status  : std_logic_vector(2 downto 0);
  signal s_sm_rx_status  : std_logic_vector(3 downto 0);

  signal s_burst_counter      : std_logic_vector(g_spw_data_width - 1 downto 0);
--  signal s_burst_counter      : unsigned(g_spw_data_width - 1 downto 0);
  signal s_reset                    :   std_logic;

  signal s_start_reply        :std_logic;
  signal s_addr_to_write_std  : std_logic_vector(g_spw_addr_width - 1 downto 0); 

  signal s_burst_count        : std_logic_vector(g_spw_data_width - 1 downto 0); 
  signal s_burst_count_uns        : unsigned(g_spw_data_width - 1 downto 0); 

  signal enBurstCounter,
         rstBurstCounter : std_logic;

component counter32BitSload is
port(
    Aclr   : in    std_logic;
    Sload  : in    std_logic;
    Clock  : in    std_logic;
    Enable : in    std_logic;
    Data   : in    std_logic_vector(31 downto 0);
    Q      : out   std_logic_vector(31 downto 0)
);
end component;

begin

-------------------------------------------------------------------------------
-- Input assignments
-------------------------------------------------------------------------------

  s_tx_rdy          <= i_txrdy;
  s_reset           <= i_reset;-- or s_reset_command_edge;
-------------------------------------------------------------------------------
-- Output assignments
-------------------------------------------------------------------------------

  o_txwrite         <= s_tx_write;
  o_txflag          <= s_tx_flag;
  o_txdata          <= s_tx_data;

  o_addr <= s_addr_to_write_std;
  o_busy <= '1' when ((s_sm_status /= c_idle_tx) or (s_sm_rx_status /= c_idle)) else '0';

-------------------------------------------------------------------------------
-- Internal assignments
-------------------------------------------------------------------------------                        
  s_burst_count_uns <= unsigned(s_burst_count);
-------------------------------------------------------------------------------
-- Processes declarations
-------------------------------------------------------------------------------

  
  send_process: process (i_spw_clk, s_reset)

  begin

    if (s_reset = '1') then
      
      s_sm_status           <= c_idle_tx;
      s_tx_write            <= '0';
      s_tx_flag             <= '0';
      s_counter             <= 0;
      s_sm_rx_status        <= c_idle;
      s_command_received    <= (others=>'0');
      s_counter_rx          <= 0;

      s_start_reply <= '0';

      rstBurstCounter <= '0';
      enBurstCounter <= '0';
      --s_burst_counter <= x"00000000";
      s_addr_to_write_std <= (others=>'0');
      s_tx_data <= (others=>'0');
      s_data_to_send <= (others=>(others=>'0'));
      s_rx_address_byte <=  (others=>(others=>'0'));
      s_rx_data_byte <=  (others=>(others=>'0'));
      s_addr_to_send <=  (others=>(others=>'0'));
      s_burst_count <= (others=>'0');

      o_data_out <= (others => '0');

      o_we <= '0';
      o_rxread <= '1';

    elsif(rising_edge(i_spw_clk)) then

      ----------------------------------------------
      -- Send command FSM
      ----------------------------------------------
      case (s_sm_status) is

        when c_idle_tx =>
          
          if(s_start_reply = '1')then

            s_sm_status <= c_ready;
    
          end if;

        when c_ready =>

          -- start to send
          if (s_tx_rdy = '1') then
            
            s_tx_write        <= '1';
            s_tx_flag         <= '0';
            s_tx_data         <= s_command;
            s_sm_status   <= c_sending_address;
            s_counter <= 0;

          end if;

        when c_sending_address =>

          -- send the address
          if (s_tx_rdy = '1') then

            s_tx_data(7 downto 0)  <= s_addr_to_send(s_counter);

            s_counter <= s_counter + 1;
            
            if (s_counter = 3) then

              s_sm_status      <= c_sending_data;
              s_counter    <= 0;

            end if;
            
          end if;
          
        when c_sending_data =>

          -- send the data
          if (s_tx_rdy = '1') then

            s_tx_data(7 downto 0)  <= s_data_to_send(s_counter);
            s_counter <= s_counter + 1;
            
            if (s_counter = 3) then

              s_sm_status  <= c_closing;
              s_counter    <= 0;
              
              if(s_command_received = c_read_burst_command) then 
                  enBurstCounter <= '1';
                --s_burst_counter <= s_burst_counter + 1;
              else
                  enBurstCounter <= '0';
              end if;

            end if;
            
          end if;
          
        when c_closing =>

          enBurstCounter <= '0';

          -- close connection sending a EOP
          if (s_tx_rdy = '1') then

            s_tx_flag <= '1';
            s_tx_data <= c_eop;
            s_sm_status <= c_closed;
            
          end if;
          
        when c_closed =>

          if (s_tx_rdy = '1') then

            s_tx_write <= '0';
            s_tx_flag  <= '0';
            s_sm_status <= c_idle_tx;
            s_start_reply <= '0';

          end if;

        when others =>

          s_tx_write <= '0';
          s_tx_flag  <= '0';
         
      end case;



      ----------------------------------------------
      -- Receive FSM
      ----------------------------------------------
      case (s_sm_rx_status) is

        when c_idle => 

          o_rxread  <= '1';
          s_start_reply <= '0';

          if ((i_rxvalid = '1') and (i_rxflag = '1')) then

            -- Invalid data received
            
          elsif (i_rxvalid = '1') then

            -- Valid data received, get the command and start to acquire address
            s_command_received  <= i_rxdata;
            s_sm_rx_status      <= c_get_address;
            s_counter_rx        <= 0;
            
          end if;

        when c_get_address =>

          -- Acquire the next 4 data byte as address
          
          o_rxread <= '1';

          if ( (i_rxvalid = '1') and (i_rxflag = '0') ) then

            -- Acquire address
            s_rx_address_byte(s_counter_rx) <= i_rxdata;
            s_counter_rx               <= s_counter_rx + 1; 
            
            if (s_counter_rx= 3) then

              -- Last address byte received
              s_sm_rx_status    <= c_get_data;
              s_counter_rx <= 0;

            end if;
            
          elsif ( i_rxvalid = '1' ) then

            -- Wrong data sequence
            
          end if;
          
        when c_get_data =>

          -- Acquire the next 4 data byte as data
          o_rxread <= '1';
          s_addr_to_write_std <= s_rx_address_byte(0);--s_rx_address_byte(3) & s_rx_address_byte(2) & s_rx_address_byte(1) & s_rx_address_byte(0);

          if ( (i_rxvalid = '1') and (i_rxflag = '0') ) then

            -- Acquire data
            s_rx_data_byte(s_counter_rx) <= i_rxdata;
            s_counter_rx            <= s_counter_rx+ 1; 
            
            if (s_counter_rx= 3) then

              -- Last data byte received
              s_sm_rx_status    <= c_wait_eop;
              s_counter_rx <= 0;

            end if;
            
          elsif ( i_rxvalid = '1' ) then

            -- Wrong data sequence

            
          end if;

        when c_wait_eop =>

          if(s_command_received = c_read_burst_command)then

            s_burst_count <= s_rx_data_byte(3) & s_rx_data_byte(2) & s_rx_data_byte(1) & s_rx_data_byte(0);
          
          end if;

          -- Complete the communication with EOP
          o_rxread <= '0';
          
          if ( (i_rxvalid = '1') and (i_rxflag = '1') and (i_rxdata = c_eop) ) then

            s_sm_rx_status <= c_execute_command;

          elsif (i_rxvalid = '1') then

            -- Wrong data sequence
            
          end if;
          
        when c_execute_command =>

          if(s_command_received = c_spacewire_write_cmd)then

            o_data_out <= s_rx_data_byte(3) & s_rx_data_byte(2) & s_rx_data_byte(1) & s_rx_data_byte(0);
            o_we <= '1';
          
            if(i_write_done = '1')then
            
              s_sm_rx_status <= c_idle;
              o_we <= '0';

            else
            
              s_sm_rx_status <= c_execute_command;

            end if;

          elsif(s_command_received = c_spacewire_read_cmd or s_command_received = c_read_burst_command)then
            
            s_sm_rx_status <= c_reply;
          
          else --command not valid

            s_sm_rx_status <= c_idle;

          end if;


        when c_reply =>

          s_command <= s_command_received;
          
          s_data_to_send(3) <= i_data_in(31 downto 24);
          s_data_to_send(2) <= i_data_in(23 downto 16);
          s_data_to_send(1) <= i_data_in(15 downto 8) ;
          s_data_to_send(0) <= i_data_in(7 downto 0)  ;
          
          s_addr_to_send(3) <= (others => '0');
          s_addr_to_send(2) <= (others => '0');
          s_addr_to_send(1) <= (others => '0');
          s_addr_to_send(0) <= s_addr_to_write_std;

          s_start_reply <= '1';

          if(s_command_received = c_read_burst_command)then

            s_sm_rx_status <= c_wait_burst;

          else

            s_sm_rx_status <= c_idle;

          end if;

        when c_wait_burst =>
          
          if(unsigned(s_burst_counter) = s_burst_count_uns)then 

            s_sm_rx_status <= c_idle;
            rstBurstCounter <= '1';
            --s_burst_counter <= x"00000000";

          else

            rstBurstCounter <= '0';

            if(s_sm_status = c_closed and s_tx_rdy = '1')then
            
              s_addr_to_write_std <= std_logic_vector(unsigned(s_addr_to_write_std) + 1);
              s_sm_rx_status <= c_refresh_addr;

            end if;

          end if;

        when c_refresh_addr => 
          
          s_sm_rx_status <= c_refresh_data;

        when c_refresh_data => 
          
          s_sm_rx_status <= c_reply;

        when others =>

          -- something wrong, reset.

      end case;

    end if;

  end process send_process;

burstCounterInst: counter32BitSload
port map(
    Aclr   => s_reset,
    Sload  => rstBurstCounter,
    Clock  => i_spw_clk,
    Enable => enBurstCounter,
    Data   => (others => '0'),
    Q      => s_burst_counter
);
  

end architecture spw_controller_arch;