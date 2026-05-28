library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_logic is
	port (clk, reset, game_active, training_mode, left_click : in std_logic;
		lfsr_value, mouse_y : in std_logic_vector(9 downto 0);
		lives_zero, shield_active, powerup_type : out std_logic;
		level, lives : out std_logic_vector(1 downto 0);
		sprite_y, pipe_x1, pipe_x2, pipe_x3, pipe_gap1, pipe_gap2, pipe_gap3, score, powerup_x, powerup_y : out std_logic_vector(9 downto 0));
end entity game_logic;

architecture logic of game_logic is
	signal update_tick, collision, lives_zero_internal, powerup_type_internal, shield_internal, collision_hit,	powerup_collected : std_logic;
	signal level_internal, lives_internal : unsigned(1 downto 0);
	signal sprite_y_internal, pipe_x1_internal, pipe_x2_internal, pipe_x3_internal, pipe_gap1_internal, pipe_gap2_internal, pipe_gap3_internal, score_internal, powerup_x_internal, powerup_y_internal : unsigned(9 downto 0);
	signal velocity : signed(9 downto 0);
	signal update_counter : unsigned(19 downto 0);
	signal cooldown : unsigned(21 downto 0);
	
	begin
		collision <= '1' when
		(sprite_y_internal >= 471) or
		(sprite_y_internal <= 8) or
		(pipe_x1_internal >= 100 and pipe_x1_internal <= 115 and
		(sprite_y_internal < pipe_gap1_internal - 40 or sprite_y_internal > pipe_gap1_internal + 40)) or
		(pipe_x2_internal >= 100 and pipe_x1_internal <= 115 and
		(sprite_y_internal < pipe_gap2_internal - 40 or sprite_y_internal > pipe_gap2_internal + 40)) or
		(pipe_x3_internal >= 100 and pipe_x1_internal <= 115 and
		(sprite_y_internal < pipe_gap3_internal - 40 or sprite_y_internal > pipe_gap3_internal + 40))
		else '0';
		update_counter_process: process(clk)
		variable threshold : unsigned(19 downto 0);
		begin
			if rising_edge(clk) then
			    if reset = '1' then
					update_counter <= (others => '0');
					update_tick <= '0';
				else
					if level_internal = "00" then
						threshold := to_unsigned(800000, 20);
					elsif level_internal = "01" then
						threshold := to_unsigned(600000, 20);
					else
						threshold := to_unsigned(400000, 20);
					end if;
						
					if update_counter >= threshold then
						update_counter <= (others => '0');
						update_tick <= '1';
					else
						update_counter <= update_counter + 1;
						update_tick <= '0';
					end if;
				end if;
			end if;			
		end process update_counter_process;
		
		Move_Sprite: process(clk)
			variable new_pos       : signed(11 downto 0);
			variable next_velocity : signed(9 downto 0);
		begin
			if rising_edge(clk) then
				if reset = '1' then
					sprite_y_internal <= to_unsigned(240,10);
					velocity <= to_signed(0,10);
				elsif collision_hit = '1' then
					sprite_y_internal <= to_unsigned(240, 10);
					velocity <= to_signed(0, 10);
				elsif game_active = '1' and update_tick = '1' then
					next_velocity := velocity;
					if left_click = '1' then
						next_velocity := to_signed(-10, 10);
					else
						if next_velocity < to_signed(12, 10) then
							next_velocity := next_velocity + to_signed(1, 10);
						end if;
					end if;
					new_pos := resize(signed('0' & std_logic_vector(sprite_y_internal)), 12)
							   + resize(next_velocity, 12);
					if new_pos >= to_signed(471, 12) then
						sprite_y_internal <= to_unsigned(471, 10);
						velocity <= to_signed(0, 10);
					elsif new_pos <= to_signed(8, 12) then
						sprite_y_internal <= to_unsigned(8, 10);
						velocity <= to_signed(0, 10);
					else
						sprite_y_internal <= unsigned(new_pos(9 downto 0));
						velocity <= next_velocity;
					end if;
				end if;
			end if;
		end process Move_Sprite;
			
		Pipe_Place: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					pipe_x1_internal <= to_unsigned(200,10);
					pipe_x2_internal <= to_unsigned(400,10);
					pipe_x3_internal <= to_unsigned(600,10);
					pipe_gap1_internal <= to_unsigned(240,10);
					pipe_gap2_internal <= to_unsigned(240,10);
					pipe_gap3_internal <= to_unsigned(240,10);
				elsif collision_hit = '1' then
					pipe_x1_internal <= to_unsigned(200, 10);
					pipe_x2_internal <= to_unsigned(400, 10);
					pipe_x3_internal <= to_unsigned(600, 10);
					pipe_gap1_internal <= to_unsigned(240, 10);
					pipe_gap2_internal <= to_unsigned(240, 10);
					pipe_gap3_internal <= to_unsigned(240, 10);
				elsif game_active = '1' and update_tick = '1' then
					if pipe_x1_internal = 0 then
						pipe_x1_internal <= to_unsigned(640,10);
						-- pipe 1: bits 7:0
						pipe_gap1_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(7 downto 0));
					else
						pipe_x1_internal <= pipe_x1_internal - 1;
					end if;
					if pipe_x2_internal = 0 then
						pipe_x2_internal <= to_unsigned(640,10);
						-- pipe 2: bits 8:1 (shifted)
						pipe_gap2_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(8 downto 1));
					else
						pipe_x2_internal <= pipe_x2_internal - 1;
					end if;
					if pipe_x3_internal = 0 then
						pipe_x3_internal <= to_unsigned(640,10);
						-- pipe 3: bits 9:2
						pipe_gap3_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(9 downto 2));
					else
						pipe_x3_internal <= pipe_x3_internal - 1;
					end if;
				end if;
			end if;
		end process Pipe_Place;
		
		Collision_Detection: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					if training_mode = '1' then
						lives_internal <= to_unsigned(3, 2);
					else
						lives_internal <= to_unsigned(1, 2);
					end if;
					cooldown <= (others => '0');
					lives_zero_internal <= '0';
					collision_hit <= '0';
					powerup_collected <= '0';
					shield_internal <= '0';
				else
					collision_hit <= '0';
					powerup_collected <= '0';
					if game_active = '1' then
						if cooldown > 0 then
							cooldown <= cooldown - 1;
						elsif collision = '1' then
							if shield_internal = '1' then
								shield_internal <= '0';
								cooldown <= to_unsigned(3000000, 22);
							else
								collision_hit <= '1';
								cooldown <= to_unsigned(3000000, 22);
								if lives_internal = 1 then
									lives_zero_internal <= '1';
								end if;
								lives_internal <= lives_internal - 1;
							end if;
						end if;

						-- Power up pickup
						if sprite_y_internal >= powerup_y_internal - 8 and
						   sprite_y_internal <= powerup_y_internal + 8 and
						   to_unsigned(100, 10) >= powerup_x_internal - 8 and
						   to_unsigned(100, 10) <= powerup_x_internal then
							if powerup_type_internal = '0' then
								shield_internal <= '1';
							else
								if lives_internal < to_unsigned(3, 2) then
									lives_internal <= lives_internal + 1;
								end if;
							end if;
							powerup_collected <= '1';
						end if;
					end if;
				end if;
			end if;
		end process Collision_Detection;
		
		Score_Tracker: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					score_internal <= (others => '0');
					level_internal <= (others => '0');
				else
				
					if game_active = '1' and update_tick = '1' then
						if pipe_x1_internal = 100 then
							score_internal <= score_internal + 1;
						end if;
						
						if pipe_x2_internal = 100 then
							score_internal <= score_internal + 1;
						end if;
						
						if pipe_x3_internal = 100 then
							score_internal <= score_internal + 1;
						end if;
						
						if score_internal >= 20 then
							level_internal <= to_unsigned(2, 2);
						elsif score_internal >= 10 then
							level_internal <= to_unsigned(1, 2);
						else
							level_internal <= (others => '0');
						end if;
					end if;
				end if;
			end if;
		end process Score_Tracker;
		
		Power_Up_Move : process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					powerup_x_internal <= to_unsigned(640, 10);
					powerup_y_internal <= to_unsigned(240, 10);
					powerup_type_internal <= '0';
				elsif powerup_collected = '1' then
					powerup_x_internal <= to_unsigned(640, 10);
					powerup_y_internal <= to_unsigned(100, 10) + unsigned("00" & lfsr_value(7 downto 0));
					powerup_type_internal <= not powerup_type_internal;
				elsif game_active = '1' and update_tick = '1' then
					if powerup_x_internal = 0 then
						powerup_x_internal <= to_unsigned(640, 10);
						powerup_y_internal <= to_unsigned(100, 10) + unsigned("00" & lfsr_value(7 downto 0));
						powerup_type_internal <= not powerup_type_internal;
					else
						powerup_x_internal <= powerup_x_internal - 1;
					end if;
				end if;
			end if;
		end process Power_Up_Move;
		
	-- Output assignments
    lives_zero  <= lives_zero_internal; 
    level       <= std_logic_vector(level_internal);
    lives       <= std_logic_vector(lives_internal);
    sprite_y     <= std_logic_vector(sprite_y_internal);
    pipe_x1      <= std_logic_vector(pipe_x1_internal);
    pipe_x2      <= std_logic_vector(pipe_x2_internal);
    pipe_x3      <= std_logic_vector(pipe_x3_internal);
    pipe_gap1    <= std_logic_vector(pipe_gap1_internal);
    pipe_gap2    <= std_logic_vector(pipe_gap2_internal);
    pipe_gap3    <= std_logic_vector(pipe_gap3_internal);
    score       <= std_logic_vector(score_internal);
	powerup_x    <= std_logic_vector(powerup_x_internal);
	powerup_y    <= std_logic_vector(powerup_y_internal);
	powerup_type <= powerup_type_internal;
	shield_active <= shield_internal;

end architecture logic;
			