library IEEE;
use IEEE.std_logic_1164.all;
library proasic3l;
use proasic3l.all;

entity refController is
generic(
    resetHGVal : std_logic_vector(15 downto 0) := x"0000";
    resetLGVal : std_logic_vector(15 downto 0) := x"0000"
);
port(
    clk24M     : in  std_logic;
    rst        : in  std_logic;
    enable     : in  std_logic;
	dacHGVal   : in  std_logic_vector(15 downto 0);
    dacLGVal   : in  std_logic_vector(15 downto 0);
    enableSclk : out std_logic;
    send       : in  std_logic;
    confDone   : out std_logic;
    dout       : out std_logic;
    syncHG     : out std_logic;
    syncLG     : out std_logic
);
end refController;

architecture architecture_refController of refController is

component serializer is
generic(
    parallelWidth      : natural;
    resetValue         : std_logic_vector(parallelWidth-1 downto 0);
    shiftBits          : natural;
    shiftDirection     : bit
);
port(
    parallelIN      : in    std_logic_vector(parallelWidth-1 downto 0);
    serialIN        : in    std_logic;
    load            : in    std_logic;
    clear           : in    std_logic;
    shift           : in    std_logic;
    serialOUT       : out   std_logic;
    shiftDone       : out   std_logic;
    clk             : in    std_logic;
    rst             : in    std_logic
    );
end component;

COMPONENT output_DDR is
    port( DataR : in    std_logic;
          DataF : in    std_logic;
          CLR   : in    std_logic;
          CLK   : in    std_logic;
          PAD   : out   std_logic
        );
end COMPONENT;

type fsmState is (start,
                  initState,
                  sclkInitEnabled,
                  idle,
                  loadBUF,
                  shiftHGBUF,
                  waitHGDone,
                  shiftLGBUF,
                  waitLGDone,
                  endState);

signal  currState,
        nextState                 : fsmState;

signal  shiftDone,
        dataSentSig, dataSentSigF,
        load, loadF,
        shift, shiftF,
        syncHGSig, syncHGSigF,
        syncLGSig, syncLGSigF,
        bufferSout,
        bufferReset, bufferResetF,
        enableSclkSig,
        initSend,initSendF,
        confDoneSig, confDoneSigF  : std_logic;

signal  bufferData                 : std_logic_vector(47 downto 0);

signal  srIn                       : std_logic_vector(1 downto 0);

constant  rstVal                   : std_logic_vector(47 downto 0) := (47 downto 40 => '0',
                                                                       39 downto 24 => resetHGVal,
                                                                       23 downto 16 => '0',
                                                                       15 downto 0  => resetLGVal);

--attribute syn_preserve : boolean;
--attribute syn_keep     : boolean;
--
--attribute syn_preserve of dataSentSig  : signal is true;
--attribute syn_preserve of initSend     : signal is true;
--attribute syn_preserve of load         : signal is true;
--
--attribute syn_keep of dataSentSig  : signal is true;
--attribute syn_keep of initSend     : signal is true;
--attribute syn_keep of load         : signal is true;

begin

bufferData(47 downto 40) <= (others => '0');  -- lo shift del buffer è a sinistra quindi esce prima HG e poi LG
bufferData(39 downto 24) <= dacHGVal;
bufferData(23 downto 16) <= (others => '0');
bufferData(15 downto 0)  <= dacLGVal;

srIn <= (send or initSend) & dataSentSig;

enableSclk <= enableSclkSig;

sclkEnFF: process(clk24M, rst, srIn, enableSclkSig)
begin
    if rst = '1' then
--        enableSclkSig <= '0';
        enableSclkSig <= '1'; -- pilota l'ingresso CLR di DDR_OUT quindi è attivo basso
    elsif rising_edge(clk24M) then
        case srIn is
            when "01" =>
--                enableSclkSig <= '0';
                  enableSclkSig <= '1'; -- pilota l'ingresso CLR di DDR_OUT quindi è attivo basso
            when "10" =>
--                enableSclkSig <= '1';
                  enableSclkSig <= '0'; -- pilota l'ingresso CLR di DDR_OUT quindi è attivo basso
            when others =>
                enableSclkSig <= enableSclkSig;
        end case;
    end if;
end process;

syncHG <= syncHGSig;

syncLG <= syncLGSig;

dout <= bufferSout;

confDone <= confDoneSig;

ser: serializer
generic map(
    parallelWidth  => 48,
    resetValue     => rstVal,
    shiftBits      => 24,
    shiftDirection => '0'
)
port map(
    parallelIN     => bufferData,
    serialIN       => '0',
    load           => load,
    clear          => bufferReset,
    shift          => shift,
    serialOUT      => bufferSout,
    shiftDone      => shiftDone,
    clk            => clk24M,
    rst            => rst
);

------------- controller FSM
reg: process(rst, clk24M)
begin
	if rst='1' then
		currState       <= start;
        load            <= '0';
        shift           <= '0';
        syncHGSig       <= '1';
        syncLGSig       <= '1';
        bufferReset     <= '1';
        dataSentSig     <= '0';
        initSend        <= '0';
        confDoneSig     <= '0';
	elsif rising_edge(clk24M) then
		currState       <= nextState;
        load            <= loadF;
        shift           <= shiftF;
        syncHGSig       <= syncHGSigF;
        syncLGSig       <= syncLGSigF;
        bufferReset     <= bufferResetF;
        dataSentSig     <= dataSentSigF;
        initSend        <= initSendF;
        confDoneSig     <= confDoneSigF;
	end if;
end process;

comb: process(currState, send, shiftDone)
begin
	case currState is
        when start =>
            if enable = '1' then
                nextState <= initState;
            else
                nextState <= start;
            end if;

        when initState =>
                nextState <= sclkInitEnabled;

        when sclkInitEnabled =>
                nextState <= shiftHGBUF;

		when idle =>
			if send='1' and enable = '1' then
				nextState <= loadBUF;
			else
				nextState <= idle;
			end if;
			
		when loadBUF =>
				nextState <= shiftHGBUF;

        when shiftHGBUF =>
                nextState <= waitHGDone;

        when waitHGDone =>
            if shiftDone = '1' then
                nextState <= shiftLGBUF;
            else
                nextState <= waitHGDone;
            end if;

        when shiftLGBUF =>
                nextState <= waitLGDone;

        when waitLGDone =>
            if shiftDone = '1' then
                nextState <= endState;
            else
                nextState <= waitLGDone;
            end if;

        when endState =>
                nextState <= idle;

        when others =>
                nextState <= idle;
	end case;
end process;

uscite: process(nextState)
begin
	case nextState is
        when start =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '1';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

        when initState =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '1';
            confDoneSigF  <= '0';

        when sclkInitEnabled =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

		when idle =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '1';

		when loadBUF =>
			loadF         <= '1';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

        when shiftHGBUF =>
			loadF         <= '0';
            shiftF        <= '1';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

        when waitHGDone =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '0';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

        when shiftLGBUF =>
			loadF         <= '0';
            shiftF        <= '1';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

        when waitLGDone =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '0';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';

		when endState =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '1';
            dataSentSigF  <= '1';
            initSendF     <= '0';
            confDoneSigF  <= '1';

        when others =>
			loadF         <= '0';
            shiftF        <= '0';
            syncHGSigF    <= '1';
            syncLGSigF    <= '1';
            bufferResetF  <= '0';
            dataSentSigF  <= '0';
            initSendF     <= '0';
            confDoneSigF  <= '0';
	end case;
end process;

end architecture_refController;
