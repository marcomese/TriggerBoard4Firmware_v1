library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library proasic3l;
use proasic3l.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity test_file is
generic(
    concurrentTriggers   : natural;
    prescaledTriggers    : natural;
    holdOffBits          : natural
);
port (
    clockSYS       : in std_logic;  -- clk di sistema: 192 MHz
    clock48M       : in std_logic;
    clock24M       : in std_logic;  -- per gli ADC
    clock200k      : in std_logic;

    rst            : in std_logic;

    triggerInhibit : in std_logic;
    triggerOUT     : out std_logic;

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

    PMT_rate            : out std_logic_vector(1023 downto 0);
    mask_rate         : out std_logic_vector(319 downto 0);
    trigger_flag_1    : out std_logic_vector(31 downto 0);
    trigger_flag_2    : out std_logic_vector(31 downto 0);

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
end test_file;


architecture Behavioral of test_file is

component pulseExpand is
    Port ( clkOrig : in  STD_LOGIC;
           clkDest : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           pulseIN : in  STD_LOGIC;
           pulseOUT : out  STD_LOGIC);
end component;

component CLKINT is
    port (A : in std_logic;
          Y : out std_logic);
end component;

component delayLine is
    Generic(
        ffNum        : integer := 8
    );
    Port(
        signalIN    : in  std_logic;
        signalOUT   : out std_logic;
        delayVal    : in  std_logic_vector;
        clk         : in  std_logic;
        rst         : in  std_logic
        );
end component;

component config_CITIROC_1 is
port(  
    clk200k           : in std_logic;
    reset             : in std_logic;

    configure_command : in std_logic;
    config_vector     : in std_logic_vector(1143 downto 0);

    idle              : out std_logic;
    load              : out std_logic;
            
    select_reg        : out std_logic;  

    SR_IN_SR          : out std_logic;  
    RST_B_SR          : out std_logic;  
    CLK_SR            : out std_logic
);
end component;

component read_FSM is
port(
    reset       : in std_logic;
    clock       : in std_logic;   
    clock200    : in std_logic;   -- clock a 200 kHz
    clock24M    : in std_logic;   -- clock a 24 MHz
    SDATA_hg    : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg    : in std_logic;    -- 2 leading '0' + 12 dati

    trigger_int : in std_logic;

    CS          : out std_logic;  -- attivo sul fronte di discesa
    SCLK        : out std_logic;  -- il dato cambia sul fronte di discesa

    LG_data     : out std_logic_vector(383 downto 0);
    HG_data     : out std_logic_vector(383 downto 0);

    hold_B      : out std_logic;  -- attivo ALTO

    CLK_READ    : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ  : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                  -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ  : out std_logic;  -- attivo basso 
                                      -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
    data_ready  : out std_logic
);
end component;

component TRIGGER_logic_FSM is
generic(
    concurrentTriggers   : natural;
    prescaledTriggers    : natural;
    holdOffBits          : natural
);
port(
    reset                : in  std_logic;
    clock                : in  std_logic;  
    clock200k            : in  std_logic;  
    debug                : in  std_logic;
    trigger_in_1         : in  std_logic_vector(31 downto 0);
    trigger_in_2         : in  std_logic_vector(31 downto 0);
    PMT_mask_1           : in  std_logic_vector(31 downto 0);
    PMT_mask_2           : in  std_logic_vector(31 downto 0);
    generic_trigger_mask : in  std_logic_vector(31 downto 0);	
    trigger_mask         : in  std_logic_vector(31 downto 0);
    apply_trigger_mask   : in  std_logic;
    apply_PMT_mask       : in  std_logic;
    start_readers        : in  std_logic;

    calibration_state    : in  std_logic;
    acquisition_state    : in  std_logic;
			
    PMT_rate             : out std_logic_vector(1023 downto 0);	
    mask_rate            : out std_logic_vector(319 downto 0);

    trigger_flag_1       : out std_logic_vector(31 downto 0);	
    trigger_flag_2       : out std_logic_vector(31 downto 0);			

    trgExtIn             : in  std_logic;

    rate1SecOut          : out std_logic;

    holdoff              : in  std_logic_vector((holdOffBits*prescaledTriggers)-1 downto 0);

    trg_to_DAQ_EASI      : out std_logic  -- attivo alto
);
end component;

component genericSync is
generic(
    sigNum : natural
);
port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sigIn  : in  std_logic_vector(sigNum-1 downto 0);
    sigOut : out std_logic_vector(sigNum-1 downto 0)
);
end component;

-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

constant holdDelayConst : std_logic_vector(7 downto 0) := x"20";

signal clk         : std_logic;
signal idle_1_sig  : std_logic;
signal idle_2_sig  : std_logic;

signal CLK_READ_1_sig, CLK_READ_2_sig : std_logic;

