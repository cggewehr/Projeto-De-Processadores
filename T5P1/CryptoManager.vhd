library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package CryptoManagerPkg is
    constant CRYPTO_AMOUNT : integer := 4; 
    constant DATA_WIDTH : integer := 8; 
    constant WAIT_COUNT : integer := 400; 
    type DataArray is array (integer range 0 to CRYPTO_AMOUNT-1 ) of std_logic_vector(DATA_WIDTH-1 downto 0);
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
        dataDD              : in std_logic;

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

    type State is (waitingID, waitingMAGICNUMBER, txMAGICNUMBER, txCHAR, waitingACK, waitingACK_EOM, txACK, txACK_EOM);

    signal currentState: State;
    signal lockedCrypto : integer;

begin

    process(clk, rst)

        variable counter: integer := 0;

    begin

        if rst = '1' then
            currentState <= waitingID;

            for i in 0 to CRYPTO_AMOUNT-1 loop
                ack_crypto(i) <= '0';
            end loop;

            lockedCrypto <= CRYPTO_AMOUNT;
            data_av_R8 <= '0';
            eom_R8 <= '0';

        elsif rising_edge(clk) then

            -- Checks if there is a new request
            if currentState = waitingID then

                data_av_R8 <= '0';
                eom_R8 <= '0';

                if unsigned(data_in_R8) >= 251 and dataDD = '0' then
                    lockedCrypto <= to_integer(unsigned(data_in_R8)) - 251;
                    data_out_R8 <= data_out_crypto( to_integer(unsigned(data_in_R8)) - 251);
                    currentState <= waitingMAGICNUMBER;
                else
                    lockedCrypto <= CRYPTO_AMOUNT;
                    currentState <= waitingID;
                end if;

                --for i in 0 to CRYPTO_AMOUNT-1 loop
                --    if keyExchange_crypto(i) = '1' then
                --        lockedCrypto <= i;                      -- Determines which Crypto to initiate communication (lowest numbered Cryptos have higher priority)
                --        data_out_R8 <= data_out_crypto(i);      -- Transmits Crypto's magic number to R8
                --        currentState <= waitingMAGICNUMBER;     -- Waits for processor acknowledgement
                --        exit;                                   -- Stop checking for new communication requests
                --    end if;
                --end loop; 

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
                    currentState <= waitingID;
                else
                    currentState <= txACK_EOM;
                end if;

            end if;
            
        end if;

    end process;    

end architecture Behavioural;