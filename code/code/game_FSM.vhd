-- =============================================================================
-- game_fsm.vhd
-- Game Finite State Machine for Flappy Bird FPGA Project
-- COMPSYS 305 - University of Auckland
-- =============================================================================
-- This component manages the overall game state. It decides which mode the
-- game is currently in, and signals other components to behave accordingly.
--
-- STATES:
--   MENU            : Start screen, waiting for player to select mode and start
--   TRAINING        : Playing in training mode (fixed easy difficulty)
--   CHALLENGE       : Playing in challenge mode (3+ increasing difficulty levels)
--   PAUSED_TRAINING : Game frozen, came from TRAINING state
--   PAUSED_CHALLENGE: Game frozen, came from CHALLENGE state
--   GAME_OVER       : Bird has died, showing score, waiting to return to MENU
--
-- INPUTS:
--   Clk         : System clock
--   reset       : Resets FSM back to MENU state
--   start_button: Starts the game from MENU, or returns to MENU from GAME_OVER
--   pause_button: Toggles pause on/off during gameplay
--   mode_switch : Selects game mode ('1' = TRAINING, '0' = CHALLENGE)
--   lives_zero  : Signal from game logic indicating the bird has died
--
-- OUTPUTS:
--   game_active  : '1' when game is actively running (not paused/menu/game over)
--   display_mode : Tells renderer which screen to draw
--                  "00" = MENU screen
--                  "01" = Game/Paused screen
--                  "10" = GAME OVER screen
-- =============================================================================


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity game_fsm is
    port(
        Clk, reset, start_button, pause_button, mode_switch, lives_zero : in std_logic;
        game_active, training_mode : out std_logic;
        display_mode : out std_logic_vector(1 downto 0)
    );
end entity game_fsm;

architecture behaviour of game_fsm is

    type state_type is (
        MENU,
        TRAINING,
        CHALLENGE,
        PAUSED_TRAINING,
        PAUSED_CHALLENGE,
        GAME_OVER
    );

    signal current_state : state_type := MENU;
    signal next_state    : state_type := MENU;

begin

    -- State register
    process(Clk)
    begin
        if rising_edge(Clk) then
            if reset = '1' then
                current_state <= MENU;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- Next-state logic
    process(current_state, start_button, pause_button, mode_switch, lives_zero)
    begin
        next_state <= current_state;

        case current_state is

            when MENU =>
                if start_button = '1' then
                    if mode_switch = '1' then
                        next_state <= TRAINING;
                    else
                        next_state <= CHALLENGE;
                    end if;
                end if;

            when TRAINING =>
                if lives_zero = '1' then
                    next_state <= GAME_OVER;
                elsif pause_button = '1' then
                    next_state <= PAUSED_TRAINING;
                end if;

            when PAUSED_TRAINING =>
                if pause_button = '1' then
                    next_state <= TRAINING;
                end if;

            when CHALLENGE =>
                if lives_zero = '1' then
                    next_state <= GAME_OVER;
                elsif pause_button = '1' then
                    next_state <= PAUSED_CHALLENGE;
                end if;

            when PAUSED_CHALLENGE =>
                if pause_button = '1' then
                    next_state <= CHALLENGE;
                end if;

            when GAME_OVER =>
                if start_button = '1' then
                    next_state <= MENU;
                end if;

        end case;
    end process;

    -- Output logic
    process(current_state)
    begin
        game_active  <= '0';
        training_mode <= '0';
        display_mode <= "00";

        case current_state is

            when MENU =>
                game_active   <= '0';
                training_mode <= '0';
                display_mode  <= "00";

            when TRAINING =>
                game_active   <= '1';
                training_mode <= '1';
                display_mode  <= "01";

            when CHALLENGE =>
                game_active   <= '1';
                training_mode <= '0';
                display_mode  <= "01";

            when PAUSED_TRAINING =>
                game_active   <= '0';
                training_mode <= '1';
                display_mode  <= "01";

            when PAUSED_CHALLENGE =>
                game_active   <= '0';
                training_mode <= '0';
                display_mode  <= "01";

            when GAME_OVER =>
                game_active   <= '0';
                training_mode <= '0';
                display_mode  <= "10";

        end case;
    end process;

end architecture behaviour;
