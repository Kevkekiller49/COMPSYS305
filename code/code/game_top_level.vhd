library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_top_level is
    port(
        CLOCK_50 : in std_logic;
        KEY      : in std_logic_vector(3 downto 0);
        SW       : in std_logic_vector(9 downto 0);
        PS2_CLK, PS2_DAT : inout std_logic;
        VGA_HS, VGA_VS   : out std_logic;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity game_top_level;

architecture wiring of game_top_level is

    signal clk_25             : std_logic;
    signal vert_sync_internal : std_logic;
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
    signal red_pixel, green_pixel, blue_pixel : std_logic;
    signal red_out_internal, green_out_internal, blue_out_internal : std_logic;
    signal mouse_x, mouse_y       : std_logic_vector(9 downto 0);
    signal left_click, right_click : std_logic;
    signal internal_button_0 : std_logic;
    signal internal_button_1 : std_logic;
    signal internal_button_2 : std_logic;
    signal ball_y_pos_display : std_logic_vector(9 downto 0);
    signal hundreds, tens, ones : std_logic_vector(3 downto 0);
    signal text_pixel : std_logic;

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

    component BOUNCY_BALL is
        port(
            clk, vert_sync   : in  std_logic;
            pb1, pb2         : in  std_logic;
            left_click       : in  std_logic;
            paused           : in  std_logic;
            pixel_row        : in  std_logic_vector(9 downto 0);
            pixel_column     : in  std_logic_vector(9 downto 0);
            red, green, blue : out std_logic;
            ball_y_out       : out std_logic_vector(9 downto 0)
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
            clock        : in  std_logic;
            pixel_row    : in  std_logic_vector(9 downto 0);
            pixel_column : in  std_logic_vector(9 downto 0);
            paused       : in  std_logic;
            text_on      : out std_logic
        );
    end component;

begin

    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            clk_25 <= not clk_25;
        end if;
    end process;

    internal_button_0 <= not KEY(0);
    internal_button_1 <= not KEY(1);
    internal_button_2 <= not KEY(2);

    -- OR in text_pixel so PAUSED text renders white over everything
    VGA_R <= (others => (red_out_internal   or text_pixel));
    VGA_G <= (others => (green_out_internal or text_pixel));
    VGA_B <= (others => (blue_out_internal  or text_pixel));
    VGA_VS <= vert_sync_internal;

    LEDR <= SW;

    -- Ball Y position -> decimal digits for 7-seg
    process(ball_y_pos_display)
        variable tempval : integer range 0 to 999;
    begin
        tempval  := to_integer(unsigned(ball_y_pos_display));
        hundreds <= std_logic_vector(to_unsigned(tempval / 100, 4));
        tens     <= std_logic_vector(to_unsigned((tempval mod 100) / 10, 4));
        ones     <= std_logic_vector(to_unsigned(tempval mod 10, 4));
    end process;

    VGA_DRIVER : component VGA_SYNC
    port map(
        clock_25Mhz    => clk_25,
        red            => red_pixel,
        green          => green_pixel,
        blue           => blue_pixel,
        red_out        => red_out_internal,
        green_out      => green_out_internal,
        blue_out       => blue_out_internal,
        horiz_sync_out => VGA_HS,
        vert_sync_out  => vert_sync_internal,
        pixel_row      => pixel_row,
        pixel_column   => pixel_column
    );

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

    BALL_UNIT : component BOUNCY_BALL
    port map(
        clk          => clk_25,
        vert_sync    => vert_sync_internal,
        pb1          => internal_button_1,
        pb2          => internal_button_2,
        left_click   => left_click,
        paused       => SW(9),
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        red          => red_pixel,
        green        => green_pixel,
        blue         => blue_pixel,
        ball_y_out   => ball_y_pos_display
    );

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

    TEXT_UNIT : component text_display
    port map(
        clock        => clk_25,
        pixel_row    => pixel_row,
        pixel_column => pixel_column,
        paused       => SW(9),
        text_on      => text_pixel
    );

    HEX3 <= (others => '1');
    HEX4 <= (others => '1');
    HEX5 <= (others => '1');

end architecture wiring;
