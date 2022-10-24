library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library proasic3l;
use proasic3l.all;
use IEEE.NUMERIC_STD.ALL;
use work.spwpkg.all;

entity top_test is
port (
    clock48M         : in std_logic;  -- clk di sistema: 48 MHz
    clock200M        : in std_logic;

    select_reg_1     : out std_logic;
	SR_IN_SR_1       : out std_logic;
	RST_B_SR_1       : out std_logic;
	CLK_SR_1         : out std_logic;
    load_1           : out std_logic;
    select_reg_2     : out std_logic;
	SR_IN_SR_2       : out std_logic;
	RST_B_SR_2       : out std_logic;
	CLK_SR_2         : out std_logic;
    load_2           : out std_logic;

    LVDS_TO_ASIC_EN_1 : out std_logic;
    LVDS_TO_ASIC_EN_2 : out std_logic;

    EN_PWR_DIG_CITIROC_1 : out std_logic;
    PGOOD_DIG_CITIROC_1  : in std_logic;
    EN_PWR_ANA_CITIROC_1 : out std_logic;
    PGOOD_ANA_CITIROC_1  : in std_logic;

    EN_PWR_DIG_CITIROC_2 : out std_logic;
    PGOOD_DIG_CITIROC_2  : in std_logic;
    EN_PWR_ANA_CITIROC_2 : out std_logic;
    PGOOD_ANA_CITIROC_2  : in std_logic;

    trgExt           : in  std_logic;
    uscitaTest       : out std_logic_vector(15 downto 0);

    PS_global_trig_1 : out std_logic;
    PS_global_trig_2 : out std_logic;

    PWR_ON_1         : out std_logic;
    PWR_ON_2         : out std_logic;

    VAL_EVT_1        : out std_logic;
    VAL_EVT_2        : out std_logic;

    RAZ_CHN_1        : out std_logic;
    RAZ_CHN_2        : out std_logic;

    trigger_in_1     : in std_logic_vector(31 downto 0);
    trigger_in_2     : in std_logic_vector(31 downto 0);

    OR32_1    : in std_logic;
    OR32_2    : in std_logic;

    NOR32_1   : inout std_logic;
    NOR32_2   : inout std_logic;
    NOR32T_1  : inout std_logic;
    NOR32T_2  : inout std_logic;

    SDATA_hg_1       : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_1       : in std_logic;    -- 2 leading '0' + 12 dati
    CS_1             : out std_logic;  -- attivo sul fronte di discesa
    SCLK_1           : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_1        : out std_logic;  -- attivo ALTO
    hold_lg_1        : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_1       : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_1     : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_1     : out std_logic;  -- attivo basso
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
    SDATA_hg_2       : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_2       : in std_logic;    -- 2 leading '0' + 12 dati
    CS_2             : out std_logic;  -- attivo sul fronte di discesa
    SCLK_2           : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_2        : out std_logic;  -- attivo ALTO
    hold_lg_2        : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_2       : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_2     : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_2     : out std_logic;  -- attivo basso
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
    SR_OUT_READ_1    : in std_logic;
    SR_OUT_READ_2    : in std_logic;
    SR_OUT_SR_1      : in std_logic;
    SR_OUT_SR_2      : in std_logic;

    RESETB_PA_1      : out std_logic;
    RESETB_PA_2      : out std_logic;

    PS_MODEB_EXT_1    : out std_logic;
    PS_MODEB_EXT_2    : out std_logic;

    DIG_PROBE_1      : in std_logic;
    DIG_PROBE_2      : in std_logic;

    HIT_MUX_1        : in std_logic;
    HIT_MUX_2        : in std_logic;

    ha_rstb_psc      : out std_logic;    -- reset del peak detector (citiroc A)
    hb_rstb_psc      : out std_logic;    -- reset del peak detector (citiroc B)

    spw_di           : in  std_logic;
    spw_si           : in  std_logic;
    spw_do           : out std_logic;
    spw_so           : out std_logic;
 
    -- segnali da DPCU
    dpcuBusyIn       : in  std_logic;
    dpcuTrgHold      : in  std_logic;
    dpcuReset        : in  std_logic;
    dpcuPPS          : in  std_logic;

    -- segnali verso DPCU
    dataReadyOut     : out std_logic;
    TRG              : out std_logic;

    -- segnali da TDAQ
    tdaqBusyIn       : in  std_logic;

    -- segnali verso TDAQ
    TRG_EVT          : out std_logic;
    TRG_1            : out std_logic;
    TRG_2            : out std_logic;
    TRG_3            : out std_logic;
    TRG_4            : out std_logic;
    TRG_5            : out std_logic;

    -- segnali per watchdog
    WDI_TO_SUPERVISOR   : out std_logic;
    RST_FROM_SUPERVISOR : in std_logic;

    -- segnali per i sensori di temperatura
    TSENS_DOUT_1 : in  std_logic;
    TSENS_CS_N_1 : out std_logic;
    TSENS_SCLK_1 : out std_logic;

    TSENS_DOUT_2 : in  std_logic;
    TSENS_CS_N_2 : out std_logic;
    TSENS_SCLK_2 : out std_logic;


    -- DAC piedistalli
    refDacDIN_1      : out std_logic;
    refDacSYNC_HG_1  : out std_logic;
    refDacSYNC_LG_1  : out std_logic;
    refDacSCLK_1     : out std_logic;
    
    refDacDIN_2      : out std_logic;
    refDacSYNC_HG_2  : out std_logic;
    refDacSYNC_LG_2  : out std_logic;
    refDacSCLK_2     : out std_logic

);
end top_test;

architecture architecture_top_test of top_test is

constant refDac1Def  : std_logic_vector(31 downto 0) := x"2F002F00"; -- TB4
constant refDac2Def  : std_logic_vector(31 downto 0) := x"2F002F00"; -- TB4

constant dataWidth   : natural := 1984;
constant fifoWidth   : natural := 496;
constant fifoDepth   : natural := 40;

component genericSync is
generic(
    sigNum : natural := 4
);
port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sigIn  : in  std_logic_vector(sigNum-1 downto 0);
    sigOut : out std_logic_vector(sigNum-1 downto 0)
);
end component;

component watchDogCtrl is
generic(
    clkFreq   : real;
    wdiHWidth : real;
    wdiLWidth : real
);
port(
    clk : in  std_logic;
    rst : in  std_logic;
    wdi : out std_logic
);
end component;

component DDR_OUT
port(
    DR  : in    std_logic := 'U';
    DF  : in    std_logic := 'U';
    CLK : in    std_logic := 'U';
    CLR : in    std_logic := 'U';
    Q   : out   std_logic
);
end component;

component OUTBUF
port(
    D   : in    std_logic := 'U';
    PAD : out   std_logic
);
end component;

component CLKINT is
port(
        A : in std_logic;
        Y : out std_logic
);
end component;

