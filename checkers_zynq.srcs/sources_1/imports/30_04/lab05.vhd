library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
use work.boardPckg.all;

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
    
--    clk: in std_logic;        
--        hsync, vsync: out std_logic;        
--        red, green, blue : out std_logic_vector(3 downto 0);
--        BTNR : IN STD_LOGIC;
--        BTNU : IN STD_LOGIC;
--        BTND : IN STD_LOGIC;
--        BTNL : IN STD_LOGIC 
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
            white_pieces: IN board;
            black_pieces: IN board;      
            MOVE_X : IN INTEGER;
            MOVE_Y : IN INTEGER
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
    
    signal CHOSEN_X: integer := -1;
    signal CHOSEN_Y: integer := -1;
    
    signal SELECTED_PIECE: boolean := false;
    
    signal TURN : std_logic := '0'; -- '0' is white, '1' is black
    
    signal OLD_CHOSEN_X: integer := 0;
    signal OLD_CHOSEN_Y: integer := 0;
    
    signal MOVE_X : integer := 0; 
    signal MOVE_Y : integer := 0;
    signal BOARD_SIZE: integer := 7;

   signal white_pieces : board := ("10101010", "01010101", "10101010", "00000000",
           "00000000","00000000","00000000","00000000");
   signal black_pieces : board := ("00000000", "00000000", "00000000", "00000000",
    "00000000","01010101","10101010","01010101");
     
begin
    joystick_test: pmod_joystick
        generic map ( clk_freq => 100)
        port map (
          clk => clk,
          reset_n => reset_n,
          miso => miso,
          mosi => mosi,
          sclk => sclk,
          cs_n => cs_n,
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
        black_pieces => black_pieces);
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
    
    select_piece: process(clk10Hz)
    begin
        if rising_edge(clk10Hz) then
            if BTNU = '1' then
--                Q <= "10101010";
                -- X_COORD and Y_COORD
                if (white_pieces(Y_COORD, X_COORD) = '1' and TURN = '0') then
                    CHOSEN_Y <= Y_COORD;
                    CHOSEN_X <= X_COORD;
                    Q <= "11000000";
                    SELECTED_PIECE <= true;
                end if;
                if (black_pieces(Y_COORD, X_COORD) = '1' and TURN = '1') then
                    CHOSEN_Y <= Y_COORD;
                    CHOSEN_X <= X_COORD;
                    Q <= "00110000";
                    SELECTED_PIECE <= true;
                end if;
            end if;
            if Y_COORD >= 0 and Y_COORD <= 7 and X_COORD >= 0 and X_COORD <= 7 and white_pieces(Y_COORD, X_COORD) = '0' and black_pieces(Y_COORD, X_COORD) = '0' then
                if (BTND = '1' and SELECTED_PIECE = true and TURN = '0') then -- white turn
                    if Y_COORD = CHOSEN_Y-1 and X_COORD = CHOSEN_X+1 then -- non capturing move
                        white_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        white_pieces(Y_COORD, X_COORD) <= '1';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '1';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y-1 and X_COORD = CHOSEN_X-1 then -- non capturing move
                        white_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        white_pieces(Y_COORD, X_COORD) <= '1';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '1';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y-2 and X_COORD = CHOSEN_X+2 and black_pieces(CHOSEN_Y-1, CHOSEN_X+1) = '1' then -- capturing move, turn should not change
                        white_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        white_pieces(Y_COORD, X_COORD) <= '1';
                        black_pieces(CHOSEN_Y-1, CHOSEN_X+1) <= '0';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '0';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y-2 and X_COORD = CHOSEN_X-2 and black_pieces(CHOSEN_Y-1, CHOSEN_X-1) = '1' then -- capturing move, turn should not change
                        white_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        white_pieces(Y_COORD, X_COORD) <= '1';
                        black_pieces(CHOSEN_Y-1, CHOSEN_X-1) <= '0';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '0';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    end if;
                end if;
                if (BTND = '1' and SELECTED_PIECE = true and TURN = '1') then -- black turn
                    if Y_COORD = CHOSEN_Y+1 and X_COORD = CHOSEN_X-1 then -- non capturing move
                        black_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        black_pieces(Y_COORD, X_COORD) <= '1';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '0';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y+1 and X_COORD = CHOSEN_X+1 then -- non capturing move
                        black_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        black_pieces(Y_COORD, X_COORD) <= '1';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '0';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y+2 and X_COORD = CHOSEN_X-2 and white_pieces(CHOSEN_Y+1, CHOSEN_X-1) = '1' then -- capturing move, turn should not change
                        black_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        black_pieces(Y_COORD, X_COORD) <= '1';
                        white_pieces(CHOSEN_Y+1, CHOSEN_X-1) <= '0';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '1';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    elsif Y_COORD = CHOSEN_Y+2 and X_COORD = CHOSEN_X+2 and white_pieces(CHOSEN_Y+1, CHOSEN_X+1) = '1' then -- capturing move, turn should not change
                        black_pieces(CHOSEN_Y, CHOSEN_X) <= '0';
                        black_pieces(Y_COORD, X_COORD) <= '1';
                        white_pieces(CHOSEN_Y+1, CHOSEN_X+1) <= '0';
                        SELECTED_PIECE <= false;
                        Q <= "00001100";
                        TURN <= '1';
                        -- dirty and repetitive, but works for now
                        CHOSEN_Y <= -1;
                        CHOSEN_X <= -1;
                    end if;
                end if;
            end if;
        else 
            CHOSEN_Y <= CHOSEN_Y;
            CHOSEN_X <= CHOSEN_X;
        end if;
    end process select_piece;
    
end Behavioral;
