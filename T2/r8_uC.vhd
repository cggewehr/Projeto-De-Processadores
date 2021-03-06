-------------------------------------------------------------------------
-- Design unit: R8_uC
-- Description: 
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity R8_uC is
	port (
		clk: in std_logic;
		rst: in std_logic;
        port_io: inout std_logic_vector(15 downto 0)
	);
end R8_uC;

architecture behavioral of R8_uC is
   
    signal clk_2                                     : std_logic;                      -- 50 MHz clock
	signal reset_sync                                : std_logic;                      -- Synchronized reset
	signal ce, rw                                    : std_logic;                      -- Auxiliary signals for R8 processor instantiation
	signal rw_MEM, clk_MEM, en_MEM, en_PORTA         : std_logic;                      -- Auxiliary signals for R8 processor instantiation
    signal data_PORTA_out, data_MEM_in, data_mem_out : std_logic_vector(15 downto 0); 
    signal data_r8_in, data_r8_out, address          : std_logic_vector(15 downto 0);

    alias address_PORTA                    : std_logic_vector(1 downto 0) is address(1 downto 0);
    alias mem_address                      : std_logic_vector(14 downto 0)is address(14 downto 0);
    alias ID_PERIFERICO                    : std_logic_vector(3 downto 0) is address(7 downto  4);  -- Id do periferico
    alias REG_PERIFERICO                   : std_logic_vector(3 downto 0) is address(3 downto  0);  -- Registador do periferico
    alias ENABLE_PERIFERICO                : std_logic is address(15);  -- Enable do periferico
	
	--signal TRISTATE_TO_PORT   : std_logic_vector(15 downto 0);
	--signal TRISTATE_TO_EN     : std_logic;
   
begin
    
    
    -- Sinais da Porta
    en_PORTA <= '1' when (ce = '1' and ENABLE_PERIFERICO = '1') else '0';
    -- Sinais do Processador
    data_r8_in <= data_MEM_out when ENABLE_PERIFERICO = '0' else data_PORTA_out;
    -- Sinais da Memoria 
    clk_MEM <= not clk_2; -- seta o clock da memoria em clock complementar
    rw_MEM  <= not rw;    -- escrita e leitura para borda complementar
    en_MEM  <= '1' when (ce = '1' and ENABLE_PERIFERICO = '0') else '0'; -- address(15)
    
    
	-- TRISTATE PARA PORTA
	--data_PORTA <= data_out_r8 when TRISTATE_TO_EN = '1' else (others=>'Z');
	--TRISTATE_TO_EN <= '1' when rw = '0' else '0';  -- Enables when writes
    
   -- data_PORTA <= TRISTATE_TO_PORT;

    ClockManager: entity work.ClockManager
        port map(
            clk_in   => clk,
            clk_div2 => clk_2,
            clk_div4 => open
        );
        
    ResetSynchronizer: entity work.ResetSynchronizer
        port map(
            clk     => clk_2,
            rst_in  => rst,
            rst_out => reset_sync
        );
         
    -- Processador
    R8Processor: entity work.R8 
        port map(
            clk      => clk_2,
            rst      => reset_sync,
            address  => address,
            data_out => data_r8_out,
            data_in  => data_r8_in,
            ce       => ce,
            rw       => rw
        );
        
    
    -- Memoria
    Memory: entity work.Memory 
        generic map(
            DATA_WIDTH => 16,
            ADDR_WIDTH => 15,
            IMAGE => "PortaIO_BRAM.txt" -- Arquivo assembly
        )
        port map(
            clk => clk_MEM,
            wr  => rw_MEM,
            en  => en_MEM,
            address  => mem_address, 
            data_in  => data_r8_out,
            data_out => data_MEM_out    
        );
        
        
    -- Porta de entrada e saida    
    PORTA: entity work.BidirectionalPort
        generic map(
			DATA_WIDTH          => 16, -- Port width in bits
			PORT_DATA_ADDR      => "00",    
			PORT_CONFIG_ADDR    => "01",     
			PORT_ENABLE_ADDR    => "10"
        )
        port map(
            clk => clk_2, 
            rst => reset_sync,
				
            -- Processor Interface
            data_in => data_R8_out,
            data_out => data_PORTA_out,
            address => address_PORTA,
            rw => rw_MEM,              -- 0: read; 1: write
            ce => en_PORTA,
				
            -- External interface
			port_io => port_io   
        );

end behavioral;