component clkDiv2 is
port(
    rst    : in  std_logic;
    clkIn  : in  std_logic;
    clkOut : out std_logic
);
end component;

component clk220kGen is
port(
    rst    : in  std_logic;
    clkIn  : in  std_logic;
    clkOut : out std_logic
);
end component;

component ppsCounter is
generic(
    clkFreq        : real;
    resolution     : real;
    ppsCountWidth  : natural;
    fineCountWidth : natural
);
port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    enable         : in  std_logic;
    ppsIn          : in  std_logic;
    counterOut     : out std_logic_vector((ppsCountWidth+fineCountWidth)-1 downto 0)
);
end component;

component citirocPwrCtrl is
port(
    clk         : in  std_logic;
    rst         : in  std_logic;
    pwrStateIn  : in  std_logic;
    enPwrDigOut : out std_logic;
    enPwrAnaOut : out std_logic;
    pGoodDigIn  : in  std_logic;
    pGoodAnaIn  : in  std_logic
);
end component;

component test_file is
generic(
    concurrentTriggers   : natural;
    prescaledTriggers    : natural;
    holdOffBits          : natural
);
port (
    clockSYS       : in std_logic;
    clock48M       : in std_logic;
    clock24M       : in std_logic;
    clock200k      : in std_logic;
    rst            : in std_logic;  --

    triggerInhibit : in std_logic;
    triggerOUT     : out std_logic;

    triggerCnt     : out std_logic_vector(31 downto 0);

    turrets              : out std_logic_vector(4 downto 0);
    turretsFlags         : out std_logic_vector(7 downto 0);
    turretsCounters      : out std_logic_vector(159 downto 0);

    PMT_mask_1      : in  std_logic_vector(31 downto 0);
    PMT_mask_2      : in  std_logic_vector(31 downto 0);
    generic_trigger_mask : in std_logic_vector(31 downto 0);	
    trigger_mask    : in  std_logic_vector(31 downto 0);
    apply_trigger_mask : in std_logic;
    apply_PMT_mask : in std_logic; 

    start_ACQ      : in std_logic; 
    stop_ACQ       : in std_logic; 
    start_cal      : in std_logic;
    stop_cal       : in std_logic;
    acquisition_state : out std_logic;
    calibration_state : out std_logic;

    PMT_rate          : out std_logic_vector(1023 downto 0);
    mask_rate         : out std_logic_vector(319 downto 0);
    trigger_flag_1    : out std_logic_vector(31 downto 0);
    trigger_flag_2    : out std_logic_vector(31 downto 0);

    triggerID         : out std_logic_vector(7 downto 0);

    config_status_1 : out std_logic;
    config_status_2 : out std_logic;

    sw_rst         : in std_logic; 

    select_reg_1   : out std_logic;
	SR_IN_SR_1     : out std_logic;
	RST_B_SR_1     : out std_logic;
	CLK_SR_1       : out std_logic;
    load_1         : out std_logic;
    select_reg_2   : out std_logic;
	SR_IN_SR_2     : out std_logic;
	RST_B_SR_2     : out std_logic;
	CLK_SR_2       : out std_logic;
    load_2         : out std_logic;

    config_vector  : in std_logic_vector(1143 downto 0);

    configure_command_1 : in std_logic;
    configure_command_2 : in std_logic;

    pwr_on_citiroc1 : in std_logic;
    pwr_on_citiroc2 : in std_logic;

    rstCIT1out : out std_logic;
    rstCIT2out : out std_logic;

    trigger_in_1    : in std_logic_vector(31 downto 0);
    trigger_in_2    : in std_logic_vector(31 downto 0);

    SDATA_hg_1        : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_1        : in std_logic;    -- 2 leading '0' + 12 dati
    CS_1              : out std_logic;  -- attivo sul fronte di discesa
    SCLK_1            : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_1         : out std_logic;  -- attivo ALTO
    hold_lg_1         : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_1        : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_1      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_1      : out std_logic;  -- attivo basso
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
    SDATA_hg_2        : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_2        : in std_logic;    -- 2 leading '0' + 12 dati
    CS_2              : out std_logic;  -- attivo sul fronte di discesa
    SCLK_2            : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_2         : out std_logic;  -- attivo ALTO
    hold_lg_2         : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_2        : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_2      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_2      : out std_logic;  -- attivo basso
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura

    dataReady         : out std_logic;

    adcDataOut        : out std_logic_vector(1535 downto 0);

    trgExtIn          : in std_logic;

    rate1SecOut       : out std_logic;

    holdoff           : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    debug_triggerIN   : in std_logic

);
end component;

component aliveDeadTCnt is
port(
    clock      : in  std_logic;
    clock200k  : in  std_logic;
    reset      : in  std_logic;
    busyState  : in  std_logic;
    acqState   : in  std_logic;
    trigger    : in  std_logic;
    aliveCount : out std_logic_vector(31 downto 0);
    deadCount  : out std_logic_vector(31 downto 0);
    lostCount  : out std_logic_vector(15 downto 0)
);
end component;

component spwFIFOInterface is
generic(
    fifoWidth           : natural;
    fifoDepth           : natural;
    acqDataLen          : natural;
    writeMuxPadding     : std_logic := '0';
    writeMuxPaddingLeft : boolean   := false
);
port(
    clk                 : in  std_logic;
    rst                 : in  std_logic;

    adcDataReady        : in  std_logic;
    acqData             : in  std_logic_vector(acqDataLen-1 downto 0);

    pcktCounter         : out natural;

    regAcqData          : out std_logic_vector(acqDataLen-1 downto 0);
    writeDataLen        : out std_logic;
    dataReadyIn         : in  std_logic;

    dpcuBusyIn          : in  std_logic;

    dataWrittenInFIFO   : out std_logic;

    fifoDATA            : out std_logic_vector(fifoWidth-1 downto 0);
    fifoQ               : in  std_logic_vector(fifoWidth-1 downto 0);
    fifoWE              : out std_logic;
    fifoRE              : out std_logic;
    fifoAFULL           : in  std_logic;
    fifoEMPTY           : in  std_logic;
    fifoWACK            : in  std_logic;
    fifoDVLD            : in  std_logic
);
end component;

component spwFIFO is
port(
    DATA  : in    std_logic_vector(fifoWidth-1 downto 0);
    Q     : out   std_logic_vector(fifoWidth-1 downto 0);
    WE    : in    std_logic;
    RE    : in    std_logic;
    CLK   : in    std_logic;
    FULL  : out   std_logic;
    EMPTY : out   std_logic;
    RESET : in    std_logic;
    AFULL : out   std_logic;
    WACK  : out   std_logic;
    DVLD  : out   std_logic
);
end component;