signal hg_data_1_sig, hg_data_2_sig : std_logic_vector(383 downto 0);
signal lg_data_1_sig, lg_data_2_sig : std_logic_vector(383 downto 0);

signal SCLK_1_sig, SCLK_2_sig: std_logic;

signal hold_1_sig, hold_2_sig: std_logic;

signal data_ready_2_sig, data_ready_1_sig, trigger_int_sig : std_logic;

signal trigger_interno_sig : std_logic;

signal s_trigger_flag_1, 
       s_trigger_flag_2 : std_logic_vector(31 downto 0);

signal s_pmt_rate : std_logic_vector(1023 downto 0);
signal s_mask_rate : std_logic_vector(319 downto 0);

signal s_config_vector : std_logic_vector(1143 downto 0);

signal conf_comm_200k_1, conf_comm_200k_2 : std_logic;

signal holdSignal_1 : std_logic;
signal holdSignal_2 : std_logic;

signal acquisition_state_sig : std_logic;
signal calibration_state_sig : std_logic;
signal start_readers_sig     : std_logic;

signal s_dataReady           : std_logic;

signal  rstCIT1FF,
        rstCIT2FF,
        rstCIT1,
        rstCIT2              : std_logic;

signal  maskedTrigger        : std_logic;

begin

clk <= clockSYS;

s_config_vector <= config_vector;

maskedTrigger <= trigger_interno_sig and (not triggerInhibit);
triggerOUT <= maskedTrigger;

PMT_rate <= s_PMT_rate;
mask_rate <= s_mask_rate;

calibration_state <= calibration_state_sig;
acquisition_state <= acquisition_state_sig;

config_status_1 <= idle_1_sig;
config_status_2 <= idle_2_sig;

trigger_flag_1 <= s_trigger_flag_1;
trigger_flag_2 <= s_trigger_flag_2;

CLK_READ_1 <= CLK_READ_1_sig;
CLK_READ_2 <= CLK_READ_2_sig;

SCLK_1 <= SCLK_1_sig;
SCLK_2 <= SCLK_2_sig;

adcDataOutReg: process(sw_rst, clk, s_dataReady)
begin
    if sw_rst = '1' then
        adcDataOut <= (others => '0');
    elsif rising_edge(clk) then
        if s_dataReady = '1' then
            adcDataOut <= HG_data_1_sig & LG_data_1_sig & 
                          HG_data_2_sig & LG_data_2_sig;
        end if;
    end if;
end process;

dataReadyExpandInst: pulseExpand
port map(
    clkOrig  => clk,
    clkDest  => clock48M,
    rst      => rst,
    pulseIN  => data_ready_1_sig,
    pulseOUT => s_dataReady
);

dataReady <= s_dataReady;

pulseExpand_inst1: pulseExpand
port map(
    clkOrig  => clk,
    clkDest  => clock200k,
    rst      => rst,
    pulseIN  => configure_command_1,
    pulseOUT => conf_comm_200k_1
);

pulseExpand_inst2: pulseExpand
port map(
    clkOrig  => clk,
    clkDest  => clock200k,
    rst      => rst,
    pulseIN  => configure_command_2,
    pulseOUT => conf_comm_200k_2
);

holdDelay_1_inst: delayLine
generic map(
    ffNum => 32
)
port map(
    clk       => clk,
    rst       => rst,
    signalIN  => hold_1_sig,
    signalOUT => holdSignal_1,
    delayVal  => holdDelayConst
);

rstCIT1Gen: process(rst, clock200k)
begin
    if rst = '1' then
        rstCIT1FF <= '0';
    elsif rising_edge(clock200k) then
        rstCIT1FF <= pwr_on_citiroc1;
    end if;
end process;

rstCIT1 <= not rstCIT1FF;
rstCIT1out <= rstCIT1;

configCit1Inst: config_CITIROC_1
port map(  
    clk200k           => clock200k,
    reset             => rstCIT1,

    configure_command => conf_comm_200k_1, 
    config_vector     => s_config_vector,

    idle              => idle_1_sig,
    load              => load_1,

    select_reg        => select_reg_1 ,

    SR_IN_SR          => SR_IN_SR_1  , 
    RST_B_SR          => RST_B_SR_1  , 
    CLK_SR            => CLK_SR_1  
);

holdDelay_2_inst: delayLine
generic map(
    ffNum => 32
)
port map(
    clk       => clk,
    rst       => rst,
    signalIN  => hold_2_sig,
    signalOUT => holdSignal_2,
    delayVal  => holdDelayConst
);

rstCIT2Gen: process(rst, clock200k)
begin
    if rst = '1' then
        rstCIT2FF <= '0';
    elsif rising_edge(clock200k) then
        rstCIT2FF <= pwr_on_citiroc2;
    end if;
end process;

rstCIT2 <= not rstCIT2FF;
rstCIT2out <= rstCIT2;

