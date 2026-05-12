library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_top_level is
    port(
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        SW : in std_logic_vector(9 downto 0);
        PS2_CLK, PS2_DAT : inout std_logic;
        VGA_HS, VGA_VS : out std_logic;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity game_top_level;

architecture wiring of game_top_level is
<<<<<<< HEAD
    signal clk_25 : std_logic;
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
    signal mouse_x, mouse_y : std_logic_vector(9 downto 0);
    signal left_click, right_click : std_logic;
    signal internal_button_0 : std_logic;  -- KEY(0) inverted
    signal internal_button_1 : std_logic;  -- KEY(1) inverted - ball control 1
    signal internal_button_2 : std_logic;  -- KEY(2) inverted - ball control 2
    signal red_pixel, green_pixel, blue_pixel : std_logic;
    signal red_out_internal, green_out_internal, blue_out_internal : std_logic;
    signal vert_sync_internal : std_logic;
    component VGA_SYNC is
        port(
            clock_25Mhz, red, green, blue                           : in  std_logic;
            red_out, green_out, blue_out, horiz_sync_out, vert_sync_out : out std_logic;
            pixel_row, pixel_column                                 : out std_logic_vector(9 downto 0)
        );
    end component;

    component MOUSE is
        port(
            clock_25Mhz, reset  : in    std_logic;
            mouse_data          : inout std_logic;
            mouse_clk           : inout std_logic;
            left_button, right_button : out std_logic;
            mouse_cursor_row    : out std_logic_vector(9 downto 0);
            mouse_cursor_column : out std_logic_vector(9 downto 0)
        );
    end component;

    component BOUNCY_BALL is
        port(
            clk, vert_sync  : in  std_logic;
            pb1, pb2        : in  std_logic;
            pixel_row       : in  std_logic_vector(9 downto 0);
            pixel_column    : in  std_logic_vector(9 downto 0);
            red, green, blue : out std_logic
        );
    end component;

begin
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            clk_25 <= not clk_25;
        end if;
    end process;
    internal_button_0 <= NOT KEY(0);
    internal_button_1 <= NOT KEY(1);
    internal_button_2 <= NOT KEY(2);
    -- pixels during sync periods.
    VGA_R <= (others => red_out_internal);
    VGA_G <= (others => green_out_internal);
    VGA_B <= (others => blue_out_internal);
    VGA_VS <= vert_sync_internal;
    HEX0 <= (others => '1');
    HEX1 <= (others => '1');
    HEX2 <= (others => '1');
    HEX3 <= (others => '1');
    HEX4 <= (others => '1');
    HEX5 <= (others => '1');

    LEDR(9 downto 0) <= SW(9 downto 0);
    VGA_DRIVER : component VGA_SYNC
    port map(
        clock_25Mhz  => clk_25,
        red          => red_pixel,           -- 1-bit colour from renderer
        green        => green_pixel,
        blue         => blue_pixel,
        red_out      => red_out_internal,    -- Blanked output (video_on applied)
        green_out    => green_out_internal,
        blue_out     => blue_out_internal,
        horiz_sync_out => VGA_HS,            -- Direct to board VGA connector
        vert_sync_out  => vert_sync_internal, -- Internal signal (also drives VGA_VS)
        pixel_row    => pixel_row,           -- Current pixel row for renderer
        pixel_column => pixel_column         -- Current pixel column for renderer
    );

    MOUSE_MAP : component MOUSE
    port map(
        clock_25Mhz => clk_25,
        reset       => SW(0),       -- Slide switch 0 resets the mouse controller
        mouse_data  => PS2_DAT,     -- Bidirectional PS/2 data line
        mouse_clk   => PS2_CLK,     -- Bidirectional PS/2 clock line
        left_button  => left_click,
        right_button => right_click,
        mouse_cursor_row    => mouse_y,  -- Current Y position (0-479)
        mouse_cursor_column => mouse_x   -- Current X position (0-639)
    );

    BALL_UNIT : component BOUNCY_BALL
    port map(
        clk         => clk_25,
        vert_sync   => vert_sync_internal,  -- Frame sync for smooth movement
        pb1         => internal_button_1,   -- KEY(1) - ball control
        pb2         => internal_button_2,   -- KEY(2) - ball control
        pixel_row   => pixel_row,           -- From VGA_SYNC
        pixel_column => pixel_column,       -- From VGA_SYNC
        red         => red_pixel,           -- 1-bit colour to VGA_SYNC
        green       => green_pixel,
        blue        => blue_pixel
    );

=======
	signal clk_25 : std_logic;
	signal pixel_row, pixel_column, mouse_x, mouse_y : std_logic_vector(9 downto 0);
	signal red_pixel, green_pixel, blue_pixel, left_click, right_click, internal_button_0, internal_button_1, internal_button_2, red_out_internal, green_out_internal, blue_out_internal, vert_sync_internal : std_logic;
	signal ball_y_pos_display : std_logic_vector(9 downto 0);
	signal hundreds, tens, ones : std_logic_vector(3 downto 0);	
	signal vert_sync_gated : std_logic; 
		

	component VGA_SYNC is
		port(
			clock_25Mhz, red, green, blue		: in std_logic;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out	: out std_logic;
			pixel_row, pixel_column: out std_logic_vector(9 downto 0));
	end component;

	component BCD_to_SevenSeg is
		port( BCD_digit : in std_logic_vector(3 downto 0);
		      SevenSeg_out : out std_logic_vector(6 downto 0));
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
			red, green, blue: out std_logic;
			ball_y_out : out std_logic_vector(9 downto 0)
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
		internal_button_1 <= NOT KEY(1);
		internal_button_2 <= NOT KEY(2);	
		VGA_R <= (others => red_out_internal);   -- This sends the 1-bit to all 4 pins
		VGA_G <= (others => green_out_internal);
		VGA_B <= (others => blue_out_internal);
		VGA_VS <= vert_sync_internal;
		vert_sync_gated <= vert_sync_internal AND (NOT SW(9)); -- when dip switch 9 is high = pause
		process(ball_y_pos_display)
			variable tempval : integer range 0 to 999;
		begin
			tempval := to_integer(unsigned(ball_y_pos_display));
			hundreds <= std_logic_vector(to_unsigned(tempval / 100, 4));
			tens <= std_logic_vector(to_unsigned((tempval mod 100) / 10, 4));
			ones <= std_logic_vector(to_unsigned(tempval mod 10, 4));
		end process;

		SEG_ONES : component BCD_to_SevenSeg
		port map(
    			BCD_digit    => ones,
    			SevenSeg_out => HEX0
			);

		SEG_TENS : component BCD_to_SevenSeg
		port map(
    			BCD_digit    => tens,
    			SevenSeg_out => HEX1
		);

		SEG_HUNDREDS : component BCD_to_SevenSeg
		port map(
    			BCD_digit    => hundreds,
   		 	SevenSeg_out => HEX2
		);
		
		HEX3 <= (others => '1');
		HEX4 <= (others => '1');
		HEX5 <= (others => '1');

		VGA_DRIVER : component VGA_SYNC
		
		port map(
			clock_25Mhz => clk_25,
			red => red_pixel, -- Internal 1-bit signal
			blue => blue_pixel, -- Internal 1-bit signal
			green => green_pixel, -- Internal 1-bit signal
			red_out => red_out_internal,  -- We use our own 4-bit mapping above
			green_out => green_out_internal, 
			blue_out => blue_out_internal,
			horiz_sync_out => VGA_HS,
			vert_sync_out => vert_sync_internal,
			pixel_row => pixel_row,
			pixel_column => pixel_column
			);
			
		MOUSE_MAP : component MOUSE
		port map(
			clock_25Mhz => clk_25,
			reset => SW(0), -- Using a switch for reset
			mouse_data => PS2_DAT, -- Physical INOUT pin from entity
			mouse_clk => PS2_CLK, -- Physical INOUT pin from entity
			left_button => left_click, 
			right_button => right_click, 
			mouse_cursor_row => mouse_y,
			mouse_cursor_column => mouse_x
			);
			
		BALL_UNIT : component BOUNCY_BALL
		port map(
			clk => clk_25,
			vert_sync       => vert_sync_gated, 
			pb1             => internal_button_1, -- Ball control 1 (Active High internally)
			pb2             => internal_button_2, -- Ball control 2 (Active High internally)
			pixel_row        => pixel_row, 
			pixel_column      => pixel_column, 
			red       => red_pixel,
			green => green_pixel,
			blue  => blue_pixel,
			ball_y_out => ball_y_pos_display
			);
			
		LEDR(9 downto 0) <= SW(9 downto 0); -- Lights up the LED above every flipped switch
>>>>>>> 3aff10ecfdbc33e451e59a9941b35475d6d0c0de
end architecture wiring;
