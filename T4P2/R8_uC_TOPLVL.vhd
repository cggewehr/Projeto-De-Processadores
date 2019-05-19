-------------------------------------------------------------------------------------------------------------
-- Design unit: R8_uC_TOPLVL
-- Description: Instantiation of R8 microcontroller connected to CryptoMessage peripheral
-- Author: Carlos Gewehr and Emilio Ferreira (cggewehr@gmail.com, emilio.ferreira@ecomp.ufsm.br)
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity R8_uC_TOPLVL is
	port (
		clk: in std_logic; -- 100MHz board clock
		rst: in std_logic  -- Synchronous reset
	);
end R8_uC_TOPLVL;

architecture Behavioural of R8_uC_TOPLVL is

    type DataArray is array (natural range <>) of std_logic_vector(7 downto 0);

	-- Basic signals
	signal clk_2, clk_4               : std_logic; -- 50MHz clock for uC, 25MHz clock for CryptoMessage
	signal reset_sync                 : std_logic; -- Synchronous reset

	-- Auxiliary signals
	signal TRISTATE_CRYPTO_TO_PORT_EN : std_logic; 
	signal TRISTATE_CRYPTO_TO_PORT    : std_logic_vector(7 downto 0);

	-- Microcontroller signals
	signal port_io_uC                 : std_logic_vector(15 downto 0);

	-- CryptoManager signals
    signal data_in_R8                 : std_logic_vector(7 downto 0);
    signal data_out_R8                : std_logic_vector(7 downto 0);
	signal data_AV_R8                 : std_logic;
	signal ack_R8                     : std_logic;
	signal eom_R8                     : std_logic;

    -- CryptoMessage signals
    signal data_in                    : DataArray(0 to 3);
    signal data_out                   : DataArray(0 to 3);
    signal keyExchange                : std_logic_vector(3 downto 0);
    signal data_AV                    : std_logic_vector(3 downto 0);
    signal ack                        : std_logic_vector(3 downto 0);
    signal eom                        : std_logic_vector(3 downto 0); 

begin

	-- Xilinx DCM
    ClockManager: entity work.ClockManager
        port map(
            clk_in   => clk,
            clk_div2 => clk_2,
            clk_div4 => clk_4
        );
        
    -- Reset synchronizer    
    ResetSynchronizer: entity work.ResetSynchronizer
        port map(
            clk     => clk_2,
            rst_in  => rst,
            rst_out => reset_sync
        );

    -- R8 Microcontroller (Processor, Memory and I/O Port)
    Microcontroller: entity work.R8_uC
    	generic map (
    		ASSEMBLY_FILE => "AssemblyT4P2_BRAM.txt"
    	)
    	port map (
    		clk     => clk_2,
    		rst     => reset_sync,
    		port_io => port_io_uC
    	);

    -- CryptoManager (Multiplexes CryptoMessages)    
    CryptoManager: entity work.CryptoManager
        generic map(
            CRYPTO_AMOUNT => 4,
            DATA_WIDTH    => 8
        )
        port map (
            clk => clk_2,
            rst => reset_sync,

            -- Processor
            data_in_R8  => data_in_R8,
            data_out_R8 => data_out_R8,
            data_AV_R8  => data_AV_R8,
            ack_R8      => ack_R8,
            eom_R8      => eom_R8,

            -- CryptoMessage 0
            data_in_crypto(0)     => data_in(0),
            data_out_crypto(0)    => data_out(0),
            keyExchange_crypto(0) => keyExchange(0),
            data_AV_crypto(0)     => data_AV(0),
            ack_crypto(0)         => ack(0),
            eom_crypto(0)         => eom(0),

            -- CryptoMessage 1
            data_in_crypto(1)     => data_in(1),
            data_out_crypto(1)    => data_out(1),
            keyExchange_crypto(1) => keyExchange(1),
            data_AV_crypto(1)     => data_AV(1),
            ack_crypto(1)         => ack(1),
            eom_crypto(1)         => eom(1),

            -- CryptoMessage 2
            data_in_crypto(2)     => data_in(2),
            data_out_crypto(2)    => data_out(2),
            keyExchange_crypto(2) => keyExchange(2),
            data_AV_crypto(2)     => data_AV(2),
            ack_crypto(2)         => ack(2),
            eom_crypto(2)         => eom(2),

            -- CryptoMessage 3
            data_in_crypto(3)     => data_in(3),
            data_out_crypto(3)    => data_out(3),
            keyExchange_crypto(3) => keyExchange(3),
            data_AV_crypto(3)     => data_AV(3),
            ack_crypto(3)         => ack(3),
            eom_crypto(3)         => eom(3)
        );

    -- CryptoMessage peripheral
    CryptoMessage0: entity work.CryptoMessage
        generic map(
            MSG_INTERVAL => 1000, -- Waits 1000 clocks before sending next msg
            FILE_NAME  => "empire.txt"
        )
    	port map(
    		clk         => clk_4,
    		rst         => reset_sync,
    		data_in     => data_in(0),
    		data_out    => data_out(0),
    		keyExchange => keyExchange(0),
    		data_AV     => data_AV(0),
    		ack         => ack(0),
    		eom         => eom(0)
    	);

    CryptoMessage1: entity work.CryptoMessage
        generic map(
            MSG_INTERVAL => 2000, -- Waits 2000 clocks before sending next msg
            FILE_NAME  => "RevolutionCalling.txt"
        )
        port map(
            clk         => clk_4,
            rst         => reset_sync,
            data_in     => data_in(1),
            data_out    => data_out(1),
            keyExchange => keyExchange(1),
            data_AV     => data_AV(1),
            ack         => ack(1),
            eom         => eom(1)
        );

    CryptoMessage2: entity work.CryptoMessage
        generic map(
            MSG_INTERVAL => 3000, -- Waits 3000 clocks before sending next msg
            FILE_NAME  => "DoctorRockter.txt"
        )
        port map(
            clk         => clk_4,
            rst         => reset_sync,
            data_in     => data_in(2),
            data_out    => data_out(2),
            keyExchange => keyExchange(2),
            data_AV     => data_AV(2),
            ack         => ack(2),
            eom         => eom(2)
        );

    CryptoMessage3: entity work.CryptoMessage
        generic map(
            MSG_INTERVAL => 4000, -- Waits 4000 clocks before sending next msg
            FILE_NAME  => "empire.txt"
        )
        port map(
            clk         => clk_4,
            rst         => reset_sync,
            data_in     => data_in(3),
            data_out    => data_out(3),
            keyExchange => keyExchange(3),
            data_AV     => data_AV(3),
            ack         => ack(3),
            eom         => eom(3)
        );

    port_io_uC(12) <= keyExchange(0); -- Highest priority Crypto
    port_io_uC(13) <= keyExchange(1);
    port_io_uC(14) <= keyExchange(2);
    port_io_uC(15) <= keyExchange(3); -- Lowest priority Crypto

    data_AV_R8 <= port_io_uC(11);
    port_io_uC(10) <= ack_R8;
    eom_R8 <= port_io_uC(9);

   	port_io_uC(11) <= data_AV_R8;
   	ack_crypto <= port_io_uC(10);
   	port_io_uC(9) <= eom_crypto;

    TRISTATE_CRYPTO_TO_PORT <= data_out_R8;
    TRISTATE_CRYPTO_TO_PORT_EN <= port_io_uC(8);

    port_io_uC(7 downto 0) <= TRISTATE_CRYPTO_TO_PORT when TRISTATE_CRYPTO_TO_PORT_EN = '1' else (others=>'Z');

    data_in_R8 <= port_io_uC(7 downto 0);
	
end architecture Behavioural;
