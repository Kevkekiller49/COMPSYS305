library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.sprite_pkg.all;

entity renderer is
    port(
        pixel_row, pixel_column : in std_logic_vector(9 downto 0);
        sprite_y                : in std_logic_vector(9 downto 0);
        pipe_x1, pipe_x2, pipe_x3 : in std_logic_vector(9 downto 0);
        pipe_gap1, pipe_gap2, pipe_gap3 : in std_logic_vector(9 downto 0);
        powerup_x, powerup_y : in std_logic_vector(9 downto 0);
        clk, reset            : in std_logic;
        red, green, blue      : out std_logic;
        powerup_type          : in std_logic;
        shield_active         : in std_logic
    );
end entity renderer;

architecture rtl of renderer is
    constant PIPE_WIDTH : integer := 24;
    constant GAP_HALF   : integer := 55;

    signal frame        : std_logic := '0';
    signal anim_counter : unsigned(23 downto 0) := (others => '0');

    function in_pipe(c, r, px, gap : integer) return boolean is
    begin
        return (c >= px - PIPE_WIDTH and c <= px and
                (r < gap - GAP_HALF or r > gap + GAP_HALF));
    end function;

begin

    -- Sprite animation frame selector
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                anim_counter <= (others => '0');
                frame <= '0';
            elsif anim_counter >= to_unsigned(12500000, anim_counter'length) then
                anim_counter <= (others => '0');
                frame <= not frame;
            else
                anim_counter <= anim_counter + 1;
            end if;
        end if;
    end process;

    process(pixel_row, pixel_column, sprite_y,
            pipe_x1, pipe_x2, pipe_x3, pipe_gap1, pipe_gap2, pipe_gap3,
            frame, powerup_x, powerup_y, powerup_type, shield_active)
        variable sp : std_logic_vector(2 downto 0);
        variable r, c, sy : integer;
        variable px1, px2, px3 : integer;
        variable gap1, gap2, gap3 : integer;
        variable pwrx, pwry : integer;
        variable dx, dy : integer;
        variable sx, sr : integer;
    begin
        r    := to_integer(unsigned(pixel_row));
        c    := to_integer(unsigned(pixel_column));
        sy   := to_integer(unsigned(sprite_y));

        px1  := to_integer(unsigned(pipe_x1));
        px2  := to_integer(unsigned(pipe_x2));
        px3  := to_integer(unsigned(pipe_x3));

        gap1 := to_integer(unsigned(pipe_gap1));
        gap2 := to_integer(unsigned(pipe_gap2));
        gap3 := to_integer(unsigned(pipe_gap3));

        pwrx := to_integer(unsigned(powerup_x));
        pwry := to_integer(unsigned(powerup_y));

        dx := c - pwrx;
        dy := r - pwry;

        -- default: sky/background
        red   <= '0';
        green <= '0';
        blue  <= '1';

        -- Bird/shark sprite: 32 x 32 screen pixels 
        if c >= 100 and c <= 131 and r >= sy and r <= sy + 31 then
            sx := (c - 100) / 2;
            sr := (r - sy) / 2;

            sp := sprite_rom(to_integer(unsigned'("0" & frame)))(sr)(sx);

            if sp /= "010" then  -- green is transparent in sprite ROM
                red   <= sp(2);
                green <= sp(1);
                blue  <= sp(0);
            end if;

        -- Pipes
        elsif in_pipe(c, r, px1, gap1) or
              in_pipe(c, r, px2, gap2) or
              in_pipe(c, r, px3, gap3) then

            -- white/blue striped pipes
            if ((r + c) mod 10) < 5 then
                red <= '1'; green <= '1'; blue <= '1';
            else
                red <= '0'; green <= '0'; blue <= '1';
            end if;

        -- Power up: shield shape
        elsif powerup_type = '0' and dx >= -9 and dx <= 9 and dy >= -10 and dy <= 10 then
            -- shield body: wide top, tapered bottom
            if (dy <= -4 and dx >= -8 and dx <= 8) or
               (dy > -4 and dy <= 4 and dx >= -7 and dx <= 7) or
               (dy > 4 and dy <= 8 and dx >= -(10 - dy) and dx <= (10 - dy)) or
               (dy > 8 and dx >= -1 and dx <= 1) then

                -- outline
                if dy = -10 or dx = -9 or dx = 9 or
                   (dy > 4 and (dx = -(10 - dy) or dx = (10 - dy))) then
                    red <= '1'; green <= '1'; blue <= '1';
                else
                    red <= '0'; green <= '1'; blue <= '1';
                end if;
            end if;

        -- Power up: heart shape
        elsif powerup_type = '1' and dx >= -9 and dx <= 9 and dy >= -8 and dy <= 9 then
            if (dy >= -8 and dy <= -5 and
                    ((dx >= -7 and dx <= -2) or (dx >= 2 and dx <= 7))) or
               (dy >= -4 and dy <= 0 and dx >= -9 and dx <= 9) or
               (dy >= 1 and dy <= 4 and dx >= -7 and dx <= 7) or
               (dy >= 5 and dy <= 7 and dx >= -4 and dx <= 4) or
               (dy >= 8 and dy <= 9 and dx >= -1 and dx <= 1) then
                red <= '1'; green <= '0'; blue <= '0';
            end if;

        -- Active shield outline around player
        elsif shield_active = '1' and
              c >= 96 and c <= 135 and r >= sy - 4 and r <= sy + 35 and
              (c = 96 or c = 135 or r = sy - 4 or r = sy + 35) then
            red <= '1'; green <= '0'; blue <= '1';
        end if;
    end process;

end architecture rtl;
