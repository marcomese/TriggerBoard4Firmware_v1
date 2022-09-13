--===================================
----	Author		: R.Calvanese		     ----
----	File		: AD7814_T_IF_0.vhd   ----
----	Revision	: 1 	              ----
----	Date		:  28 Luglio 2022 		  ----     	
--===================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity AD7814_T_IF_0 is
  port(-------------------------------------------------------------	  
	  Clr : in std_logic;-- Active Low	async
	  clk : in std_logic;-- Fatt.div. /x interno ..
	  -- settare costante in funzione del sys_clk esterno ..
	  Start     : in std_logic;-- Active High	pulse  
	  Completed : out std_logic;-- Active High	pulse
	  Data_acquired: out std_logic_vector(9 downto 0);--10b Data out..
    -- serial I/F :
    Data_in : in std_logic;
    CS_out  : out std_logic;    
    Clk_out : out std_logic  	   	  
   );---------------------------------------------------------------
end entity AD7814_T_IF_0;
--
architecture Ar_AD7814_T_IF_0 of AD7814_T_IF_0 is
--
component ff_ce is
generic(clr_active	:std_logic:= '0';en_active	:std_logic:='1');
Port ( d :in std_logic;q :out std_logic;en  :in std_logic;clr :in std_logic;clk :in std_logic);
end component;
--
signal clk_div,togg_clk,clr_clk_cnt,en_shifter,Enable_acq_i: std_logic;
signal clr_cs_i,CS_i,clr_bit_cnt,en_bit_cnt,rst_RX_in: std_logic;
signal clk_cnt : std_logic_vector(4 downto 0);
signal bit_cnt : std_logic_vector(11 downto 0);
signal Start_acq_i,Start_acq_i_r,clr_clk,is_last_period,is_rising_r,is_rising : std_logic;
signal is_last_period_r,clr_enstat,is_last_period_r4 : std_logic;
signal Data_Acquired_int : std_logic_vector(15 downto 0);
signal is_last_valid_bit_r,is_last_valid_bit,c0,c1: std_logic;
signal q_ff : std_logic_vector(16 downto 0);
--
constant Delay_bit_cnt : std_logic_vector(11 downto 0):=X"20A";--<<
--
begin ----------------------------------------------------------------------------------------------
--
ff_bf_en: ff_ce generic map(clr_active =>'0',en_active =>'1')
  Port map (d=>'1',q=>Enable_acq_i,en=>Start,clr=>clr_enstat,clk=>clk);
clr_enstat <= clr and (not is_last_period_r);
-- 
ff_bf_str: ff_ce generic map(clr_active =>'0',en_active =>'1')
  Port map (d=>Start, q=>Start_acq_i, en=>'1',clr=>clr,clk=>clk );
ff_bf_str_r: ff_ce generic map(clr_active =>'0',en_active =>'1')
  Port map (d=>Start_acq_i, q=>Start_acq_i_r, en=>'1',clr=>clr,clk=>clk );
