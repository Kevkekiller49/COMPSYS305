library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity test_bench_game_FSM is
end entity test_bench_game_FSM;


architecture test of test_bench_game_FSM is
	signal t_Clk : std_logic := '0';
	signal t_Reset : std_logic;
	signal t_start_button : std_logic;
	signal t_mode_switch : std_logic;
	signal t_lives_zero : std_logic;
	signal t_pause_button : std_logic;
	signal t_game_active : std_logic;
	signal t_display_mode : std_logic_vector(1 downto 0);


	component game_FSM is
		port(Clk, reset, start_button, pause_button, mode_switch, lives_zero : in std_logic;
			game_active : out std_logic;
			display_mode : out std_logic_vector (1 downto 0));
	end component;
	begin
		DUT: game_FSM port map(
			Clk => t_Clk, 
			start_button => t_start_button, 
			pause_button => t_pause_button, 
			Reset => t_Reset, 
			lives_zero => t_lives_zero,
			mode_switch => t_mode_switch,
			game_active => t_game_active,
			display_mode => t_display_mode
			);
		
	 	clk_process: process
		begin
			t_Clk <= not t_Clk;
			wait for 10 ns;
		end process clk_process;
		
		init: process
		begin
			-- initialise all inputs
		t_Reset <= '0';
		t_start_button <= '0';
		t_pause_button <= '0';
		t_mode_switch <= '0';
		t_lives_zero <= '0';
		wait for 20 ns;

		-- test reset
		t_Reset <= '1';
		wait for 20 ns;
		t_Reset <= '0';
		wait for 20 ns;

		-- continue with next test...
		
		t_mode_switch <= '1';
		t_start_button <= '1';
		wait for 20 ns;
		t_mode_switch <= '0';
		t_start_button <= '0';
		wait for 20 ns;
		
		t_pause_button <= '1';
		wait for 20 ns;
		t_pause_button <= '0';
		wait for 20 ns;
		
		t_pause_button <= '1';
		wait for 20 ns;
		t_pause_button <= '0';
		wait for 20 ns;
		
		t_lives_zero <= '1';
		wait for 20 ns;
		t_lives_zero <= '0';
		wait for 20 ns;
		
		t_start_button <= '1';
		wait for 20 ns;
		t_start_button <= '0';
		wait for 20 ns;
		
		t_mode_switch <= '0';
		t_start_button <= '1';
		wait for 20 ns;
		t_start_button <= '0';
		wait for 20 ns;
		
		t_pause_button <= '1';
		wait for 20 ns;
		t_pause_button <= '0';
		wait for 20 ns;
		
		t_pause_button <= '1';
		wait for 20 ns;
		t_pause_button <= '0';
		wait for 20 ns;
		
		t_lives_zero <= '1';
		wait for 20 ns;
		t_lives_zero <= '0';
		wait for 20 ns;
	
		wait;
		end process init;
		
end architecture test;
			

