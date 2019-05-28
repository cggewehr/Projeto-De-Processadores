library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CryptoManagerPkg is
    constant CRYPTO_AMOUNT : natural := 4; 
    constant DATA_WIDTH : natural := 8; 
    constant WAIT_COUNT : natural := 400; 
    type DataArray is array (natural range 0 to CRYPTO_AMOUNT-1 ) of std_logic_vector(DATA_WIDTH-1 downto 0);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CryptoManagerPkg.all;

entity CryptoManager is
    port(
        --Basic
        clk                 : in std_logic;
        rst                 : in std_logic;

        -- Processor Interface
        data_in_R8          : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_R8         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_av_R8          : out std_logic;
        ack_R8              : in std_logic;
        eom_R8              : out std_logic;      

        -- CryptoMessage Interface
        keyExchange_crypto  : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        data_av_crypto      : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        ack_crypto          : out std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        eom_crypto          : in std_logic_vector(CRYPTO_AMOUNT-1 downto 0);
        data_in_crypto      : out DataArray;
        data_out_crypto     : in DataArray
    );
end CryptoManager;

architecture Behavioural of CryptoManager is

    type State is (waitingITR, waitingMAGICNUMBER, txMAGICNUMBER, txCHAR, waitingACK, waitingACK_EOM, txACK, txACK_EOM);

    signal currentState: State;
    signal lockedCrypto : integer;

begin

    process(clk, rst)

        variable counter: natural := 0;

    begin

        if rst = '1' then
            currentState <= waitingITR;

            for i in 0 to CRYPTO_AMOUNT-1 loop
                ack_crypto(i) <= '0';
            end loop;

            lockedCrypto <= 0;
            data_av_R8 <= '0';
            eom_R8 <= '0';

        elsif rising_edge(clk) then

            -- Checks if there is a new request 
            if currentState = waitingITR then
                currentState <= waitingITR; -- Defaults to waitingITR

                data_av_R8 <= '0';
                eom_R8 <= '0';

                for i in 0 to CRYPTO_AMOUNT-1 loop
                    if keyExchange_crypto(i) = '1' then
                        lockedCrypto <= i;                      -- Determines which Crypto to initiate communication (lowest numbered Cryptos have higher priority)
                        data_out_R8 <= data_out_crypto(i);      -- Transmits Crypto's magic number to R8
                        currentState <= waitingMAGICNUMBER;     -- Waits for processor acknowledgement
                        exit;                                   -- Stop checking for new communication requests
                    end if;
                end loop; -- If no keyExchange is active, holds on waitingITR

            elsif currentState = waitingMAGICNUMBER then

                if ack_R8 = '1' then
                    data_in_crypto(lockedCrypto) <= data_in_R8; -- Transmits R8's magic number to locked crypto
                    ack_crypto(lockedCrypto) <= '1';            -- ACK pulse
                    currentState <= txMAGICNUMBER;
                else
                    currentState <= waitingMAGICNUMBER;         -- waits for processor to transmit its magic number
                end if;

            elsif currentState = txMAGICNUMBER then

                if ack_R8 = '0' then
                    ack_crypto(lockedCrypto) <= '0';            -- Completes ACK pulse
                    currentState <= txCHAR;
                else 
                    currentState <= txMAGICNUMBER;
                end if;

            elsif currentState = txCHAR then

                if data_av_crypto(lockedCrypto) = '1' then
                    data_out_R8 <= data_out_crypto(lockedCrypto);
                    data_av_R8 <= '1';

                    if eom_crypto(lockedCrypto) = '1' then
                        currentState <= waitingACK_EOM;
                        eom_R8 <= '1';
                    else
                        currentState <= waitingACK;
                        eom_R8 <= '0';
                    end if;

                else
                    currentState <= txCHAR;                     -- Defaults to txCHAR
                    data_av_R8 <= '0';
                    eom_R8 <= '0';
                end if;
                
            elsif currentState = waitingACK then

                if ack_R8 = '1' then
                    ack_crypto(lockedCrypto) <= '1';
                    currentState <= txACK;
                else
                    currentState <= waitingACK;
                end if;

            elsif currentState = txACK then

                if ack_R8 = '0' then
                    ack_crypto(lockedCrypto) <= '0';
                    currentState <= txCHAR;
                else
                    currentState <= txACK;
                end if;

            elsif currentState = waitingACK_EOM then

                if ack_R8 = '1' then
                    ack_crypto(lockedCrypto) <= '1';
                    currentState <= txACK_EOM;
                else
                    currentState <= waitingACK_EOM;
                end if;

            elsif currentState = txACK_EOM then

                if ack_R8 = '0' then
                    ack_crypto(lockedCrypto) <= '0';
                    currentState <= waitingITR;
                else
                    currentState <= txACK_EOM;
                end if;

            end if;
            
        end if;

    end process;    

end architecture Behavioural;