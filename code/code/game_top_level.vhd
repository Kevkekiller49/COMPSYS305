library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_top_level is
    port(
        CLOCK_50         : in    std_logic;
        KEY              : in    std_logic_vector(3 downto 0);
        SW               : in    std_logic_vector(9 downto 0);
        PS2_CLK, PS2_DAT : inout std_logic;
        VGA_HS, VGA_VS   : out   std_logic;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
        LEDR             : out   std_logic_vector(9 downto 0)
    );
end entity game_top_level;

architecture wiring of game_top_level is

    -- Clocks and VGA sync
    signal clk_25             : std_logic;
    signal vert_sync_internal : std_logic;
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);

    -- VGA output signals from renderer
    signal red_out_internal, green_out_internal, blue_out_internal : std_logic;
    signal renderer_r, renderer_g, renderer_b : std_logic;
	

    -- Mouse inputs
    signal mouse_x, mouse_y        : std_logic_vector(9 downto 0);
    signal left_click, right_click : std_logic;

    -- Game logic outputs
    signal sprite_y, pipe_x1, pipe_x2, pipe_x3       : std_logic_vector(9 downto 0);
    signal pipe_gap1, pipe_gap2, pipe_gap3           : std_logic_vector(9 downto 0);
    signal score, lfsr_value                      : std_logic_vector(9 downto 0);
    signal display_mode, level, lives             : std_logic_vector(1 downto 0);
    signal game_active, training_mode, lives_zero : std_logic;
	signal powerup_x, powerup_y : std_logic_vector(9 downto 0);
	signal powerup_type, shield_active : std_logic;

    -- Seven segment display digits
    signal score_tens, score_ones, level_disp, lives_disp : std_logic_vector(3 downto 0);

    -- Text overlay
    signal text_on : std_logic;

    -- Reset and button signals
    signal reset            : std_logic;
    signal internal_button_1 : std_logic;
    signal internal_button_2 : std_logic;
	signal pixel_row_d, pixel_col_d : std_logic_vector(9 downto 0);
	signal locked : std_logic;
	signal raw_reset : std_logic;
	signal btn1_prev, btn2_prev : std_logic;
	signal btn1_pulse, btn2_pulse : std_logic;

    -- Component declarations
    component VGA_SYNC is
        port(
            clock_25Mhz, red, green, blue                               : in  std_logic;
            red_out, green_out, blue_out, horiz_sync_out, vert_sync_out : out std_logic;
            pixel_row, pixel_column                                     : out std_logic_vector(9 downto 0)
        );
    end component;

    component MOUSE is
        port(
            clock_25Mhz, reset        : in    std_logic;
            mouse_data                : inout std_logic;
            mouse_clk                 : inout std_logic;
            left_button, right_button : out   std_logic;
            mouse_cursor_row          : out   std_logic_vector(9 downto 0);
            mouse_cursor_column       : out   std_logic_vector(9 downto 0)
        );
    end component;

    component BCD_to_SevenSeg is
        port(
            BCD_digit    : in  std_logic_vector(3 downto 0);
            SevenSeg_out : out std_logic_vector(6 downto 0)
        );
    end component;

    component text_display is
        port(
            clk          : in  std_logic;
            pixel_row    : in  std_logic_vector(9 downto 0);
            pixel_col    : in  std_logic_vector(9 downto 0);
            display_mode : in  std_logic_vector(1 downto 0);
            score        : in  std_logic_vector(9 downto 0);
            lives        : in  std_logic_vector(1 downto 0);
            level        : in  std_logic_vector(1 downto 0);
            text_on      : out std_logic
        );
    end component;

    component game_fsm is
        port(
            Clk, reset, start_button, pause_button,
            mode_switch, lives_zero : in  std_logic;
            game_active             : out std_logic;
            training_mode           : out std_logic;
            display_mode            : out std_logic_vector(1 downto 0)
        );
    end component;

    component game_logic is
        port(
            clk, reset, game_active, training_mode, left_click : in  std_logic;
            lfsr_value, mouse_y : in  std_logic_vector(9 downto 0);
            lives_zero          : out std_logic;
            level, lives        : out std_logic_vector(1 downto 0);
            sprite_y, pipe_x1, pipe_x2, pipe_x3,
            pipe_gap1, pipe_gap2, pipe_gap3, score : out std_logic_vector(9 downto 0);
			shield_active, powerup_type : out std_logic;
			powerup_x, powerup_y : out std_logic_vector(9 downto 0)
        );
    end component;

    component renderer is
        port(
            pixel_row, pixel_column      : in  std_logic_vector(9 downto 0);
            sprite_y                      : in  std_logic_vector(9 downto 0);
            pipe_x1, pipe_x2, pipe_x3      : in  std_logic_vector(9 downto 0);
            pipe_gap1, pipe_gap2, pipe_gap3 : in  std_logic_vector(9 downto 0);
			powerup_x, powerup_y : in std_logic_vector(9 downto 0);
			powerup_type, shield_active : in std_logic;
            clk, reset                   : in  std_logic;
            red, green, blue             : out std_logic
        );
    end component;

    component lfsr is
        port(
            clk, reset  : in  std_logic;
            lfsr_value  : out std_logic_vector(9 downto 0)
        );
    end component;
	
	component pll is
		port(
			refclk   : in  std_logic;
			rst      : in  std_logic;
			outclk_0 : out std_logic;
			locked   : out std_logic
		);
	end component;

