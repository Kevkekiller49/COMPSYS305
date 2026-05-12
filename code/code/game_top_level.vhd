-- =============================================================================
-- game_top_level.vhd
-- Top Level Design for Flappy Bird FPGA Game Console
-- COMPSYS 305 - University of Auckland
-- =============================================================================
-- This file is the top level of the design. It contains no logic of its own -
-- it simply wires all components together and connects them to the physical
-- pins of the DE0-CV board.
--
-- COMPONENTS INSTANTIATED:
--   VGA_SYNC    : Generates VGA timing signals and provides pixel coordinates
--   MOUSE       : Decodes PS/2 mouse serial data into X/Y cursor position
--   BOUNCY_BALL : Renders a bouncing ball on the VGA display (interim demo)
--
-- BOARD INTERFACES:
--   CLOCK_50    : 50MHz board clock (divided to 25MHz for VGA)
--   KEY[3:0]    : Push buttons (active low - '0' when pressed)
--   SW[9:0]     : Slide switches (SW(0) used as mouse reset)
--   PS2_CLK/DAT : Bidirectional PS/2 mouse interface
--   VGA_*       : VGA display output (4-bit colour per channel)
--   HEX[5:0]    : Six 7-segment displays (active low, driven off for now)
--   LEDR[9:0]   : LEDs mirror switch positions for demo
-- =============================================================================

library IEEE;
use IEEE.std_logic_1164.all;

entity game_top_level is
    port(
        -- Board clock input
        CLOCK_50 : in std_logic;

        -- Push buttons (active low: '0' = pressed, '1' = released)
        KEY : in std_logic_vector(3 downto 0);

        -- Slide switches
        SW : in std_logic_vector(9 downto 0);

        -- PS/2 mouse interface (bidirectional - mouse drives clock during data transfer)
        PS2_CLK, PS2_DAT : inout std_logic;

        -- VGA sync signals
        VGA_HS, VGA_VS : out std_logic;

        -- VGA colour outputs (4 bits per channel - board uses resistor DAC)
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);

        -- Six 7-segment displays (active low: '0' turns segment ON)
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);

        -- 10 red LEDs
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity game_top_level;

architecture wiring of game_top_level is

    -- =========================================================================
    -- INTERNAL SIGNALS
    -- =========================================================================

    -- 25MHz clock derived from 50MHz board clock (toggled every clock cycle)
    signal clk_25 : std_logic;

    -- Current pixel coordinates from VGA_SYNC (used by renderer to decide colour)
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);

    -- Mouse cursor position (10-bit to cover 640x480 screen)
    signal mouse_x, mouse_y : std_logic_vector(9 downto 0);

    -- Mouse button states
    signal left_click, right_click : std_logic;

    -- Active-high versions of push buttons (board buttons are active low)
    signal internal_button_0 : std_logic;  -- KEY(0) inverted
    signal internal_button_1 : std_logic;  -- KEY(1) inverted - ball control 1
    signal internal_button_2 : std_logic;  -- KEY(2) inverted - ball control 2

    -- 1-bit RGB pixel values from the renderer (BOUNCY_BALL)
    signal red_pixel, green_pixel, blue_pixel : std_logic;

    -- 1-bit RGB outputs from VGA_SYNC (includes video_on blanking signal)
    -- These are used to drive the 4-bit VGA colour outputs on the board
    signal red_out_internal, green_out_internal, blue_out_internal : std_logic;

    -- Internal vert_sync signal - needed because VGA_VS is an output port
    -- and VHDL does not allow reading output ports directly
    signal vert_sync_internal : std_logic;

    -- =========================================================================
    -- COMPONENT DECLARATIONS
    -- These describe the interfaces of the components we want to instantiate.
    -- They must match exactly the entity declarations in the component files.
    -- =========================================================================

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

    -- =========================================================================
    -- CLOCK DIVIDER
    -- The board provides 50MHz but VGA requires 25MHz.
    -- Toggling clk_25 on every 50MHz rising edge gives a 25MHz clock.
    -- =========================================================================
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            clk_25 <= not clk_25;
        end if;
    end process;

    -- =========================================================================
    -- CONCURRENT SIGNAL ASSIGNMENTS
    -- These happen continuously in hardware - not sequentially like software.
    -- =========================================================================

    -- Invert push buttons from active-low (board) to active-high (internal)
    internal_button_0 <= NOT KEY(0);
    internal_button_1 <= NOT KEY(1);
    internal_button_2 <= NOT KEY(2);

    -- Expand 1-bit colour signals to 4-bit VGA outputs.
    -- (others => x) fills all 4 bits with the same value.
    -- This uses the blanked output from VGA_SYNC which correctly turns off
    -- pixels during sync periods.
    VGA_R <= (others => red_out_internal);
    VGA_G <= (others => green_out_internal);
    VGA_B <= (others => blue_out_internal);

    -- Drive vert_sync to the output pin via the internal signal.
    -- We need an internal signal because VHDL cannot read output ports,
    -- and BOUNCY_BALL needs to read vert_sync for its timing.
    VGA_VS <= vert_sync_internal;

    -- Drive all seven segment displays off (active low, so '1' = segment off).
    -- These will be replaced by the seven segment controller component later.
    HEX0 <= (others => '1');
    HEX1 <= (others => '1');
    HEX2 <= (others => '1');
    HEX3 <= (others => '1');
    HEX4 <= (others => '1');
    HEX5 <= (others => '1');

    -- Mirror switch positions to LEDs for demo purposes.
    -- Flipping a switch will light the LED directly above it.
    LEDR(9 downto 0) <= SW(9 downto 0);

    -- =========================================================================
    -- COMPONENT INSTANTIATIONS
    -- Each component is wired up here using a port map.
    -- The format is: component_port => internal_signal
    -- =========================================================================

    -- VGA Synchronisation Controller
    -- Generates hsync/vsync timing signals and provides current pixel coordinates.
    -- Accepts 1-bit RGB from renderer, outputs blanked 1-bit RGB and sync signals.
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

    -- PS/2 Mouse Controller
    -- Decodes serial PS/2 data into X/Y cursor position and button states.
    -- SW(0) is used as a reset switch for the mouse controller.
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

    -- Bouncy Ball Renderer (interim demo)
    -- Draws a bouncing ball on the VGA display.
    -- pb1 and pb2 buttons change the ball behaviour.
    -- Uses vert_sync for frame timing to keep movement smooth.
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

end architecture wiring;
