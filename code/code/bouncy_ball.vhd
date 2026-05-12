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
SIGNAL click_prev : std_logic := '0';

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
    if rising_edge(vert_sync) then
        if (paused = '1') then
            -- Do nothing, effectively freezing the ball
        else
            -- 1. Edge Detection
            click_prev <= left_click;

            -- 2. Jump Logic
            -- If left click is pressed and was NOT pressed last cycle
            if (left_click = '1' and click_prev = '0') then
                velocity <= CONV_STD_LOGIC_VECTOR(-12, 10); 
            else
                -- 3. Gravity
                velocity <= velocity + 1; 
            end if;

            -- 4. Position Update & Floor Collision
            -- 440 is the bottom of the screen (minus ball size)
            if (ball_y_pos >= 440 and velocity > 0) then
                ball_y_pos <= CONV_STD_LOGIC_VECTOR(440, 10);
                velocity <= (others => '0'); 
            else
                ball_y_pos <= ball_y_pos + velocity;
            end if;
        end if;
    end if;
end process Move_Ball;
