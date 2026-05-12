library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Using numeric_std for safe math

entity text_display is
    port (
        clk          : in  std_logic;
        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_col    : in  std_logic_vector(9 downto 0);
        text_on      : out std_logic
    );
end text_display;

architecture Behavioral of text_display is
    signal char_addr : std_logic_vector(5 downto 0);
    signal f_row     : std_logic_vector(2 downto 0);
    signal f_col     : std_logic_vector(2 downto 0);
    
    -- Unsigned versions for easier math
    signal row_u : unsigned(9 downto 0);
    signal col_u : unsigned(9 downto 0);
begin
    row_u <= unsigned(pixel_row);
    col_u <= unsigned(pixel_col);

    -- Instantiate the ROM you provided
    font_unit: entity work.char_rom
        port map (
            clock             => clk,
            character_address => char_addr,
            font_row          => f_row,
            font_col          => f_col,
            rom_mux_output    => text_on
        );

    process(row_u, col_u)
    begin
        -- Default: ROM is looking at a blank space
        char_addr <= "100000"; -- Usually space (ASCII 32)
        f_row <= "000";
        f_col <= "000";

        -- WORD 1: "BOUNCY" (Small 8x8) at Top Left (row 16)
        if (row_u >= 16 and row_u < 24) then
            if (col_u >= 16 and col_u < 64) then -- 6 characters * 8 pixels = 48 wide
                f_row <= std_logic_vector(row_u(2 downto 0)); -- row 16-23 -> 0-7
                f_col <= std_logic_vector(col_u(2 downto 0)); -- cycling 0-7 every 8 pixels
                
                -- Character selection logic
                case to_integer(col_u(5 downto 3)) is -- col/8
                    when 2 => char_addr <= "000010"; -- 'B' (Address 2)
                    when 3 => char_addr <= "001111"; -- 'O' (Address 15)
                    when 4 => char_addr <= "010101"; -- 'U'
                    when 5 => char_addr <= "001110"; -- 'N'
                    when 6 => char_addr <= "000011"; -- 'C'
                    when 7 => char_addr <= "011001"; -- 'Y'
                    when others => char_addr <= "100000";
                end case;
            end if;

        -- WORD 2: "BALL" (Large 16x16) at Bottom (row 400)
        elsif (row_u >= 400 and row_u < 416) then
            if (col_u >= 16 and col_u < 80) then -- 4 characters * 16 pixels = 64 wide
                -- SCALE: Divide relative position by 2
                f_row <= std_logic_vector(row_u(3 downto 1)); -- 16px high / 2 = 8 ROM rows
                f_col <= std_logic_vector(col_u(3 downto 1)); -- 16px wide / 2 = 8 ROM cols
                
                case to_integer(col_u(6 downto 4)) is -- col/16
                    when 1 => char_addr <= "000010"; -- 'B'
                    when 2 => char_addr <= "000001"; -- 'A'
                    when 3 => char_addr <= "001100"; -- 'L'
                    when 4 => char_addr <= "001100"; -- 'L'
                    when others => char_addr <= "100000";
                end case;
            end if;
        end if;
    end process;

end Behavioral;