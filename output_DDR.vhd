-- Version: v11.5 SP3 11.5.3.10

library ieee;
use ieee.std_logic_1164.all;
library proasic3l;
use proasic3l.all;

entity output_DDR is

    port( DataR : in    std_logic;
          DataF : in    std_logic;
          CLR   : in    std_logic;
          CLK   : in    std_logic;
          PAD   : out   std_logic
        );

end output_DDR;

architecture DEF_ARCH of output_DDR is 

  component OUTBUF
    port( D   : in    std_logic := 'U';
          PAD : out   std_logic
        );
  end component;

  component INV
    port( A : in    std_logic := 'U';
          Y : out   std_logic
        );
  end component;

  component DDR_OUT
    port( DR  : in    std_logic := 'U';
          DF  : in    std_logic := 'U';
          CLK : in    std_logic := 'U';
          CLR : in    std_logic := 'U';
          Q   : out   std_logic
        );
  end component;

  component VCC
    port(Y : out std_logic); 
  end component;

    signal CLRR, Q, \VCC\ : std_logic;
    signal VCC_power_net1 : std_logic;

begin 

    \VCC\ <= VCC_power_net1;

    \OUTBUF[0]\ : OUTBUF
      port map(D => Q, PAD => PAD);
    
    CLR_INV : INV
      port map(A => CLR, Y => CLRR);
    
    \DDR_OUT[0]\ : DDR_OUT
      port map(DR => DataR, DF => DataF, CLK => CLK, CLR => CLRR, 
        Q => Q);
    
    VCC_power_inst1 : VCC
      port map( Y => VCC_power_net1);


end DEF_ARCH; 

-- _Disclaimer: Please leave the following comments in the file, they are for internal purposes only._


-- _GEN_File_Contents_

-- Version:11.5.3.10
-- ACTGENU_CALL:1
-- BATCH:T
-- FAM:PA3
-- OUTFORMAT:VHDL
-- LPMTYPE:LPM_DDR
-- LPM_HINT:DDR_OUT_REG
-- INSERT_PAD:NO
-- INSERT_IOREG:NO
-- GEN_BHV_VHDL_VAL:F
-- GEN_BHV_VERILOG_VAL:F
-- MGNTIMER:F
-- MGNCMPL:T
-- DESDIR:C:/Users/Scotti/Desktop/trg_26_11/smartgen\output_DDR
-- GEN_BEHV_MODULE:F
-- SMARTGEN_DIE:IT10X10M3
-- SMARTGEN_PACKAGE:pq208
-- AGENIII_IS_SUBPROJECT_LIBERO:T
-- WIDTH:1
-- TYPE:
-- TRIEN_POLARITY:0
-- CLR_POLARITY:0

-- _End_Comments_

