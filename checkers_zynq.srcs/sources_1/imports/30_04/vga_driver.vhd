-- COLORS
-- CB2 -> yellow   (1100, 1011, 0010)
-- 410 -> brown     (0100, 0001, 0000)
-- FFF -> white     (1111, 1111, 1111)
-- 000 -> black     (0000, 0000, 0000)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.boardPckg.all;
use work.legalMovesPckg.all;

entity vga_driver is

    port (
        clk50MHz: in std_logic;        
        hsync, vsync: out std_logic;        
        red, green, blue : out std_logic_vector(3 downto 0);
        white_pieces: IN pieces;
        black_pieces: IN pieces;
        MOVE_X, MOVE_Y : IN INTEGER;
        SELECT_MODE: IN INTEGER;
        winner: IN INTEGER;
        CHOSEN_X, CHOSEN_Y : IN INTEGER;
        legal_moves : IN board;
        STATE: IN INTEGER
    ); 
end vga_driver; 

architecture vga_driver_arch of vga_driver is  
    signal clk10Hz : std_logic;    
    signal hcount, vcount: integer := 0;  
    
    
    -- row constants  
    constant H_TOTAL : integer:=1344-1; 
    constant H_SYNC : integer:=48-1; 
    constant H_BACK : integer:=240-1; 
    constant H_START : integer:=48+240-1; 
    constant H_ACTIVE : integer:=1024-1; 
    constant H_END : integer:=1344-32-1-45;    -- Readjust the size to the VGA monitor. The monitor width is < 1024
    constant H_FRONT : integer:=32-1;
    
    -- column constants
    constant V_TOTAL : integer:=625-1; 
    constant V_SYNC : integer:=3-1; 
    constant V_BACK : integer:=12-1; 
    constant V_START : integer:=3+12-1; 
    constant V_ACTIVE : integer:=600-1; 
    constant V_END : integer:=625-10-1; 
    constant V_FRONT : integer:=10-1;
    
    constant LENGTH : integer := 600; 
    signal H_TOP_LEFT : integer := (H_START + H_END)/2 -LENGTH/2; 
    signal V_TOP_LEFT : integer := (V_START + V_END)/2 -LENGTH/2;
    
    signal H_INNER_TOP_LEFT: integer := H_TOP_LEFT + 60;
    signal V_INNER_TOP_LEFT: integer := V_TOP_LEFT + 60;
    signal H_INNER_BOT_RIGHT: integer := H_TOP_LEFT + LENGTH - 60;
    signal V_INNER_BOT_RIGHT: integer := V_TOP_LEFT + LENGTH - 60;
    
    constant PIECE_LENGTH : integer := 30;
    signal H_PIECE_TOP_LEFT : integer := H_INNER_TOP_LEFT + 15;
    signal V_PIECE_TOP_LEFT : integer := V_INNER_TOP_LEFT + 15;
    
    signal X_COORD: integer := 0;
    signal Y_COORD: integer := 0;
    signal SQUARE_COLOR: integer;
    constant PIECE_RADIUS : integer := 225;
    
    
    signal MENU_CHOOSE: std_logic := '0';
    signal BOARD_SIZE: integer := 7;
    
--    signal MOVE_X : integer := 0; 
--    signal MOVE_Y : integer := 0;
    signal square_colors : board := ("01010101", "10101010", "01010101", "10101010",
                   "01010101","10101010","01010101","10101010");
                   

begin
    -- generate 50MHz clock
