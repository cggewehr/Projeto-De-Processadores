-------------------------------------------------------------------------------------------------------------
-- Design unit: R8_uC
-- Description: Instantiation of R8 processor with an I/O Port, meant for synthisys on Nexys 3 board
-- Author: Carlos Gewehr and Emilio Ferreira (cggewehr@gmail.com, emilio.ferreira@ecomp.ufsm.br)
------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity R8_uC is
    generic (
        ASSEMBLY_FILE : string;
        ADDR_PORT     : std_logic_vector(3 downto 0);
        ADDR_PIC      : std_logic_vector(3 downto 0);
        ADDR_UART_TX  : std_logic_vector(3 downto 0)
    );
	port (
		clk           : in std_logic; -- 50MHz from DCM
		rst           : in std_logic; -- Synchronous reset
        port_io       : inout std_logic_vector(15 downto 0);
        uart_tx       : out std_logic
	);
end R8_uC;

architecture behavioral of R8_uC is
   
    signal ce, rw                                    : std_logic;                      -- Auxiliary signals for R8 processor instantiation
    signal rw_MEM, clk_MEM, en_MEM, en_PORT          : std_logic;                      -- Auxiliary signals for R8 processor instantiation

    signal data_PORT, data_MEM_in, data_mem_out      : std_logic_vector(15 downto 0); 
    signal data_r8_in, data_r8_out, address          : std_logic_vector(15 downto 0);

    alias address_PORT                     : std_logic_vector(1 downto 0) is address(1 downto 0);
    alias mem_address                      : std_logic_vector(14 downto 0)is address(14 downto 0);
    alias ID_PERIFERICO                    : std_logic_vector(3 downto 0) is address(7 downto  4);  -- Perf. ID
    alias REG_PERIFERICO                   : std_logic_vector(3 downto 0) is address(3 downto  0);  -- Perf. Address
    alias ENABLE_PERIFERICO                : std_logic is address(15); 							    -- Perf. Enable (I/O operation to be carried out on peripheral)

    alias address_PIC                      : std_logic_vector(1 downto 0) is address(1 downto 0);
    signal data_PIC                        : std_logic_vector(7 downto 0);
	
    -- Tristate for bidirectional bus between processor and i/o port
	signal TRISTATE_PORT_EN   : std_logic;
    signal TRISTATE_PIC_EN    : std_logic;
	
	 -- Interruption Interface
	signal irq_R8             : std_logic;
	signal irq_PORT           : std_logic_vector(15 downto 0);
	
	 -- Pic signals
	signal en_pic             : std_logic;
	signal intr_pic           : std_logic;
	signal irq_pic            : std_logic_vector(7 downto 0);

    -- UART TX signals
    signal en_UART_TX         : std_logic;
    signal data_UART_TX       : std_logic_vector(7 downto 0);
    signal ready_UART_TX      : std_logic;

