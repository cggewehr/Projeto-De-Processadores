----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:07:48 04/12/2019 
-- Design Name: 
-- Module Name:    NovaPortaBidirecional - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use IEEE.numeric_std.all;

entity BidirectionalPort is
    generic (
        DATA_WIDTH          : integer;    -- Port width in bits
        PORT_DATA_ADDR      : std_logic_vector(1 downto 0);     -- NÃO ALTERAR!
        PORT_CONFIG_ADDR    : std_logic_vector(1 downto 0);     -- NÃO ALTERAR! 
        PORT_ENABLE_ADDR    : std_logic_vector(1 downto 0)      -- NÃO ALTERAR!
    );
    port (  
        clk         : in std_logic;
        rst         : in std_logic; 
        
        -- Processor interface
        --data        : inout std_logic_vector (DATA_WIDTH-1 downto 0);
        data_in     : in std_logic_vector (DATA_WIDTH-1 downto 0);
        data_out    : out std_logic_vector (DATA_WIDTH-1 downto 0);
        address     : in std_logic_vector (1 downto 0);         -- NÃO ALTERAR!
        rw          : in std_logic; -- 0: read; 1: write
        ce          : in std_logic;
        
        -- External interface
        port_io     : inout std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end BidirectionalPort;

architecture Behavioral of BidirectionalPort  is
    
    signal REG_PORT_DATA      : std_logic_vector (DATA_WIDTH-1 downto 0); -- Registrador de dados
    signal REG_PORT_CONFIG    : std_logic_vector (DATA_WIDTH-1 downto 0); -- Registrador de configuracao (0 = Saida, 1 = Entrada)
    signal REG_PORT_ENABLE    : std_logic_vector (DATA_WIDTH-1 downto 0); -- Registrador de enable (0 = Desabilitado, 1 = Habilitado)
    signal REG_SYNC1          : std_logic_vector (DATA_WIDTH-1 downto 0); -- Registrador para sincronizao com porta de comunicao
    signal REG_SYNC2          : std_logic_vector (DATA_WIDTH-1 downto 0); -- Registrador para sincronizao com porta de comunicao
    
    --signal TRISTATE_DATA_TEMP : std_logic_vector (DATA_WIDTH-1 downto 0); -- Sinal temporario para comunicação com processador
    --signal TRISTATE_DATA_EN   : std_logic;
    
    --signal TRISTATE_PORT_IO_TEMP : std_logic_vector (DATA_WIDTH-1 downto 0);
    signal TRISTATE_PORT_IO_EN   : std_logic_vector (DATA_WIDTH-1 downto 0);
    
begin
 
--    -- ESCRITA NOS REGISTRADORES
--    process(rst, clk) begin
--        if(rst = '1') then
--            -- Reseta registradores
--            REG_PORT_DATA <= (others=>'0');
--            REG_PORT_CONFIG <= (others=>'1'); -- Entrada
--            REG_PORT_ENABLE <= (others=>'0');
--            
--        elsif rising_edge(clk) then
--            -- PORT DATA           
--            if address = PORT_DATA_ADDR then
--                for i in 0 to DATA_WIDTH-1 loop
----                    if TRISTATE_PORT_IO_EN(i) = '1' then
----                        REG_PORT_DATA(i) <= data(i);
----                    elsif TRISTATE_PORT_IO_EN(i) = '0' then
----                        REG_PORT_DATA(i) <= REG_SYNC2(i);
----                    end if;
--                    if REG_PORT_CONFIG(i) = '0' then -- SAIDA
--                        if ce = '1' then
--                            REG_PORT_DATA(i) <= data(i);
--                       -- else
--                       --     null;
--                        end if;
--                    else -- REG_PORT_CONFIG(i) = '1'
--                        REG_PORT_DATA(i) <= REG_SYNC2(i);
--                    end if;
--                end loop; 
--            end if;     
--        
--            -- PORT CONFIG (0 = saida, 1 = entrada)
--            if address = PORT_CONFIG_ADDR then
--                if ( ce = '1' and rw = '1') then
--                    REG_PORT_CONFIG <= data;
--                end if;
--            end if;
--            
--            -- PORT ENABLE
--            if address = PORT_ENABLE_ADDR then
--                if ( ce = '1' and rw = '1') then
--                    REG_PORT_ENABLE <= data;
--                end if; 
--            end if;
--        end if; 
--    end process;
	 
    -- REGISTRADOR DE DADOS
	process(clk, rst) begin
        if rst = '1' then
			REG_PORT_DATA <= (others=>'0');
		elsif rising_edge(clk) then
			for i in 0 to DATA_WIDTH-1 loop
            
                -- Saida / PROCESSADOR -> PORTA
				if TRISTATE_PORT_IO_EN(i) = '1' and address = PORT_DATA_ADDR and ce = '1' and rw = '1' then
					REG_PORT_DATA(i) <= data_in(i);
				end if;
                    
                --Entrada / EXTERIOR -> PORTA
                if REG_PORT_CONFIG(i) = '1' and REG_PORT_ENABLE(i) = '1' then
                    REG_PORT_DATA(i) <= REG_SYNC2(i);
                end if;
			end loop;
		end if;
	 end process;
	 
	-- REGISTRADOR DE CONFIGURAÇÂO
    process(clk, rst) begin
        if rst = '1' then
            REG_PORT_CONFIG <= (others=>'1'); -- Default como entrada
        elsif rising_edge(clk) then
            if address = PORT_CONFIG_ADDR and ce = '1' and rw = '1' then
                REG_PORT_CONFIG <= data_in;
            end if;
        end if;
    end process;
    
    -- REGISTRADOR DE ENABLE
    process(clk, rst) begin
        if rst = '1' then
            REG_PORT_ENABLE <= (others=>'0');
        elsif rising_edge(clk) then
            if address = PORT_ENABLE_ADDR and ce = '1' and rw = '1' then
                REG_PORT_ENABLE <= data_in;
            end if;
        end if;
    end process;
    
    -- REGISTRADORES DE SINCRONIZACAO
    REG_SYNC: process(clk, rst) begin
        if rst = '1' then
            REG_SYNC1 <= (others=>'0');
            REG_SYNC2 <= (others=>'0');
        elsif rising_edge(clk) then
            REG_SYNC1 <= port_io;
            REG_SYNC2 <= REG_SYNC1;
        end if;
    end process; 
    
--    -- MULTIPLEXADOR PARA TRISTATE_DATA
--    --TRISTATE_DATA_TEMP <= REG_PORT_DATA when address = PORT_DATA_ADDR else
--                          REG_PORT_CONFIG when address = PORT_CONFIG_ADDR else
--                          REG_PORT_ENABLE when address = PORT_ENABLE_ADDR else
--                          (others=>'0');
--    
--    -- CONTROLE TRISTATE PARA PROCESSADOR
--    TRISTATE_DATA_EN <= '1' when rw = '0' and ce = '1' else '0';
--
--    -- TRISTATE PARA PROCESSADOR
--    data <= TRISTATE_DATA_TEMP when TRISTATE_DATA_EN = '1' else (others=>'Z'); -- read

    -- BARRAMENTO DE SAIDA
    data_out <= REG_PORT_DATA when address = PORT_DATA_ADDR else
                REG_PORT_CONFIG when address = PORT_CONFIG_ADDR else
                REG_PORT_ENABLE;
    
    -- CONTROLE TRISTATE PARA CONEXAO DA PORTA
    TRISTATE_SAIDA_EN: for i in 0 to DATA_WIDTH-1 generate
        TRISTATE_PORT_IO_EN(i) <= '1' when REG_PORT_CONFIG(i) = '0' and REG_PORT_ENABLE(i) = '1' else '0';
    end generate;
    
    -- TRISTATE PARA CONEXAO DA PORTA
    TRISTATE_SAIDA: for i in 0 to DATA_WIDTH-1 generate
        port_io(i) <= REG_PORT_DATA(i) when TRISTATE_PORT_IO_EN(i) = '1' else 'Z';
    end generate;
    
end architecture;