component spw_controller is
generic(
    g_spw_addr_width  : integer := 16; --! spw address width generic parameter
    g_spw_data_width  : integer := 32; --! spw data width generic parameter
    g_spw_addr_offset : unsigned := x"0000";     --! component address offset generic parameter
    g_spw_num        : integer := 32; --! spw number generic parameter
    g_spw_idx        : unsigned(7 downto 0) := x"00"  --! unique ID index generic parameter
);
port(
    i_spw_clk           : in    std_logic;  --! system clock
    i_reset             : in    std_logic;  --! master active low reset
  
    --regfile interface
    i_data_in           : in    std_logic_vector(g_spw_data_width - 1 downto 0);  --! spw address from cpu
    o_data_out          : out    std_logic_vector(g_spw_data_width - 1 downto 0);     --! spw write data from cpu
    o_we                : out   std_logic;                                           --! spw enable from cpu
    o_addr              : out   std_logic_vector(g_spw_data_width - 1 downto 0);                                           --! spw write enable from cpu    
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
end component;

component edgeDetector is
generic(
    edge      : std_logic := '0' -- '0' falling, '1' rising
);
port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    signalIn  : in  std_logic;
    signalOut : out std_logic
);
end component;

component tempSensorRead is
generic(
    clkFreq      : real;
    sclkFreq     : real;
    sDataWidth   : natural;
    tempWidth    : natural
);
port(
    clk          : in  std_logic;
    rst          : in  std_logic;
    enableIn     : in  std_logic;
    startConvIn  : in  std_logic;
    sDataIn      : in  std_logic;
    dataReadyOut : out std_logic;
    sclkOut      : out std_logic;
    csOut        : out std_logic;
    dataOut      : out std_logic_vector(tempWidth-1 downto 0)
);
end component;

component register_file is
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
    acquisition_state   : in std_logic; -- = '1' quando il sistema è in acquisizione
    calibration_state   : in std_logic; -- = '1' quando il sistema è in calibrazione

    refDac_status_1     : in std_logic;
    refDac_status_2     : in std_logic;

    fifoPckCnt          : in  natural;

    writeDataLen        : in   std_logic;

    regAcqData          : in  std_logic_vector(dataWidth-1  downto 0);

    holdoff             : out std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    PMT_rate            : in std_logic_vector(1023 downto 0);
    mask_rate           : in std_logic_vector(319 downto 0);
    board_temp          : in std_logic_vector(31 downto 0)
);
end component;

component refController
generic(
    resetHGVal : std_logic_vector(15 downto 0);
    resetLGVal : std_logic_vector(15 downto 0)
);
port(
    clk24M     : in  std_logic;
    rst        : in  std_logic;
	dacHGVal   : in  std_logic_vector(15 downto 0);
    dacLGVal   : in  std_logic_vector(15 downto 0);
    enableSclk : out std_logic;
    send       : in  std_logic;
    confDone   : out std_logic;
    dout       : out std_logic;
    syncHG     : out std_logic;
    syncLG     : out std_logic
);
end component;

component spwstream

generic (

  sysfreq:        real;
  txclkfreq:      real := 0.0;
  rximpl:         spw_implementation_type := impl_generic;
  rxchunk:        integer range 1 to 4 := 1;
  tximpl:         spw_implementation_type := impl_generic;
  rxfifosize_bits: integer range 6 to 14 := 11;
  txfifosize_bits: integer range 2 to 14 := 11

);

port (

  clk:        in  std_logic;
  rxclk:      in  std_logic;
  txclk:      in  std_logic;
  rst:        in  std_logic;
  autostart:  in  std_logic;
  linkstart:  in  std_logic;
  linkdis:    in  std_logic;
  txdivcnt:   in  std_logic_vector(7 downto 0);
  tick_in:    in  std_logic;
  ctrl_in:    in  std_logic_vector(1 downto 0);
  time_in:    in  std_logic_vector(5 downto 0);
  txwrite:    in  std_logic;
  txflag:     in  std_logic;
  txdata:     in  std_logic_vector(7 downto 0);
  txrdy:      out std_logic;
  txhalff:    out std_logic;
  tick_out:   out std_logic;
  ctrl_out:   out std_logic_vector(1 downto 0);
  time_out:   out std_logic_vector(5 downto 0);
  rxvalid:    out std_logic;
  rxhalff:    out std_logic;
  rxflag:     out std_logic;
  rxdata:     out std_logic_vector(7 downto 0);
  rxread:     in  std_logic;
  started:    out std_logic;
  connecting: out std_logic;
  running:    out std_logic;
  errdisc:    out std_logic;
  errpar:     out std_logic;
  erresc:     out std_logic;
  errcred:    out std_logic;
  spw_di:     in  std_logic;
  spw_si:     in  std_logic;
  spw_do:     out std_logic;
  spw_so:     out std_logic
  
);

end component;

component powerOnResetFSM is
generic(
    rstTime : integer
);
port (
	clk : IN  std_logic;
    rstIN : in std_logic;
    rstOUT : OUT std_logic
);
end component;

component pulseExt is
generic(
    clkFreq    : real;
    pulseWidth : real
);
port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    sigIn      : in  std_logic;
    sigOut     : out std_logic
);
end component;

constant concurrentTriggers : natural := 6;
constant prescaledTriggers  : natural := 4;
constant holdOffBits        : natural := 16;

constant tSDataWidth        : natural := 16;
constant tempWidth          : natural := 10;

signal  wdRst,
        wdi,
        swRst,
        s_global_rst     : std_logic;

---------------------------------------------------
-- Segnali per test_file
---------------------------------------------------

signal s_clock24MBuff    : std_logic;
signal s_clock200M       : std_logic;
signal s_clock24M        : std_logic;
signal s_clock48M        : std_logic;

signal clk200k_sig, 
       clk200k_int : std_logic;

signal s_select_reg_1    : std_logic;
signal s_SR_IN_SR_1      : std_logic;
signal s_RST_B_SR_1      : std_logic;
signal s_CLK_SR_1        : std_logic;
signal s_load_1          : std_logic;
signal s_select_reg_2    : std_logic;
signal s_SR_IN_SR_2      : std_logic;
signal s_RST_B_SR_2      : std_logic;
signal s_CLK_SR_2        : std_logic;
signal s_load_2          : std_logic;

signal s_trigger_in_1    : std_logic_vector(31 downto 0);
signal s_trigger_in_2    : std_logic_vector(31 downto 0);

signal s_SDATA_hg_1      : std_logic;
signal s_SDATA_lg_1      : std_logic;
signal s_CS_1            : std_logic;
signal s_SCLK_1          : std_logic;
signal s_hold_hg_1       : std_logic;
signal s_hold_lg_1       : std_logic;

signal s_CLK_READ_1      : std_logic;
signal s_SR_IN_READ_1    : std_logic;
signal s_RST_B_READ_1    : std_logic;

