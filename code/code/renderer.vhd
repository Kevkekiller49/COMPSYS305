library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.sprite_pkg.all;

entity renderer is
    port(
        pixel_row, pixel_column : in std_logic_vector(9 downto 0);
        child_y                 : in std_logic_vector(9 downto 0);
        arm_x1, arm_x2, arm_x3 : in std_logic_vector(9 downto 0);
        arm_gap1, arm_gap2, arm_gap3 : in std_logic_vector(9 downto 0);
        clk, reset                   : in std_logic;  -- animation frame 0/1
        red, green, blue        : out std_logic
    );
end entity renderer;

architecture rtl of renderer is
    signal frame         : std_logic;
    signal anim_counter  : unsigned(23 downto 0);
    signal row, col      : unsigned(9 downto 0);
    signal cy            : unsigned(9 downto 0);
begin
	row <= unsigned(pixel_row);
	col <= unsigned(pixel_column);
	cy  <= unsigned(child_y);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
            anim_counter <= (others => '0');
            frame <= '0';
			elsif anim_counter >= 12500000 then
				anim_counter <= (others => '0');
				frame <= not frame;
			else
				anim_counter <= anim_counter + 1;
			end if;
		end if;
	end process;
	
	process(row, col, cy, arm_x1, arm_x2, arm_x3, arm_gap1, arm_gap2, arm_gap3, frame)
    variable sp : std_logic_vector(2 downto 0);
	begin
		-- default: blue background
		red   <= '0';
		green <= '0';
		blue  <= '1';
			-- check bird sprite first (col 100-115, row cy to cy+15)
			if col >= 100 and col <= 115 and row >= cy and row <= cy+15 then
				sp := sprite_rom(to_integer(unsigned'("0" & frame)))(
						  to_integer(row - cy))(
						  to_integer(col - to_unsigned(100, 10)));
				if sp /= "011" then
					red   <= sp(2);
					green <= sp(1);
					blue  <= sp(0);
				end if;

			-- pipes next
			elsif col + 20 >= unsigned(arm_x1) and col <= unsigned(arm_x1) and
				 (row < unsigned(arm_gap1) - 40 or row > unsigned(arm_gap1) + 40) then
				red <= '1'; green <= '1'; blue <= '1';
			elsif col + 20 >= unsigned(arm_x2) and col <= unsigned(arm_x2) and
				 (row < unsigned(arm_gap2) - 40 or row > unsigned(arm_gap2) + 40) then
				red <= '1'; green <= '1'; blue <= '1';
			elsif col + 20 >= unsigned(arm_x3) and col <= unsigned(arm_x3) and
				 (row < unsigned(arm_gap3) - 40 or row > unsigned(arm_gap3) + 40) then
				red <= '1'; green <= '1'; blue <= '1';
		end if;
	end process;
end architecture;
	
	
	
	