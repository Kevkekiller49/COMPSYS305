LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;

ENTITY bouncy_ball IS
    PORT(
        pb1, pb2     : IN  std_logic;
        clk          : IN  std_logic;
        vert_sync    : IN  std_logic;
        left_click   : IN  std_logic;   -- mouse left click = flap
        paused       : IN  std_logic;   -- '1' = paused (from SW(9))
        pixel_row    : IN  std_logic_vector(9 DOWNTO 0);
        pixel_column : IN  std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic;
        ball_y_out   : OUT std_logic_vector(9 DOWNTO 0)
    );
END bouncy_ball;

architecture behavior of bouncy_ball is

SIGNAL ball_on     : std_logic;
SIGNAL size        : std_logic_vector(9 DOWNTO 0);
SIGNAL ball_x_pos  : std_logic_vector(9 DOWNTO 0);
SIGNAL ball_y_pos  : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240, 10);
SIGNAL velocity    : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(0, 10);
SIGNAL click_prev  : std_logic := '0';

BEGIN

size      <= CONV_STD_LOGIC_VECTOR(8, 10);
ball_x_pos <= CONV_STD_LOGIC_VECTOR(200, 10);

-- Draw ball when current pixel is inside the ball square
ball_on <= '1' when (
    ('0' & ball_x_pos <= '0' & pixel_column + size) and
    ('0' & pixel_column <= '0' & ball_x_pos + size) and
    ('0' & ball_y_pos <= pixel_row + size) and
    ('0' & pixel_row <= ball_y_pos + size))
    else '0';

-- Colours
Red   <= pb1;
Green <= (not pb2) and (not ball_on);
Blue  <= not ball_on;

ball_y_out <= ball_y_pos;

-- Flappy Bird physics
Move_Ball: process(vert_sync)
begin
    if (rising_edge(vert_sync)) then
        if (paused = '0') then

            -- Edge detect click: only flap on the moment of press
            click_prev <= left_click;

            if (left_click = '1' and click_prev = '0') then
                -- FLAP: kick upward (negative = up on screen)
                velocity <= CONV_STD_LOGIC_VECTOR(-12, 10);
            else
                -- GRAVITY: accelerate downward every frame
                velocity <= velocity + CONV_STD_LOGIC_VECTOR(1, 10);
            end if;

            -- Boundary checks then apply velocity
            if ('0' & ball_y_pos >= CONV_STD_LOGIC_VECTOR(471, 11)) then
                -- Hit ground
                ball_y_pos <= CONV_STD_LOGIC_VECTOR(471, 10);
                velocity   <= CONV_STD_LOGIC_VECTOR(0, 10);
            elsif (ball_y_pos <= size) then
                -- Hit ceiling
                ball_y_pos <= size;
                velocity   <= CONV_STD_LOGIC_VECTOR(0, 10);
            else
                -- Normal movement
                ball_y_pos <= ball_y_pos + velocity;
            end if;

        end if; -- paused
    end if; -- rising_edge
end process Move_Ball;

END behavior;