signal s_SDATA_hg_2      : std_logic;
signal s_SDATA_lg_2      : std_logic;
signal s_CS_2            : std_logic;
signal s_SCLK_2          : std_logic;
signal s_hold_hg_2       : std_logic;
signal s_hold_lg_2       : std_logic;
signal s_CLK_READ_2      : std_logic;
signal s_SR_IN_READ_2    : std_logic;

signal s_RST_B_READ_2    : std_logic;

---------------------------------------------------
-- Segnali per cses_reg_file_manager
---------------------------------------------------

signal s_txrdy           : std_logic;
signal s_rxvalid         : std_logic;
signal s_rxflag          : std_logic;
signal s_rxdata          : std_logic_vector(7 downto 0);
signal s_rxread          : std_logic;
signal s_txwrite         : std_logic;
signal s_txflag          : std_logic;
signal s_txdata          : std_logic_vector(7 downto 0);

signal s_we              : std_logic;
signal s_addr            : std_logic_vector(31 downto 0);
signal s_di              : std_logic_vector(31 downto 0);
signal s_do              : std_logic_vector(31 downto 0);

---------------------------------------------------
-- Segnali per register_file
---------------------------------------------------

signal s_trigger_mask          : std_logic_vector(31 downto 0);
signal s_generic_trigger_mask  : std_logic_vector(31 downto 0);
signal s_PMT_mask_1            : std_logic_vector(31 downto 0);
signal s_PMT_mask_2            : std_logic_vector(31 downto 0);

signal s_start_config_1      : std_logic;
signal s_start_config_2      : std_logic;
signal s_sw_rst              : std_logic;
signal s_pwr_on_citiroc1     : std_logic;
signal s_pwr_on_citiroc2     : std_logic;
signal s_start_debug         : std_logic;
signal s_apply_trigger_mask  : std_logic;
signal s_apply_PMT_mask      : std_logic;
signal s_start_ACQ           : std_logic;
signal s_stop_ACQ            : std_logic;
signal s_start_cal           : std_logic;
signal s_stop_cal            : std_logic;

signal s_config_status_1   : std_logic;
signal s_config_status_2   : std_logic;
signal s_acquisition_state : std_logic;
signal s_calibration_state : std_logic;

signal s_PMT_rate          : std_logic_vector(1023 downto 0);
signal s_mask_rate       : std_logic_vector(319 downto 0);

signal s_trigger_flag_1,
       s_trigger_flag_2  : std_logic_vector(31 downto 0);

signal s_config_vector   : std_logic_vector(1143 downto 0);

---------------------------------------------------
-- Segnali per spwstream
---------------------------------------------------

signal s_spw_di          : std_logic;
signal s_spw_si          : std_logic;
signal s_spw_do          : std_logic;
signal s_spw_so          : std_logic;
---- debug
signal s_started     : std_logic;
signal s_connecting  : std_logic;
signal s_running     : std_logic;
signal s_errdisc     : std_logic;
signal s_errpar      : std_logic;
signal s_erresc      : std_logic;
signal s_errcred     : std_logic;

signal trigger_interno_sig : std_logic;

signal s_sendRefDAC,
       s_sendRefDAC_24M,
       enableSclk_1,
       enableSclk_2,
       s_refDacSync1HG,
       s_refDacSync1LG,
       s_refDacSync2HG,
       s_refDacSync2LG  : std_logic;

signal s_confDoneCIT1, s_confDoneCIT2     : std_logic;

signal s_refDac1, s_refDac2 : std_logic_vector(31 downto 0);

signal dataReady            : std_logic;

signal adcDataOut           :  std_logic_vector(1535 downto 0);

--------------------------------------
-- Segnali per spwFIFOInterface
--------------------------------------
signal acqData      : std_logic_vector(dataWidth-1 downto 0);
signal pcktCounter  : natural;
signal trigCounter  : std_logic_vector(31 downto 0);
signal regAcqData   : std_logic_vector(dataWidth-1 downto 0);

signal fifoDATA     : std_logic_vector(fifoWidth-1 downto 0);
signal fifoQ        : std_logic_vector(fifoWidth-1 downto 0);
signal fifoWE       : std_logic;
signal fifoRE       : std_logic;
signal fifoFULL     : std_logic;
signal fifoAFULL    : std_logic;
signal fifoEMPTY    : std_logic;
signal fifoWACK     : std_logic;
signal fifoDVLD     : std_logic;

signal rstCIT1out, rstCIT2out : std_logic;

signal writeDone    : std_logic;
signal spwCtrlBusy  : std_logic;
signal trgInhibit   : std_logic;

signal dpcu_tdaq_in   : std_logic_vector(3 downto 0);
signal dpcu_tdaq_sync : std_logic_vector(3 downto 0);

-- Sincronizzazione segnali da DPCU/TDAQ
signal  dpcuPPSSync,
        dpcuBusyInSync,
        dpcuTrgHoldSync,
        tdaqBusyInSync      : std_logic; 

signal extendedTriggerOut   : std_logic;

signal writeDataLen,
       writeDataLenBuff     : std_logic;

signal  dataReadyOutSig,
        dataReadyOutSigBuff : std_logic;

signal  ppsCount,
        ppsCountSync        : std_logic_vector(31 downto 0);

signal  holdoff             : std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

signal  CLK_READ_1_toBuf,
        CLK_READ_2_toBuf,
        SCLK_1_toBuf,
        SCLK_2_toBuf,
        CLK_SR_1_toBuf,
        CLK_SR_2_toBuf,
        s_refDacSCLK_1_toBuf,
        s_refDacSCLK_2_toBuf : std_logic;

signal  tempData,
        s_board_temp         : std_logic_vector(31 downto 0);

signal  rate1SecSig,
        rate1SecSigRise,
        enableTsens,
        temp1Completed,
        temp2Completed       : std_logic;

signal  trgBusy,
        trgBusySet,
        trgBusyRst           : std_logic;

signal  aliveCount,
        deadCount            : std_logic_vector(31 downto 0);

signal  lostCount            : std_logic_vector(15 downto 0);

signal  s_turrets            : std_logic_vector(4 downto 0);

signal  s_turretsFlags       : std_logic_vector(7 downto 0);

signal  s_turretsCounters    : std_logic_vector(159 downto 0);

signal  s_triggerID          : std_logic_vector(7 downto 0);

signal  crc32                : std_logic_vector(31 downto 0);

begin

PWR_ON_1  <= s_pwr_on_citiroc1;
PWR_ON_2  <= s_pwr_on_citiroc2;
VAL_EVT_1  <= '1';
VAL_EVT_2  <= '1';    
RAZ_CHN_1  <= '0';
RAZ_CHN_2  <= '0';

LVDS_TO_ASIC_EN_1 <= s_pwr_on_citiroc1;
LVDS_TO_ASIC_EN_2 <= s_pwr_on_citiroc2;

