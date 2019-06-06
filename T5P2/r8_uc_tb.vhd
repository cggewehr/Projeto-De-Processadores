library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity r8_uC_tb is
end r8_uC_tb;

architecture behavioral of r8_uC_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal port_io : std_logic_vector(15 downto 0);
    signal uart_rx_data_out : std_logic_vector(7 downto 0);
    signal uart_rx_data_av : std_logic;
	 
begin
    R8: entity work.R8_uC_TOPLVL
        port map(
            clock => clk,
            reset => rst,
            port_io_uC => port_io,
            uart_tx => uart_tx
        );

    clk <= not clk after 5 ns; -- 100 MHz
    rst <= '1', '0' after 5 ns;
	port_io <= "ZZZZZZZZZZZZZZZZ";


    -- UART RX
    UART_RX: entity work.UART_RX
        generic map(
            RATE_FREQ_BAUD => 10416
        )

        port map(
            clk => clk,
            rst => rst,
            rx => uart_tx,
            data_out => uart_rx_data_out,
            data_av => uart_rx_data_av
        );

end behavioral;
