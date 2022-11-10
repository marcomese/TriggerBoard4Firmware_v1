library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ppsCounter is
generic(
    clk_freq      : natural := 50; -- clock freq in MHz
    pps_reset_len : natural := 40  -- PSS reset len in us
);
port(
    clk : in std_logic;
    rst : in std_logic;
    PPS : in std_logic;
    timestamp  : out std_logic_vector(31 downto 0)
);
end entity;


architecture Behavioral of ppsCounter is

	-- fine counter step in us
	constant fine_counter_step : integer := 16;
	-- clock divider for the fine counter
	constant clock_div_len : natural := clk_freq*fine_counter_step;
	signal clock_div_cnt : natural range 0 to clock_div_len := 0;

	signal pps_sync : std_logic;

	-- counter for the pps reset pulse
	constant pps_high_cnt_len : natural := clk_freq*pps_reset_len;
	signal pps_high_cnt : natural range 0 to pps_high_cnt_len := 0;
	signal reset_pulse_valid : std_logic := '0';

	signal fine_counter, coarse_counter : unsigned(15 downto 0);

begin


    pps_sync <= PPS;


	counter_gen: process(clk)
	begin
		if rising_edge(clk) then

			-- increase fine counter
			clock_div_cnt <= clock_div_cnt + 1;
			if clock_div_cnt >= clock_div_len-1 then
				clock_div_cnt <= 0;
				fine_counter <= fine_counter + 1;
			end if;

			-- incremement counter
			if fine_counter = integer(1e6/16 - 1) then
				coarse_counter <= coarse_counter + 1;
				fine_counter <= (others => '0');
			end if;


			-- pps reset detector
			if pps_sync = '0' then

				if pps_high_cnt = pps_high_cnt_len then
					reset_pulse_valid <= '1';
				else
					pps_high_cnt <= pps_high_cnt + 1;
				end if;

			else
				pps_high_cnt <= 0;
			end if;


			-- reset on risign edge of pps
			if (reset_pulse_valid = '1' and pps_sync = '1') or rst = '1'then
				fine_counter <= (others => '0');
				coarse_counter <= (others => '0');
				reset_pulse_valid <= '0';
			end if;

		end if;
	end process;

	timestamp <= std_logic_vector(coarse_counter & fine_counter);

end Behavioral;
