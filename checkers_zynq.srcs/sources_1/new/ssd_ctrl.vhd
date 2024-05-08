library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ssd_ctrl is
  Port (
    -- TODO-1: Create the input/output ports
    clk: in std_logic;
    switch: in std_logic_vector ( 7 downto 0 );
    sel: buffer std_logic := '0';
    ssd: out std_logic_vector ( 6 downto 0 )
  );
end ssd_ctrl;

architecture Behavioral of ssd_ctrl is
    -- TODO-4: Create the component of clk_div
component clock_divider is
        generic (N : integer); 
        port ( clk: in std_logic; 
            clk_out: out std_logic ); 
    end component;

-- Add any signals if needed
signal digit: STD_LOGIC_VECTOR(3 downto 0);
signal clk100hz: std_logic;
begin
    -- TODO-2: Fill in the blank
    process(digit) begin
        case digit is
            when "0000" => ssd <= "1111110";    -- 0x0
            when "0001" => ssd <= "0110000";    -- 0x1
            when "0010" => ssd <= "1101101";    -- 0x2
            when "0011" => ssd <= "1111001";    -- 0x3
            when "0100" => ssd <= "0110011";    -- 0x4
            when "0101" => ssd <= "1011011";    -- 0x5
            when "0110" => ssd <= "1011111";    -- 0x6
            when "0111" => ssd <= "1110000";    -- 0x7
            when "1000" => ssd <= "1111111";    -- 0x8
            when "1001" => ssd <= "1111011";    -- 0x9
            when "1010" => ssd <= "1110111";    -- 0xA
            when "1011" => ssd <= "0011111";    -- 0xb (lowercase)
            when "1100" => ssd <= "1001110";    -- 0xC
            when "1101" => ssd <= "0111101";    -- 0xd (lowercase)
            when "1110" => ssd <= "1001111";    -- 0xE
            when "1111" => ssd <= "1000111";    -- 0xF
            when others => ssd <= "00000000";
        end case;
    end process;

    -- TODO-5 : Port map the clk_div component (100MHz --> 100Hz)
    comp_clk100Hz : clock_divider generic map(N => 500000) port map (clk => clk, clk_out => clk100hz); 

    -- TODO-6: Time-multiplexing (Create as many process as you want, OR use both sequential and combinational statement)
    sel_proc: process(clk100hz)
    begin
        if rising_edge(clk100hz) then
            sel <= not sel;
        end if;
    end process sel_proc;
    
    digit <= switch(3 downto 0) when (sel = '0') else switch(7 downto 4);
    
end Behavioral;