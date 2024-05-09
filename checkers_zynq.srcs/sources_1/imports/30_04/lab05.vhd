library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
use work.boardPckg.all;
use work.legalMovesPckg.all;


entity project is
    port (
        clk: in std_logic;        
        hsync, vsync: out std_logic;        
        red, green, blue : out std_logic_vector(3 downto 0);
--        BTNR : IN STD_LOGIC;
        BTNU : IN STD_LOGIC;
        BTND : IN STD_LOGIC;
--        BTNL : IN STD_LOGIC;
        sel: buffer std_logic := '0';
        ssd: out std_logic_vector ( 6 downto 0 ); 
        miso            : IN     STD_LOGIC;
        mosi            : OUT    STD_LOGIC;
        sclk       : buffer std_logic;
        cs_n: out std_logic;
        Q : out std_logic_vector (7 downto 0)   
    ); 
end project; 

architecture Behavioral of project is
    component clock_divider is
        generic (N : integer); 
        port ( clk: in std_logic; 
            clk_out: out std_logic ); 
    end component;
    
    component pmod_joystick is
      generic (
        clk_freq: integer
      );
      port (
        clk             : IN     STD_LOGIC;                     --system clock
        reset_n         : IN     STD_LOGIC;                     --active low reset
        miso            : IN     STD_LOGIC;                     --SPI master in, slave out
        mosi            : OUT    STD_LOGIC;                     --SPI master out, slave in
        sclk            : BUFFER STD_LOGIC;                     --SPI clock
        cs_n            : OUT    STD_LOGIC;                     --pmod chip select
        x_position      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick x-axis position
        y_position      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  --joystick y-axis position
        trigger_button  : OUT    STD_LOGIC;                     --trigger button status
        center_button   : OUT    STD_LOGIC);                    --center button status
    end component;
    component vga_driver is
        port (
            clk50MHz: in std_logic;        
            hsync, vsync: out std_logic;        
            red, green, blue : out std_logic_vector(3 downto 0); 
            CHOSEN_X, CHOSEN_Y : IN INTEGER;
            white_pieces: IN pieces;
            black_pieces: IN pieces;      
            MOVE_X : IN INTEGER;
            MOVE_Y : IN INTEGER;
            legal_moves : IN board
        ); 
    end component;
    
    component ssd_ctrl is
        port (
            clk: in std_logic;
            switch: in std_logic_vector ( 7 downto 0 );
            sel: buffer std_logic := '0';
            ssd: out std_logic_vector ( 6 downto 0 )
        );
    end component;
    
    signal reset_n: std_logic:='1';
    signal x_position      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal y_position      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal trigger_button  : STD_LOGIC;
    signal center_button   : STD_LOGIC;
    
    signal UPPER_LIMIT : std_logic_vector(7 downto 0) := "11000000"; -- 3/4
    signal LOWER_LIMIT : std_logic_vector(7 downto 0) := "01000000";  -- 1/4
    
    signal clk50MHz : std_logic;    
    signal clk10Hz : std_logic;    
    
    signal X_COORD: integer := 0;
    signal Y_COORD: integer := 0;
    signal X_COORD_VEC: std_logic_vector(3 downto 0);
    signal Y_COORD_VEC: std_logic_vector(3 downto 0);
    signal COORD_VEC: std_logic_vector(7 downto 0);
    
    
    signal CHOSEN_X: integer := -1;
    signal CHOSEN_Y: integer := -1;
    
    signal SELECTED_PIECE: boolean := false;
    
    signal TURN : std_logic := '0'; -- '0' is white, '1' is black
    
    signal MOVE_X : integer := 0; 
    signal MOVE_Y : integer := 0;
    signal BOARD_SIZE: integer := 7;

   signal black_pieces : pieces := (
   (0, 1, 0, 1, 0, 1, 0, 1),
   (1, 0, 1, 0, 1, 0, 1, 0),
   (0, 1, 0, 1, 0, 1, 0, 1),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0)
   );
   
   signal white_pieces : pieces := (
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (0, 0, 0, 0, 0, 0, 0, 0),
   (1, 0, 1, 0, 1, 0, 1, 0),
   (0, 1, 0, 1, 0, 1, 0, 1),
   (1, 0, 1, 0, 1, 0, 1, 0)
   );
    
   signal legal_moves : board := ("00000000", "00000000", "00000000", "00000000",
    "00000000", "00000000", "00000000", "00000000");
   signal number_of_legal_moves: integer := 0;
   
   signal STATE: integer := 1;
    
     
