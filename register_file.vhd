library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_MISC.ALL;

entity register_file is
generic(
    sysid                 : std_logic_vector(31 downto 0) := x"00000000";
    refDac1Def            : std_logic_vector(31 downto 0);
    refDac2Def            : std_logic_vector(31 downto 0);
    dataWidth             : natural;
    prescaledTriggers     : natural;
    holdOffBits           : natural
);
port(
    clk                   : in std_logic;
    rst                   : in std_logic;
    we                    : in std_logic;
    en                    : in std_logic;
    addr                  : in std_logic_vector(31 downto 0);
    di                    : in std_logic_vector(31 downto 0);
    do                    : out std_logic_vector(31 downto 0);
    o_write_done          : out    std_logic;
    i_busy                : in std_logic;

    -- configuration
    config_vector         : out std_logic_vector(1143 downto 0);

    -- DAC piedistalli
    refDAC_1              : out std_logic_vector(31 downto 0); -- refDAC_1_HG (31 downto 16) refDAC_1_LG (15 downto 0)
    refDAC_2              : out std_logic_vector(31 downto 0); -- refDAC_2_HG (31 downto 16) refDAC_2_LG (15 downto 0)

    trigger_mask          : out std_logic_vector(31 downto 0);
    generic_trigger_mask  : out std_logic_vector(31 downto 0);
    PMT_mask_1            : out std_logic_vector(31 downto 0);
    PMT_mask_2            : out std_logic_vector(31 downto 0);

    -- Commands
    start_config_1      : out std_logic;
    start_config_2      : out std_logic;
    sw_rst              : out std_logic;
    pwr_on_citiroc1     : out std_logic; 
    pwr_on_citiroc2     : out std_logic;   
    start_debug         : out std_logic;   
    apply_trigger_mask  : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    apply_PMT_mask      : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    start_ACQ           : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    stop_ACQ            : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    start_cal           : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    stop_cal            : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)

    enableTsens         : out std_logic;

    -- Segnali da/verso DPCU e TDAQ
--    dataReady           : in  std_logic;
    TDAQ_BUSY           : in  std_logic;
    DPCU_TRGHOLD        : in  std_logic;
    DPCU_BUSY           : in  std_logic;
    dataReadyOut        : out std_logic;

    -- DAC piedistalli
    sendRefDAC          : out std_logic;

    -- status register
    config_status_1     : in std_logic; 
    config_status_2     : in std_logic; 
    acquisition_state   : in std_logic; -- = '1' quando il sistema � in acquisizione
    calibration_state   : in std_logic; -- = '1' quando il sistema � in calibrazione

    refDac_status_1     : in std_logic;
    refDac_status_2     : in std_logic;

    fifoPckCnt          : in  natural;

    writeDataLen        : in   std_logic;

    regAcqData          : in  std_logic_vector(dataWidth-1  downto 0);

    holdoff             : out std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    trgCounter          : in std_logic_vector(31 downto 0);
    ppsCounter          : in std_logic_vector(31 downto 0);

    calibPeriod         : out std_logic_vector(15 downto 0);

    PMT_rate            : in std_logic_vector(1023 downto 0);
    mask_rate           : in std_logic_vector(175 downto 0);
    mask_grb            : in std_logic_vector(31 downto 0);
    board_temp          : in std_logic_vector(31 downto 0)
);
end register_file;

-------------------------------------------------------------------------------
-- Architecture Declaration
-------------------------------------------------------------------------------

architecture Behavioral of register_file is

-------------------------------------------------------------------------------
-- Type and constant Declaration
-------------------------------------------------------------------------------

constant DATA_LENGHT        : integer := 32;
constant ADDR_LENGHT        : integer := 32;

constant RST_WORD           : std_logic_vector(31 downto 0) := x"0DA00DA0";

constant dataLenConst       : std_logic_vector(31 downto 0) := x"0000003E";

-- define the memory array
type mem_t is array (natural range <>) of std_logic_vector(DATA_LENGHT - 1 downto 0);

-- define the register mode: RW = read/write, RO = read only
type register_mode_t is (RW, RO);

-- define the base type for the address vector that store the address map table
type addr_t is 
record
    addr : std_logic_vector(ADDR_LENGHT - 1 downto 0);
    mode : register_mode_t;
end record;

-- define the type for the address vector that store the address map table
type addr_vector_t is array (natural range <>) of addr_t;

