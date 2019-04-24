library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity r8_uC_tb is
end r8_uC_tb;

architecture behavioral of r8_uC_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal port_io : std_logic_vector(15 downto 0);
begin
    R8_uC: entity work.R8_uC
        port map(
            clk => clk,
            rst => rst,
            port_io => port_io
        );
        
    clk <= not clk after 5 ns; -- 100 MHz
    rst <= '1', '0' after 5 ns;   
    --port_io <= (others=>'Z'), "0001101000001001" after 1360 ns, "ZZZZZZZZ10111111" after 1700 ns, "010110101010ZZZZ" after 2500 ns;
    --port_io <= "ZZZZZZZZ10101010", "ZZZZZZZZ11111110" after 70.1 us, "ZZZZZZZZ00000001" after 160 us;
    
  --  Stimulus: process begin
        
   --     port_io <= "ZZZZZZZZ10101010";
        
        --wait for 400 us;
        
    --    port_io <= "ZZ1ZZZZZ11111110";
        
        --wait for 400 us;
    
    --    port_io <= "ZZ1ZZZZZ00000001";
		  
		--wait for 400 us;
		  
    --    port_io <= "ZZ1ZZZZZ01010101";
		  
	--	wait for 2 ms;

	--	port_io <= "ZZZZZZZZ11001100";
        
        port_io <= "ZZZZZZZZ10101010", "ZZZZZZZZ11111111" after 2 ms;
        
        
    
    --end process;
end behavioral;