begin

    -- FSM
    -- State 1 -> move around the board and choose the piece
    -- State 2 -> The piece is chosen, make a move, OR move around the board and choose another piece
    -- State 3 -> Multiple captures. Capture multiple pieces. ONLY capturing moves accepted.
    --            If there are no pieces to capture, the turn is passed to another player
    get_coords: process(clk10Hz)
    begin
        Q <= std_logic_vector(TO_UNSIGNED(STATE, 8));
        X_COORD_VEC <= std_logic_vector(TO_UNSIGNED(X_COORD, 4));
        Y_COORD_VEC <= std_logic_vector(TO_UNSIGNED(Y_COORD, 4));
        COORD_VEC (7 downto 4) <= X_COORD_VEC; 
        COORD_VEC (3 downto 0) <= Y_COORD_VEC; 
    end process get_coords;
    comp_ssd_ctrl : ssd_ctrl port map (clk => clk, switch => COORD_VEC, sel => sel, ssd => ssd); 
    joystick_test: pmod_joystick
        generic map ( clk_freq => 100)
        port map (
          clk => clk,
          reset_n => reset_n,
          miso => miso,
          mosi => mosi,
          sclk => sclk,
          cs_n => cs_n,
          trigger_button => trigger_button,
          x_position => x_position,
          y_position => y_position
    );
    -- generate 50MHz clock
    comp_clk50MHz : clock_divider generic map(N => 1) port map(clk, clk50MHz);
    
    comp_clk10Hz : clock_divider generic map(N => 5000000) port map(clk, clk10Hz);
    -- print board
    vga_display: vga_driver port map(
        clk50MHz => clk50MHz, 
        MOVE_X => MOVE_X, 
        MOVE_Y => MOVE_Y,
        CHOSEN_X => CHOSEN_X,
        CHOSEN_Y => CHOSEN_Y,
        hsync => hsync, 
        vsync => vsync, 
        red => red, 
        green => green, 
        blue => blue,
        white_pieces => white_pieces,
        black_pieces => black_pieces,
        legal_moves => legal_moves);
    --move right
    pointer: process(clk10Hz)
    begin
        if( rising_edge(clk10Hz) ) then
            if (x_position > UPPER_LIMIT and MOVE_X < BOARD_SIZE) then
--                H_TOP_LEFT <= H_TOP_LEFT + 10;
                MOVE_X <= MOVE_X + 1;
            end if;
                         
            if (x_position < LOWER_LIMIT and MOVE_X > 0) then
--                H_TOP_LEFT <= H_TOP_LEFT - 10;
                MOVE_X <= MOVE_X - 1;
            end if;
            
            if (y_position < LOWER_LIMIT and MOVE_Y > 0) then
--                V_TOP_LEFT <= V_TOP_LEFT - 10;
                MOVE_Y <= MOVE_Y - 1;
            end if; 
                        
            if (y_position > UPPER_LIMIT and MOVE_Y < BOARD_SIZE) then
