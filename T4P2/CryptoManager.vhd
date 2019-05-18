library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CryptoManagerPkg is
    type Data_Out_Array is array (natural range <> ) of std_logic_vector;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CryptoManagerPkg.all;

entity CryptoManager is
    generic (
        CRYPTO_AMOUNT       : integer;
        DATA_WIDTH          : integer
    );
    port(
        --Basic
        clk                 : in std_logic;
        rst                 : in std_logic;

        -- Processor Interface
        data                : inout std_logic_vector(DATA_WIDTH-1 downto 0);
        dataDD              : in std_logic;
        keyExchange_R8      : out std_logic_vector(CRYPTO_AMOUNT-1 downto 0); 
        data_av_R8          : out std_logic;
        ack_R8              : in std_logic;
        eom_R8              : out std_logic;      

        -- CryptoMessage Interface
        keyExchange_crypto  : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        data_av_crypto      : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        ack_crypto          : out std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        eom_crypto          : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        data_in_crypto      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_crypto     : in Data_Out_Array(CRYPTO_AMOUNT-1)(DATA_WIDTH-1) -- Será que funciona?
    );
end CryptoManager;

architecture Behavioural of CryptoManager is

    type State is (waitingITR, waitingMAGICNUMBER, txMAGICNUMBER, txCHAR, waitingACK, waitingACK_EOM);

    signal currentState: State;
    signal lockedCrypto : integer;

begin

    process(clk, rst)

    begin
        if rst = '1' then
            currentState <= waitingITR;

            for i in 0 to CRYPTO_AMOUNT-1 loop
                keyExchange_R8(i) <= '0';
                ack_crypto(i) <= '0';
            end loop;

            lockedCrypto <= 0;
            data_av_R8 <= '0';
            eom_R8 <= '0';

        elsif rising_edge(clk) then

            -- Checks if there is a new request 
            if currentState = waitingITR then
                currentState <= waitingITR; -- Defaults to waitingITR

                for i in 0 to CRYPTO_AMOUNT-1 loop
                    if keyExchange_crypto(i) = '1' then
                        lockedCrypto <= i;                  -- Determines which Crypto to initiate communication (lowest numbered Cryptos have higher priority)
                        data <= data_out_crypto(i);         -- Transmits Crypto's magic number to R8
                        currentState <= waitingMAGICNUMBER; -- Waits for processor acknowledgement
                        exit;                               -- Stop checking for new communication requests
                    end if;
                end loop; -- If no keyExchange is active, holds on waitingITR

            elsif currentState = waitingMAGICNUMBER then

                if ack_R8 = '1' then
                    data_in_crypto(lockedCrypto) <= data;   -- Transmits R8's magic number to locked crypto
                    ack_crypto(lockedCrypto) <= '1';        -- ACK pulse
                    currentState <= txMAGICNUMBER;
                else
                    currentState <= waitingMAGICNUMBER;     -- waits for processor to transmit its magic number
                end if;

            elsif currentState = txMAGICNUMBER then

                ack_crypto(lockedCrypto) <= '0';            -- Completes ACK pulse

                currentState <= txCHAR;

            elsif currentState = txCHAR then
                currentState <= txCHAR;                     -- Defaults to txCHAR

                if data_av_crypto(lockedCrypto) = '1' then
                    data <= data_out_crypto(lockedCrypto);
                    data_av_R8 <= '1';

                    if eom_crypto(lockedCrypto) = '1' then
                        currentState <= waitingACK_EOM;
                    else
                        currentState <= waitingACK;
                    end if;

                end if;
                
            elsif currentState = waitingACK then
                currentState <= waitingACK;

                if ack_R8 = '1' then
                    ack_crypto(lockedCrypto) <= '1';
                    currentState <= txACK;
                end if;

            elsif currentState = txACK then

                ack_crypto(lockedCrypto) <= '0';

                currentState <= txCHAR;

            elsif currentState = waitingACK_EOM then
                currentState <= waitingACK_EOM;

                if ack_R8 = '1' then
                    ack_crypto(lockedCrypto) = '1';
                    currentState <= txACK_EOM;
                end if;

            elsif currentState = txACK_EOM then

                ack_crypto(lockedCrypto) <= '0';

                currentState <= waitingITR;

            end if;
        end if;

    end process;    
    

end architecture Behavioural;