begin
		
    -- Processor signals
    data_r8_in <= data_PORT when ENABLE_PERIFERICO = '1' and ID_PERIFERICO = ADDR_PORT else
                  ("00000000" & data_PIC) when ENABLE_PERIFERICO = '1' and ID_PERIFERICO = ADDR_PIC else
                  ("000000000000000" & ready_UART_TX) when ENABLE_PERIFERICO = '1' and ID_PERIFERICO = ADDR_UART_TX else
                  data_MEM_out;

    -- Processor
    R8Processor: entity work.R8 
        port map(
            clk      => clk,
            rst      => rst,
			irq      => intr_PIC,
            address  => address,
            data_out => data_r8_out,
            data_in  => data_r8_in,
            ce       => ce,
            rw       => rw                 -- Write : 0, Read : 1
        );
		
    -- Memory signals
    clk_MEM <= not clk;   -- Makes memory sensitive to falling edge
    rw_MEM  <= not rw;    -- Writes when 1, Reads when 0
    en_MEM  <= '1' when (ce = '1' and ENABLE_PERIFERICO = '0') else '0'; -- address(15)      
    
    -- Memory
    Memory: entity work.Memory 
        generic map(
            DATA_WIDTH => 16,
            ADDR_WIDTH => 15,
            IMAGE => ASSEMBLY_FILE -- Assembly code (must be in same directory)
        )
        port map(
            clk => clk_MEM,
            wr  => rw_MEM,
            en  => en_MEM,
            address  => mem_address, 
            data_in  => data_r8_out,
            data_out => data_MEM_out    
        );
		
    -- Port signals
    en_PORT <= '1' when (ce = '1' and ENABLE_PERIFERICO = '1' and ID_PERIFERICO = ADDR_PORT) else '0';   
        
    -- Tristate between I/O port and processor
	data_PORT <= data_r8_out when TRISTATE_PORT_EN = '1' else (others=>'Z');
	TRISTATE_PORT_EN <= '1' when rw = '0' and ID_PERIFERICO = ADDR_PORT and ENABLE_PERIFERICO = '1' else '0';  -- Enables when writes

    -- I/O port
    IO_Port: entity work.BidirectionalPort
        generic map(
			DATA_WIDTH          => 16, -- Port width in bits
			PORT_DATA_ADDR      => "00",    
			PORT_CONFIG_ADDR    => "01",     
			PORT_ENABLE_ADDR    => "10",
			PORT_IRQ_ADDR       => "11"
        )
        port map(
            clk => clk, 
            rst => rst,

            -- Processor Interface
            data => data_PORT,
            address => address_PORT,
            rw => rw_MEM,              -- 0: read; 1: write
            ce => en_PORT,
			irq => irq_PORT,           -- To PIC
				
            -- External interface
			port_io => port_io         -- To Peripheral
        );

    -- PIC signals
    en_PIC <= '1' when (ce = '1' and ENABLE_PERIFERICO = '1' and ID_PERIFERICO = ADDR_PIC) else '0';

    --en_PIC <= '1' when (ce = '1' and ENABLE_PERIFERICO = '1') else '0';
	 
    irq_PIC(7) <= irq_PORT(15);
    irq_PIC(6) <= irq_PORT(14);
    irq_PIC(5) <= irq_PORT(13);
    irq_PIC(4) <= irq_PORT(12);
    irq_PIC(3 downto 0) <= (others=>'0');

    -- Tristate between PIC and processor
    data_PIC <= data_r8_out(7 downto 0) when TRISTATE_PIC_EN = '1' else (others=>'Z');
    TRISTATE_PIC_EN <= '1' when rw = '0' and ID_PERIFERICO = ADDR_PIC and ENABLE_PERIFERICO = '1' else '0';  -- Enables when writes

    -- Peripheral Interrupt Controller:
    PIC: entity work.InterruptController
        generic map(
            IRQ_ID_ADDR    => "00",
            INT_ACK_ADDR   => "01",
            MASK_ADDR      => "10"
        )   
        port map(
            clk       => clk,
            rst       => rst,
            data      => data_PIC,
            address   => address_PIC,
            rw        => rw_MEM,         -- 0: read; 1: write
            ce        => en_PIC,
            intr      => intr_PIC,       -- To processor
            irq       => irq_PIC         -- From port
        );

    -- Sinais UART
    data_UART_TX <= data_r8_out(7 downto 0);
    en_UART_TX <= '1' when rw = '0' and ID_PERIFERICO = ADDR_UART_TX and ENABLE_PERIFERICO = '1' else '0';

    TX: entity work.UART_TX
        generic map(
            --RATE_FREQ_BAUD => 5208 -- 9600 baud @ 50MHz
            RATE_FREQ_BAUD => 4 -- Simulation
        )
        port map (
            clk     => clk,
            rst     => rst,
            tx      => uart_tx,
            data_in => data_UART_TX,
            data_av => en_UART_TX,
            ready   => ready_UART_TX
        );

end behavioral;