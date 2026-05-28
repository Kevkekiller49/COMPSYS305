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
    port(Clk, reset, start_button, pause_button, mode_switch, lives_zero : in std_logic;
        game_active, training_mode : out std_logic;
        display_mode : out std_logic_vector (1 downto 0));
end entity game_fsm;

architecture behaviour of game_fsm is

    -- Define all possible game states as an enumerated type.
    -- Using named states makes the code far more readable than binary numbers.
    type state_type is (MENU, TRAINING, CHALLENGE, PAUSED_TRAINING, PAUSED_CHALLENGE, GAME_OVER);

    -- current_state holds where the FSM is right now.
    -- next_state holds where it will go on the next clock edge.
    signal current_state : state_type;
    signal start_prev : std_logic := '0';
	 signal pause_prev : std_logic := '0';
	 signal start_edge : std_logic;
	 signal pause_edge : std_logic;
 
begin

    -- =========================================================================
    -- PROCESS 1: State Register
    -- This is a clocked process - it updates current_state on every rising
    -- clock edge. If reset is pressed, it forces the game back to MENU.
    -- This process contains no logic - it simply stores the current state.
    -- =========================================================================
    process(Clk)
    begin
        if (rising_edge(Clk)) then
            if (Reset = '1') then
                current_state <= MENU;      -- Reset always returns to start screen
            else
                current_state <= next_state; -- Otherwise advance to next state
            end if;
        end if;
    end process;

    -- =========================================================================
    -- PROCESS 2: Next State Logic
    -- This is a combinational process - no clock. It looks at the current state
    -- and input signals to determine what state to go to next.
    -- Priority order within each state matters - e.g. lives_zero is checked
    -- before pause_button so a dead bird cannot be paused.
    -- =========================================================================
    process (current_state, start_button, pause_button, mode_switch, lives_zero)
    begin
        case current_state is

            -- MENU: Wait for start button, then go to selected mode
            when MENU =>
                if start_button = '1' then
                    if mode_switch = '1' then
                        next_state <= TRAINING;   -- Switch up = Training mode
                    else
                        next_state <= CHALLENGE;  -- Switch down = Challenge mode
                    end if;
                else
                    next_state <= current_state;  -- Stay in MENU until started
                end if;

            -- TRAINING: Check for death first (highest priority), then pause
            when TRAINING =>
                if lives_zero = '1' then
                    next_state <= GAME_OVER;          -- Bird died - go to game over
                elsif pause_button = '1' then
                    next_state <= PAUSED_TRAINING;    -- Pause button pressed
                else
                    next_state <= current_state;      -- Keep playing
                end if;

            -- PAUSED_TRAINING: Only unpause when pause button pressed again
            when PAUSED_TRAINING =>
                if pause_button = '1' then
                    next_state <= TRAINING;       -- Resume training
                else
                    next_state <= current_state;  -- Stay paused
                end if;

            -- CHALLENGE: Same logic as TRAINING but goes to PAUSED_CHALLENGE
            when CHALLENGE =>
                if lives_zero = '1' then
                    next_state <= GAME_OVER;          -- Bird died - go to game over
                elsif pause_button = '1' then
                    next_state <= PAUSED_CHALLENGE;   -- Pause button pressed
                else
                    next_state <= current_state;      -- Keep playing
                end if;

            -- PAUSED_CHALLENGE: Only unpause when pause button pressed again
            when PAUSED_CHALLENGE =>
                if pause_button = '1' then
                    next_state <= CHALLENGE;      -- Resume challenge
                else
                    next_state <= current_state;  -- Stay paused
                end if;

            -- GAME_OVER: Wait for start button to return to MENU
            when GAME_OVER =>
                if start_button = '1' then
                    next_state <= MENU;           -- Return to start screen
                else
                    next_state <= current_state;  -- Stay on game over screen
                end if;

        end case;
    end process;

    -- =========================================================================
    -- PROCESS 3: Output Logic
    -- This is a combinational process that sets the output signals based on
    -- the current state. No clock needed - outputs update immediately when
    -- the state changes.
    -- =========================================================================
    process (current_state)
    begin
        case current_state is

            -- MENU: Game not running, show menu screen
            when MENU =>
                game_active  <= '0';
                display_mode <= "00";

            -- TRAINING or CHALLENGE: Game actively running, show game screen
            when TRAINING | CHALLENGE =>
                game_active  <= '1';
                display_mode <= "01";

            -- PAUSED: Game frozen but still showing game screen
            when PAUSED_TRAINING | PAUSED_CHALLENGE =>
                game_active  <= '0';
                display_mode <= "01";

            -- GAME_OVER: Game not running, show game over screen
            when GAME_OVER =>
                game_active  <= '0';
                display_mode <= "10";

        end case;
		
    end process;
	training_mode <= '1' when (current_state = TRAINING or current_state = PAUSED_TRAINING) else '0';
end architecture behaviour;