NOR32_1  <= 'Z' when s_pwr_on_citiroc1 = '1' else '0';
NOR32_2  <= 'Z' when s_pwr_on_citiroc2 = '1' else '0';
NOR32T_1 <= 'Z' when s_pwr_on_citiroc1 = '1' else '0';
NOR32T_2 <= 'Z' when s_pwr_on_citiroc2 = '1' else '0';

RESETB_PA_1 <= '0';
RESETB_PA_2 <= '0';

clk48BufInst: CLKINT
port map(
    A => clock48M,
    Y => s_clock48M
);

clk200BufInst: CLKINT
port map(
    A => clock200M,
    Y => s_clock200M
);

clk48DivInst: clkDiv2
port map(
    rst    => s_global_rst,
    clkIn  => s_clock48M,
    clkOut => s_clock24M
);

clk24MBuf: CLKINT
    port map(
        A => s_clock24M,
        Y => s_clock24MBuff
    );

clk200kGenInst: clk220kGen
port map(
    rst    => s_global_rst,
    clkIn  => s_clock24MBuff,
    clkOut => clk200k_int
);

BUFclk200: CLKINT
port map(
    Y => clk200k_sig,
    A => clk200k_int
);

dpcu_tdaq_in <= dpcuPPS & dpcuBusyIn & dpcuTrgHold & tdaqBusyIn;

sincroDPCU: genericSync
generic map(
    sigNum => 4
)
port map(
    clk    => s_clock48M,
    rst    => s_global_rst,
    sigIn  => dpcu_tdaq_in,
    sigOut => dpcu_tdaq_sync
);

-- Sincronizzazione segnali da DPCU/TDAQ
dpcuPPSSync     <= dpcu_tdaq_sync(3);
dpcuBusyInSync  <= dpcu_tdaq_sync(2);
dpcuTrgHoldSync <= dpcu_tdaq_sync(1);
tdaqBusyInSync  <= dpcu_tdaq_sync(0);

trgInhibit <= (not dpcuTrgHoldSync) or (not tdaqBusyInSync) or fifoAFULL;

triggerOutExpand: pulseExt
generic map(
    clkFreq    => 200.0e6,
    pulseWidth => 100.0e-9
)
port map(
    clk        => s_clock200M,
    rst        => s_global_rst,
    sigIn      => trigger_interno_sig,
    sigOut     => extendedTriggerOut
);

PS_global_trig_1 <= extendedTriggerOut;
PS_global_trig_2 <= extendedTriggerOut;

TRG     <= extendedTriggerOut;

TRG_EVT <= extendedTriggerOut;
TRG_1   <= s_turrets(0);
TRG_2   <= s_turrets(1);
TRG_3   <= s_turrets(2);
TRG_4   <= s_turrets(3);
TRG_5   <= s_turrets(4);

wdRst <= not RST_FROM_SUPERVISOR;

watchDogInst: watchDogCtrl
generic map(
    clkFreq   => 200.0e3,
    wdiHWidth => 5.0e-6,
    wdiLWidth => 25.0e-6
)
port map(
    clk => clk200k_sig,
    rst => wdRst,
    wdi => wdi
);

WDI_TO_SUPERVISOR <= wdi;

global_reset_buffer_instance: CLKINT
port map(
    A => wdRst or not dpcuReset,
    Y => s_global_rst
);

sw_reset_buffer_instance: CLKINT
port map(
    A => s_global_rst or s_sw_rst,
    Y => swRst
);

ha_rstb_psc <= RST_FROM_SUPERVISOR and s_pwr_on_citiroc1;
hb_rstb_psc <= RST_FROM_SUPERVISOR and s_pwr_on_citiroc2;

---------------------------------------------------
-- Uscite verso CITIROC
---------------------------------------------------

select_reg_1 <= s_select_reg_1 and s_pwr_on_citiroc1;
SR_IN_SR_1   <= s_SR_IN_SR_1 and s_pwr_on_citiroc1;
RST_B_SR_1   <= s_RST_B_SR_1 and s_pwr_on_citiroc1;
load_1       <= s_load_1 and s_pwr_on_citiroc1;

select_reg_2 <= s_select_reg_2 and s_pwr_on_citiroc2;
SR_IN_SR_2   <= s_SR_IN_SR_2 and s_pwr_on_citiroc2;
RST_B_SR_2   <= s_RST_B_SR_2 and s_pwr_on_citiroc2;
load_2       <= s_load_2 and s_pwr_on_citiroc2;

---------------------------------------------------

s_trigger_in_1 <= trigger_in_1;
s_trigger_in_2 <= trigger_in_2;

s_SDATA_hg_1 <= SDATA_hg_1;
s_SDATA_lg_1 <= SDATA_lg_1;
CS_1 <= s_CS_1;

hold_hg_1 <= s_hold_hg_1 and s_pwr_on_citiroc1;
hold_lg_1 <= s_hold_lg_1 and s_pwr_on_citiroc1;

SR_IN_READ_1 <= s_SR_IN_READ_1 and s_pwr_on_citiroc1;
RST_B_READ_1 <= s_RST_B_READ_1 and s_pwr_on_citiroc1;

s_SDATA_hg_2 <= SDATA_hg_2;
s_SDATA_lg_2 <= SDATA_lg_2;
CS_2 <= s_CS_2;

hold_hg_2 <= s_hold_hg_2 and s_pwr_on_citiroc2;
hold_lg_2 <= s_hold_lg_2 and s_pwr_on_citiroc2;

SR_IN_READ_2 <= s_SR_IN_READ_2 and s_pwr_on_citiroc2;
RST_B_READ_2 <= s_RST_B_READ_2 and s_pwr_on_citiroc2;

PS_MODEB_EXT_1 <= '1' and s_pwr_on_citiroc1;
PS_MODEB_EXT_2 <= '1' and s_pwr_on_citiroc2;

---------------------------------------------------
-- Gli ingressi e le uscite di top_test 
-- legate a spwstream li collego ai segnali 
-- che vanno a spwstream
---------------------------------------------------

s_spw_di <= spw_di;
s_spw_si <= spw_si;
spw_do <= s_spw_do;
spw_so <= s_spw_so;

-- Accensione CITIROC tramite comando SpaceWire
cit1PwrCtrlInst: citirocPwrCtrl
port map(
    clk         => s_clock48M,
    rst         => s_global_rst,
    pwrStateIn  => s_pwr_on_citiroc1,
    enPwrDigOut => EN_PWR_DIG_CITIROC_1,
    enPwrAnaOut => EN_PWR_ANA_CITIROC_1,
    pGoodDigIn  => PGOOD_DIG_CITIROC_1,
    pGoodAnaIn  => PGOOD_ANA_CITIROC_1
);

cit2PwrCtrlInst: citirocPwrCtrl
port map(
    clk         => s_clock48M,
    rst         => s_global_rst,
    pwrStateIn  => s_pwr_on_citiroc2,
    enPwrDigOut => EN_PWR_DIG_CITIROC_2,
    enPwrAnaOut => EN_PWR_ANA_CITIROC_2,
    pGoodDigIn  => PGOOD_DIG_CITIROC_2,
    pGoodAnaIn  => PGOOD_ANA_CITIROC_2
);