--    comp_clk50MHz : clock_divider generic map(N => 1) port map(clk, clk50MHz);
    -- horizontal counter
    hcount_proc: process(clk50MHz)
    begin 
        if( rising_edge(clk50MHz) )  
            then if(hcount = H_TOTAL) then 
                hcount<= 0; 
            else 
                hcount <= hcount + 1;   
            end if; 
        end if; 
    end process hcount_proc;    
    --vertical counter 
    vcount_proc: process(clk50MHz)
    begin 
        if( rising_edge(clk50MHz) ) then 
            if(hcount = H_TOTAL) then 
                if(vcount = V_TOTAL) then 
                    vcount <= 0; 
                else 
                    vcount <= vcount + 1; 
                end if; 
            end if; 
        end if; 
    end process vcount_proc;  
    --generate hsync
    square_color_proc: process(hcount, vcount)
    begin
        X_COORD <= (hcount - H_INNER_TOP_LEFT) / 60;
        Y_COORD <= (vcount - V_INNER_TOP_LEFT) / 60;
        
        if (square_colors(Y_COORD, X_COORD) = '1') then
            SQUARE_COLOR <= 1;
        else
            SQUARE_COLOR <= 0;
        end if;
        if legal_moves(Y_COORD, X_COORD) = '1' then
            SQUARE_COLOR <= 4;
        end if;
        if (X_COORD = CHOSEN_X and Y_COORD = CHOSEN_Y) then
            SQUARE_COLOR <= 3;
        end if;
        if (X_COORD = MOVE_X and Y_COORD = MOVE_Y) then
            SQUARE_COLOR <= 2;
        end if;
    end process square_color_proc;
    
    main_menu_color: process(hcount, vcount)
    variable X: integer := 0;
    begin
        if (STATE = 4) then
            X := (hcount - H_TOP_LEFT) / 300;
            
            if (X = SELECT_MODE) then
                MENU_CHOOSE <= '1';
            else
                MENU_CHOOSE <= '0';
            end if;
        else
            MENU_CHOOSE <= '0';
        end if;
    end process main_menu_color;
    
    hsync_gen_proc: process(hcount)
    begin 
        if(hcount < H_SYNC) then 
            hsync<= '0'; 
        else 
            hsync <= '1'; 
        end if; 
    end process hsync_gen_proc;
    -- generate vsync
    vsync_gen_proc: process(vcount) begin
        if(vcount < V_SYNC) then 
            vsync <= '0'; 
        else 
            vsync <= '1'; 
        end if;
    end process vsync_gen_proc;
    -- generate RGB signals for 1024x600 display area 
    data_output_proc: process(hcount, vcount)
    variable piece_h : integer := 0; 
    variable piece_v : integer := 0;
    variable king_h : integer := 0; 
    variable king_v : integer := 0;
    variable round_distance : integer := 0;
    begin 
        if( (hcount >= H_START and hcount < H_END) and 
            (vcount >= V_START and vcount< V_END) ) then
            --Display Area (draw the square here) 
            -- ... (on the next page) 
            if ((hcount >= H_TOP_LEFT and hcount < H_TOP_LEFT + LENGTH) and 
                (vcount >= V_TOP_LEFT and vcount < V_TOP_LEFT + LENGTH)) then 
                -- inside the board
                
                if (STATE /= 4) then
                    if (hcount < H_INNER_TOP_LEFT or hcount >= H_INNER_BOT_RIGHT or vcount < V_INNER_TOP_LEFT or vcount >= V_INNER_BOT_RIGHT) then
                        -- white borders
                        red <= "1111";
                        green <= "1111";
                        blue <= "1111";
                    else
                        piece_h := hcount - (H_INNER_TOP_LEFT + X_COORD * 60 + 25);
                        piece_v := vcount - (V_INNER_TOP_LEFT + Y_COORD * 60 + 25);
                        round_distance := piece_h * piece_h + piece_v * piece_v;
                        if (round_distance <= PIECE_RADIUS) then 
                            
                            if (white_pieces(Y_COORD, X_COORD) >= 1) then
                                red <= "1111";
                                green <= "1111";
                                blue <= "1111";
                                if ((white_pieces(Y_COORD, X_COORD) = 2) and ((hcount >= H_INNER_TOP_LEFT + X_COORD * 60 + 18) and (hcount < H_INNER_TOP_LEFT + X_COORD * 60 + 33)) and ((vcount >= Y_COORD * 60 + V_INNER_TOP_LEFT + 18) and (vcount < V_INNER_TOP_LEFT + Y_COORD * 60 + 33))) then 
                                    king_h := (hcount - H_INNER_TOP_LEFT - X_COORD * 60 - 18) / 3;
                                    king_v := (vcount - V_INNER_TOP_LEFT - Y_COORD * 60 - 18) / 3;
                                    
                                    if ((king_h + king_v) = 4) or (king_h = king_v) then
                                        red <= "0000";
                                        green <= "0000";
                                        blue <= "0000";
                                    end if;
                                end if;
                            elsif (black_pieces(Y_COORD, X_COORD) >= 1) then
                                
                                red <= "0000";
                                green <= "0000";
                                blue <= "0000";
                                if ((black_pieces(Y_COORD, X_COORD) = 2) and ((hcount >= H_INNER_TOP_LEFT + X_COORD * 60 + 18) and (hcount < H_INNER_TOP_LEFT + X_COORD * 60 + 33)) and ((vcount >= Y_COORD * 60 + V_INNER_TOP_LEFT + 18) and (vcount < V_INNER_TOP_LEFT + Y_COORD * 60 + 33))) then 
                                    king_h := (hcount - H_INNER_TOP_LEFT - X_COORD * 60 - 18) / 3;
                                    king_v := (vcount - V_INNER_TOP_LEFT - Y_COORD * 60 - 18) / 3;
                                    
                                    if ((king_h + king_v) = 4) or (king_h = king_v) then
                                        red <= "1111";
                                        green <= "1111";
                                        blue <= "1111";
                                    end if;
                                end if;
                            else
                                if (SQUARE_COLOR = 1) then
                                     -- brown squares
                                    red <= "0100"; 
                                    green <= "0001"; 
                                    blue <= "0000";
                                elsif (SQUARE_COLOR = 2) then
                                    -- green select square
                                    red <= "0000"; 
                                    green <= "1011"; 
                                    blue <= "0000";
                                
                                elsif (SQUARE_COLOR = 3) then
                                    red <= "0000"; 
                                    green <= "0000"; 
                                    blue <= "1100";
                                elsif (SQUARE_COLOR = 4) then
                                    red <= "1101"; 
                                    green <= "0000"; 
                                    blue <= "0000"; 
                                elsif (SQUARE_COLOR = 0) then
                                    -- yellow squares
                                    red <= "1100"; 
                                    green <= "1011"; 
                                    blue <= "0010";
                                end if;  
                            end if;
                        else
                            if (SQUARE_COLOR = 1) then
                                 -- brown squares
                                red <= "0100"; 
                                green <= "0001"; 
                                blue <= "0000";
                            
                            elsif (SQUARE_COLOR = 2) then
                                -- green select square
                                red <= "0000"; 
                                green <= "1011"; 
                                blue <= "0000";
                            
                            elsif (SQUARE_COLOR = 3) then
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "1100";
                            elsif (SQUARE_COLOR = 4) then
                                red <= "1101"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            elsif (SQUARE_COLOR = 0) then
                                -- yellow squares
                                red <= "1100"; 
                                green <= "1011"; 
                                blue <= "0010";
                            end if; 
                        end if;  
                    end if;   
                else
                     -- State 4: Choose AI vs Player
                      
                    red <= "0000"; 
                    green <= "0000"; 
                    blue <= "0000";           
                    if ((hcount >= H_TOP_LEFT) and (hcount < H_TOP_LEFT + 600) and (vcount >= V_TOP_LEFT + 180) and (vcount < V_TOP_LEFT + 180 + 70)) then
                        if (WINNER = 0) then
                            if (WHITE_WON((vcount - V_TOP_LEFT - 180)/10, (hcount - H_TOP_LEFT)/10) = '1') then
                                red <= "1111"; 
                                green <= "1111"; 
                                blue <= "1111";
                            else 
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            end if;
                        elsif (WINNER = 1) then
                            if (BLACK_WON((vcount - V_TOP_LEFT - 180)/10, (hcount - H_TOP_LEFT)/10) = '1') then
                                red <= "1111"; 
                                green <= "1111"; 
                                blue <= "1111";
                            else 
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            end if;
                        else
                            if (NEW_GAME((vcount - V_TOP_LEFT - 180)/10, (hcount - H_TOP_LEFT)/10) = '1') then
                                red <= "1111"; 
                                green <= "1111"; 
                                blue <= "1111";
                            else 
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            end if;
                        end if;
                    end if;
                    if ((hcount >= H_TOP_LEFT) and (hcount < H_TOP_LEFT + 300) and (vcount >= V_TOP_LEFT + 320) and (vcount < V_TOP_LEFT + 320 + 90)) then
                        if (AI((vcount - V_TOP_LEFT - 320)/10, (hcount - H_TOP_LEFT)/10) = '1') then
                            if (MENU_CHOOSE) = '0' then
                                red <= "1111"; 
                                green <= "1111"; 
                                blue <= "1111"; 
                            else
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000";
                            end if;
                        else 
                            if (MENU_CHOOSE = '0') then
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            else
                                red <= "0000"; 
                                green <= "1111"; 
                                blue <= "0000"; 
                            end if;
                        end if;
                    end if;
                    if ((hcount >= H_TOP_LEFT + 300) and (hcount < H_TOP_LEFT + 300 + 300) and (vcount >= V_TOP_LEFT + 320) and (vcount < V_TOP_LEFT + 320 + 90)) then
                        if (PvP((vcount - V_TOP_LEFT - 320)/10, (hcount - H_TOP_LEFT - 300)/10) = '1') then
                            if (MENU_CHOOSE = '0') then
                                red <= "1111"; 
                                green <= "1111"; 
                                blue <= "1111"; 
                            else
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000";
                            end if;
                        else 
                            if (MENU_CHOOSE = '0') then
                                red <= "0000"; 
                                green <= "0000"; 
                                blue <= "0000"; 
                            else
                                red <= "0000"; 
                                green <= "1111"; 
                                blue <= "0000"; 
                            end if;
                        end if;
                    end if;
                end if; -- c
            else 
                -- black background
                red <= "0000"; 
                green <= "0000"; 
                blue <= "0000"; 
            end if; -- c
        else
        --Blanking Area 
            red   <= "0000"; 
            green <= "0000"; 
            blue  <= "0000"; 
        end if; -- c
    end process data_output_proc;
end vga_driver_arch;
