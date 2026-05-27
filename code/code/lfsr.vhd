library IEEE;
use IEEE.std_logic_1164.all;

entity lfsr is
    port(
        clk, reset : in  std_logic;
        lfsr_value : out std_logic_vector(9 downto 0)
    );
end entity lfsr;

architecture rtl of lfsr is
    signal reg : std_logic_vector(9 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg <= "0000000001";  -- seed: never all zeros
            else
                -- Maximal length taps at positions 10 and 7
                reg <= reg(8 downto 0) & (reg(9) xor reg(6));
            end if;
        end if;
    end process;

    lfsr_value <= reg;
end architecture rtl;