-- control registers
constant ID_REG_ADDR                  : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000000";
constant STATUS_REG_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000001";
constant RST_REG_ADDR                 : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000003"; -- 0x0DA00DA0
constant CLK_REG_ADDR                 : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000004";
constant RW_REG_ADDR                  : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000005";
constant CMD_REG_ADDR                 : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000008";
constant CONFIG_CITIROC_1_0_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000009";
constant CONFIG_CITIROC_1_1_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000A";
constant CONFIG_CITIROC_1_2_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000B";
constant CONFIG_CITIROC_1_3_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000C";
constant CONFIG_CITIROC_1_4_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000D";
constant CONFIG_CITIROC_1_5_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000E";
constant CONFIG_CITIROC_1_6_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000F";
constant CONFIG_CITIROC_1_7_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000010";
constant CONFIG_CITIROC_1_8_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000011";
constant CONFIG_CITIROC_1_9_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000012";
constant CONFIG_CITIROC_1_10_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000013";
constant CONFIG_CITIROC_1_11_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000014";
constant CONFIG_CITIROC_1_12_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000015";
constant CONFIG_CITIROC_1_13_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000016";
constant CONFIG_CITIROC_1_14_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000017";
constant CONFIG_CITIROC_1_15_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000018";
constant CONFIG_CITIROC_1_16_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000019";
constant CONFIG_CITIROC_1_17_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001A";
constant CONFIG_CITIROC_1_18_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001B";
constant CONFIG_CITIROC_1_19_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001C";
constant CONFIG_CITIROC_1_20_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001D";
constant CONFIG_CITIROC_1_21_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001E";
constant CONFIG_CITIROC_1_22_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001F";
constant CONFIG_CITIROC_1_23_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000020";
constant CONFIG_CITIROC_1_24_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000021";
constant CONFIG_CITIROC_1_25_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000022";
constant CONFIG_CITIROC_1_26_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000023";
constant CONFIG_CITIROC_1_27_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000024";
constant CONFIG_CITIROC_1_28_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000025";
constant CONFIG_CITIROC_1_29_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000026";
constant CONFIG_CITIROC_1_30_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000027";
constant CONFIG_CITIROC_1_31_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000028";
constant CONFIG_CITIROC_1_32_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000029";
constant CONFIG_CITIROC_1_33_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002A";
constant CONFIG_CITIROC_1_34_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002B";
constant CONFIG_CITIROC_1_35_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002C";
constant TRIGGER_MASK_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000051";
constant GENERIC_TRIGGER_MASK_ADDR    : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000052";
constant PMT_1_MASK_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000053";
constant PMT_2_MASK_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000054";
constant BOARD_TEMP_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000056";
constant PMT_RATE_00_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000057";
constant PMT_RATE_01_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000058";
constant PMT_RATE_02_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000059";
constant PMT_RATE_03_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005A";
constant PMT_RATE_04_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005B";
constant PMT_RATE_05_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005C";
constant PMT_RATE_06_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005D";
constant PMT_RATE_07_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005E";
constant PMT_RATE_08_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000005F";
constant PMT_RATE_09_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000060";
constant PMT_RATE_10_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000061";
constant PMT_RATE_11_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000062";
constant PMT_RATE_12_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000063";
constant PMT_RATE_13_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000064";
constant PMT_RATE_14_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000065";
constant PMT_RATE_15_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000066";
constant PMT_RATE_16_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000067";
constant PMT_RATE_17_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000068";
constant PMT_RATE_18_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000069";
constant PMT_RATE_19_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006A";
constant PMT_RATE_20_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006B";
constant PMT_RATE_21_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006C";
constant PMT_RATE_22_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006D";
constant PMT_RATE_23_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006E";
constant PMT_RATE_24_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000006F";
constant PMT_RATE_25_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000070";
constant PMT_RATE_26_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000071";
constant PMT_RATE_27_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000072";
constant PMT_RATE_28_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000073";
constant PMT_RATE_29_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000074";
constant PMT_RATE_30_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000075";
constant PMT_RATE_31_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000076";
constant MASK_RATE_00_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000077";
constant MASK_RATE_01_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000078";
constant MASK_RATE_02_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000079";
constant MASK_RATE_03_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007A";
constant MASK_RATE_04_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007B";
constant MASK_RATE_05_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007C";
constant STATUS_REG_MIR_ADDR          : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007D";
constant CMD_REG_MIR_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007E";
constant TRG_COUNTER_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000007F";
constant PPS_COUNTER_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000080";
constant MASK_RATE_GRB_ADDR           : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000081";
constant REF_DAC_1_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000A0";
constant REF_DAC_2_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000A1";
constant PCKTS_IN_FIFO_ADDR           : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B2";
constant ACQDATALEN_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B3";
constant ACQDATA0_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B4";
constant ACQDATA1_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B5";
constant ACQDATA2_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B6";
constant ACQDATA3_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B7";
constant ACQDATA4_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B8";
constant ACQDATA5_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000B9";
constant ACQDATA6_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BA";
constant ACQDATA7_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BB";
constant ACQDATA8_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BC";
constant ACQDATA9_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BD";
constant ACQDATA10_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BE";
constant ACQDATA11_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000BF";
constant ACQDATA12_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C0";
constant ACQDATA13_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C1";
constant ACQDATA14_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C2";
constant ACQDATA15_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C3";
constant ACQDATA16_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C4";
constant ACQDATA17_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C5";
constant ACQDATA18_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C6";
constant ACQDATA19_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C7";
constant ACQDATA20_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C8";
constant ACQDATA21_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000C9";
constant ACQDATA22_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CA";
constant ACQDATA23_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CB";
constant ACQDATA24_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CC";
constant ACQDATA25_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CD";
constant ACQDATA26_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CE";
constant ACQDATA27_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000CF";
constant ACQDATA28_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D0";
constant ACQDATA29_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D1";
constant ACQDATA30_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D2";
constant ACQDATA31_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D3";
constant ACQDATA32_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D4";
constant ACQDATA33_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D5";
constant ACQDATA34_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D6";
constant ACQDATA35_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D7";
constant ACQDATA36_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D8";
constant ACQDATA37_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000D9";
constant ACQDATA38_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DA";
constant ACQDATA39_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DB";
constant ACQDATA40_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DC";
constant ACQDATA41_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DD";
constant ACQDATA42_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DE";
constant ACQDATA43_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000DF";
constant ACQDATA44_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E0";
constant ACQDATA45_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E1";
constant ACQDATA46_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E2";
constant ACQDATA47_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E3";
constant ACQDATA48_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E4";
constant ACQDATA49_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E5";
constant ACQDATA50_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E6";
constant ACQDATA51_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E7";
constant ACQDATA52_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E8";
constant ACQDATA53_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000E9";
constant ACQDATA54_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000EA";
constant ACQDATA55_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000EB";
constant ACQDATA56_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000EC";
constant ACQDATA57_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000ED";
constant ACQDATA58_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000EE";
constant ACQDATA59_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000EF";
constant ACQDATA60_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000F0";
constant ACQDATA61_ADDR               : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000F1";
constant PRESC_M3_M2_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000FD";
constant PRESC_M1_M0_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"000000FE";
----------------------------
-- define the length of the REGISTER_FILE
-- aumento la dimensione di questa costante per tener conto dei nuovi 42 registri che ho aggiunto (114+42=156)
-- aggiungo un altro registro per PMT_RATE_63 (156+1=157)
-- aggiungo due registri per REF_DAC (157+2=159)
-- aggiungo 16 registri per modificare le uscite di probe (159+16=175)
-- aggiungo un registro per il numero di pacchetti nella fifo (176+1=176)
-- aggiungo un registro BURST_COUNT, un registro RST_REG e due registri RESERVED (176+4=180)
-- estendo il registro ACQDATA in 72 registri (180+72-1=251)
-- aggiungo il registro ACQDATALEN (251+1=252)
-- + registro defensive (252+1=253)
-- tolgo i registri di probe (253-16=237)
-- tolgo il registro di BURST_COUNT (237-1=236)
-- tolgo i due registri reserved (236-2=234)
-- tolgo 32 registri pmt_rate (234-32=202)
-- aggiungo un registro MASK_RATE_9 (202+1=203)
-- aggiungo due registri per i prescaler (203+2=205)
-- rimossi i registri di citiroc_2 (205-36=169)
-- rimosso il registro CAL_FREQ (169-1=168)
-- ho rimosso 10 registri di dato non utilizzati (168-10=158)
-- aggiungo 4 registri di telemetria (158+4=162)
-- aggiungo un registro per grb (162+1=163)
-- rimuovo 4 registri mask rate (li compatto) (163-4=159)
constant REGISTER_FILE_LENGTH    : integer := 159;

constant dataRegsStart      : natural := 46;
constant dataRegsStop       : natural := REGISTER_FILE_LENGTH-2;

constant refDac1LocalAddr   : natural := 93;
constant refDac2LocalAddr   : natural := 94;

