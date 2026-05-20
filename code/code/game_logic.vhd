library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_logic is
	port (clk, reset, game_active, training_mode, left_click : in std_logic;
		lfsr_value, mouse_y : in std_logic_vector(9 downto 0);
		lives_zero : out std_logic;
		level, lives : out std_logic_vector(1 downto 0);
		child_y, arm_x1, arm_x2, arm_x3, arm_gap1, arm_gap2, arm_gap3, score : out std_logic_vector(9 downto 0));
end entity game_logic;

architecture logic of game_logic is
	signal update_tick, collision, lives_zero_internal: std_logic;
	signal level_internal, lives_internal : unsigned(1 downto 0);
	signal child_y_internal, arm_x1_internal, arm_x2_internal, arm_x3_internal, arm_gap1_internal, arm_gap2_internal, arm_gap3_internal, score_internal : unsigned(9 downto 0);
	signal velocity : signed(9 downto 0);
	signal update_counter : unsigned(19 downto 0);
	signal cooldown : unsigned(21 downto 0);
	
	begin
		collision <= '1' when
		(child_y_internal >= 471) or
		(child_y_internal <= 8) or
		(arm_x1_internal >= 80 and arm_x1_internal <= 120 and
		(child_y_internal < arm_gap1_internal - 40 or child_y_internal > arm_gap1_internal + 40)) or
		(arm_x2_internal >= 80 and arm_x2_internal <= 120 and
		(child_y_internal < arm_gap2_internal - 40 or child_y_internal > arm_gap2_internal + 40)) or
		(arm_x3_internal >= 80 and arm_x3_internal <= 120 and
		(child_y_internal < arm_gap3_internal - 40 or child_y_internal > arm_gap3_internal + 40))
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
		
		Move_Child: process(clk)
			variable new_pos       : signed(11 downto 0);
			variable next_velocity : signed(9 downto 0);
		begin
			if rising_edge(clk) then
				if reset = '1' then
					child_y_internal <= to_unsigned(240,10);
					velocity <= to_signed(0,10);
				end if;
				if game_active = '1' and update_tick = '1' then

					next_velocity := velocity;

					-- Mouse click = flap upward
					-- This checks if the mouse is held down, instead of trying to catch one tiny edge
					if left_click = '1' then
						next_velocity := to_signed(-10, 10);

					-- Gravity
					else
						if next_velocity < to_signed(12, 10) then
							next_velocity := next_velocity + to_signed(1, 10);
						end if;
					end if;

					-- Apply movement immediately using next_velocity
					new_pos := resize(signed('0' & std_logic_vector(child_y_internal)), 12)
							   + resize(next_velocity, 12);

					-- Ground
					if new_pos >= to_signed(471, 12) then
						child_y_internal <= to_unsigned(471, 10);
						velocity   <= to_signed(0, 10);

					-- Ceiling
					elsif new_pos <= to_signed(8, 12) then
						child_y_internal <= to_unsigned(8, 10);
						velocity   <= to_signed(0, 10);

					-- Normal movement
					else
						child_y_internal <= unsigned(new_pos(9 downto 0));
						velocity   <= next_velocity;
					end if;

				end if;

			end if;
		end process Move_Child;
			
		Arm_Place: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					arm_x1_internal <= to_unsigned(200,10);
					arm_x2_internal <= to_unsigned(400,10);
					arm_x3_internal <= to_unsigned(600,10);
					arm_gap1_internal <= to_unsigned(240,10);
					arm_gap2_internal <= to_unsigned(240,10);
					arm_gap3_internal <= to_unsigned(240,10);
				end if;
				
				if game_active = '1' and update_tick = '1' then

					if arm_x1_internal = 0 then
						-- recycle to right edge with new gap
						arm_x1_internal <= to_unsigned(640,10);
						arm_gap1_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(7 downto 0));
					else
						-- move left by 1
						arm_x1_internal <= arm_x1_internal - 1;
					end if;

					if arm_x2_internal = 0 then
						-- recycle to right edge with new gap
						arm_x2_internal <= to_unsigned(640,10);
						arm_gap2_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(7 downto 0));					
					else
						-- move left by 1
						arm_x2_internal <= arm_x2_internal - 1;
					end if;
					
					if arm_x3_internal = 0 then
						-- recycle to right edge with new gap
						arm_x3_internal <= to_unsigned(640,10);
						arm_gap3_internal <= to_unsigned(100,10) + unsigned("00" & lfsr_value(7 downto 0));
					else
						-- move left by 1
						arm_x3_internal <= arm_x3_internal - 1;
					end if;
				end if;
			end if;
		end process Arm_Place;
		
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
				else
				
					if game_active = '1' then
						if cooldown > 0 then
							cooldown <= cooldown - 1;
					
						elsif collision = '1' then
							arm_x1_internal <= to_unsigned(200, 10);
							arm_x2_internal <= to_unsigned(400, 10);
							arm_x3_internal <= to_unsigned(600, 10);
							arm_gap1_internal <= to_unsigned(240, 10);
							arm_gap2_internal <= to_unsigned(240, 10);
							arm_gap3_internal <= to_unsigned(240, 10);
							cooldown <= to_unsigned(3000000, 22);
							child_y_internal <= to_unsigned(240, 10); 
							velocity <= to_signed(0, 10);
							if lives_internal = 1 then
								lives_zero_internal <= '1';
							end if;
							lives_internal <= lives_internal - 1;
							
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
						if arm_x1_internal = 100 then
							score_internal <= score_internal + 1;
						end if;
						
						if arm_x2_internal = 100 then
							score_internal <= score_internal + 1;
						end if;
						
						if arm_x3_internal = 100 then
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
	-- Output assignments
    lives_zero  <= lives_zero_internal; 
    level       <= std_logic_vector(level_internal);
    lives       <= std_logic_vector(lives_internal);
    child_y     <= std_logic_vector(child_y_internal);
    arm_x1      <= std_logic_vector(arm_x1_internal);
    arm_x2      <= std_logic_vector(arm_x2_internal);
    arm_x3      <= std_logic_vector(arm_x3_internal);
    arm_gap1    <= std_logic_vector(arm_gap1_internal);
    arm_gap2    <= std_logic_vector(arm_gap2_internal);
    arm_gap3    <= std_logic_vector(arm_gap3_internal);
    score       <= std_logic_vector(score_internal);

end architecture logic;
			