uscitaTest(15) <= OR32_1 or OR32_2;
uscitaTest(14) <= HIT_MUX_1 or HIT_MUX_2;
uscitaTest(13) <= DIG_PROBE_1;
uscitaTest(12) <= DIG_PROBE_2;
uscitaTest(11) <= SR_OUT_SR_1;
uscitaTest(10) <= SR_OUT_SR_2;
uscitaTest(9)  <= SR_OUT_READ_1;
uscitaTest(8)  <= SR_OUT_READ_2;
uscitaTest(7)  <= dpcuReset;
uscitaTest(6)  <= dataReadyOutSigBuff;
uscitaTest(5)  <= trgInhibit;
uscitaTest(4)  <= extendedTriggerOut;
uscitaTest(3)  <= fifoAFULL;
uscitaTest(2)  <= tdaqBusyInSync;
uscitaTest(1)  <= dpcuTrgHoldSync;
uscitaTest(0)  <= dpcuBusyInSync;

dataReadyOut <= dataReadyOutSigBuff;

inst_test_file: test_file
generic map(
    concurrentTriggers   => concurrentTriggers,
    prescaledTriggers    => prescaledTriggers,
    holdOffBits          => holdOffBits
)
port map(
    clockSYS => s_clock200M,
    clock48M => s_clock48M,
    clock24M => s_clock24MBuff,
    clock200k => clk200k_sig,
    rst => s_global_rst,

    triggerInhibit => trgInhibit,
    triggerOUT => trigger_interno_sig,

    triggerCnt => trigCounter,

    turrets => s_turrets,
    turretsFlags => s_turretsFlags,
    turretsCounters => s_turretsCounters,

    PMT_mask_1           => s_PMT_mask_1,
    PMT_mask_2           => s_PMT_mask_2,
    generic_trigger_mask => s_generic_trigger_mask,
    trigger_mask         => s_trigger_mask,
    apply_trigger_mask   => s_apply_trigger_mask,
    apply_PMT_mask       => s_apply_PMT_mask,

    start_ACQ            => s_start_ACQ,
    stop_ACQ             => s_stop_ACQ,
    start_cal            => s_start_cal,
    stop_cal             => s_stop_cal,
    acquisition_state    => s_acquisition_state,
    calibration_state    => s_calibration_state,
    PMT_rate => s_PMT_rate,
    mask_rate => s_mask_rate,
    trigger_flag_1 => s_trigger_flag_1,
    trigger_flag_2 => s_trigger_flag_2,

    triggerID => s_triggerID,

    config_status_1 => s_config_status_1,
    config_status_2 => s_config_status_2,

    sw_rst => swRst,

    select_reg_1 => s_select_reg_1,
    SR_IN_SR_1 => s_SR_IN_SR_1,
    RST_B_SR_1 => s_RST_B_SR_1,
    CLK_SR_1 => s_CLK_SR_1,
    load_1 => s_load_1,
    select_reg_2 => s_select_reg_2,
    SR_IN_SR_2 => s_SR_IN_SR_2,
    RST_B_SR_2 => s_RST_B_SR_2,
    CLK_SR_2 => s_CLK_SR_2,
    load_2 => s_load_2,

    config_vector => s_config_vector,

    configure_command_1 => s_start_config_1,
    configure_command_2 => s_start_config_2,

    pwr_on_citiroc1 => s_pwr_on_citiroc1,
    pwr_on_citiroc2 => s_pwr_on_citiroc2,

    rstCIT1out => rstCIT1out,
    rstCIT2out => rstCIT2out,

    trigger_in_1 => s_trigger_in_1,
    trigger_in_2 => s_trigger_in_2,

    SDATA_hg_1 => s_SDATA_hg_1,
    SDATA_lg_1 => s_SDATA_lg_1,
    CS_1 => s_CS_1,
    SCLK_1 => s_SCLK_1,
    hold_hg_1 => s_hold_hg_1,
    hold_lg_1 => s_hold_lg_1,

    CLK_READ_1 => s_CLK_READ_1,
    SR_IN_READ_1 => s_SR_IN_READ_1,

    RST_B_READ_1 => s_RST_B_READ_1,

    SDATA_hg_2 => s_SDATA_hg_2,
    SDATA_lg_2 => s_SDATA_lg_2,
    CS_2 => s_CS_2,
    SCLK_2 => s_SCLK_2,
    hold_hg_2 => s_hold_hg_2,
    hold_lg_2 => s_hold_lg_2,

    CLK_READ_2 => s_CLK_READ_2,
    SR_IN_READ_2 => s_SR_IN_READ_2,

    RST_B_READ_2 => s_RST_B_READ_2,

    dataReady => dataReady,

    adcDataOut => adcDataOut,

    trgExtIn => trgExt,

    rate1SecOut => rate1SecSig,

    holdoff => holdoff,

    debug_triggerIN => s_start_debug
);

ppsCounterInst: ppsCounter
generic map(
    clkFreq        => 48.0e6,
    resolution     => 16.0e-6,
    ppsCountWidth  => 16,
    fineCountWidth => 16
)
port map(
    clk            => s_clock48M,
    rst            => s_global_rst,
    enable         => s_acquisition_state,
    ppsIn          => dpcuPPSSync,
    counterOut     => ppsCount
);

ppsCountReg: process(s_clock48M, s_global_rst)
begin
    if s_global_rst = '1' then
        ppsCountSync <= (others => '0');
    elsif rising_edge(s_clock48M) then
        ppsCountSync <= ppsCount;
    end if;
end process;

trgBusySetEdge: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => s_clock48M,
    rst       => s_global_rst,
    signalIn  => extendedTriggerOut,
    signalOut => trgBusySet
);

trgBusyInst: process(s_clock48M, swRst)
begin
    if swRst = '1' then
        trgBusy <= '0';
    elsif rising_edge(s_clock48M) then
        if trgBusySet = '0' and trgBusyRst = '1' then
            trgBusy <= '0';
        elsif trgBusySet = '1' and trgBusyRst = '0' then
            trgBusy <= '1';
        else
            trgBusy <= trgBusy;
        end if;
    end if;
end process;

aliveDeadinst: aliveDeadTCnt
port map(
    clock      => s_clock48M,
    clock200k  => clk200k_sig,
    reset      => swRst,
    busyState  => trgInhibit or trgBusy,
    acqState   => s_acquisition_state,
    trigger    => extendedTriggerOut,
    aliveCount => aliveCount,
    deadCount  => deadCount,
    lostCount  => lostCount
);

crc32 <= (others => '0'); -- (not implemented yet)