configCit2Inst: config_CITIROC_1
port map(  
    clk200k           => clock200k,
    reset             => rstCIT2,

    configure_command => conf_comm_200k_2, 
    config_vector     => s_config_vector,

    idle              => idle_2_sig,
    load              => load_2,

    select_reg        => select_reg_2 ,

    SR_IN_SR          => SR_IN_SR_2  , 
    RST_B_SR          => RST_B_SR_2  , 
    CLK_SR            => CLK_SR_2  
);

readFsmCit2Inst: READ_FSM
port map(
    clock       => clk,
    reset       => sw_rst,
    clock200    => clock200k,
    clock24M    => clock24M,

    SDATA_hg    => SDATA_hg_1,
    SDATA_lg    => SDATA_lg_1,

    trigger_int => maskedTrigger,

    CS          => CS_1,
    SCLK        => SCLK_1_sig,

    HG_data     => HG_data_1_sig,
    LG_data     => LG_data_1_sig,

    hold_B      => hold_1_sig,
    CLK_READ    => CLK_READ_1_sig,
    SR_IN_READ  => SR_IN_READ_1,
    RST_B_READ  => RST_B_READ_1,
    data_ready  => data_ready_1_sig
);

readFsmCit1Inst: READ_FSM
port map(
    clock       => clk,
    reset       => sw_rst,
    clock200    => clock200k,
    clock24M    => clock24M,

    SDATA_hg    => SDATA_hg_2,
    SDATA_lg    => SDATA_lg_2,

    trigger_int => maskedTrigger,

    CS          => CS_2,
    SCLK        => SCLK_2_sig,

    HG_data     => HG_data_2_sig,
    LG_data     => LG_data_2_sig,

    hold_B      => hold_2_sig,
    CLK_READ    => CLK_READ_2_sig,
    SR_IN_READ  => SR_IN_READ_2,
    RST_B_READ  => RST_B_READ_2,
    data_ready  => data_ready_2_sig
);

hold_hg_1 <= holdSignal_1;
hold_lg_1 <= holdSignal_1;
hold_hg_2 <= holdSignal_2;
hold_lg_2 <= holdSignal_2;

ACQ_REGISTER: process(clk, rst, start_ACQ, stop_ACQ)
begin
   if rst='1' then
        acquisition_state_sig <= '0';
   elsif rising_edge(clk) then
        if start_ACQ = '1' and stop_ACQ = '0' then
            acquisition_state_sig <= '1';
        elsif start_ACQ = '0' and stop_ACQ = '1' then
            acquisition_state_sig <= '0';
        else
            acquisition_state_sig <= acquisition_state_sig;
        end if;
   end if;
end process;

CAL_REGISTER: process(clk, rst, start_cal, stop_cal)
begin
   if rst='1' then
        calibration_state_sig <= '0';
   elsif rising_edge(clk) then
        if start_cal = '1' and stop_cal = '0' then
            calibration_state_sig <= '1';
        elsif start_cal = '0' and stop_cal = '1' then
            calibration_state_sig <= '0';
        else
            calibration_state_sig <= calibration_state_sig;
        end if;
   end if;
end process;

start_readers_sig <= acquisition_state_sig or calibration_state_sig;

triggerLogicFSMInst: TRIGGER_logic_FSM
generic map(
    concurrentTriggers   => concurrentTriggers,
    prescaledTriggers    => prescaledTriggers,
    holdOffBits          => holdOffBits
)
port map (
    reset                => sw_rst,
    clock                => clk,
    clock200k            => clock200k,
    debug                => trigger_int_sig,
    trigger_in_1         => trigger_in_1,
    trigger_in_2         => trigger_in_2,
    PMT_mask_1           => PMT_mask_1,
    PMT_mask_2           => PMT_mask_2,
    generic_trigger_mask => generic_trigger_mask,
    trigger_mask         => trigger_mask,
    apply_trigger_mask   => apply_trigger_mask,
    apply_PMT_mask       => apply_PMT_mask,
    start_readers        => start_readers_sig,

    calibration_state    => calibration_state_sig,
    acquisition_state    => acquisition_state_sig,

    mask_rate            => s_mask_rate,
    PMT_rate             => s_PMT_rate,				

    trigger_flag_1       => s_trigger_flag_1,		
    trigger_flag_2       => s_trigger_flag_2,			

    trgExtIn             => trgExtIn,

    rate1SecOut          => rate1SecOut,

    holdoff              => holdoff,

    trg_to_DAQ_EASI      => trigger_interno_sig
);

edge_trigger: process(clk, rst, debug_triggerIN)
variable resync : std_logic_vector(1 to 3);
begin
    if rst='1' then
        trigger_int_sig <= '0';
    elsif rising_edge(clk) then
        trigger_int_sig <= resync(2) and not resync(3);
        resync := debug_triggerIN & resync(1 to 2);
    end if;
end process;

end Behavioral;
