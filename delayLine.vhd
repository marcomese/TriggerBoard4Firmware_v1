library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity delayLine is
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
end delayLine;

architecture Behavioral of delayLine is

begin

noDelayGen: if ffNum = 0 generate
begin
    signalOUT <= signalIN;
end generate;

singleClkDelayGen: if ffNum = 1 generate
begin
    singleDelayBlock: block is
        signal ffIn   : std_logic;
        signal ffOut  : std_logic;
        signal muxIn  : std_logic_vector(1 downto 0);
        signal muxOut : std_logic;
    begin
    
        signalOut <= muxOut;

        muxIn <= ffOut & signalIn;
        muxOut <= muxIn(to_integer(unsigned(delayVal(0 downto 0))));
    
        ffIn <= signalIN;
    
        ffGenSingle: process(clk,rst)
        begin
            if rst = '1' then
                ffOut <= '0';
            elsif rising_edge(clk) then
                ffOut <= ffIn;
            end if;
        end process;

    end block singleDelayBlock;

end generate;

delayGen: if ffNum > 1 generate
begin

    delayBlock: block is
        signal ffIn   : std_logic;
        signal ffOut  : std_logic_vector(ffNum-1 downto 0);
        signal muxLSB : std_logic_vector(ffNum downto 0);
        signal muxIn  : std_logic_vector((2**delayVal'length)-1 downto 0);
        signal muxOut : std_logic;
    begin
    
        signalOut <= muxOut;

        muxLSB <= ffOut & signalIn;

        muxIn(ffNum downto  0) <= muxLSB;
        muxIn((2**delayVal'length)-1 downto ffNum+1) <= (others => ffOut(ffNum-1));
        
        muxOut <= muxIn(to_integer(unsigned(delayVal)));

        ffIn <= signalIN;
    
        ffGen: process(clk,rst)
        begin
            if rst = '1' then
                ffOut <= (others => '0');
            elsif rising_edge(clk) then
                ffOut(0) <= ffIn;
                for i in 0 to ffNum-2 loop
                    ffOut(i+1) <= ffOut(i);
                end loop;
            end if;
        end process;
    end block delayBlock;
    
end generate;

end Behavioral;