--
--
---------------------------------------------------------------------------
ff_CS_out : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>'1',q=>CS_i,en=>Start_acq_i,clr=>clr_CS_i,clk=>Clk);	
clr_CS_i <= clr and (not is_last_period_r);--
--
CS_out <= not CS_i;
--
---------------------------------------------------------------------------
-- sClk Generation .........
Clk_out <= not clk_div;
--
fflop_T2: process (clk)
  begin
    if (clk'event and clk = '1') then					
        if (clr_clk='0') then clk_div<='0';					
        else if (togg_clk='1') then clk_div <= not clk_div;
             end if;					
        end if;		
      end if;			
end process;	
clr_clk <= clr and (Enable_acq_i);-- 
--
cnt_for_clk_in: process(clk,clr_CLK_cnt) 
begin   
 if (clr_CLK_cnt='0') then CLK_cnt(4 downto 0) <="00000";
          else if (clk'event and clk='1') then	CLK_cnt<=CLK_cnt+'1';											
 end if;end if;			 
end process;		
--
clr_CLK_cnt <= clr and Enable_acq_i and (not is_last_period);-----
togg_clk<= '1' when (((CLK_cnt(4 downto 0)="11111")or(CLK_cnt(4 downto 0)="10000"))and(Enable_acq_i='1')) else '0';
--
is_rising<= '1' when ((CLK_cnt(4 downto 0)="11111")and(Enable_acq_i='1'))  else '0';
--
ff_is_rising_r : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>is_rising,q=>is_rising_r,en=>'1',clr=>clr,clk=>Clk);
--
--
-----------------------------------------------------
cnt_bits: process(clk,clr_bit_cnt) 
begin   
 if (clr_bit_cnt='0') then bit_cnt(11 downto 0)<=X"000";
          else if (clk'event and clk='1') then	
            if (en_bit_cnt='1') then bit_cnt<=bit_cnt+'1';											
            end if;
 end if;end if;		 
end process;		
--
clr_bit_cnt <= clr and Enable_acq_i and (not is_last_period_r);
--
ff_en_bit_cnt : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>'1',q=>en_bit_cnt,en=>Start_acq_i_r,clr=>clr_bit_cnt,clk=>Clk);	
--
--------------
--
is_last_period <= '1' when (bit_cnt>(Delay_bit_cnt-X"00C")) else '0';-- ultimo clock pulse..
--
ff_is_lst_p : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>is_last_period,q=>is_last_period_r,en=>'1',clr=>clr,clk=>Clk);	
--
ff_is_lst_p4 : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>is_last_period_r,q=>is_last_period_r4,en=>'1',clr=>clr,clk=>Clk);	
--
is_last_valid_bit <= '1' when (bit_cnt=(Delay_bit_cnt-X"08D")) else '0';-- al 10° bit !!!..
--
ff_is_lst_b : ff_ce generic map(clr_active=>'0',en_active=>'1')
Port map(d=>is_last_valid_bit,q=>is_last_valid_bit_r,en=>'1',clr=>clr,clk=>Clk);	
--
---------------------------------------------------
-- Data Input Section (serial acq..)
Par_out: for i in 16 downto 1 generate
ff_wce: process (clk,rst_RX_in)
begin
  if (rst_RX_in='0') then q_ff(i)<='0';
	              else	if (clk'event and clk='1') then	
	                 if (En_shifter='1') then q_ff(i)<=q_ff(i-1);								
				           end if;	
				        end if;				
	end if;				
end process;
end generate;
q_ff(0)<=Data_in; 
Data_Acquired_int(15 downto 0)<= q_ff(16 downto 1);
--
En_shifter <='1' when ((Enable_acq_i='1')and((Start_acq_i_r='1')or(is_rising_r='1'))) else '0';                                                                           
--
rst_RX_in <= clr and Enable_acq_i and (not Start_acq_i); 
--
RG_out: process (clk,clr) 
begin 
if (clr='0') then	Data_Acquired(9 downto 0)<="00" & X"00"; 
  else if (clk'event and clk='1') then													
			if (is_last_valid_bit_r='1') then Data_Acquired(9 downto 0)<=Data_Acquired_int(9 downto 0);								
			end if;						
end if;end if;			 
end process;		
--
---------------------------------------------------------------------------
ff_cmpl0: ff_ce generic map(clr_active=>'0',en_active=>'1') 
  Port map(d=>is_last_period_r4,q=>c0,en=>'1',clr=>clr,clk=>clk);
ff_cmpl1: ff_ce generic map(clr_active=>'0',en_active=>'1')
  Port map(d=>c0,q=>c1,en=>'1',clr=>clr,clk=>clk);    
ff_cmpl2: ff_ce generic map(clr_active=>'0',en_active=>'1') --  Completed ..
  Port map(d=>c1,q=>Completed,en=>'1',clr=>clr,clk=>clk);    
--
end Ar_AD7814_T_IF_0;-----------------------------------------------------------------------------