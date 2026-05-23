library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity text_display is
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
end entity text_display;

architecture Behavioral of text_display is
    signal char_addr : std_logic_vector(5 downto 0);
    signal f_row     : std_logic_vector(2 downto 0);
    signal f_col     : std_logic_vector(2 downto 0);
    signal rom_out   : std_logic;
    signal row_u     : unsigned(9 downto 0);
    signal col_u     : unsigned(9 downto 0);

    -- Score/lives/level digit helpers
    signal score_tens : integer range 0 to 9;
    signal score_ones : integer range 0 to 9;
    signal level_val  : integer range 0 to 3;
    signal lives_val  : integer range 0 to 3;

begin
    row_u <= unsigned(pixel_row);
    col_u <= unsigned(pixel_col);

    -- Extract decimal digits from score (max 63 with 6-bit score)
    score_tens <= to_integer(unsigned(score)) / 10;
    score_ones <= to_integer(unsigned(score)) mod 10;
    level_val  <= to_integer(unsigned(level));
    lives_val  <= to_integer(unsigned(lives));

    font_unit: entity work.char_rom
        port map (
            clock             => clk,
            character_address => char_addr,
            font_row          => f_row,
            font_col          => f_col,
            rom_mux_output    => rom_out
        );

    text_on <= rom_out;

    process(row_u, col_u, display_mode, score, lives, level,
            score_tens, score_ones, level_val, lives_val)
    begin
        char_addr <= "100000";
        f_row     <= "000";
        f_col     <= "000";

        -- ===================== MENU =====================
        if display_mode = "00" then

            -- "ESCAPE FROM" 2x scale, rows 80-96, centred col 232-408
            if row_u >= 80 and row_u < 96 then
                if col_u >= 232 and col_u < 408 then
                    f_row <= std_logic_vector(row_u(3 downto 1));
                    f_col <= std_logic_vector(col_u(3 downto 1));
                    case to_integer(col_u(7 downto 4)) is
                        when 14 => char_addr <= "000100"; -- E
                        when 15 => char_addr <= "010010"; -- S
                        when 16 => char_addr <= "000010"; -- C
                        when 17 => char_addr <= "000000"; -- A
                        when 18 => char_addr <= "001111"; -- P
                        when 19 => char_addr <= "000100"; -- E
                        when 20 => char_addr <= "100000"; -- space
                        when 21 => char_addr <= "000101"; -- F
                        when 22 => char_addr <= "010001"; -- R
                        when 23 => char_addr <= "001110"; -- O
                        when 24 => char_addr <= "001100"; -- M
                        when others => char_addr <= "100000";
                    end case;
                end if;

            -- "EPSTEIN ISLAND" 2x scale, rows 112-128, centred col 208-432
            elsif row_u >= 112 and row_u < 128 then
                if col_u >= 208 and col_u < 432 then
                    f_row <= std_logic_vector(row_u(3 downto 1));
                    f_col <= std_logic_vector(col_u(3 downto 1));
                    case to_integer(col_u(7 downto 4)) is
                        when 13 => char_addr <= "000100"; -- E
                        when 14 => char_addr <= "001111"; -- P
                        when 15 => char_addr <= "010010"; -- S
                        when 16 => char_addr <= "010011"; -- T
                        when 17 => char_addr <= "000100"; -- E
                        when 18 => char_addr <= "001000"; -- I
                        when 19 => char_addr <= "001101"; -- N
                        when 20 => char_addr <= "100000"; -- space
                        when 21 => char_addr <= "001000"; -- I
                        when 22 => char_addr <= "010010"; -- S
                        when 23 => char_addr <= "001011"; -- L
                        when 24 => char_addr <= "000000"; -- A
                        when 25 => char_addr <= "001101"; -- N
                        when 26 => char_addr <= "000011"; -- D
                        when others => char_addr <= "100000";
                    end case;
                end if;

            -- "TRAINING" and "CHALLENGE" 1x scale, rows 280-288
            elsif row_u >= 280 and row_u < 288 then
                f_row <= std_logic_vector(row_u(2 downto 0));
                f_col <= std_logic_vector(col_u(2 downto 0));
                -- TRAINING: col 160-224
                if col_u >= 160 and col_u < 224 then
                    case to_integer(col_u(6 downto 3)) is
                        when 20 => char_addr <= "010011"; -- T
                        when 21 => char_addr <= "010001"; -- R
                        when 22 => char_addr <= "000000"; -- A
                        when 23 => char_addr <= "001000"; -- I
                        when 24 => char_addr <= "001101"; -- N
                        when 25 => char_addr <= "001000"; -- I
                        when 26 => char_addr <= "001101"; -- N
                        when 27 => char_addr <= "000110"; -- G
                        when others => char_addr <= "100000";
                    end case;
                -- CHALLENGE: col 360-432
                elsif col_u >= 360 and col_u < 432 then
                    case to_integer(col_u(6 downto 3)) is
                        when 45 => char_addr <= "000010"; -- C
                        when 46 => char_addr <= "000111"; -- H
                        when 47 => char_addr <= "000000"; -- A
                        when 48 => char_addr <= "001011"; -- L
                        when 49 => char_addr <= "001011"; -- L
                        when 50 => char_addr <= "000100"; -- E
                        when 51 => char_addr <= "001101"; -- N
                        when 52 => char_addr <= "000110"; -- G
                        when 53 => char_addr <= "000100"; -- E
                        when others => char_addr <= "100000";
                    end case;
                end if;

            -- "PRESS A KEY" 1x scale, rows 400-408, centred col 295-383
            elsif row_u >= 400 and row_u < 408 then
                if col_u >= 295 and col_u < 383 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    case to_integer(col_u(6 downto 3)) is
                        when 36 => char_addr <= "001111"; -- P
                        when 37 => char_addr <= "010001"; -- R
                        when 38 => char_addr <= "000100"; -- E
                        when 39 => char_addr <= "010010"; -- S
                        when 40 => char_addr <= "010010"; -- S
                        when 41 => char_addr <= "100000"; -- space
                        when 42 => char_addr <= "000000"; -- A
                        when 43 => char_addr <= "100000"; -- space
                        when 44 => char_addr <= "001010"; -- K
                        when 45 => char_addr <= "000100"; -- E
                        when 46 => char_addr <= "011000"; -- Y
                        when others => char_addr <= "100000";
                    end case;
                end if;
            end if;

        -- ===================== GAME HUD =====================
        elsif display_mode = "01" then

            -- Row 8-16: "SCORE:XX  LEVEL:X  LIVES:X"
            if row_u >= 8 and row_u < 16 then
                f_row <= std_logic_vector(row_u(2 downto 0));
                f_col <= std_logic_vector(col_u(2 downto 0));

                -- "SCORE:" col 8-56
                if col_u >= 8 and col_u < 56 then
                    case to_integer(col_u(5 downto 3)) is
                        when 1 => char_addr <= "010010"; -- S
                        when 2 => char_addr <= "000010"; -- C
                        when 3 => char_addr <= "001110"; -- O
                        when 4 => char_addr <= "010001"; -- R
                        when 5 => char_addr <= "000100"; -- E
                        when 6 => char_addr <= "111010"; -- :
                        when others => char_addr <= "100000";
                    end case;
                -- Score tens digit col 56-64
                elsif col_u >= 56 and col_u < 64 then
                    char_addr <= std_logic_vector(to_unsigned(26 + score_tens, 6));
                -- Score ones digit col 64-72
                elsif col_u >= 64 and col_u < 72 then
                    char_addr <= std_logic_vector(to_unsigned(26 + score_ones, 6));

                -- "LEVEL:" col 200-248
                elsif col_u >= 200 and col_u < 248 then
                    case to_integer(col_u(5 downto 3)) is
                        when 25 => char_addr <= "001011"; -- L
                        when 26 => char_addr <= "000100"; -- E
                        when 27 => char_addr <= "010101"; -- V
                        when 28 => char_addr <= "000100"; -- E
                        when 29 => char_addr <= "001011"; -- L
                        when 30 => char_addr <= "111010"; -- :
                        when others => char_addr <= "100000";
                    end case;
                -- Level digit col 248-256
                elsif col_u >= 248 and col_u < 256 then
                    char_addr <= std_logic_vector(to_unsigned(26 + level_val, 6));

                -- "LIVES:" col 400-448
                elsif col_u >= 400 and col_u < 448 then
                    case to_integer(col_u(5 downto 3)) is
                        when 50 => char_addr <= "001011"; -- L
                        when 51 => char_addr <= "001000"; -- I
                        when 52 => char_addr <= "010101"; -- V
                        when 53 => char_addr <= "000100"; -- E
                        when 54 => char_addr <= "010010"; -- S
                        when 55 => char_addr <= "111010"; -- :
                        when others => char_addr <= "100000";
                    end case;
                -- Lives digit col 448-456
                elsif col_u >= 448 and col_u < 456 then
                    char_addr <= std_logic_vector(to_unsigned(26 + lives_val, 6));
                end if;
            end if;

        -- ===================== GAME OVER =====================
        elsif display_mode = "10" then

            -- "GAME OVER" 2x scale, rows 16-32, centred col 176-320
            if row_u >= 16 and row_u < 32 then
                if col_u >= 176 and col_u < 320 then
                    f_row <= std_logic_vector(row_u(3 downto 1));
                    f_col <= std_logic_vector(col_u(3 downto 1));
                    case to_integer(col_u(7 downto 4)) is
                        when 11 => char_addr <= "000110"; -- G
                        when 12 => char_addr <= "000000"; -- A
                        when 13 => char_addr <= "001100"; -- M
                        when 14 => char_addr <= "000100"; -- E
                        when 15 => char_addr <= "100000"; -- space
                        when 16 => char_addr <= "001110"; -- O
                        when 17 => char_addr <= "010101"; -- V
                        when 18 => char_addr <= "000100"; -- E
                        when 19 => char_addr <= "010001"; -- R
                        when others => char_addr <= "100000";
                    end case;
                end if;

            -- "YOU WERE CAUGHT" 1x scale, rows 200-208, centred col 245-365
            elsif row_u >= 200 and row_u < 208 then
                if col_u >= 245 and col_u < 365 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    case to_integer(col_u(6 downto 3)) is
                        when 30 => char_addr <= "011000"; -- Y
                        when 31 => char_addr <= "001110"; -- O
                        when 32 => char_addr <= "010100"; -- U
                        when 33 => char_addr <= "100000"; -- space
                        when 34 => char_addr <= "010110"; -- W
                        when 35 => char_addr <= "000100"; -- E
                        when 36 => char_addr <= "010001"; -- R
                        when 37 => char_addr <= "000100"; -- E
                        when 38 => char_addr <= "100000"; -- space
                        when 39 => char_addr <= "000010"; -- C
                        when 40 => char_addr <= "000000"; -- A
                        when 41 => char_addr <= "010100"; -- U
                        when 42 => char_addr <= "000110"; -- G
                        when 43 => char_addr <= "000111"; -- H
                        when 44 => char_addr <= "010011"; -- T
                        when others => char_addr <= "100000";
                    end case;
                end if;

            -- "SCORE:XX" 1x scale, rows 300-308, centred col 272-336
            elsif row_u >= 300 and row_u < 308 then
                if col_u >= 272 and col_u < 336 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    case to_integer(col_u(5 downto 3)) is
                        when 34 => char_addr <= "010010"; -- S
                        when 35 => char_addr <= "000010"; -- C
                        when 36 => char_addr <= "001110"; -- O
                        when 37 => char_addr <= "010001"; -- R
                        when 38 => char_addr <= "000100"; -- E
                        when 39 => char_addr <= "111010"; -- :
                        when others => char_addr <= "100000";
                    end case;
                elsif col_u >= 336 and col_u < 344 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    char_addr <= std_logic_vector(to_unsigned(26 + score_tens, 6));
                elsif col_u >= 344 and col_u < 352 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    char_addr <= std_logic_vector(to_unsigned(26 + score_ones, 6));
                end if;

            -- "PRESS RESET" 1x scale, rows 400-408, centred col 268-356
            elsif row_u >= 400 and row_u < 408 then
                if col_u >= 268 and col_u < 356 then
                    f_row <= std_logic_vector(row_u(2 downto 0));
                    f_col <= std_logic_vector(col_u(2 downto 0));
                    case to_integer(col_u(6 downto 3)) is
                        when 33 => char_addr <= "001111"; -- P
                        when 34 => char_addr <= "010001"; -- R
                        when 35 => char_addr <= "000100"; -- E
                        when 36 => char_addr <= "010010"; -- S
                        when 37 => char_addr <= "010010"; -- S
                        when 38 => char_addr <= "100000"; -- space
                        when 39 => char_addr <= "010001"; -- R
                        when 40 => char_addr <= "000100"; -- E
                        when 41 => char_addr <= "010010"; -- S
                        when 42 => char_addr <= "000100"; -- E
                        when 43 => char_addr <= "010011"; -- T
                        when others => char_addr <= "100000";
                    end case;
                end if;
            end if;

        end if;
    end process;

end Behavioral;