-- define the map of the address this is used to get the local address of the register
constant address_vector : addr_vector_t(0 to REGISTER_FILE_LENGTH - 1) :=
(
    -- control registers
    (addr => ID_REG_ADDR,               mode => RO),
    (addr => STATUS_REG_ADDR,           mode => RO),
    (addr => RST_REG_ADDR,              mode => RW),
    (addr => CLK_REG_ADDR,              mode => RO),
    (addr => RW_REG_ADDR,               mode => RW),
    (addr => CMD_REG_ADDR,              mode => RW),
    (addr => CONFIG_CITIROC_1_0_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_1_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_2_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_3_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_4_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_5_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_6_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_7_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_8_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_9_ADDR,   mode => RW),
    (addr => CONFIG_CITIROC_1_10_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_11_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_12_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_13_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_14_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_15_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_16_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_17_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_18_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_19_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_20_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_21_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_22_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_23_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_24_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_25_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_26_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_27_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_28_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_29_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_30_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_31_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_32_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_33_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_34_ADDR,  mode => RW),
    (addr => CONFIG_CITIROC_1_35_ADDR,  mode => RW),  
    (addr => TRIGGER_MASK_ADDR,         mode => RW),         
    (addr => GENERIC_TRIGGER_MASK_ADDR, mode => RW),     
    (addr => PMT_1_MASK_ADDR,           mode => RW),    
    (addr => PMT_2_MASK_ADDR,           mode => RW),    
    (addr => BOARD_TEMP_ADDR,           mode => RO),         
    (addr => PMT_RATE_00_ADDR,          mode => RO),   
    (addr => PMT_RATE_01_ADDR,          mode => RO),   
    (addr => PMT_RATE_02_ADDR,          mode => RO),   
    (addr => PMT_RATE_03_ADDR,          mode => RO),   
    (addr => PMT_RATE_04_ADDR,          mode => RO),   
    (addr => PMT_RATE_05_ADDR,          mode => RO),   
    (addr => PMT_RATE_06_ADDR,          mode => RO),   
    (addr => PMT_RATE_07_ADDR,          mode => RO),   
    (addr => PMT_RATE_08_ADDR,          mode => RO),   
    (addr => PMT_RATE_09_ADDR,          mode => RO),   
    (addr => PMT_RATE_10_ADDR,          mode => RO),   
    (addr => PMT_RATE_11_ADDR,          mode => RO),   
    (addr => PMT_RATE_12_ADDR,          mode => RO),   
    (addr => PMT_RATE_13_ADDR,          mode => RO),   
    (addr => PMT_RATE_14_ADDR,          mode => RO),   
    (addr => PMT_RATE_15_ADDR,          mode => RO),   
    (addr => PMT_RATE_16_ADDR,          mode => RO),   
    (addr => PMT_RATE_17_ADDR,          mode => RO),   
    (addr => PMT_RATE_18_ADDR,          mode => RO),   
    (addr => PMT_RATE_19_ADDR,          mode => RO),   
    (addr => PMT_RATE_20_ADDR,          mode => RO),   
    (addr => PMT_RATE_21_ADDR,          mode => RO),   
    (addr => PMT_RATE_22_ADDR,          mode => RO),   
    (addr => PMT_RATE_23_ADDR,          mode => RO),   
    (addr => PMT_RATE_24_ADDR,          mode => RO),   
    (addr => PMT_RATE_25_ADDR,          mode => RO),   
    (addr => PMT_RATE_26_ADDR,          mode => RO),   
    (addr => PMT_RATE_27_ADDR,          mode => RO),   
    (addr => PMT_RATE_28_ADDR,          mode => RO),   
    (addr => PMT_RATE_29_ADDR,          mode => RO),   
    (addr => PMT_RATE_30_ADDR,          mode => RO),   
    (addr => PMT_RATE_31_ADDR,          mode => RO),   
    (addr => MASK_RATE_00_ADDR,         mode => RO),   
    (addr => MASK_RATE_01_ADDR,         mode => RO),   
    (addr => MASK_RATE_02_ADDR,         mode => RO),   
    (addr => MASK_RATE_03_ADDR,         mode => RO),   
    (addr => MASK_RATE_04_ADDR,         mode => RO),   
    (addr => MASK_RATE_05_ADDR,         mode => RO),   
    (addr => STATUS_REG_MIR_ADDR,       mode => RO),
    (addr => CMD_REG_MIR_ADDR,          mode => RO),
    (addr => TRG_COUNTER_ADDR,          mode => RO),
    (addr => PPS_COUNTER_ADDR,          mode => RO),
    (addr => MASK_RATE_GRB_ADDR,        mode => RO),
    (addr => REF_DAC_1_ADDR,            mode => RW),
    (addr => REF_DAC_2_ADDR,            mode => RW),
    (addr => PCKTS_IN_FIFO_ADDR,        mode => RO),
    (addr => ACQDATALEN_ADDR,           mode => RW),
    (addr => ACQDATA0_ADDR,             mode => RO),
    (addr => ACQDATA1_ADDR,             mode => RO),
    (addr => ACQDATA2_ADDR,             mode => RO),
    (addr => ACQDATA3_ADDR,             mode => RO),
    (addr => ACQDATA4_ADDR,             mode => RO),
    (addr => ACQDATA5_ADDR,             mode => RO),
    (addr => ACQDATA6_ADDR,             mode => RO),
    (addr => ACQDATA7_ADDR,             mode => RO),
    (addr => ACQDATA8_ADDR,             mode => RO),
    (addr => ACQDATA9_ADDR,             mode => RO),
    (addr => ACQDATA10_ADDR,            mode => RO),
    (addr => ACQDATA11_ADDR,            mode => RO),
    (addr => ACQDATA12_ADDR,            mode => RO),
    (addr => ACQDATA13_ADDR,            mode => RO),
    (addr => ACQDATA14_ADDR,            mode => RO),
    (addr => ACQDATA15_ADDR,            mode => RO),
    (addr => ACQDATA16_ADDR,            mode => RO),
    (addr => ACQDATA17_ADDR,            mode => RO),
    (addr => ACQDATA18_ADDR,            mode => RO),
    (addr => ACQDATA19_ADDR,            mode => RO),
    (addr => ACQDATA20_ADDR,            mode => RO),
    (addr => ACQDATA21_ADDR,            mode => RO),
    (addr => ACQDATA22_ADDR,            mode => RO),
    (addr => ACQDATA23_ADDR,            mode => RO),
    (addr => ACQDATA24_ADDR,            mode => RO),
    (addr => ACQDATA25_ADDR,            mode => RO),
    (addr => ACQDATA26_ADDR,            mode => RO),
    (addr => ACQDATA27_ADDR,            mode => RO),
    (addr => ACQDATA28_ADDR,            mode => RO),
    (addr => ACQDATA29_ADDR,            mode => RO),
    (addr => ACQDATA30_ADDR,            mode => RO),
    (addr => ACQDATA31_ADDR,            mode => RO),
    (addr => ACQDATA32_ADDR,            mode => RO),
    (addr => ACQDATA33_ADDR,            mode => RO),
    (addr => ACQDATA34_ADDR,            mode => RO),
    (addr => ACQDATA35_ADDR,            mode => RO),
    (addr => ACQDATA36_ADDR,            mode => RO),
    (addr => ACQDATA37_ADDR,            mode => RO),
    (addr => ACQDATA38_ADDR,            mode => RO),
    (addr => ACQDATA39_ADDR,            mode => RO),
    (addr => ACQDATA40_ADDR,            mode => RO),
    (addr => ACQDATA41_ADDR,            mode => RO),
    (addr => ACQDATA42_ADDR,            mode => RO),
    (addr => ACQDATA43_ADDR,            mode => RO),
    (addr => ACQDATA44_ADDR,            mode => RO),
    (addr => ACQDATA45_ADDR,            mode => RO),
    (addr => ACQDATA46_ADDR,            mode => RO),
    (addr => ACQDATA47_ADDR,            mode => RO),
    (addr => ACQDATA48_ADDR,            mode => RO),
    (addr => ACQDATA49_ADDR,            mode => RO),
    (addr => ACQDATA50_ADDR,            mode => RO),
    (addr => ACQDATA51_ADDR,            mode => RO),
    (addr => ACQDATA52_ADDR,            mode => RO),
    (addr => ACQDATA53_ADDR,            mode => RO),
    (addr => ACQDATA54_ADDR,            mode => RO),
    (addr => ACQDATA55_ADDR,            mode => RO),
    (addr => ACQDATA56_ADDR,            mode => RO),
    (addr => ACQDATA57_ADDR,            mode => RO),
    (addr => ACQDATA58_ADDR,            mode => RO),
    (addr => ACQDATA59_ADDR,            mode => RO),
    (addr => ACQDATA60_ADDR,            mode => RO),
    (addr => ACQDATA61_ADDR,            mode => RO),
    (addr => PRESC_M3_M2_ADDR,          mode => RW),
    (addr => PRESC_M1_M0_ADDR,          mode => RW),
    (addr => x"00000000",               mode => RO)  -- defensive
);