begin
    -- Active-high reset from active-low KEY(0)
    raw_reset <= not KEY(0);              -- plain, for PLL
	reset     <= (not KEY(0)) and locked; -- gated, for everything else
	

    -- Active-high buttons from active-low keys
    internal_button_1 <= not KEY(1);  -- start
    internal_button_2 <= not KEY(2);  -- pause

    -- Drive VGA vertical sync from internal signal
    VGA_VS <= vert_sync_internal;
	VGA_R <= (others => red_out_internal);
	VGA_G <= (others => green_out_internal);
	VGA_B <= (others => blue_out_internal);

    -- lives_zero lights LED 0 as a hardware death indicator
    LEDR(0)           <= lives_zero;
    LEDR(9 downto 1)  <= (others => '0');

    -- Seven segment: score ones/tens, level, lives
    level_disp <= "00" & level;
    lives_disp <= "00" & lives;

    -- Unused displays off (active low segments = all 1s)
    HEX4 <= (others => '1');
    HEX5 <= (others => '1');
	
	
	
	btn1_pulse <= internal_button_1 and not btn1_prev; 
	btn2_pulse <= internal_button_2 and not btn2_prev;
	

		process(clk_25)
		begin
			if rising_edge(clk_25) then
				pixel_row_d    <= pixel_row;
				pixel_col_d <= pixel_column;
				btn1_prev <= internal_button_1;
				btn2_prev <= internal_button_2;
			end if;
		end process;

			-- Score BCD extraction
			process(score)
				variable tempval : integer range 0 to 999;
			begin
				tempval    := to_integer(unsigned(score));
				score_tens <= std_logic_vector(to_unsigned(tempval / 10, 4));
				score_ones <= std_logic_vector(to_unsigned(tempval mod 10, 4));
			end process;


    -- VGA sync controller (25MHz pixel clock)
    VGA_DRIVER : component VGA_SYNC
    port map(
        clock_25Mhz    => clk_25,
        red            => renderer_r or text_on,
        green          => renderer_g or text_on,
        blue           => renderer_b or text_on,
        red_out        => red_out_internal,
        green_out      => green_out_internal,
        blue_out       => blue_out_internal,
        horiz_sync_out => VGA_HS,
        vert_sync_out  => vert_sync_internal,
        pixel_row      => pixel_row,
        pixel_column   => pixel_column
    );

    -- PS/2 mouse controller
    MOUSE_MAP : component MOUSE
    port map(
        clock_25Mhz         => clk_25,
        reset               => SW(0),
        mouse_data          => PS2_DAT,
        mouse_clk           => PS2_CLK,
        left_button         => left_click,
        right_button        => right_click,
        mouse_cursor_row    => mouse_y,
        mouse_cursor_column => mouse_x
    );

    -- FSM: handles menu/game/pause/game-over states
    FSM_UNIT : component game_fsm
    port map(
        Clk           => clk_25,
        reset         => reset,
        start_button  => btn1_pulse ,
        pause_button  => internal_button_2,
        mode_switch   => SW(1),
        lives_zero    => lives_zero,
        game_active   => game_active,
        training_mode => training_mode,
        display_mode  => display_mode
    );

    -- Game logic: bird physics, pipes, collision, scoring
    LOGIC : component game_logic
    port map(
        clk           => clk_25,
        reset         => reset,
        game_active   => game_active,
        training_mode => training_mode,
        left_click    => left_click,
        lfsr_value    => lfsr_value,
        mouse_y       => mouse_y,
        lives_zero    => lives_zero,
        level         => level,
        lives         => lives,
        sprite_y       => sprite_y,
        pipe_x1        => pipe_x1,
        pipe_x2        => pipe_x2,
        pipe_x3        => pipe_x3,
        pipe_gap1      => pipe_gap1,
        pipe_gap2      => pipe_gap2,
        pipe_gap3      => pipe_gap3,
        score         => score,
		shield_active => shield_active,
		powerup_type  => powerup_type,
		powerup_x     => powerup_x,
		powerup_y     => powerup_y
    );

    -- Renderer: draws background, pipes, bird sprite
    RENDER_UNIT : component renderer
    port map(
        clk      => clk_25,
        reset    => reset,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        sprite_y      => sprite_y,
        pipe_x1       => pipe_x1,
        pipe_x2       => pipe_x2,
        pipe_x3       => pipe_x3,
        pipe_gap1     => pipe_gap1,
        pipe_gap2     => pipe_gap2,
        pipe_gap3     => pipe_gap3,
        red          => renderer_r,
        green        => renderer_g,
        blue         => renderer_b,
		powerup_x     => powerup_x,
		powerup_y     => powerup_y,
		powerup_type  => powerup_type,
		shield_active => shield_active
    );

    -- Text display: overlays menu/HUD/game-over text
	TEXT_UNIT : component text_display
    port map(
        clk          => clk_25,
        pixel_row    => pixel_row_d,
        pixel_col    => pixel_col_d,
        display_mode => display_mode,
        score        => score,
        lives        => lives,
        level        => level,
        text_on      => text_on
    );

    -- LFSR: pseudo-random number for pipe gap generation
    LFSR_UNIT : component lfsr
    port map(
        clk        => clk_25,
        reset      => reset,
        lfsr_value => lfsr_value
    );
	
	PLL_UNIT : component pll
		port map(
			refclk   => CLOCK_50,
			rst      => raw_reset,
			outclk_0 => clk_25,
			locked   => locked
		);

    -- Seven segment displays
    SEG_ONES : component BCD_to_SevenSeg
    port map(BCD_digit => score_ones, SevenSeg_out => HEX0);

    SEG_TENS : component BCD_to_SevenSeg
    port map(BCD_digit => score_tens, SevenSeg_out => HEX1);

    SEG_LEVEL : component BCD_to_SevenSeg
    port map(BCD_digit => level_disp, SevenSeg_out => HEX2);

    SEG_LIVES : component BCD_to_SevenSeg
    port map(BCD_digit => lives_disp, SevenSeg_out => HEX3);

end architecture wiring;