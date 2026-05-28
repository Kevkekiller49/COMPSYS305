library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_logic is
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
end entity game_logic;

architecture rtl of game_logic is

    constant BIRD_X      : integer := 100;
    constant BIRD_W      : integer := 32;
    constant BIRD_H      : integer := 32;
    constant PIPE_W      : integer := 24;
    constant GAP_HALF    : integer := 55;
    constant FRAME_LIMIT : unsigned(18 downto 0) := to_unsigned(416666, 19); -- about 60 Hz at 25 MHz

    signal frame_count : unsigned(18 downto 0) := (others => '0');

    signal bird_y_i : integer range 0 to 448 := 224;
    signal velocity : integer range -12 to 12 := 0;

    signal pipe1_x_i : integer range 0 to 1023 := 680;
    signal pipe2_x_i : integer range 0 to 1023 := 900;
    signal pipe3_x_i : integer range 0 to 1023 := 1020;

    signal gap1_i : integer range 80 to 400 := 160;
    signal gap2_i : integer range 80 to 400 := 260;
    signal gap3_i : integer range 80 to 400 := 340;

    signal score_i : integer range 0 to 999 := 0;
    signal lives_i : integer range 0 to 3 := 3;
    signal level_i : integer range 0 to 3 := 1;

    signal scored1, scored2, scored3 : std_logic := '0';
    signal collision_cooldown : integer range 0 to 60 := 0;

    signal pwr_x_i : integer range 0 to 1023 := 850;
    signal pwr_y_i : integer range 0 to 479 := 220;
    signal pwr_type_i : std_logic := '0'; -- 0 = shield, 1 = heart

    signal shield_timer : integer range 0 to 300 := 0;

    function random_gap(rand : std_logic_vector(9 downto 0); offset : integer) return integer is
        variable val : integer;
    begin
        -- returns 90 to 369 so the pipe opening is always on screen
        val := (to_integer(unsigned(rand)) + offset) mod 280;
        return 90 + val;
    end function;

    function pipe_collision(px, gap, by : integer) return boolean is
    begin
        return ((BIRD_X + BIRD_W) >= (px - PIPE_W) and BIRD_X <= px) and
               ((by < gap - GAP_HALF) or ((by + BIRD_H) > gap + GAP_HALF));
    end function;

