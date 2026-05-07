library IEEE;
use IEEE.std_logic_1164.all;

entity game_top_level is
	port(CLOCK_50 : in std_logic;
		KEY : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(9 downto 0);
		PS2_CLK, PS2_DAT : inout std_logic;
		VGA_HS, VGA_VS : out std_logic;
		VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : OUT STD_LOGIC_VECTOR(6 downto 0);
		LEDR : out std_logic_vector(9 downto 0));
end entity game_top_level;

architecture wiring of game_top_level is
	signal clk_25 : std_logic;
	signal pixel_row, pixel_column, mouse_x, mouse_y : std_logic_vector(9 downto 0);
	signal red_pixel, green_pixel, blue_pixel, left_click, right_click : std_logic;
	
	component VGA_SYNC is
		port(
			clock_25Mhz, red, green, blue		: in std_logic;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out	: out std_logic;
			pixel_row, pixel_column: out std_logic_vector(9 downto 0));
	end component;
	
	component MOUSE is
	   port( clock_25Mhz, reset 		: in std_logic;
			 mouse_data					: inout std_logic;
			 mouse_clk 					: inout std_logic;
			 left_button, right_button	: out std_logic;
			 mouse_cursor_row 			: out std_logic_vector(9 downto 0); 
			 mouse_cursor_column 		: out std_logic_vector(9 downto 0));       	
	end component;
	
	component BOUNCY_BALL is
		port(
			clk, vert_sync	: in std_logic;
			pb1, pb2	: in std_logic;
			pixel_row	: in std_logic_vector(9 downto 0);
			pixel_column	: in std_logic_vector(9 downto 0);
			red, green, blue: out std_logic
		);
	end component;
	
	begin
		process(CLOCK_50)
		begin
			if rising_edge(CLOCK_50) then
				clk_25 <= NOT clk_25;
			end if;
		end process;
		
		internal_button_0 <= NOT KEY(0);
		VGA_R <= (others => red_pixel);   -- This sends the 1-bit to all 4 pins
		VGA_G <= (others => green_pixel);
		VGA_B <= (others => blue_pixel);
		
		VGA_DRIVER : component VGA_SYNC
		port map(
			clock_25m => clk_25,
			red => red_pixel, -- Internal 1-bit signal
			blue => blue_pixel, -- Internal 1-bit signal
			green => green_pixel, -- Internal 1-bit signal
			red_out => open,  -- We use our own 4-bit mapping above
			green_out => open, 
			blue_out => open,
			horiz_sync_out => VGA_HS,
			vert_sync_out => VGA_VS,
			pixel_row => pixel_row,
			pixel_column => pixel_column
			);
			
		MOUSE_MAP : component MOUSE
		port map(
			clock_25m => clk_25,
			reset => SW(0), -- Using a switch for reset
			mouse_data => PS2_DAT, -- Physical INOUT pin from entity
			mouse_clk => PS2_CLK, -- Physical INOUT pin from entity
			left_button => left_click, 
			right_button => right_click, 
			mouse_cursor_row => mouse_y,
			mouse_cursor_column => mouse_x,
			);
			
		BALL_UNIT : component BOUNCY_BALL
		port map(red_in
			clk => clk_25,
			vert_sync       => VGA_VS, -- Uses sync from VGA_SYNC for timing
			pb1             => NOT KEY(1), -- Ball control 1 (Active High internally)
			pb2             => NOT KEY(2), -- Ball control 2 (Active High internally)
			pixel_row        => pixel_row, 
			pixel_column      => pixel_column, 
			red       => red_pixel,
			green => green_pixel,
			blue  => blue_pixel,
			);
			
		LEDR(9 downto 0) <= SW(9 downto 0); -- Lights up the LED above every flipped switch
		LEDR(3 downto 0) <= NOT KEY(3 downto 0); -- The LEDs will light up when you press the buttons
end architecture wiring;
		