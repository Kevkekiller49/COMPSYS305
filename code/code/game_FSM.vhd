library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_fsm is
	port(Clk, reset, start_button, pause_button, mode_switch, lives_zero : in std_logic;
		game_active : out std_logic;
		display_mode : out std_logic_vector (1 downto 0));
end entity game_fsm;

architecture behaviour of game_fsm is
	type state_type is (MENU, TRAINING, CHALLENGE, PAUSED_TRAINING, PAUSED_CHALLENGE, GAME_OVER);
	signal current_state : state_type;
	signal next_state : state_type;
	begin
		process(Clk)
		begin
			if (rising_edge(Clk)) then
				if (Reset = '1') then
					current_state <= MENU;
				else
					current_state <= next_state;
				end if;
			end if;
		end process;
		
		process (current_state, start_button, pause_button, mode_switch, lives_zero) 
		begin
			Case current_state is 
				when MENU => 
					if start_button = '1' then
						if mode_switch = '1' then
							next_state <= TRAINING;
						else
							next_state <= CHALLENGE;
						end if;
					else
						next_state <= current_state;
					end if;
				when TRAINING => 
					if lives_zero = '1' then
						next_state <= GAME_OVER;
					elsif pause_button = '1' then
						next_state <= PAUSED_TRAINING;
					else
						next_state <= current_state;
					end if;
				when PAUSED_TRAINING => 
					if pause_button = '1' then
						next_state <= TRAINING;
					else
						next_state <= current_state;
					end if;
				when CHALLENGE => 
					if lives_zero = '1' then
						next_state <= GAME_OVER;
					elsif pause_button = '1' then
						next_state <= PAUSED_CHALLENGE;
					else
						next_state <= current_state;
					end if;
				when PAUSED_CHALLENGE => 
					if pause_button = '1' then
						next_state <= CHALLENGE;
					else
						next_state <= current_state;
					end if;
				when GAME_OVER => 
					if start_button = '1' then
						next_state <= MENU;
					else
						next_state <= current_state;
					end if;
			end case;
		end process;
		
		process (current_state) 
		begin
			Case current_state is 
				when MENU => 
				game_active <= '0';
				display_mode <= "00";
				when TRAINING | CHALLENGE => 
				game_active <= '1';
				display_mode <= "01";
				when PAUSED_TRAINING | PAUSED_CHALLENGE => 
				game_active <= '0';
				display_mode <= "01";
				when GAME_OVER => 
				game_active <= '0';
				display_mode <= "10";
			end case;
		end process;
end architecture behaviour;