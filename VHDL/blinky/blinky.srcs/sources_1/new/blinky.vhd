----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/25/2018 10:39:54 PM
-- Design Name: 
-- Module Name: blinky - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blinky is
    Port ( CLK12MHZ : in STD_LOGIC;
           led      : out STD_LOGIC_VECTOR (3 downto 0));
end blinky;

architecture Behavioral of blinky is



begin

blink_process : process (CLK12MHZ)

variable count : STD_LOGIC_VECTOR (23 downto 0) := X"000000";

begin 
    if rising_edge(CLK12MHZ) then
        count := std_logic_vector( unsigned(count) + 1);   --X"000001";    
        
        led(3) <= count (23);
        led(2) <= count (22);
        led(1) <= count (21);
        led(0) <= count (20);
        
    end if;

end process;

end Behavioral;