begin

    process(clk)
        variable speed : integer;
        variable hit   : boolean;
    begin
        if rising_edge(clk) then

            if reset = '1' then
                frame_count <= (others => '0');

                bird_y_i <= 224;
                velocity <= 0;

                pipe1_x_i <= 680;
                pipe2_x_i <= 900;
                pipe3_x_i <= 1020;

                gap1_i <= random_gap(lfsr_value, 17);
                gap2_i <= random_gap(lfsr_value, 103);
                gap3_i <= random_gap(lfsr_value, 219);

                score_i <= 0;
                lives_i <= 3;
                level_i <= 1;

                scored1 <= '0';
                scored2 <= '0';
                scored3 <= '0';

                collision_cooldown <= 0;

                pwr_x_i <= 850;
                pwr_y_i <= random_gap(lfsr_value, 55);
                pwr_type_i <= lfsr_value(0);
                shield_timer <= 0;

            elsif game_active = '1' then

                if frame_count >= FRAME_LIMIT then
                    frame_count <= (others => '0');

                    -- Difficulty/speed
                    if training_mode = '1' then
                        speed := 2;
                        level_i <= 1;
                        lives_i <= 3;
                    elsif score_i < 5 then
                        speed := 2;
                        level_i <= 1;
                    elsif score_i < 15 then
                        speed := 3;
                        level_i <= 2;
                    else
                        speed := 4;
                        level_i <= 3;
                    end if;

                    -- Bird movement.
                    -- Left mouse click makes it jump; otherwise gravity pulls it down.
                    if left_click = '1' then
                        velocity <= -7;
                    elsif velocity < 8 then
                        velocity <= velocity + 1;
                    end if;

                    if bird_y_i + velocity < 0 then
                        bird_y_i <= 0;
                        velocity <= 0;
                    elsif bird_y_i + velocity > 448 then
                        bird_y_i <= 448;
                        velocity <= 0;
                    else
                        bird_y_i <= bird_y_i + velocity;
                    end if;

                    -- Move and recycle pipe 1
                    if pipe1_x_i <= speed then
                        pipe1_x_i <= 760;
                        gap1_i <= random_gap(lfsr_value, score_i * 13 + 11);
                        scored1 <= '0';
                    else
                        pipe1_x_i <= pipe1_x_i - speed;
                    end if;

                    -- Move and recycle pipe 2
                    if pipe2_x_i <= speed then
                        pipe2_x_i <= 760;
                        gap2_i <= random_gap(lfsr_value, score_i * 17 + 89);
                        scored2 <= '0';
                    else
                        pipe2_x_i <= pipe2_x_i - speed;
                    end if;

                    -- Move and recycle pipe 3
                    if pipe3_x_i <= speed then
                        pipe3_x_i <= 760;
                        gap3_i <= random_gap(lfsr_value, score_i * 19 + 173);
                        scored3 <= '0';
                    else
                        pipe3_x_i <= pipe3_x_i - speed;
                    end if;

                    -- Score when each pipe passes the player
                    if pipe1_x_i < BIRD_X and scored1 = '0' then
                        if score_i < 999 then
                            score_i <= score_i + 1;
                        end if;
                        scored1 <= '1';
                    end if;

                    if pipe2_x_i < BIRD_X and scored2 = '0' then
                        if score_i < 999 then
                            score_i <= score_i + 1;
                        end if;
                        scored2 <= '1';
                    end if;

                    if pipe3_x_i < BIRD_X and scored3 = '0' then
                        if score_i < 999 then
                            score_i <= score_i + 1;
                        end if;
                        scored3 <= '1';
                    end if;

                    -- Move and recycle power-up
                    if pwr_x_i <= speed then
                        pwr_x_i <= 820;
                        pwr_y_i <= random_gap(lfsr_value, score_i * 23 + 37);
                        pwr_type_i <= lfsr_value(0);
                    else
                        pwr_x_i <= pwr_x_i - speed;
                    end if;

                    -- Collect power-up
                    if pwr_x_i >= BIRD_X - 12 and pwr_x_i <= BIRD_X + BIRD_W + 12 and
                       pwr_y_i >= bird_y_i - 12 and pwr_y_i <= bird_y_i + BIRD_H + 12 then
                        if pwr_type_i = '1' then
                            if lives_i < 3 then
                                lives_i <= lives_i + 1;
                            end if;
                        else
                            shield_timer <= 300; -- about 5 seconds
                        end if;

                        pwr_x_i <= 820;
                        pwr_y_i <= random_gap(lfsr_value, score_i * 29 + 71);
                        pwr_type_i <= not pwr_type_i;
                    end if;

                    if shield_timer > 0 then
                        shield_timer <= shield_timer - 1;
                    end if;

                    -- Collision
                    hit := pipe_collision(pipe1_x_i, gap1_i, bird_y_i) or
                           pipe_collision(pipe2_x_i, gap2_i, bird_y_i) or
                           pipe_collision(pipe3_x_i, gap3_i, bird_y_i) or
                           bird_y_i <= 0 or bird_y_i >= 448;

                    if collision_cooldown > 0 then
                        collision_cooldown <= collision_cooldown - 1;
                    elsif hit then
                        collision_cooldown <= 45;

                        if training_mode = '1' then
                            -- Unlimited lives in training mode. Keep playing after collisions.
                            lives_i <= 3;
                        elsif shield_timer > 0 then
                            shield_timer <= 0;
                        elsif lives_i > 0 then
                            lives_i <= lives_i - 1;
                        end if;
                    end if;

                else
                    frame_count <= frame_count + 1;
                end if;

            else
                -- MENU/PAUSE/GAME_OVER: freeze motion, but keep values for display.
                frame_count <= (others => '0');
            end if;
        end if;
    end process;

    sprite_y  <= std_logic_vector(to_unsigned(bird_y_i, 10));

    pipe_x1   <= std_logic_vector(to_unsigned(pipe1_x_i, 10));
    pipe_x2   <= std_logic_vector(to_unsigned(pipe2_x_i, 10));
    pipe_x3   <= std_logic_vector(to_unsigned(pipe3_x_i, 10));
    pipe_gap1 <= std_logic_vector(to_unsigned(gap1_i, 10));
    pipe_gap2 <= std_logic_vector(to_unsigned(gap2_i, 10));
    pipe_gap3 <= std_logic_vector(to_unsigned(gap3_i, 10));

    score <= std_logic_vector(to_unsigned(score_i, 10));

    lives <= std_logic_vector(to_unsigned(lives_i, 2));
    level <= std_logic_vector(to_unsigned(level_i, 2));
    lives_zero <= '0' when training_mode = '1' else
                  '1' when lives_i = 0 else
                  '0';

    powerup_x <= std_logic_vector(to_unsigned(pwr_x_i, 10));
    powerup_y <= std_logic_vector(to_unsigned(pwr_y_i, 10));
    powerup_type <= pwr_type_i;
    shield_active <= '1' when shield_timer > 0 else '0';

end architecture rtl;
