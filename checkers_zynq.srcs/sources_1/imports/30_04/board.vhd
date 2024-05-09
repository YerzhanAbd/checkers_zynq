library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

package boardPckg is
    type board is array (0 to 7,0 to 7) of std_logic;
    type pieces is array (0 to 7,0 to 7) of integer;
    type piece_shape is array (0 to 3,0 to 3) of integer;
    
    constant PIECE_PIXELS : piece_shape := (
    (0, 0, 0),
    (0, 0, 0),
    (0, 0, 0)
    ); --bits wide
end package boardPckg;

package legalMovesPckg is
  type legalMoves is array (0 to 3,0 to 1) of integer;
end package legalMovesPckg;