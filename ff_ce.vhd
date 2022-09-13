--=============================================
----	Author		  : R.Calvanese		  ----
----	File		  : ff_ce.vhd		   ----
----	Revision          : 2				   ----
----	Date		  : 3 October 2016 ----		      	
--=============================================
-- Library Definition
library ieee;
use ieee.std_logic_1164.all;
--=============================================================
-- Entity Description
entity ff_ce is
generic(clr_active	:std_logic:= '0';
         en_active	:std_logic:='1');
Port ( d :in std_logic;
       q :out std_logic;
       en  :in std_logic;
       clr :in std_logic;
       clk :in std_logic);
end ff_ce;
--=============================================================
-- Architecture Description
--
architecture rtl_ff_ce of ff_ce is	
begin -- of architecture
--
fflop_ce: process (clk,clr)
begin
if (clr = clr_active) then q<='0';
	  else if (clk'event and clk = '1') then					
				if (en = en_active) then	q<=d;								
				end if;						
	       end if;		
end if;			
end process;	
--
end rtl_ff_ce; -- of architecture