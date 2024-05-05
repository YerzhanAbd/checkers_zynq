library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

package boardPckg is
    type board is array (7 downto 0,7 downto 0) of std_logic;
end package boardPckg;