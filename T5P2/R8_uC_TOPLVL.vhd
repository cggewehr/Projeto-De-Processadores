-------------------------------------------------------------------------------------------------------------
-- Design unit: R8_uC_TOPLVL
-- Description: Instantiation of R8 microcontroller
-- Author: Carlos Gewehr and Emilio Ferreira (cggewehr@gmail.com, emilio.ferreira@ecomp.ufsm.br)
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity R8_uC_TOPLVL is
	port (
		clock      : in std_logic; -- 100MHz board clock
		reset      : in std_logic;  -- Asynchronous reset
		port_io_uc : inout std_logic_vector(15 downto 0);
		uart_tx    : out std_logic
	);
end R8_uC_TOPLVL;

architecture Behavioural of R8_uC_TOPLVL is

    --type DataArray is array (natural range <>) of std_logic_vector(7 downto 0);

    -- Basic signals
	signal clk_2, clk_4               : std_logic; -- 50MHz clock for uC
	signal reset_sync                 : std_logic; -- Synchronous reset

	-- Microcontroller signals
	--signal port_io_uC                 : std_logic_vector(15 downto 0);
    --signal uart_tx                    : std_logic;

    --UART RX signals
    signal data_out_rx                : std_logic_vector(7 downto 0);
    signal data_av_rx                 : std_logic;

begin

	-- Xilinx DCM
    ClockManager: entity work.ClockManager
        port map(
            clk_in   => clock,
            clk_div2 => clk_2,
            clk_div4 => clk_4
        );
        
    -- Reset Synchronizer    
    ResetSynchronizer: entity work.ResetSynchronizer
        port map(
            clk     => clk_2,
            rst_in  => reset,
            rst_out => reset_sync
        );

    -- R8 Microcontroller (Processor, Memory, I/O Port and PIC)
    Microcontroller: entity work.R8_uC
    	generic map (
    	    ASSEMBLY_FILE => "NovoAssemblyT3P2_BRAM.txt",
            ADDR_PORT     => "0000",
            ADDR_PIC      => "1111",
            ADDR_UART_TX  => "1000"
    	)
		port map (
    	    clk     => clk_2,
    		rst     => reset_sync,
    		port_io => port_io_uC,
            uart_tx => uart_tx
    	);

    -- Serial Receiver
--    UART_RX: entity work.UART_RX
--        generic map(
--            RATE_FREQ_BAUD  => 5208 -- 9600 baud @ 50 MHz
--        )
--        port map(
--            clk      => clk_2,
--            rst      => reset_sync,
--            rx       => uart_tx,
--            data_out => data_out_rx,
--            data_av  => data_av_rx
--        );
	
end architecture Behavioural;
