LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

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
SIGNAL ball_y_pos : unsigned(9 DOWNTO 0) := to_unsigned(240, 10);
SIGNAL ball_x_pos : unsigned(9 DOWNTO 0) := to_unsigned(200, 10);
SIGNAL size       : unsigned(9 DOWNTO 0) := to_unsigned(8,   10);
SIGNAL velocity   : signed(9 DOWNTO 0)   := to_signed(0,     10);
SIGNAL click_prev : std_logic := '0';

BEGIN

-- Draw ball when current pixel is inside the ball square
    ball_on <= '1' WHEN (
        unsigned(pixel_column) >= ball_x_pos - size AND
        unsigned(pixel_column) <= ball_x_pos + size AND
        unsigned(pixel_row)    >= ball_y_pos - size AND
        unsigned(pixel_row)    <= ball_y_pos + size
    ) ELSE '0';

-- Colours
Red   <= pb1;
Green <= (not pb2) and (not ball_on);
Blue  <= not ball_on;

ball_y_out <= std_logic_vector(ball_y_pos);

-- Flappy Bird physics
Move_Ball: process(vert_sync)
	variable new_pos : signed(10 DOWNTO 0);
begin
    if (rising_edge(vert_sync)) then
        if (paused = '0') then
		click_prev <= left_click;
            	if (left_click = '1' AND click_prev = '0') then
                	velocity <= to_signed(-10, 10);
            	else
                	if velocity < to_signed(12, 10) then
				velocity <= velocity + to_signed(1, 10);
            		end if;
		end if;

		new_pos := resize(signed(ball_y_pos), 11) + resize(velocity, 11);

            	-- Boundary checks
            	if new_pos >= to_signed(471, 11) then
                	-- Hit ground: stop at bottom
                	ball_y_pos <= to_unsigned(471, 10);
                	velocity   <= to_signed(0, 10);
            	elsif new_pos <= to_signed(8, 11) then
                	-- Hit ceiling: stop at top
                	ball_y_pos <= to_unsigned(8, 10);
                	velocity   <= to_signed(0, 10);
            	else
                	-- Normal: apply velocity
                	ball_y_pos <= unsigned(new_pos(9 downto 0));
            	end if;

        end if; -- paused
    end if; -- rising_edge
end process Move_Ball;

END behavior;
