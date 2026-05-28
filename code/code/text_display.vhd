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
    signal char_addr : std_logic_vector(5 downto 0) := "100000";
    signal f_row     : std_logic_vector(2 downto 0) := "000";
    signal f_col     : std_logic_vector(2 downto 0) := "000";
    signal rom_out   : std_logic;
    signal text_en   : std_logic := '0';

    constant MENU_TITLE : string := "ESCAPE FROM EPSTEIN ISLAND";
    constant MENU_START : string := "KEY1 START";
    constant MENU_MODE1 : string := "SW1 UP TRAINING";
    constant MENU_MODE2 : string := "SW1 DOWN CHALLENGE";

    constant HUD_SCORE : string := "SCORE";
    constant HUD_LEVEL : string := "LEVEL";
    constant HUD_LIVES : string := "LIVES";

    constant OVER_TITLE : string := "GAME OVER";
    constant OVER_INFO  : string := "KEY1 MENU";

    constant MENU_TITLE_X : integer := (640 - (MENU_TITLE'length * 16)) / 2;
    constant MENU_START_X : integer := (640 - (MENU_START'length * 8)) / 2;
    constant MENU_MODE1_X : integer := (640 - (MENU_MODE1'length * 8)) / 2;
    constant MENU_MODE2_X : integer := (640 - (MENU_MODE2'length * 8)) / 2;
    constant OVER_TITLE_X : integer := (640 - (OVER_TITLE'length * 16)) / 2;
    constant OVER_INFO_X  : integer := (640 - (OVER_INFO'length * 8)) / 2;
    constant OVER_SCORE_X : integer := (640 - ((HUD_SCORE'length + 2) * 8)) / 2;

    function char_to_addr(c : character) return std_logic_vector is
    begin

        case c is
            when 'A' => return "000001";
            when 'B' => return "000010";
            when 'C' => return "000011";
            when 'D' => return "000100";
            when 'E' => return "000101";
            when 'F' => return "000110";
            when 'G' => return "000111";
            when 'H' => return "001000";
            when 'I' => return "001001";
            when 'J' => return "001010";
            when 'K' => return "001011";
            when 'L' => return "001100";
            when 'M' => return "001101";
            when 'N' => return "001110";
            when 'O' => return "001111";
            when 'P' => return "010000";
            when 'Q' => return "010001";
            when 'R' => return "010010";
            when 'S' => return "010011";
            when 'T' => return "010100";
            when 'U' => return "010101";
            when 'V' => return "010110";
            when 'W' => return "010111";
            when 'X' => return "011000";
            when 'Y' => return "011001";
            when 'Z' => return "011010";
            when '0' => return "110000";
            when '1' => return "110001";
            when '2' => return "110010";
            when '3' => return "110011";
            when '4' => return "110100";
            when '5' => return "110101";
            when '6' => return "110110";
            when '7' => return "110111";
            when '8' => return "111000";
            when '9' => return "111001";
            when ':' => return "111010";
            when others => return "100000"; -- space
        end case;
    end function;

    function digit_to_addr(d : integer) return std_logic_vector is
    begin
        case d is
            when 0 => return char_to_addr('0');
            when 1 => return char_to_addr('1');
            when 2 => return char_to_addr('2');
            when 3 => return char_to_addr('3');
            when 4 => return char_to_addr('4');
            when 5 => return char_to_addr('5');
            when 6 => return char_to_addr('6');
            when 7 => return char_to_addr('7');
            when 8 => return char_to_addr('8');
            when others => return char_to_addr('9');
        end case;
    end function;

    function char_from_string(s : string; idx : integer) return character is
    begin
        if idx < 0 or idx >= s'length then
            return ' ';
        else
            return s(s'low + idx);
        end if;
    end function;

begin

    font_unit: entity work.char_rom
        port map (
            clock             => clk,
            character_address => char_addr,
            font_row          => f_row,
            font_col          => f_col,
            rom_mux_output    => rom_out
        );


    text_on <= rom_out and text_en;

    process(pixel_row, pixel_col, display_mode, score, lives, level)
        variable row_i, col_i : integer;
        variable idx          : integer;
        variable local_row    : integer;
        variable local_col    : integer;
        variable sc           : integer;
        variable lv           : integer;
        variable li           : integer;
        variable ch           : character;
    begin
        row_i := to_integer(unsigned(pixel_row));
        col_i := to_integer(unsigned(pixel_col));

        sc := to_integer(unsigned(score)) mod 100;
        lv := to_integer(unsigned(level));
        li := to_integer(unsigned(lives));

        char_addr <= char_to_addr(' ');
        f_row     <= "000";
        f_col     <= "000";
        text_en   <= '0';

        -- ===================== MENU =====================
        if display_mode = "00" then

            -- Big title: 2x scale, char = 16x16 pixels
            if row_i >= 96 and row_i < 112 and col_i >= MENU_TITLE_X and col_i < MENU_TITLE_X + MENU_TITLE'length * 16 then
                idx       := (col_i - MENU_TITLE_X) / 16;
                local_row := ((row_i - 96) / 2) mod 8;
                local_col := ((col_i - MENU_TITLE_X) / 2) mod 8;

                ch := char_from_string(MENU_TITLE, idx);
                if idx < MENU_TITLE'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;

            -- KEY1 START
            elsif row_i >= 220 and row_i < 228 and col_i >= MENU_START_X and col_i < MENU_START_X + MENU_START'length * 8 then
                idx       := (col_i - MENU_START_X) / 8;
                local_row := (row_i - 220) mod 8;
                local_col := (col_i - MENU_START_X) mod 8;

                ch := char_from_string(MENU_START, idx);
                if idx < MENU_START'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;

            -- SW1 UP TRAINING
            elsif row_i >= 300 and row_i < 308 and col_i >= MENU_MODE1_X and col_i < MENU_MODE1_X + MENU_MODE1'length * 8 then
                idx       := (col_i - MENU_MODE1_X) / 8;
                local_row := (row_i - 300) mod 8;
                local_col := (col_i - MENU_MODE1_X) mod 8;

                ch := char_from_string(MENU_MODE1, idx);
                if idx < MENU_MODE1'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;

            -- SW1 DOWN CHALLENGE
            elsif row_i >= 320 and row_i < 328 and col_i >= MENU_MODE2_X and col_i < MENU_MODE2_X + MENU_MODE2'length * 8 then
                idx       := (col_i - MENU_MODE2_X) / 8;
                local_row := (row_i - 320) mod 8;
                local_col := (col_i - MENU_MODE2_X) mod 8;

                ch := char_from_string(MENU_MODE2, idx);
                if idx < MENU_MODE2'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;
            end if;

        -- ===================== GAME HUD =====================
        elsif display_mode = "01" then

            if row_i >= 8 and row_i < 16 then
                local_row := (row_i - 8) mod 8;
                f_row <= std_logic_vector(to_unsigned(local_row, 3));

                -- SCOREXX
                if col_i >= 8 and col_i < 8 + (HUD_SCORE'length + 2) * 8 then
                    idx       := (col_i - 8) / 8;
                    local_col := (col_i - 8) mod 8;
                    text_en   <= '1';
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));

                    if idx < HUD_SCORE'length then
                        char_addr <= char_to_addr(char_from_string(HUD_SCORE, idx));
                    elsif idx = HUD_SCORE'length then
                        char_addr <= digit_to_addr(sc / 10);
                    elsif idx = HUD_SCORE'length + 1 then
                        char_addr <= digit_to_addr(sc mod 10);
                    else
                        char_addr <= char_to_addr(' ');
                    end if;

                -- LEVEL:X
                elsif col_i >= 200 and col_i < 200 + (HUD_LEVEL'length + 1) * 8 then
                    idx       := (col_i - 200) / 8;
                    local_col := (col_i - 200) mod 8;
                    text_en   <= '1';
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));

                    if idx < HUD_LEVEL'length then
                        char_addr <= char_to_addr(char_from_string(HUD_LEVEL, idx));
                    elsif idx = HUD_LEVEL'length then
                        char_addr <= digit_to_addr(lv);
                    else
                        char_addr <= char_to_addr(' ');
                    end if;

                -- LIVES:X
                elsif col_i >= 400 and col_i < 400 + (HUD_LIVES'length + 1) * 8 then
                    idx       := (col_i - 400) / 8;
                    local_col := (col_i - 400) mod 8;
                    text_en   <= '1';
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));

                    if idx < HUD_LIVES'length then
                        char_addr <= char_to_addr(char_from_string(HUD_LIVES, idx));
                    elsif idx = HUD_LIVES'length then
                        char_addr <= digit_to_addr(li);
                    else
                        char_addr <= char_to_addr(' ');
                    end if;
                end if;
            end if;

        -- ===================== GAME OVER =====================
        elsif display_mode = "10" then

            -- GAME OVER, 2x scale
            if row_i >= 80 and row_i < 96 and col_i >= OVER_TITLE_X and col_i < OVER_TITLE_X + OVER_TITLE'length * 16 then
                idx       := (col_i - OVER_TITLE_X) / 16;
                local_row := ((row_i - 80) / 2) mod 8;
                local_col := ((col_i - OVER_TITLE_X) / 2) mod 8;

                ch := char_from_string(OVER_TITLE, idx);
                if idx < OVER_TITLE'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;

            -- SCORE:XX
            elsif row_i >= 220 and row_i < 228 and col_i >= OVER_SCORE_X and col_i < OVER_SCORE_X + (HUD_SCORE'length + 2) * 8 then
                idx       := (col_i - OVER_SCORE_X) / 8;
                local_row := (row_i - 220) mod 8;
                local_col := (col_i - OVER_SCORE_X) mod 8;

                text_en <= '1';
                f_row   <= std_logic_vector(to_unsigned(local_row, 3));
                f_col   <= std_logic_vector(to_unsigned(local_col, 3));

                if idx < HUD_SCORE'length then
                    char_addr <= char_to_addr(char_from_string(HUD_SCORE, idx));
                elsif idx = HUD_SCORE'length then
                    char_addr <= digit_to_addr(sc / 10);
                elsif idx = HUD_SCORE'length + 1 then
                    char_addr <= digit_to_addr(sc mod 10);
                else
                    char_addr <= char_to_addr(' ');
                end if;

            -- KEY1 MENU
            elsif row_i >= 320 and row_i < 328 and col_i >= OVER_INFO_X and col_i < OVER_INFO_X + OVER_INFO'length * 8 then
                idx       := (col_i - OVER_INFO_X) / 8;
                local_row := (row_i - 320) mod 8;
                local_col := (col_i - OVER_INFO_X) mod 8;

                ch := char_from_string(OVER_INFO, idx);
                if idx < OVER_INFO'length then
                    text_en   <= '1';
                    char_addr <= char_to_addr(ch);
                    f_row     <= std_logic_vector(to_unsigned(local_row, 3));
                    f_col     <= std_logic_vector(to_unsigned(local_col, 3));
                end if;
            end if;
        end if;
    end process;

end Behavioral;
