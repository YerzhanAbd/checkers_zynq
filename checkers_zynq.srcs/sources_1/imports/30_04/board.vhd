library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

package boardPckg is
    type board is array (0 to 7,0 to 7) of std_logic;
end package boardPckg;

package legalMovesPckg is
  type legalMoves is array (0 to 3,0 to 1) of integer;
end package legalMovesPckg;