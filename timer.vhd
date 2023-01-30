library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timer is
generic(
    countWidth : natural
);
port(
    clk        : in  std_logic;
    rst        : in  std_logic;
    start      : in  std_logic;
    stop       : in  std_logic;
    clear      : in  std_logic;
    count      : in  std_logic_vector(countWidth-1 downto 0);
    timeout    : out std_logic
);
end timer;

architecture architecture_timer of timer is

type    state is (idle, waitCount, endCount, rstCount);

signal  currState,
        nextState               : state;

signal  timeoutSig, timeoutSigF,
        cntEnSig, cntEnSigF,
        cntRstSig, cntRstSigF   : std_logic;

signal  clkCount                : unsigned(countWidth-1 downto 0);

begin

timeout <= timeoutSig;

syncProc: process(clk, rst)
begin
    if rst = '1' then
        currState  <= idle;
        timeoutSig <= '0';
        cntEnSig   <= '0';
        cntRstSig  <= '1';
    elsif rising_edge(clk) then
        currState  <= nextState;
        timeoutSig <= timeoutSigF;
        cntEnSig   <= cntEnSigF;
        cntRstSig  <= cntRstSigF;
    end if;
end process;

combProc: process(currState, start, stop, clear, clkCount)
begin
    case currState is
        when idle =>
             if start = '0' and stop = '0' and clear = '0' then
                nextState <= idle;
            elsif start = '0' and stop = '0' and clear = '1' then
                nextState <= rstCount;
            elsif start = '0' and stop = '1' and clear = '0' then
                nextState <= idle;
            elsif start = '0' and stop = '1' and clear = '1' then
                nextState <= rstCount;
            elsif start = '1' and stop = '0' and clear = '0' then
                nextState <= waitCount;
            elsif start = '1' and stop = '0' and clear = '1' then
                nextState <= rstCount;
            elsif start = '1' and stop = '1' and clear = '0' then
                nextState <= idle;
            elsif start = '1' and stop = '1' and clear = '1' then
                nextState <= rstCount;
            else
                nextState <= waitCount;
            end if;

        when waitCount =>
            if clkCount = unsigned(count) - 1 then
                nextState <= endCount;
            else
                if start = '0' and stop = '0' and clear = '0' then
                    nextState <= waitCount;
                elsif start = '0' and stop = '0' and clear = '1' then
                    nextState <= rstCount;
                elsif start = '0' and stop = '1' and clear = '0' then
                    nextState <= idle;
                elsif start = '0' and stop = '1' and clear = '1' then
                    nextState <= rstCount;
                elsif start = '1' and stop = '0' and clear = '0' then
                    nextState <= waitCount;
                elsif start = '1' and stop = '0' and clear = '1' then
                    nextState <= rstCount;
                elsif start = '1' and stop = '1' and clear = '0' then
                    nextState <= idle;
                elsif start = '1' and stop = '1' and clear = '1' then
                    nextState <= rstCount;
                else
                    nextState <= waitCount;
                end if;
            end if;

        when endCount =>
            nextState <= idle;

        when rstCount =>
            nextState <= idle;

        when others =>
            nextState <= idle;
    end case;
end process;

outProc: process(nextState)
begin
    case nextState is
        when idle =>
            timeoutSigF <= '0';
            cntEnSigF   <= '0';
            cntRstSigF  <= '0';

        when waitCount =>
            timeoutSigF <= '0';
            cntEnSigF   <= '1';
            cntRstSigF  <= '0';

        when endCount =>
            timeoutSigF <= '1';
            cntEnSigF   <= '0';
            cntRstSigF  <= '1';

        when rstCount =>
            timeoutSigF <= '0';
            cntEnSigF   <= '0';
            cntRstSigF  <= '1';

        when others =>
            timeoutSigF <= '0';
            cntEnSigF   <= '0';
            cntRstSigF  <= '0';
    end case;
end process;

counterProc: process(rst, clk, cntRstSig, cntEnSig)
begin
    if rst = '1' then
        clkCount <= (others => '0');
    elsif rising_edge(clk) then
        if cntEnSig = '0' and cntRstSig = '0' then
            clkCount <= clkCount;
        elsif cntEnSig = '0' and cntRstSig = '1' then
            clkCount <= (others => '0');
        elsif cntEnSig = '1' and cntRstSig = '0' then
            clkCount <= clkCount + 1;
        elsif cntEnSig = '1' and cntRstSig = '1' then
            clkCount <= (others => '0');
        else
            clkCount <= clkCount;
        end if;
    end if;
end process;

end architecture_timer;