constant register_vector_reset : mem_t(0 to REGISTER_FILE_LENGTH - 1) :=
(
    -- control registers
    sysid,        -- ID_REG_ADDR,        
    x"00000000",  -- STATUS_REG_ADDR,    
    x"00000000",  -- RST_REG_ADDR,       
    x"00000000",  -- CLK_REG_ADDR,       
    x"00000000",  -- RW_REG_ADDR,        
    x"00000000",  -- CMD_REG_ADDR,       
-- modifico la configurazione iniziale dei registri per renderla compatibile con i valori iniziali da impostare sui citiroc
    -- citiroc 1 configuration registers  
    x"E1B9563B",  -- CONFIG_CITIROC_1_0_ADDR     (DAC_code_1(4 downto 0) | DAC_code_2(9 downto 0) -> EN_32_trigg)
    x"85CD0BE6",  -- CONFIG_CITIROC_1_1_ADDR     (PreAMP_config30(3 downto 0) | PreAMP_config31(14 downto 0) | Temp -> DAC_PP_2 (8bit) | DAC_code_1(9 downto 5))
    x"A17342E6",  -- CONFIG_CITIROC_1_2_ADDR     (PreAMP_config28(5 downto 0) -> PreAMP_config30(14 downto 4))
    x"685CD0B9",  -- CONFIG_CITIROC_1_3_ADDR     (PreAMP_config26(7 downto 0) -> PreAMP_config28(14 downto 6)) 
    x"9A17342E",  -- CONFIG_CITIROC_1_4_ADDR     (PreAMP_config24(9 downto 0) -> PreAMP_config26(14 downto 8))
    x"E685CD0B",  -- CONFIG_CITIROC_1_5_ADDR     (PreAMP_config22(11 downto 0) -> PreAMP_config24(14 downto 10))
    x"B9A17342",  -- CONFIG_CITIROC_1_6_ADDR     (PreAMP_config20(13 downto 0) -> PreAMP_config22(14 downto 12))
    x"2E685CD0",  -- CONFIG_CITIROC_1_7_ADDR     (PreAMP_config17(0) -> PreAMP_config20(14))
    x"0B9A1734",  -- CONFIG_CITIROC_1_8_ADDR     (PreAMP_config15(2 downto 0) -> PreAMP_config17(14 downto 1))
    x"42E685CD",  -- CONFIG_CITIROC_1_9_ADDR     (PreAMP_config13(4 downto 0) -> PreAMP_config15(14 downto 3))     
    x"D0B9A173",  -- CONFIG_CITIROC_1_10_ADDR    (PreAMP_config11(6 downto 0) -> PreAMP_config13(14 downto 5))
    x"342E685C",  -- CONFIG_CITIROC_1_11_ADDR    (PreAMP_config09(8 downto 0) -> PreAMP_config11(14 downto 7)) 
    x"CD0B9A17",  -- CONFIG_CITIROC_1_12_ADDR    (PreAMP_config07(10 downto 0) -> PreAMP_config09(14 downto 9))
    x"7342E685",  -- CONFIG_CITIROC_1_13_ADDR    (PreAMP_config05(12 downto 0) -> PreAMP_config07(14 downto 11))
    x"5CD0B9A1",  -- CONFIG_CITIROC_1_14_ADDR    (PreAMP_config03(14 downto 0) -> PreAMP_config05(14 downto 13))
    x"17342E68",  -- CONFIG_CITIROC_1_15_ADDR    (PreAMP_config00(1 downto 0) -> PreAMP_config02(14 downto 0))
    x"80402B9A",  -- CONFIG_CITIROC_1_16_ADDR    (DAC29_in(0) -> DAC31_in(8 downto 0) | PreAMP_config00(14 downto 2))
    x"04020100",  -- CONFIG_CITIROC_1_17_ADDR    (DAC26_in(5 downto 0) -> DAC29_in(8 downto 1))
    x"40201008",  -- CONFIG_CITIROC_1_18_ADDR    (DAC22_in(1 downto 0) -> DAC26_in(8 downto 6))
    x"02010080",  -- CONFIG_CITIROC_1_19_ADDR    (DAC19_in(6 downto 0) -> DAC22_in(8 downto 2))
    x"20100804",  -- CONFIG_CITIROC_1_20_ADDR    (DAC15_in(2 downto 0) -> DAC19_in(8 downto 7))
    x"01008040",  -- CONFIG_CITIROC_1_21_ADDR    (DAC12_in(7 downto 0) -> DAC15_in(8 downto 3))
    x"10080402",  -- CONFIG_CITIROC_1_22_ADDR    (DAC08_in(3 downto 0) -> DAC12_in(8))
    x"00804020",  -- CONFIG_CITIROC_1_23_ADDR    (DAC05_in(8 downto 0) -> DAC08_in(8 downto 4))
    x"08040201",  -- CONFIG_CITIROC_1_24_ADDR    (DAC01_in(4 downto 0) -> DAC04_in(8 downto 0))
    x"630F6010",  -- CONFIG_CITIROC_1_25_ADDR    (Fast_Shaper_PP -> DAC01_in(8 downto 5)
    x"FFFF8145",  -- CONFIG_CITIROC_1_26_ADDR    (discriMask(16 downto 0) | HG_TeH -> EN_Fast_Shaper )
    x"00957FFF",  -- CONFIG_CITIROC_1_27_ADDR    (DAC30 | DAC31 | EN_discri -> discriMask(31 downto 17))
    x"00000000",  -- CONFIG_CITIROC_1_28_ADDR    (DAC22 -> DAC29)
    x"00000000",  -- CONFIG_CITIROC_1_29_ADDR    (DAC14 -> DAC21)
    x"00000000",  -- CONFIG_CITIROC_1_30_ADDR    (DAC06 -> DAC13)
    x"00000000",  -- CONFIG_CITIROC_1_31_ADDR    (DAC30_t -> DAC31_t | DAC00 -> DAC05)
    x"00000000",  -- CONFIG_CITIROC_1_32_ADDR    (DAC22_t -> DAC29_t)
    x"00000000",  -- CONFIG_CITIROC_1_33_ADDR    (DAC14_t -> DAC21_t)
    x"00000000",  -- CONFIG_CITIROC_1_34_ADDR    (DAC06_t -> DAC13_t)
    x"20000000",  -- CONFIG_CITIROC_1_35_ADDR    (HoldDelay | DAC00_t -> DAC05_t)

    -- trigger mask registers  
    x"00000000",  -- TRIGGER_MASK_ADDR            
    x"00000000",  -- GENERIC_TRIGGER_MASK_ADDR    
    x"FFFFFFFF",  -- PMT_1_MASK_ADDR              
    x"FFFFFFFF",  -- PMT_2_MASK_ADDR              
    
    -- temperature sensors registers     
    x"00000000", --  BOARD_TEMP_ADDR           

    -- PMT rate meter registers           
    x"00000000",  -- PMT_RATE_00_ADDR             
    x"00000000",  -- PMT_RATE_01_ADDR             
    x"00000000",  -- PMT_RATE_02_ADDR             
    x"00000000",  -- PMT_RATE_03_ADDR             
    x"00000000",  -- PMT_RATE_04_ADDR             
    x"00000000",  -- PMT_RATE_05_ADDR             
    x"00000000",  -- PMT_RATE_06_ADDR             
    x"00000000",  -- PMT_RATE_07_ADDR             
    x"00000000",  -- PMT_RATE_08_ADDR             
    x"00000000",  -- PMT_RATE_09_ADDR             
    x"00000000",  -- PMT_RATE_10_ADDR             
    x"00000000",  -- PMT_RATE_11_ADDR             
    x"00000000",  -- PMT_RATE_12_ADDR             
    x"00000000",  -- PMT_RATE_13_ADDR             
    x"00000000",  -- PMT_RATE_14_ADDR             
    x"00000000",  -- PMT_RATE_15_ADDR             
    x"00000000",  -- PMT_RATE_16_ADDR             
    x"00000000",  -- PMT_RATE_17_ADDR             
    x"00000000",  -- PMT_RATE_18_ADDR             
    x"00000000",  -- PMT_RATE_19_ADDR             
    x"00000000",  -- PMT_RATE_20_ADDR             
    x"00000000",  -- PMT_RATE_21_ADDR             
    x"00000000",  -- PMT_RATE_22_ADDR             
    x"00000000",  -- PMT_RATE_23_ADDR             
    x"00000000",  -- PMT_RATE_24_ADDR             
    x"00000000",  -- PMT_RATE_25_ADDR             
    x"00000000",  -- PMT_RATE_26_ADDR             
    x"00000000",  -- PMT_RATE_27_ADDR             
    x"00000000",  -- PMT_RATE_28_ADDR             
    x"00000000",  -- PMT_RATE_29_ADDR             
    x"00000000",  -- PMT_RATE_30_ADDR             
    x"00000000",  -- PMT_RATE_31_ADDR             
            -- mask rate registers         
    x"00000000",  -- MASK_RATE_00_ADDR            
    x"00000000",  -- MASK_RATE_01_ADDR            
    x"00000000",  -- MASK_RATE_02_ADDR            
    x"00000000",  -- MASK_RATE_03_ADDR            
    x"00000000",  -- MASK_RATE_04_ADDR            
    x"00000000",  -- MASK_RATE_05_ADDR            
    x"00000000",  -- STATUS_REG_MIR_ADDR
    x"00000000",  -- CMD_REG_MIR_ADDR
    x"00000000",  -- TRG_COUNTER_ADDR
    x"00000000", --  PPS_COUNTER_ADDR
    x"00000000", --  MASK_RATE_GRB_ADDR

    -- DAC piedistalli
    refDac1Def,  -- REF_DAC_1_ADDR
    refDac2Def,  -- REF_DAC_2_ADDR
    -- registri di probe
    x"00000000", -- PCKTS_IN_FIFO
    x"00000000", -- ACQDATALEN
    x"00000000", -- ACQDATA0
    x"00000000", -- ACQDATA1
    x"00000000", -- ACQDATA2
    x"00000000", -- ACQDATA3
    x"00000000", -- ACQDATA4
    x"00000000", -- ACQDATA5
    x"00000000", -- ACQDATA6
    x"00000000", -- ACQDATA7
    x"00000000", -- ACQDATA8
    x"00000000", -- ACQDATA9
    x"00000000", -- ACQDATA10
    x"00000000", -- ACQDATA11
    x"00000000", -- ACQDATA12
    x"00000000", -- ACQDATA13
    x"00000000", -- ACQDATA14
    x"00000000", -- ACQDATA15
    x"00000000", -- ACQDATA16
    x"00000000", -- ACQDATA17
    x"00000000", -- ACQDATA18
    x"00000000", -- ACQDATA19
    x"00000000", -- ACQDATA20
    x"00000000", -- ACQDATA21
    x"00000000", -- ACQDATA22
    x"00000000", -- ACQDATA23
    x"00000000", -- ACQDATA24
    x"00000000", -- ACQDATA25
    x"00000000", -- ACQDATA26
    x"00000000", -- ACQDATA27
    x"00000000", -- ACQDATA28
    x"00000000", -- ACQDATA29
    x"00000000", -- ACQDATA30
    x"00000000", -- ACQDATA31
    x"00000000", -- ACQDATA32
    x"00000000", -- ACQDATA33
    x"00000000", -- ACQDATA34
    x"00000000", -- ACQDATA35
    x"00000000", -- ACQDATA36
    x"00000000", -- ACQDATA37
    x"00000000", -- ACQDATA38
    x"00000000", -- ACQDATA39
    x"00000000", -- ACQDATA40
    x"00000000", -- ACQDATA41
    x"00000000", -- ACQDATA42
    x"00000000", -- ACQDATA43
    x"00000000", -- ACQDATA44
    x"00000000", -- ACQDATA45
    x"00000000", -- ACQDATA46
    x"00000000", -- ACQDATA47
    x"00000000", -- ACQDATA48
    x"00000000", -- ACQDATA49
    x"00000000", -- ACQDATA50
    x"00000000", -- ACQDATA51
    x"00000000", -- ACQDATA52
    x"00000000", -- ACQDATA53
    x"00000000", -- ACQDATA54
    x"00000000", -- ACQDATA55
    x"00000000", -- ACQDATA56
    x"00000000", -- ACQDATA57
    x"00000000", -- ACQDATA58
    x"00000000", -- ACQDATA59
    x"00000000", -- ACQDATA60
    x"00000000", -- ACQDATA61
    x"00010001", -- PRESC_M3_M2
    x"00040001", -- PRESC_M1_M0
    x"00000000"
);
    
-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

-- register declaration, each register has local address from 0 to REGISTER_FILE_LENGTH - 1. The address_vector map the remote address to local address.
signal register_vector : mem_t(0 to REGISTER_FILE_LENGTH - 1);

-- the signal local_address is the conversion of the remote address to local using the address_vector
signal local_address        : integer;

signal clk_counter : unsigned(31 downto 0) := (others => '0');

signal sw_rst_pipe_0              : std_logic;
signal sw_rst_pipe_1              : std_logic;

signal start_config_1_pipe_0      : std_logic;
signal start_config_1_pipe_1      : std_logic;

signal start_config_2_pipe_0      : std_logic;
signal start_config_2_pipe_1      : std_logic;

signal start_debug_pipe_0         : std_logic;
signal start_debug_pipe_1         : std_logic;

signal apply_trigger_mask_pipe_0  : std_logic;
signal apply_trigger_mask_pipe_1  : std_logic;

signal apply_PMT_mask_pipe_0      : std_logic;
signal apply_PMT_mask_pipe_1      : std_logic;

signal start_ACQ_pipe_0           : std_logic;
signal start_ACQ_pipe_1           : std_logic;

signal stop_ACQ_pipe_0            : std_logic;
signal stop_ACQ_pipe_1            : std_logic;

signal start_cal_pipe_0           : std_logic;
signal start_cal_pipe_1           : std_logic;

signal stop_cal_pipe_0            : std_logic;
signal stop_cal_pipe_1            : std_logic;

-- DAC piedistalli
signal sendRefDAC_pipe_0          : std_logic;
signal sendRefDAC_pipe_1          : std_logic;

signal r_write_done, s_write_done : std_logic;

signal dataReadyOutSig            : std_logic;

signal  r_start_config_1,
        r_start_config_2,
        r_sw_rst,
        r_start_debug,
        r_apply_trigger_mask,
        r_apply_PMT_mask,
        r_start_ACQ,
        r_stop_ACQ,
        r_start_cal,
        r_stop_cal,
        r_sendRefDAC              : std_logic;


-------------------------------------------------------------------------------
-- Function prototype
-------------------------------------------------------------------------------

-- the get_local_addr function get the map of the address (address_vector) and convert the input address to an integer address from 0 to memory length
-- last address shall be an address not mapped for this memory and must be RO it will be returned if the address is not found in the previous address
function get_local_addr (address : std_logic_vector; address_vector : addr_vector_t) return integer is
begin
    for I in address_vector'range loop
        if (address = address_vector(I).addr) then
            return I;
        end if;
    end loop;
return address_vector'high; 
end function;
        
begin

dataReadyOut <= dataReadyOutSig;

    -- configuration
o_write_done      <= r_write_done;

-- Commands
start_config_1      <= r_start_config_1;
start_config_2      <= r_start_config_2;

sw_rst              <= r_sw_rst;
  
start_debug         <= r_start_debug;

apply_trigger_mask  <= r_apply_trigger_mask;
apply_PMT_mask      <= r_apply_PMT_mask;
start_ACQ           <= r_start_ACQ;
stop_ACQ            <= r_stop_ACQ;
start_cal           <= r_start_cal;
stop_cal            <= r_stop_cal;

sendRefDAC          <= r_sendRefDAC;

clk_counter_proc : process (clk, rst)
begin
    if (rst = '1') then
        clk_counter <= (others => '0');
    elsif (rising_edge(clk)) then
        clk_counter <= clk_counter + 1;
    end if;
end process clk_counter_proc;

read_write_process : process(clk, rst)
begin
    if (rst = '1') then
        local_address             <= 0;

        -- Commands
        r_start_config_1      <= '0';
        r_start_config_2      <= '0';

        r_sw_rst              <= '0';
          
        r_start_debug         <= '0';

        r_apply_trigger_mask  <= '0';
        r_apply_PMT_mask      <= '0';
        r_start_ACQ           <= '0';
        r_stop_ACQ            <= '0';
        r_start_cal           <= '0';
        r_stop_cal            <= '0';
        r_sendRefDAC          <= '0';

        pwr_on_citiroc1     <= '0'; 
        pwr_on_citiroc2     <= '0'; 

        enableTsens         <= '0';

        -- reset to zero
        register_vector <= register_vector_reset;
        r_write_done <= '0';

        refDAC_1 <= (others => '0');
        refDAC_2 <= (others => '0');

        holdoff <= (others => '0');

        config_vector   <=  (others => '0');

        trigger_mask           <= (others => '0');
        generic_trigger_mask   <= (others => '0'); 
        PMT_mask_1             <= (others => '0'); 
        PMT_mask_2             <= (others => '0'); 


        sw_rst_pipe_0             <= '0';
        sw_rst_pipe_1             <= '0';

        start_config_1_pipe_0     <= '0';
        start_config_1_pipe_1     <= '0';

        start_config_2_pipe_0     <= '0';
        start_config_2_pipe_1     <= '0';
            
        start_debug_pipe_0        <= '0';
        start_debug_pipe_1        <= '0';
        
        apply_trigger_mask_pipe_0 <= '0';
        apply_trigger_mask_pipe_1 <= '0';
        
        apply_PMT_mask_pipe_0     <= '0';
        apply_PMT_mask_pipe_1     <= '0';
        
        start_ACQ_pipe_0          <= '0';
        start_ACQ_pipe_1          <= '0';
        
        stop_ACQ_pipe_0           <= '0';
        stop_ACQ_pipe_1           <= '0';
        
        start_cal_pipe_0          <= '0';
        start_cal_pipe_1          <= '0';
        
        stop_cal_pipe_0           <= '0';
        stop_cal_pipe_1           <= '0';

        sendRefDAC_pipe_0         <= '0';
        sendRefDAC_pipe_1         <= '0';

        calibPeriod               <= (others => '0');

        s_write_done <= '0';

    elsif (rising_edge(clk)) then
        local_address             <= get_local_addr(addr, address_vector);

        -- Commands
        r_start_config_1      <= start_config_1_pipe_0 and (not start_config_1_pipe_1);
        r_start_config_2      <= start_config_2_pipe_0 and (not start_config_2_pipe_1); 

        r_sw_rst              <= sw_rst_pipe_0 and (not sw_rst_pipe_1);
          
        r_start_debug         <= start_debug_pipe_0 and (not start_debug_pipe_1);

        r_apply_trigger_mask  <= apply_trigger_mask_pipe_0 and (not apply_trigger_mask_pipe_1);
        r_apply_PMT_mask      <= apply_PMT_mask_pipe_0 and (not apply_PMT_mask_pipe_1);
        r_start_ACQ           <= start_ACQ_pipe_0 and (not start_ACQ_pipe_1);
        r_stop_ACQ            <= stop_ACQ_pipe_0 and (not stop_ACQ_pipe_1);
        r_start_cal           <= start_cal_pipe_0 and (not start_cal_pipe_1);
        r_stop_cal            <= stop_cal_pipe_0 and (not stop_cal_pipe_1);
        r_sendRefDAC          <= sendRefDAC_pipe_0 and (not sendRefDAC_pipe_1);

        pwr_on_citiroc1           <= register_vector(get_local_addr(CMD_REG_ADDR, address_vector))(4); 
        pwr_on_citiroc2           <= register_vector(get_local_addr(CMD_REG_ADDR, address_vector))(5); 

        enableTsens               <= register_vector(get_local_addr(CMD_REG_ADDR, address_vector))(2);

        start_config_1_pipe_0     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(0);
        start_config_1_pipe_1     <= start_config_1_pipe_0;
        
        start_config_2_pipe_0     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(1);
        start_config_2_pipe_1     <= start_config_2_pipe_0;
    
        sw_rst_pipe_0             <= '1' when register_vector(get_local_addr(RST_REG_ADDR, address_vector)) = RST_WORD else '0';
        sw_rst_pipe_1             <= sw_rst_pipe_0;
        
        start_debug_pipe_0        <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(6);
        start_debug_pipe_1        <= start_debug_pipe_0;
        
        apply_trigger_mask_pipe_0 <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(7);
        apply_trigger_mask_pipe_1 <= apply_trigger_mask_pipe_0;
        
        apply_PMT_mask_pipe_0     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(8);
        apply_PMT_mask_pipe_1     <= apply_PMT_mask_pipe_0;
        
        start_ACQ_pipe_0          <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(9);
        start_ACQ_pipe_1          <= start_ACQ_pipe_0;
        
        stop_ACQ_pipe_0           <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(10);
        stop_ACQ_pipe_1           <= stop_ACQ_pipe_0;
        
        start_cal_pipe_0          <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(11);
        start_cal_pipe_1          <= start_cal_pipe_0;
        
        stop_cal_pipe_0           <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(12);
        stop_cal_pipe_1           <= stop_cal_pipe_0;
        
        sendRefDAC_pipe_0         <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(14);
        sendRefDAC_pipe_1         <= sendRefDAC_pipe_0;

        calibPeriod               <= register_vector(get_local_addr(CMD_REG_ADDR, address_vector))(31 downto 16);

        do                        <= register_vector(local_address);

        r_write_done              <= s_write_done;

        refDAC_1 <= register_vector(get_local_addr(REF_DAC_1_ADDR, address_vector));
        refDAC_2 <= register_vector(get_local_addr(REF_DAC_2_ADDR, address_vector));

        holdoff <= register_vector(get_local_addr(PRESC_M3_M2_ADDR, address_vector)) &
                   register_vector(get_local_addr(PRESC_M1_M0_ADDR, address_vector));

        config_vector   <=  register_vector( get_local_addr(CONFIG_CITIROC_1_35_ADDR, address_vector) )(23 downto 0) &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_34_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_33_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_32_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_31_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_30_ADDR,  address_vector) )             & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_29_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_28_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_27_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_26_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_25_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_24_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_23_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_22_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_21_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_20_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_19_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_18_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_17_ADDR,  address_vector) )             & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_16_ADDR, address_vector) )              & 
                            register_vector( get_local_addr(CONFIG_CITIROC_1_15_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_14_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_13_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_12_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_11_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_10_ADDR, address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_9_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_8_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_7_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_6_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_5_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_4_ADDR,  address_vector) )              &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_3_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_2_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_1_ADDR, address_vector) )               &
                            register_vector( get_local_addr(CONFIG_CITIROC_1_0_ADDR, address_vector) );

        trigger_mask           <= register_vector( get_local_addr(TRIGGER_MASK_ADDR, address_vector) ); 
        generic_trigger_mask   <= register_vector( get_local_addr(GENERIC_TRIGGER_MASK_ADDR, address_vector) ); 
        PMT_mask_1             <= register_vector( get_local_addr(PMT_1_MASK_ADDR, address_vector) ); 
        PMT_mask_2             <= register_vector( get_local_addr(PMT_2_MASK_ADDR, address_vector) ); 

        if register_vector(get_local_addr(ACQDATALEN_ADDR, address_vector)) = dataLenConst then
            dataReadyOutSig <= '1';
        else
            dataReadyOutSig <= '0';
        end if;

        if(i_busy = '0')then 
            s_write_done <= '0';

            -- update register vector
            register_vector(get_local_addr(CLK_REG_ADDR, address_vector))         <= std_logic_vector(clk_counter);
            
            register_vector(get_local_addr(STATUS_REG_ADDR, address_vector))      <=  (31 downto 10 => '0') & -- bits [31:10]
                                                                                      refDac_status_2       & -- bit  9
                                                                                      refDac_status_1       & -- bit  8
                                                                                      dataReadyOutSig       & -- bit  7
                                                                                      TDAQ_BUSY             & -- bit  6
                                                                                      DPCU_TRGHOLD          & -- bit  5
                                                                                      DPCU_BUSY             & -- bit  4
                                                                                      calibration_state     & -- bit  3
                                                                                      acquisition_state     & -- bit  2
                                                                                      config_status_2       & -- bit  1
                                                                                      config_status_1       ; -- bit  0

            if sw_rst = '1' then
                register_vector(get_local_addr(RST_REG_ADDR, address_vector)) <= (others => '0');

                rstRegGen: for i in dataRegsStart to dataRegsStop loop
                    if i = refDac1LocalAddr or i = refDac2LocalAddr then
                        next;
                    end if;

                    register_vector(i) <= register_vector_reset(i);
                end loop;
            else
                register_vector(get_local_addr(PMT_RATE_31_ADDR, address_vector))     <= PMT_rate(1023 downto  992);
                register_vector(get_local_addr(PMT_RATE_30_ADDR, address_vector))     <= PMT_rate(991  downto  960);
                register_vector(get_local_addr(PMT_RATE_29_ADDR, address_vector))     <= PMT_rate(959  downto  928);
                register_vector(get_local_addr(PMT_RATE_28_ADDR, address_vector))     <= PMT_rate(927  downto  896);
                register_vector(get_local_addr(PMT_RATE_27_ADDR, address_vector))     <= PMT_rate(895  downto  864);
                register_vector(get_local_addr(PMT_RATE_26_ADDR, address_vector))     <= PMT_rate(863  downto  832);
                register_vector(get_local_addr(PMT_RATE_25_ADDR, address_vector))     <= PMT_rate(831  downto  800);
                register_vector(get_local_addr(PMT_RATE_24_ADDR, address_vector))     <= PMT_rate(799  downto  768);
                register_vector(get_local_addr(PMT_RATE_23_ADDR, address_vector))     <= PMT_rate(767  downto  736);
                register_vector(get_local_addr(PMT_RATE_22_ADDR, address_vector))     <= PMT_rate(735  downto  704);
                register_vector(get_local_addr(PMT_RATE_21_ADDR, address_vector))     <= PMT_rate(703  downto  672);
                register_vector(get_local_addr(PMT_RATE_20_ADDR, address_vector))     <= PMT_rate(671  downto  640);
                register_vector(get_local_addr(PMT_RATE_19_ADDR, address_vector))     <= PMT_rate(639  downto  608);
                register_vector(get_local_addr(PMT_RATE_18_ADDR, address_vector))     <= PMT_rate(607  downto  576);
                register_vector(get_local_addr(PMT_RATE_17_ADDR, address_vector))     <= PMT_rate(575  downto  544);
                register_vector(get_local_addr(PMT_RATE_16_ADDR, address_vector))     <= PMT_rate(543  downto  512);
                register_vector(get_local_addr(PMT_RATE_15_ADDR, address_vector))     <= PMT_rate(511  downto  480);
                register_vector(get_local_addr(PMT_RATE_14_ADDR, address_vector))     <= PMT_rate(479  downto  448);
                register_vector(get_local_addr(PMT_RATE_13_ADDR, address_vector))     <= PMT_rate(447  downto  416);
                register_vector(get_local_addr(PMT_RATE_12_ADDR, address_vector))     <= PMT_rate(415  downto  384);
                register_vector(get_local_addr(PMT_RATE_11_ADDR, address_vector))     <= PMT_rate(383  downto  352);
                register_vector(get_local_addr(PMT_RATE_10_ADDR, address_vector))     <= PMT_rate(351  downto  320);
                register_vector(get_local_addr(PMT_RATE_09_ADDR, address_vector))     <= PMT_rate(319  downto  288);
                register_vector(get_local_addr(PMT_RATE_08_ADDR, address_vector))     <= PMT_rate(287  downto  256);
                register_vector(get_local_addr(PMT_RATE_07_ADDR, address_vector))     <= PMT_rate(255  downto  224);
                register_vector(get_local_addr(PMT_RATE_06_ADDR, address_vector))     <= PMT_rate(223  downto  192);
                register_vector(get_local_addr(PMT_RATE_05_ADDR, address_vector))     <= PMT_rate(191  downto  160);
                register_vector(get_local_addr(PMT_RATE_04_ADDR, address_vector))     <= PMT_rate(159  downto  128);
                register_vector(get_local_addr(PMT_RATE_03_ADDR, address_vector))     <= PMT_rate(127  downto   96);
                register_vector(get_local_addr(PMT_RATE_02_ADDR, address_vector))     <= PMT_rate(95   downto   64);
                register_vector(get_local_addr(PMT_RATE_01_ADDR, address_vector))     <= PMT_rate(63   downto   32);
                register_vector(get_local_addr(PMT_RATE_00_ADDR, address_vector))     <= PMT_rate(31   downto    0);

                register_vector(get_local_addr(MASK_RATE_00_ADDR, address_vector))    <= mask_rate(31  downto 0);
                register_vector(get_local_addr(MASK_RATE_01_ADDR, address_vector))    <= mask_rate(63  downto 32);
                register_vector(get_local_addr(MASK_RATE_02_ADDR, address_vector))    <= mask_rate(95  downto 64);
                register_vector(get_local_addr(MASK_RATE_03_ADDR, address_vector))    <= mask_rate(127 downto 96);
                register_vector(get_local_addr(MASK_RATE_04_ADDR, address_vector))    <= mask_rate(159 downto 128);
                register_vector(get_local_addr(MASK_RATE_05_ADDR, address_vector))    <= x"0000" & mask_rate(175 downto 160);

                register_vector(get_local_addr(STATUS_REG_MIR_ADDR, address_vector))  <= register_vector(get_local_addr(STATUS_REG_ADDR, address_vector));
                register_vector(get_local_addr(CMD_REG_MIR_ADDR, address_vector))     <= register_vector(get_local_addr(CMD_REG_ADDR, address_vector));
                register_vector(get_local_addr(TRG_COUNTER_ADDR, address_vector))     <= trgCounter;
                register_vector(get_local_addr(PPS_COUNTER_ADDR, address_vector))     <= ppsCounter;

                register_vector(get_local_addr(MASK_RATE_GRB_ADDR, address_vector))   <= mask_grb;

                register_vector(get_local_addr(PCKTS_IN_FIFO_ADDR, address_vector))   <= std_logic_vector(to_unsigned(fifoPckCnt,32));

                register_vector(get_local_addr(ACQDATA0_ADDR, address_vector))        <= regAcqData(dataWidth-1    downto dataWidth-32);
                register_vector(get_local_addr(ACQDATA1_ADDR, address_vector))        <= regAcqData(dataWidth-33   downto dataWidth-64);
                register_vector(get_local_addr(ACQDATA2_ADDR, address_vector))        <= regAcqData(dataWidth-65   downto dataWidth-96);
                register_vector(get_local_addr(ACQDATA3_ADDR, address_vector))        <= regAcqData(dataWidth-97   downto dataWidth-128);
                register_vector(get_local_addr(ACQDATA4_ADDR, address_vector))        <= regAcqData(dataWidth-129  downto dataWidth-160);
                register_vector(get_local_addr(ACQDATA5_ADDR, address_vector))        <= regAcqData(dataWidth-161  downto dataWidth-192);
                register_vector(get_local_addr(ACQDATA6_ADDR, address_vector))        <= regAcqData(dataWidth-193  downto dataWidth-224);
                register_vector(get_local_addr(ACQDATA7_ADDR, address_vector))        <= regAcqData(dataWidth-225  downto dataWidth-256);
                register_vector(get_local_addr(ACQDATA8_ADDR, address_vector))        <= regAcqData(dataWidth-257  downto dataWidth-288);
                register_vector(get_local_addr(ACQDATA9_ADDR, address_vector))        <= regAcqData(dataWidth-289  downto dataWidth-320);
                register_vector(get_local_addr(ACQDATA10_ADDR, address_vector))       <= regAcqData(dataWidth-321  downto dataWidth-352);
                register_vector(get_local_addr(ACQDATA11_ADDR, address_vector))       <= regAcqData(dataWidth-353  downto dataWidth-384);
                register_vector(get_local_addr(ACQDATA12_ADDR, address_vector))       <= regAcqData(dataWidth-385  downto dataWidth-416);
                register_vector(get_local_addr(ACQDATA13_ADDR, address_vector))       <= regAcqData(dataWidth-417  downto dataWidth-448);
                register_vector(get_local_addr(ACQDATA14_ADDR, address_vector))       <= regAcqData(dataWidth-449  downto dataWidth-480);
                register_vector(get_local_addr(ACQDATA15_ADDR, address_vector))       <= regAcqData(dataWidth-481  downto dataWidth-512);
                register_vector(get_local_addr(ACQDATA16_ADDR, address_vector))       <= regAcqData(dataWidth-513  downto dataWidth-544);
                register_vector(get_local_addr(ACQDATA17_ADDR, address_vector))       <= regAcqData(dataWidth-545  downto dataWidth-576);
                register_vector(get_local_addr(ACQDATA18_ADDR, address_vector))       <= regAcqData(dataWidth-577  downto dataWidth-608);
                register_vector(get_local_addr(ACQDATA19_ADDR, address_vector))       <= regAcqData(dataWidth-609  downto dataWidth-640);
                register_vector(get_local_addr(ACQDATA20_ADDR, address_vector))       <= regAcqData(dataWidth-641  downto dataWidth-672);
                register_vector(get_local_addr(ACQDATA21_ADDR, address_vector))       <= regAcqData(dataWidth-673  downto dataWidth-704);
                register_vector(get_local_addr(ACQDATA22_ADDR, address_vector))       <= regAcqData(dataWidth-705  downto dataWidth-736);
                register_vector(get_local_addr(ACQDATA23_ADDR, address_vector))       <= regAcqData(dataWidth-737  downto dataWidth-768);
                register_vector(get_local_addr(ACQDATA24_ADDR, address_vector))       <= regAcqData(dataWidth-769  downto dataWidth-800);
                register_vector(get_local_addr(ACQDATA25_ADDR, address_vector))       <= regAcqData(dataWidth-801  downto dataWidth-832);
                register_vector(get_local_addr(ACQDATA26_ADDR, address_vector))       <= regAcqData(dataWidth-833  downto dataWidth-864);
                register_vector(get_local_addr(ACQDATA27_ADDR, address_vector))       <= regAcqData(dataWidth-865  downto dataWidth-896);
                register_vector(get_local_addr(ACQDATA28_ADDR, address_vector))       <= regAcqData(dataWidth-897  downto dataWidth-928);
                register_vector(get_local_addr(ACQDATA29_ADDR, address_vector))       <= regAcqData(dataWidth-929  downto dataWidth-960);
                register_vector(get_local_addr(ACQDATA30_ADDR, address_vector))       <= regAcqData(dataWidth-961  downto dataWidth-992);
                register_vector(get_local_addr(ACQDATA31_ADDR, address_vector))       <= regAcqData(dataWidth-993  downto dataWidth-1024);
                register_vector(get_local_addr(ACQDATA32_ADDR, address_vector))       <= regAcqData(dataWidth-1025 downto dataWidth-1056);
                register_vector(get_local_addr(ACQDATA33_ADDR, address_vector))       <= regAcqData(dataWidth-1057 downto dataWidth-1088);
                register_vector(get_local_addr(ACQDATA34_ADDR, address_vector))       <= regAcqData(dataWidth-1089 downto dataWidth-1120);
                register_vector(get_local_addr(ACQDATA35_ADDR, address_vector))       <= regAcqData(dataWidth-1121 downto dataWidth-1152);
                register_vector(get_local_addr(ACQDATA36_ADDR, address_vector))       <= regAcqData(dataWidth-1153 downto dataWidth-1184);
                register_vector(get_local_addr(ACQDATA37_ADDR, address_vector))       <= regAcqData(dataWidth-1185 downto dataWidth-1216);
                register_vector(get_local_addr(ACQDATA38_ADDR, address_vector))       <= regAcqData(dataWidth-1217 downto dataWidth-1248);
                register_vector(get_local_addr(ACQDATA39_ADDR, address_vector))       <= regAcqData(dataWidth-1249 downto dataWidth-1280);
                register_vector(get_local_addr(ACQDATA40_ADDR, address_vector))       <= regAcqData(dataWidth-1281 downto dataWidth-1312);
                register_vector(get_local_addr(ACQDATA41_ADDR, address_vector))       <= regAcqData(dataWidth-1313 downto dataWidth-1344);
                register_vector(get_local_addr(ACQDATA42_ADDR, address_vector))       <= regAcqData(dataWidth-1345 downto dataWidth-1376);
                register_vector(get_local_addr(ACQDATA43_ADDR, address_vector))       <= regAcqData(dataWidth-1377 downto dataWidth-1408);
                register_vector(get_local_addr(ACQDATA44_ADDR, address_vector))       <= regAcqData(dataWidth-1409 downto dataWidth-1440);
                register_vector(get_local_addr(ACQDATA45_ADDR, address_vector))       <= regAcqData(dataWidth-1441 downto dataWidth-1472);
                register_vector(get_local_addr(ACQDATA46_ADDR, address_vector))       <= regAcqData(dataWidth-1473 downto dataWidth-1504);
                register_vector(get_local_addr(ACQDATA47_ADDR, address_vector))       <= regAcqData(dataWidth-1505 downto dataWidth-1536);
                register_vector(get_local_addr(ACQDATA48_ADDR, address_vector))       <= regAcqData(dataWidth-1537 downto dataWidth-1568);
                register_vector(get_local_addr(ACQDATA49_ADDR, address_vector))       <= regAcqData(dataWidth-1569 downto dataWidth-1600);
                register_vector(get_local_addr(ACQDATA50_ADDR, address_vector))       <= regAcqData(dataWidth-1601 downto dataWidth-1632);
                register_vector(get_local_addr(ACQDATA51_ADDR, address_vector))       <= regAcqData(dataWidth-1633 downto dataWidth-1664);
                register_vector(get_local_addr(ACQDATA52_ADDR, address_vector))       <= regAcqData(dataWidth-1665 downto dataWidth-1696);
                register_vector(get_local_addr(ACQDATA53_ADDR, address_vector))       <= regAcqData(dataWidth-1697 downto dataWidth-1728);
                register_vector(get_local_addr(ACQDATA54_ADDR, address_vector))       <= regAcqData(dataWidth-1729 downto dataWidth-1760);
                register_vector(get_local_addr(ACQDATA55_ADDR, address_vector))       <= regAcqData(dataWidth-1761 downto dataWidth-1792);
                register_vector(get_local_addr(ACQDATA56_ADDR, address_vector))       <= regAcqData(dataWidth-1793 downto dataWidth-1824);
                register_vector(get_local_addr(ACQDATA57_ADDR, address_vector))       <= regAcqData(dataWidth-1825 downto dataWidth-1856);
                register_vector(get_local_addr(ACQDATA58_ADDR, address_vector))       <= regAcqData(dataWidth-1857 downto dataWidth-1888);
                register_vector(get_local_addr(ACQDATA59_ADDR, address_vector))       <= regAcqData(dataWidth-1889 downto dataWidth-1920);
                register_vector(get_local_addr(ACQDATA60_ADDR, address_vector))       <= regAcqData(dataWidth-1921 downto dataWidth-1952);
                register_vector(get_local_addr(ACQDATA61_ADDR, address_vector))       <= regAcqData(dataWidth-1953 downto 0);

                register_vector(get_local_addr(BOARD_TEMP_ADDR, address_vector))      <= board_temp;

                if writeDataLen = '1' and DPCU_BUSY = '1' then
                    register_vector(get_local_addr(ACQDATALEN_ADDR, address_vector))  <= dataLenConst;
                end if;
            end if;

        else
            if (we = '1') then                                                                                    
            -- on write request the local address is check whether it is writeable                            
                if (address_vector(local_address).mode = RW) then
                    -- local address writeable, write it
                    register_vector(local_address) <= di;
                end if;

                s_write_done <= '1';
            end if;
        end if;

    end if;
end process read_write_process;

end Behavioral;
