------------------------------------------------------------------------------
-- DESIGN UNIT  : R8 PROGRAMMER                                             --
-- DESCRIPTION  : Programms device RAM based on data received through UART  --
--              :                                                           --
-- AUTHOR       : Carlos Gewehr                                             --
-- CREATED      : July, 2019                                                --
-- VERSION      : 1.0                                                       --
-- HISTORY      : Version 1.0 - July, 2019 - Gewehr                         --         
------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity Programmer is
    generic(
        UART_RX_ADDR: std_logic_vector(3 downto 0);
        RX_DATA_ADDR: std_logic_vector(3 downto 0)
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        en          : in std_logic; -- Enables device
        ce          : out std_logic; -- Enables RAM access
        rw          : out std_logic; -- 0: read; 1: write
        address     : out std_logic_vector(15 downto 0); 
        data_in     : in std_logic_vector(15 downto 0);
        data_out    : out std_logic_vector(15 downto 0);
        rx_data_av  : in std_logic -- When '1', signals that new data is available from UART RX
    );
end Programmer;

architecture Behavioral of Programmer is
         
     type State is (IDLE, SAVE_ON_HIGHER_GET_BYTE, SAVE_ON_HIGHER_WRITE_BYTE, SAVE_ON_HIGHER_WAIT_FOR_DATA_AV, SAVE_ON_LOWER_GET_BYTE, SAVE_ON_LOWER_WRITE_BYTE, DONE);

     signal currentState: State;
     signal currentByte, previousByte: std_logic_vector(7 downto 0);
     --signal currentInstruction: std_logic_vector(15 downto 0);
     signal memIndex: integer range 0 to 32767;

begin

    process(clk, rst, en) begin

    if rst = '1' then

        currentState <= IDLE;
        currentByte <= std_logic_vector(to_unsigned(0, currentByte'length));
        previousByte <= std_logic_vector(to_unsigned(0, previousByte'length));
        --currentInstruction <= std_logic_vector(to_unsigned(0, currentInstruction'length));
        memIndex <= 0;
        ce <= '0';
        rw <= '0';

    elsif rising_edge(clk) and en = '1' then

        if currentState = IDLE then

            ce <= '0';

            if rx_data_av = '1' then
                currentState <= SAVE_ON_HIGHER_GET_BYTE;
            else 
                currentState <= IDLE;
            end if;

        elsif currentState = SAVE_ON_HIGHER_GET_BYTE then

            address <= x"80" & UART_RX_ADDR & RX_DATA_ADDR;
            ce <= '1';
            rw <= '0';

            currentState <= SAVE_ON_HIGHER_WRITE_BYTE;

        elsif currentState = SAVE_ON_HIGHER_WRITE_BYTE then

            currentByte <= data_in(7 downto 0);

            address <= std_logic_vector(to_unsigned(memIndex, address'length));
            data_out <= currentByte & "00000000";
            ce <= '1';
            rw <= '1';

            currentState <= SAVE_ON_HIGHER_WAIT_FOR_DATA_AV;

        elsif currentState = SAVE_ON_HIGHER_WAIT_FOR_DATA_AV then

            ce <= '0';

            if rx_data_av = '1' then

                currentState <= SAVE_ON_LOWER_GET_BYTE;
                previousByte <= currentByte;

            else

                currentState <= SAVE_ON_HIGHER_WAIT_FOR_DATA_AV;

            end if;

        elsif currentState = SAVE_ON_LOWER_GET_BYTE then

            address <= x"80" & UART_RX_ADDR & RX_DATA_ADDR;
            ce <= '1';
            rw <= '0';

            currentState <= SAVE_ON_LOWER_WRITE_BYTE;

        elsif currentState = SAVE_ON_LOWER_WRITE_BYTE then

            currentByte <= data_in(7 downto 0);

            address <= std_logic_vector(to_unsigned(memIndex, address'length));
            data_out <= previousByte & currentByte;
            ce <= '1';
            rw <= '1';

            if memIndex < 32767 then
                memIndex <= memIndex + 1;
                currentState <= IDLE;
            else
                currentState <= DONE;
            end if;

        elsif currentState = DONE then

            ce <= '0';
            rw <= '1';
            currentState <= DONE;

        end if;

    end if;
	 
	 end process;
    
end Behavioral;