acqData(dataWidth-1 downto 0) <= x"4645"             &
                                 trigCounter         &
                                 ppsCountSync        &
                                 s_triggerID         &
                                 adcDataOut          &
                                 lostCount           &
                                 aliveCount          &
                                 deadCount           &
                                 s_trigger_flag_1    &
                                 s_trigger_flag_2    &
                                 s_turretsFlags      &
                                 s_turretsCounters   &
                                 crc32               &
                                 x"4748";

inst_spwFIFOInterface: spwFIFOInterface
generic map(
    fifoWidth      => fifoWidth,
    fifoDepth      => fifoDepth,
    acqDataLen     => acqData'length
)
port map(
    clk               => s_clock48M,
    rst               => swRst,

    adcDataReady      => dataReady,
    acqData           => acqData,

    pcktCounter       => pcktCounter,

    regAcqData        => regAcqData,

    dpcuBusyIn        => dpcuBusyInSync,
    dataReadyIn       => dataReadyOutSigBuff,

    writeDataLen      => writeDataLen,

    dataWrittenInFIFO => trgBusyRst,

    fifoDATA          => fifoDATA,
    fifoQ             => fifoQ,
    fifoWE            => fifoWE,
    fifoRE            => fifoRE,
    fifoAFULL         => fifoAFULL,
    fifoEMPTY         => fifoEMPTY,
    fifoWACK          => fifoWACK,
    fifoDVLD          => fifoDVLD
);

writeDataLenBuff <= writeDataLen;

inst_spwFIFO: spwFIFO
port map(
    CLK      => s_clock48M,
    RESET    => swRst,
    DATA     => fifoDATA,
    Q        => fifoQ,
    WE       => fifoWE,
    RE       => fifoRE,
    FULL     => fifoFULL,
    EMPTY    => fifoEMPTY,
    AFULL    => fifoAFULL,
    WACK     => fifoWACK,
    DVLD     => fifoDVLD
);

instSpwController: spw_controller
generic map(
    g_spw_addr_width    => 12,
    g_spw_data_width    => 32,
    g_spw_addr_offset   => x"000",
    g_spw_num           => 0,
    g_spw_idx           => x"00"
)
port map(
    i_spw_clk           => s_clock48M,
    i_reset             => s_global_rst,
  
    --regfile interface
    i_data_in           => s_do,
    o_data_out          => s_di,
    o_we                => s_we,
    o_addr              => s_addr,
    i_write_done        => writeDone,
    o_busy              => spwCtrlBusy,

    --SPW interface
    i_txrdy             => s_txrdy,
    i_rxvalid           => s_rxvalid,
    i_rxflag            => s_rxflag,
    i_rxdata            => s_rxdata,
    o_rxread            => s_rxread,
    o_txwrite           => s_txwrite,
    o_txflag            => s_txflag,
    o_txdata            => s_txdata
);

startTConvSigInst: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => s_clock24MBuff,
    rst       => s_global_rst,
    signalIn  => rate1SecSig,
    signalOut => rate1SecSigRise
);

temp1Inst: tempSensorRead
generic map(
    clkFreq       => 24.0e6,
    sclkFreq      => 750.0e3,
    sDataWidth    => tSDataWidth,
    tempWidth     => tempWidth
)
port map(
    clk           => s_clock24MBuff,
    rst           => s_global_rst,
    enableIn      => enableTsens,
    startConvIn   => rate1SecSigRise,
    sDataIn       => TSENS_DOUT_1,
    dataReadyOut  => temp1Completed,
    sclkOut       => TSENS_SCLK_1,
    csOut         => TSENS_CS_N_1,
    dataOut       => tempData(9 downto 0)
);

tempData(15 downto 10) <= (others => '0');

temp2Inst: tempSensorRead
generic map(
    clkFreq       => 24.0e6,
    sclkFreq      => 750.0e3,
    sDataWidth    => tSDataWidth,
    tempWidth     => tempWidth
)
port map(
    clk           => s_clock24MBuff,
    rst           => s_global_rst,
    enableIn      => enableTsens,
    startConvIn   => temp1Completed,
    sDataIn       => TSENS_DOUT_2,
    dataReadyOut  => temp2Completed,
    sclkOut       => TSENS_SCLK_2,
    csOut         => TSENS_CS_N_2,
    dataOut       => tempData(25 downto 16)
);

tempData(31 downto 26) <= (others => '0');

tDataReg: process(s_clock24MBuff, s_global_rst)
begin
    if s_global_rst = '1' then
        s_board_temp <= (others => '0');
    elsif rising_edge(s_clock24MBuff) then
        if temp2Completed = '1' then
            s_board_temp <= tempData;
        end if;
    end if;
end process;

inst_register_file: register_file
generic map(
    sysid => x"33CC33CC",
    refDac1Def => refDac1Def,
    refDac2Def => refDac2Def,
    dataWidth => dataWidth,
    prescaledTriggers => prescaledTriggers,
    holdOffBits => holdOffBits
)
port map(
    clk => s_clock48M,
    rst => s_global_rst,
    we => s_we,
    en => '1',
    addr => s_addr,
    di => s_di,
    do => s_do,
    o_write_done  => writeDone,
    i_busy => spwCtrlBusy,

    -- DAC piedistalli
    refDAC_1 => s_refDAC1,
    refDAC_2 => s_refDAC2,

    config_vector => s_config_vector,

    trigger_mask => s_trigger_mask,
    generic_trigger_mask => s_generic_trigger_mask,
    PMT_mask_1 => s_PMT_mask_1,
    PMT_mask_2 => s_PMT_mask_2,

    start_config_1 => s_start_config_1,
    start_config_2 => s_start_config_2,

    sw_rst => s_sw_rst,
    pwr_on_citiroc1 => s_pwr_on_citiroc1,
    pwr_on_citiroc2 => s_pwr_on_citiroc2,
    start_debug => s_start_debug,
    apply_trigger_mask => s_apply_trigger_mask,
    apply_PMT_mask => s_apply_PMT_mask,
    start_ACQ => s_start_ACQ,
    stop_ACQ => s_stop_ACQ,
    start_cal => s_start_cal,
    stop_cal => s_stop_cal,

    enableTsens => enableTsens,

    -- Segnali da/verso DPCU e TDAQ
    TDAQ_BUSY    => tdaqBusyInSync,
    DPCU_TRGHOLD => dpcuTrgHoldSync,
    DPCU_BUSY    => dpcuBusyInSync,
    dataReadyOut => dataReadyOutSig,

    -- DAC piedistalli
    sendRefDAC => s_sendRefDAC,

    config_status_1 => s_config_status_1,
    config_status_2 => s_config_status_2,
    acquisition_state => s_acquisition_state,
    calibration_state => s_calibration_state,

    refDac_status_1 => s_confDoneCIT1,
    refDac_status_2 => s_confDoneCIT2,

    fifoPckCnt => pcktCounter,

    writeDataLen => writeDataLenBuff,

    regAcqData => regAcqData,

    holdoff => holdoff,

    PMT_rate => s_PMT_rate,
    mask_rate => s_mask_rate,
    board_temp => s_board_temp
);