--                V_TOP_LEFT <= V_TOP_LEFT + 10;
                MOVE_Y <= MOVE_Y + 1;
            end if;
        end if;
        X_COORD <= MOVE_X;
        Y_COORD <= MOVE_Y;
    end process pointer;
    legal_moves_select: process(CHOSEN_X, CHOSEN_Y)
        begin
        legal_moves <= ("00000000", "00000000", "00000000", "00000000",
    "00000000", "00000000", "00000000", "00000000");
        number_of_legal_moves <= 0;
        if (white_pieces(CHOSEN_Y, CHOSEN_X) = 1 and TURN = '0') then
                    
            if (STATE /= 3) and (CHOSEN_Y-1 >= 0) and (CHOSEN_X+1 <= BOARD_SIZE) and white_pieces(CHOSEN_Y-1, CHOSEN_X+1) = 0 and black_pieces(CHOSEN_Y-1, CHOSEN_X+1) = 0 then
                -- top-right
                legal_moves(CHOSEN_Y-1,CHOSEN_X+1) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            elsif CHOSEN_Y-2 >= 0 and CHOSEN_X+2 <= BOARD_SIZE and black_pieces(CHOSEN_Y-1, CHOSEN_X+1) = 1 and white_pieces(CHOSEN_Y-2, CHOSEN_X+2) = 0 and black_pieces(CHOSEN_Y-2, CHOSEN_X+2) = 0 then
                -- top-left capture
                legal_moves(CHOSEN_Y-2,CHOSEN_X+2) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            end if;
            if (STATE /= 3) and (CHOSEN_Y-1 >= 0) and (CHOSEN_X-1 >= 0) and white_pieces(CHOSEN_Y-1, CHOSEN_X-1) = 0 and black_pieces(CHOSEN_Y-1, CHOSEN_X-1) = 0 then
                -- top-left
                legal_moves(CHOSEN_Y-1,CHOSEN_X-1) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            elsif CHOSEN_Y-2 >= 0 and CHOSEN_X-2 >= 0 and black_pieces(CHOSEN_Y-1, CHOSEN_X-1) = 1 and white_pieces(CHOSEN_Y-2, CHOSEN_X-2) = 0 and black_pieces(CHOSEN_Y-2, CHOSEN_X-2) = 0 then
                -- top-left capture
                legal_moves(CHOSEN_Y-2,CHOSEN_X-2) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            end if;
        end if;
        -- Identify legal moves for non-king
        if (black_pieces(CHOSEN_Y, CHOSEN_X) = 1 and TURN = '1') then
            
            if (STATE /= 3) and (CHOSEN_Y+1 <= BOARD_SIZE) and (CHOSEN_X-1 >= 0) and white_pieces(CHOSEN_Y+1, CHOSEN_X-1) = 0 and black_pieces(CHOSEN_Y+1, CHOSEN_X-1) = 0 then
                -- down-left
                legal_moves(CHOSEN_Y+1,CHOSEN_X-1) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            elsif CHOSEN_Y+2 <= BOARD_SIZE and CHOSEN_X-2 >= 0 and white_pieces(CHOSEN_Y+1, CHOSEN_X-1) = 1 and white_pieces(CHOSEN_Y+2, CHOSEN_X-2) = 0 and black_pieces(CHOSEN_Y+2, CHOSEN_X-2) = 0 then
                -- down-left capture
                legal_moves(CHOSEN_Y+2,CHOSEN_X-2) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            end if;
            if (STATE /= 3) and (CHOSEN_Y+1 <= BOARD_SIZE) and (CHOSEN_X+1 <= BOARD_SIZE) and white_pieces(CHOSEN_Y+1, CHOSEN_X+1) = 0 and black_pieces(CHOSEN_Y+1, CHOSEN_X+1) = 0 then
                -- down-right
                legal_moves(CHOSEN_Y+1,CHOSEN_X+1) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            elsif CHOSEN_Y+2 <= BOARD_SIZE and CHOSEN_X+2 <= BOARD_SIZE and white_pieces(CHOSEN_Y+1, CHOSEN_X+1) = 1 and white_pieces(CHOSEN_Y+2, CHOSEN_X+2) = 0 and black_pieces(CHOSEN_Y+2, CHOSEN_X+2) = 0 then
                -- down-right capture
                legal_moves(CHOSEN_Y+2,CHOSEN_X+2) <= '1';
                number_of_legal_moves <= number_of_legal_moves + 1;
            end if;
        end if; 
    end process legal_moves_select;
    select_piece: process(clk10Hz)
    variable capture: integer := -1;
    begin
        if rising_edge(clk10Hz) then
            
            if ((STATE = 1 or STATE = 2) and trigger_button = '1') and (STATE /= 3) then
                if (white_pieces(Y_COORD, X_COORD) = 1 and TURN = '0') then
                    CHOSEN_Y <= Y_COORD;
                    CHOSEN_X <= X_COORD;
                    
                    STATE <= 2;
                    SELECTED_PIECE <= true;
                end if;
                if (black_pieces(Y_COORD, X_COORD) = 1 and TURN = '1') then
                    CHOSEN_Y <= Y_COORD;
                    CHOSEN_X <= X_COORD;
                    
                    STATE <= 2;
                    SELECTED_PIECE <= true;
                end if;
            end if;
            
            if (STATE = 3) and (number_of_legal_moves = 0) then
                CHOSEN_X <= -1;
                CHOSEN_Y <= -1;
                STATE <= 1;
                TURN <= not TURN;
                SELECTED_PIECE <= false;
            end if;
            if legal_moves(Y_COORD, X_COORD) = '1' then
                if (((STATE = 2 or STATE = 3) and trigger_button = '1') and SELECTED_PIECE = true) then
                    if (TURN = '0') then -- white turn
                        if Y_COORD = CHOSEN_Y-1 and X_COORD = CHOSEN_X+1 then -- non capturing move
                            white_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            white_pieces(Y_COORD, X_COORD) <= 1;
                            capture := 0;
                            
                        elsif Y_COORD = CHOSEN_Y-1 and X_COORD = CHOSEN_X-1 then -- non capturing move
                            white_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            white_pieces(Y_COORD, X_COORD) <= 1;
                            capture := 0;
                        elsif Y_COORD = CHOSEN_Y-2 and X_COORD = CHOSEN_X+2 then -- capturing move, turn should not change
                            white_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            white_pieces(Y_COORD, X_COORD) <= 1;
                            black_pieces(CHOSEN_Y-1, CHOSEN_X+1) <= 0;
                            capture := 1;
                        elsif Y_COORD = CHOSEN_Y-2 and X_COORD = CHOSEN_X-2 then -- capturing move, turn should not change
                            white_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            white_pieces(Y_COORD, X_COORD) <= 1;
                            black_pieces(CHOSEN_Y-1, CHOSEN_X-1) <= 0;
                            capture := 1;
                        end if;
                    else -- black turn
                        if Y_COORD = CHOSEN_Y+1 and X_COORD = CHOSEN_X-1 then -- non capturing move
                            black_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            black_pieces(Y_COORD, X_COORD) <= 1;
                            capture := 0;
                        elsif Y_COORD = CHOSEN_Y+1 and X_COORD = CHOSEN_X+1 then -- non capturing move
                            black_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            black_pieces(Y_COORD, X_COORD) <= 1;
                            capture := 0;
                        elsif Y_COORD = CHOSEN_Y+2 and X_COORD = CHOSEN_X-2 then -- capturing move, turn should not change
                            black_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            black_pieces(Y_COORD, X_COORD) <= 1;
                            white_pieces(CHOSEN_Y+1, CHOSEN_X-1) <= 0;
                            capture := 1;
                        elsif Y_COORD = CHOSEN_Y+2 and X_COORD = CHOSEN_X+2 then -- capturing move, turn should not change
                            black_pieces(CHOSEN_Y, CHOSEN_X) <= 0;
                            black_pieces(Y_COORD, X_COORD) <= 1;
                            white_pieces(CHOSEN_Y+1, CHOSEN_X+1) <= 0;
                            capture := 1;
                        end if;
                    end if;
                    
                    if (capture = 0) then
                        SELECTED_PIECE <= false;
                        STATE <= 1;
                        TURN <= not TURN;
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    end if;
                    if (capture = 1) then
                        STATE <= 3;
                        CHOSEN_Y <= Y_COORD;
                        CHOSEN_X <= X_COORD;
                    end if;
                end if;
            end if;
        end if;
    end process select_piece;
    
end Behavioral;
