library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ppsCounter is
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
end ppsCounter;

architecture Behavioral of ppsCounter is

component edgeDetector is
generic(
    edge      : std_logic
);
port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    signalIn  : in  std_logic;
    signalOut : out std_logic
);
end component;

constant fineCount   : natural := natural(resolution*clkFreq);

signal   ppsRising,
         fineElapsed : std_logic;

signal   ppsCounter  : natural range 0 to (2**ppsCountWidth)-1;
signal   fineCounter : natural range 0 to (2**fineCountWidth)-1;
signal   resCounter  : natural range 0 to fineCount;

begin

counterOut <= std_logic_vector(to_unsigned(ppsCounter,16)) &
              std_logic_vector(to_unsigned(fineCounter,16));

ppsEdgeDetInst: edgeDetector
generic map(
    edge      => '1'
)
port map(
    clk       => clk,
    rst       => rst,
    signalIn  => ppsIn,
    signalOut => ppsRising
);

ppsCounterInst: process(clk, rst, ppsRising)
begin
    if rst = '1' then
        ppsCounter <= 0;
    elsif rising_edge(clk) then
        if enable = '1' then
            if ppsRising = '1' then
                ppsCounter <= ppsCounter + 1;
            else
                ppsCounter <= ppsCounter;
            end if;
        else
            ppsCounter <= 0;
        end if;
    end if;
end process;

fineCounterInst: process(clk, rst, ppsRising, fineElapsed, enable)
begin
    if rst = '1' then
        fineCounter <= 0;
    elsif rising_edge(clk) then
        if enable = '1' then
            if ppsRising = '1' then
                fineCounter <= 0;
            elsif fineElapsed = '1' then
                fineCounter <= fineCounter + 1;
            else
                fineCounter <= fineCounter;
            end if;
        else
            fineCounter <= 0;
        end if;
    end if;
end process;

resCounterInst: process(clk, rst, resCounter, ppsRising, enable)
begin
    if rst = '1' then
        resCounter  <= 0;
        fineElapsed <= '0';
    elsif rising_edge(clk) then
        if enable = '1' then
            if ppsRising = '1' then
                resCounter <= 0;
                fineElapsed <= '0';
            else
                if resCounter = fineCount-1 then
                    resCounter <= 0;
                    fineElapsed <= '0';
                elsif resCounter = fineCount-2 then
                    resCounter <= resCounter + 1;
                    fineElapsed <= '1';
                else
                    resCounter <= resCounter + 1;
                    fineElapsed <= '0';
                end if;
            end if;
        else
            resCounter <= 0;
            fineElapsed <= '0';
        end if;
    end if;
end process;

end Behavioral;