dataReadyOutSigBuff <= dataReadyOutSig;

sendRefDacExtInst: pulseExt
generic map(
    clkFreq    => 48.0e6,
    pulseWidth => 41.7e-9
)
port map(
    clk        => s_clock48M,
    rst        => s_global_rst,
    sigIn      => s_sendRefDAC,
    sigOut     => s_sendRefDAC_24M
);

refControlCIT1: refController
generic map(
    resetHGVal => refDac1Def(31 downto 16),
    resetLGVal => refDac1Def(15 downto 0)
)
port map(
    clk24M     => s_clock24MBuff,
    rst        => rstCIT1out,
	dacHGVal   => s_refDAC1(31 downto 16),
    dacLGVal   => s_refDAC1(15 downto 0),
    enableSclk => enableSclk_1,
    send       => s_sendRefDAC_24M,
    confDone   => s_confDoneCIT1,
    dout       => refDacDIN_1,
    syncHG     => s_refDacSync1HG,
    syncLG     => s_refDacSync1LG
);

refControlCIT2: refController
generic map(
    resetHGVal => refDac2Def(31 downto 16),
    resetLGVal => refDac2Def(15 downto 0)
)
port map(
    clk24M   => s_clock24MBuff,
    rst      => rstCIT2out,
	dacHGVal => s_refDAC2(31 downto 16),
    dacLGVal => s_refDAC2(15 downto 0),
    enableSclk => enableSclk_2,
    send     => s_sendRefDAC_24M,
    confDone => s_confDoneCIT2,
    dout     => refDacDIN_2,
    syncHG   => s_refDacSync2HG,
    syncLG   => s_refDacSync2LG
);

refDacSYNC_HG_1 <= s_refDacSync1HG;
refDacSYNC_LG_1 <= s_refDacSync1LG;
refDacSYNC_HG_2 <= s_refDacSync2HG;
refDacSYNC_LG_2 <= s_refDacSync2LG;

-- spwstream instance
spwstream_inst: spwstream
    generic map (
        sysfreq         => 48.0e6,
        txclkfreq       => 48.0e6,
        rximpl          => impl_generic,
        rxchunk         => 1,
        tximpl          => impl_generic,
        rxfifosize_bits => 6,
        txfifosize_bits => 6 )
    port map (
        clk         => s_clock48M,
        rxclk       => s_clock48M,
        txclk       => s_clock48M,
        rst         => s_global_rst,
        autostart   => '0',
        linkstart   => '1',
        linkdis     => '0',
        txdivcnt    => "00000010",
        tick_in     => '0',
        ctrl_in     => (others => '0'),
        time_in     => (others => '0'),
        txwrite     => s_txwrite,
        txflag      => s_txflag,
        txdata      => s_txdata,
        txrdy       => s_txrdy,
        txhalff     => open,
        tick_out    => open,
        ctrl_out    => open,
        time_out    => open,
        rxvalid     => s_rxvalid,
        rxhalff     => open,
        rxflag      => s_rxflag,
        rxdata      => s_rxdata,
        rxread      => s_rxread,
        started     => s_started,
        connecting  => s_connecting,
        running     => s_running,
        errdisc     => s_errdisc,
        errpar      => s_errpar,
        erresc      => s_erresc,
        errcred     => s_errcred,
        spw_di      => s_spw_di,
        spw_si      => s_spw_si,
        spw_do      => s_spw_do,
        spw_so      => s_spw_so
);

ODDR_CLK_READ_1: DDR_OUT
port map(
    DR  => '0',
    DF  => '1',
    CLR => s_CLK_READ_1,
    CLK => clk200k_sig,
    Q   => CLK_READ_1_toBuf
);

ODDR_CLK_READ_1_BUF: OUTBUF
port map(
    D   => CLK_READ_1_toBuf,
    PAD => CLK_READ_1
);

ODDR_CLK_READ_2: DDR_OUT
port map(
    DR  => '0',
    DF  => '1',
    CLR => s_CLK_READ_2,
    CLK => clk200k_sig,
    Q   => CLK_READ_2_toBuf
);

ODDR_CLK_READ_2_BUF: OUTBUF
port map(
    D   => CLK_READ_2_toBuf,
    PAD => CLK_READ_2
);

ODDR_SCLK_1: DDR_OUT
port map(
    DR  => '0',
    DF  => '1',
    CLR => s_SCLK_1,
    CLK => s_clock24MBuff,
    Q   => SCLK_1_toBuf
);

ODDR_SCLK_1_BUF: OUTBUF
port map(
    D   => SCLK_1_toBuf,
    PAD => SCLK_1
);

ODDR_SCLK_2: DDR_OUT
port map(
    DR  => '0',
    DF  => '1',
    CLR => s_SCLK_2,
    CLK => s_clock24MBuff,
    Q   => SCLK_2_toBuf
);

ODDR_SCLK_2_BUF: OUTBUF
port map(
    D   => SCLK_2_toBuf,
    PAD => SCLK_2
);

ODRR_citirocClkSR1: DDR_OUT
port map(
    DR => '0',
    DF => '1',
    CLR   => s_CLK_SR_1,
    CLK   => clk200k_sig,
    Q     => CLK_SR_1_toBuf
);

ODRR_citirocClkSR1_BUF: OUTBUF
port map(
    D   => CLK_SR_1_toBuf,
    PAD => CLK_SR_1
);

ODRR_citirocClkSR2: DDR_OUT
port map(
    DR => '0',
    DF => '1',
    CLR   => s_CLK_SR_2,
    CLK   => clk200k_sig,
    Q     => CLK_SR_2_toBuf
);

ODRR_citirocClkSR2_BUF: OUTBUF
port map(
    D   => CLK_SR_2_toBuf,
    PAD => CLK_SR_2
);

ODRR_dacSCLK1: DDR_OUT
port map( 
    DR  => '1',
    DF  => '0',
    CLR => enableSclk_1, -- attivo basso
    CLK => s_clock24MBuff,
    Q   => s_refDacSCLK_1_toBuf
);

ODRR_dacSCLK1_BUF: OUTBUF
port map(
    D   => s_refDacSCLK_1_toBuf,
    PAD => refDacSCLK_1
);

ODRR_dacSCLK2: DDR_OUT
port map( 
    DR  => '1',
    DF  => '0',
    CLR => enableSclk_2, -- attivo basso
    CLK => s_clock24MBuff,
    Q   => s_refDacSCLK_2_toBuf
);

ODRR_dacSCLK2_BUF: OUTBUF
port map(
    D   => s_refDacSCLK_2_toBuf,
    PAD => refDacSCLK_2
);

end architecture_top_test;
