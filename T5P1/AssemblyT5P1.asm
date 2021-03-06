


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O VIA PIC

; APLICAÇÃO ATUAL:
; COMUNICAÇAO COM MULTIPLOS PERIFERICOS "CRYPTOMESSAGE" VIA INTERRUPÇÃO COM PRIORIDADES

; CHANGELOG:
    ;   - Emilio - Adicionado a mascara para interrupção no pic
    ;            - Trocada a ordem dos HANDLERS ( No hdl Estamos usando os menos prioritários)
;

; TODO:
;

; OBSERVAÇÕES:
;   - O parametro ISR_ADDR deve ser setado para 0x"0001" na instanciação do processador na entity top level
;   - Respeitar o padrão de registradores estabelecidos
;   - Novas adições ao código deve ser o mais modular possível
;   - Subrotinas importantes devem começar com letra maiuscula
;   - Subrotinas auxiliares devem começar com letra minuscula e serem identadas com 2 espaços
;   - Instruções devem ser identadas com 4 espaços

; REGISTRADORES:
; --------------------- r0  = 0
; --------------------- r2  = PARAMETRO para subrotina
; --------------------- r3  = PARAMETRO para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

; port_io[8] = Direção dos bits de dados (dataDD) (15 a 8) , 1 = entrada, 0 = saida (out)

; port_io[7] = data[7] (in/out)
; port_io[6] = data[6] (in/out)
; port_io[5] = data[5] (in/out)
; port_io[4] = data[4] (in/out)
; port_io[3] = data[3] (in/out)
; port_io[2] = data[2] (in/out)
; port_io[1] = data[1] (in/out)
; port_io[0] = data[0] (in/out)

; port_io[11] = data_av (in)
; port_io[10] = ack (out)
; port_io[9]  = eom (in)

; port_io[12] = keyExchange CryptoMessage0 (in) Maior prioridade
; port_io[13] = keyExchange CryptoMessage0 (in)
; port_io[14] = keyExchange CryptoMessage0 (in)
; port_io[15] = keyExchange CryptoMessage0 (in) Menor prioridade

.org #0000h

.code

;-----------------------------------------------------BOOT---------------------------------------------------

    jmpd #setup                               ;Sempre primeira instrução do programa
    jmpd #InterruptionServiceRoutine          ;Sempre segunda instrução do programa

;---------------------------------------------CONFIGURAÇÃO INICIAL-------------------------------------------

setup:

;   Inicializa ponteiro da pilha para 0x"7FFF" (ultimo endereço no espaço de endereçamento da memoria)
    ldh r0, #7Fh
    ldl r0, #FFh
    ldsp r0

;   Inicializa ponteiro da pilha para 0x"03E6" (ultimo endereço no espaço de endereçamento da memoria)
;    ldh r0, #03h
;    ldl r0, #E6h
;    ldsp r0

;   Seta endereço do tratador de interrupção
    ldh r0, #InterruptionServiceRoutine
    ldl r0, #InterruptionServiceRoutine
    ldisra r0

    xor r0, r0, r0

;   Seta a Mascara do vetor de interrupções
    ldl r4, #02h   ; Atualiza o indexador para carregar a mascara em arrayPIC

    ldh r7, #arrayPIC   ; Carrega o endereço para o vetor de interrupções
    ldl r7, #arrayPIC   ; Carrega o endereço do vetor de interrupções
    ld r7, r4, r7       ; &mask

    ldh r8, #00h
    ldl r8, #F0h   ; Carrega a Mascara para o PIC [ r8 <= "0000_0000_1111_0000"]

    st r8, r0, r7  ; arrayPIC [MASK] <= "0000_0000_1111_0000"

    ; Array de registradores do controlador de interrupções
    ; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ]
    ;arrayPIC:                 db #80F0h, #80F1h, #80F2h

;   r1 <= &arrayPorta
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1

    xor r4, r4, r4
    
;   Seta PortConfig
    ldl r4, #01h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #FAh   ; r5 <= "11111010_11111111"
    ldl r5, #FFh   ; bits 7 a 0 inicialmente são entrada, espera interrupção
    st r5, r1, r4  ; PortConfig <= "11111010_11111111"

;   Seta irqtEnable
    ldl r4, #03h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #F0h   ; r5 <= "11110000_00000000"
    ldl r5, #00h   ; Habilita a interrupção nos bits 12 a 15
    st r5, r1, r4  ; irqtEnable <= "11110000_00000000"

;   Seta PortEnable
    ldl r4, #02h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #FFh   ; r5 <= "11111111_11111111"
    ldl r5, #FFh   ; Habilita acesso a todos os bits da porta de I/O
    st r5, r1, r4  ; PortEnable <= "11111111_11111111"

;   Seta dataDD como '1', ack como '0'
    ldl r4, #0     ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortData ]
    ldh r5, #01h   ; r5 <= "xxxxx0x1_xxxxxxxx"
    ldl r5, #00h   ; dataDD = '1', ACK = '0'
    st r5, r1, r4  ; portData <= "xxxxx0x1_xxxxxxxx"


;   Inicialização dos registradores
    xor r0, r0, r0
    xor r1, r1, r1
    xor r2, r2, r2
    xor r3, r3, r3
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6
    xor r7, r7, r7
    xor r8, r8, r8
    xor r9, r9, r9
    xor r10, r10, r10
    xor r11, r11, r11
    xor r12, r12, r12
    xor r13, r13, r13
    xor r13, r13, r13
    xor r14, r14, r14
    xor r15, r15, r15


    jmpd #main

; END SETUP
;____________________________________________________________________________________________________________


;-----------------------------------------TRATAMENTO DE INTERRUPÇÃO------------------------------------------

InterruptionServiceRoutine:

; 1. Salvamento de contexto
; 2. Ler do PIC o número da IRQ
; 3. Indexar irq_handlers e gravar em algum registrador o endereço do handler
; 4. jsr reg (chama handler)
; 5. Notificar PIC sobre a IRQ tratada
; 6. Recuperação de contexto
; 7. Retorno (rti)

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

; port_io[8] = Direção dos bits de dados (dataDD) (15 a 8) , 1 = entrada, 0 = saida (out)

; port_io[7] = data[7] (in/out)
; port_io[6] = data[6] (in/out)
; port_io[5] = data[5] (in/out)
; port_io[4] = data[4] (in/out)
; port_io[3] = data[3] (in/out)
; port_io[2] = data[2] (in/out)
; port_io[1] = data[1] (in/out)
; port_io[0] = data[0] (in/out)

; port_io[11] = data_av (in)
; port_io[10] = ack (out)
; port_io[9]  = eom (in)

; port_io[12] = keyExchange CryptoMessage0 (in) Maior prioridade
; port_io[13] = keyExchange CryptoMessage1 (in)
; port_io[14] = keyExchange CryptoMessage2 (in)
; port_io[15] = keyExchange CryptoMessage3 (in) Menor prioridade

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

;-----------------------------------------------Salva contexto-----------------------------------------------
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    pushf

    xor r0, r0, r0
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6

;------------------------------------------Ler ID da interrupção do PIC--------------------------------------

;   r4 <= IrqID
    ldh r4, #arrayPIC
    ldl r4, #arrayPIC
    ld r4, r0, r4 ; r4 <= &IrqID
    ld r4, r0, r4 ; r4 <= IrqID

;   r1 <= &interruptVector
    ldh r1, #interruptVector
    ldl r1, #interruptVector

;   r1 <= interruptVector[IrqID]
    ld r1, r4, r1

;-----------------------------------------------Jump para handler--------------------------------------------

    jsr r1

;-----------------------------------------------Recupera contexto--------------------------------------------

    popf
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0

    rti

; END InterruptionServiceRoutine
;____________________________________________________________________________________________________________



;-------------------------------------------------HANDLERS---------------------------------------------------

irq0Handler: ; OPEN

    halt

irq1Handler: ; OPEN

    halt

irq2Handler: ; OPEN

    halt

irq3Handler: ; OPEN

    halt

irq4Handler: ; CryptoMessage 0

;   Informa qual crypto utilizar ao CryptoManager
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1
    addi r1, #1 ; r1 <= &PortConfig
    
    ldh r5, #FAh
    ldl r5, #00h
    
    st r5, r0, r1 ; Bits de dados como saida
    
    subi r1, #1 ; r1 <= &PortData
    
    ldh r5, #0
    ldl r5, #251
    
    st r5, r0, r1 ; CryptoManager <= ID 0

;   Chama Driver com ID = 0
    xor r2, r2, r2
    jsrd #GenericCryptoDriver
    
;   ACK Interrupçao
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    ld r1, r0, r1 ; r1 <= &irqID
    addi r1, #1   ; r1 <= &itrACK
    
    ldh r5, #0
    ldl r5, #4
    
    st r5, r0, r1
    
    rts

irq5Handler: ; CryptoMessage 1

;   Informa qual crypto utilizar ao CryptoManager
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1
    addi r1, #1 ; r1 <= &PortConfig
    
    ldh r5, #FAh
    ldl r5, #00h
    
    st r5, r0, r1 ; Bits de dados como saida
    
    subi r1, #1 ; r1 <= &PortData
    
    ldh r5, #0
    ldl r5, #252
    
    st r5, r0, r1 ; CryptoManager <= ID 0

;   Chama Driver com ID = 1
    xor r2, r2, r2
    addi r2, #1
    jsrd #GenericCryptoDriver
      
;   ACK Interrupçao
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    ld r1, r0, r1 ; r1 <= &irqID
    addi r1, #1   ; r1 <= &itrACK
    
    ldh r5, #0
    ldl r5, #5
    
    st r5, r0, r1
    
    rts

irq6Handler: ; CryptoMessage 2

;   Informa qual crypto utilizar ao CryptoManager
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1
    addi r1, #1 ; r1 <= &PortConfig
    
    ldh r5, #FAh
    ldl r5, #00h
    
    st r5, r0, r1 ; Bits de dados como saida
    
    subi r1, #1 ; r1 <= &PortData
    
    ldh r5, #0
    ldl r5, #253
    
    st r5, r0, r1 ; CryptoManager <= ID 0

;   Chama Driver com ID = 2
    xor r2, r2, r2
    addi r2, #2
    jsrd #GenericCryptoDriver
    
;   ACK Interrupçao
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    ld r1, r0, r1 ; r1 <= &irqID
    addi r1, #1   ; r1 <= &itrACK
    
    ldh r5, #0
    ldl r5, #6
    
    st r5, r0, r1
    
    rts

irq7Handler: ; CryptoMessage 3

;   Informa qual crypto utilizar ao CryptoManager
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1
    addi r1, #1 ; r1 <= &PortConfig
    
    ldh r5, #FAh
    ldl r5, #00h
    
    st r5, r0, r1 ; Bits de dados como saida
    
    subi r1, #1 ; r1 <= &PortData
    
    ldh r5, #0
    ldl r5, #254
    
    st r5, r0, r1 ; CryptoManager <= ID 0

;   Chama Driver com ID = 3
    xor r2, r2, r2
    addi r2, #3
    jsrd #GenericCryptoDriver
    
;   ACK Interrupçao
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    ld r1, r0, r1 ; r1 <= &irqID
    addi r1, #1   ; r1 <= &itrACK
    
    ldh r5, #0
    ldl r5, #7
    
    st r5, r0, r1
    
    rts

;-------------------------------------------------DRIVERS----------------------------------------------------


GenericCryptoDriver: ; Espera como parametro o ID do CryptoMessage interrompente em r2

; 1. CryptoMessage ativa keyExchange e coloca no barramento data_out seu magicNumber
; 2. R8 lê o magicNumber e calcula o seu magicNumber
; 3. R8 coloca o seu magicNumber no barramento data_in do CryptoMessage e gera um pulso em ack. Feito isso, ambos calculam a chave criptografica.
; 4. CryptoMessage coloca um caracter da mensagem criptografado no barramento data_out e ativa data_av
; 5. R8 lê o caracter e gera um pulso em ack

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ESTADO 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    push r1
    push r4
    push r5
    push r6

    xor r0, r0, r0
    xor r1, r1, r1
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ESTADO 2 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   r1 <= &PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1

;   Seta PortConfig
    ldl r4, #01h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #FAh   ; r5 <= "11111010_11111111"
    ldl r5, #FFh   ; bits 15 a 8 inicialmente são entrada, espera keyExchange
    st r5, r1, r4  ; PortConfig <= "11111111_0xxx1101"

;   Set data direction as IN ( ack = 0, dataDD = 1 )
    ldh r5, #01h
    ldl r5, #00h
    st r5, r0, r1 ; portData <= "xxxxx0x1_xxxxxxxx"

;   r1 <= &PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1

;   r5 <= PortData
    ld r5, r0, r1

;   Apaga parte alta dos dados lidos ( r5 <= "00000000" & magicNumberCrypto )
    ldh r5, #0

;   Carrega endereço da variavel magicNumberCryptoMessage
    ldh r1, #magicNumberCryptoMessage
    ldl r1, #magicNumberCryptoMessage

;   Salva magicNumber do periférico na variavel magicNumberCryptoMessage
    st r5, r0, r1

;   Calcula magicNumber do processador (dado disponivel em r14)
    jsrd #CalculaMagicNumberR8

;   Salva magicNumber do processador
    ldh r1, #magicNumberR8
    ldl r1, #magicNumberR8 ; r1 <= &magicNumberR8
    add r5, r0, r14        ; r5 <= magicNumberR8
    st r5, r0, r1          ; Salva magicNumberR8 em memoria

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ESTADO 3 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   Set data direction as OUT
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1        ; r1 <= &portData

;   r5 <= "xxxxx0x0_xxxxxxxx" (Disables Tristate)
    ldh r5, #00h
    ldl r5, #00h

    st r5, r0, r1

;   Seta em portConfig a direção dos dados como saída
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    addi r1, #1
    ld r1, r0, r1        ; r1 <= &portConfig

    ldh r5, #FAh
    ldl r5, #00h

    st r5, r0, r1        ; portConfig <= ("11111010_00000000")

;   Prepara dado para escrita
    ldh r1, #magicNumberR8
    ldl r1, #magicNumberR8
    ld r5, r0, r1

;   Seta ack para '1', dataDD para '0' (saida)
    ldh r5, #04h ; r5 <= "xxxxx1x0" & magicNumberR8

;   Carrega endereço de PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1        ; r1 <= &portData

;   Transmite p/ porta magicNumberR8, sinaliza dataDD = OUT, ack = '1'
    st r5, r0, r1 ; r5 <= "xxxxx1x0_(magicnumberR8)"

;   Transmite ACK = '0'
    st r0, r0, r1

;   Seta bits de dados novamente como entrada
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    addi r1, #1
    ld r1, r0, r1        ; r1 <= &portConfig

;   Seta bits de dados novamente como entrada
    ldh r5, #FAh
    ldl r5, #FFh
    st r5, r0, r1        ; r5 <= "11111010_11111111"

;   Seta dataDD como entrada (dataDD = '1', ack = '0')
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1        ; r1 <= &portData

    ldh r5, #01h
    ldl r5, #00h
    st r5, r0, r1        ; r5 <= "xxxx_x0x1_xxxx_xxxx"

;   Seta argumento para calculo da chave criptografica (r2 <= magicNumberCryptoMessage)
    ldh r1, #magicNumberCryptoMessage
    ldl r1, #magicNumberCryptoMessage
    ld r2, r0, r1

;   Calcula chave criptografica
    jsrd #CalculaCryptoKey

;   Salva chave criptografica
    ldh r1, #cryptoKey
    ldl r1, #cryptoKey
    st r14, r0, r1       ; Salva chave criptografica em memoria

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ESTADO 4 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollingLoop: ; Espera próximo sinal de data_av = '1'

;   Seta bits de dados como entrada
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    addi r1, #1
    ld r1, r0, r1        ; r1 <= &portConfig

;   Seta bits de dados novamente como entrada
    ldh r5, #FAh
    ldl r5, #FFh
    st r5, r0, r1        ; r5 <= "11111010_11111111"

;   Seta dataDD como entrada (dataDD = '1', ack = '0')
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1        ; r1 <= &portData

    ldh r5, #01h
    ldl r5, #00h
    st r5, r0, r1        ; r5 <= "xxxx_xxx1_xxxx_xxxx"

;   r1 <= &PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1

;   r5 <= PortData
    ld r5, r0, r1

;   Carrega mascara de comparação para bit 11 (data_av)
    ldh r6, #08h
    ldl r6, #00h         ; r6 <= "00001000_00000000"

;   Se operação com mascara resultar em 0, coloca caracter no array criptografado e descriptografado
    and r1, r5, r6
    sub r6, r6, r1
    jmpzd #callLeCaracter

 returncallLeCaracter:

;   Carrega mascara de comparação para bit 9 (eom)
    ldh r6, #02h
    ldl r6, #00h         ; r6 <= "00000010_00000000"

;   Se operação com mascara resultar em 0, retorna da subrotina de driver p/ ISR, else, espera novo caracter
    and r1, r5, r6
    sub r6, r6, r1
    jmpzd #returnPollingLoop

    jmpd #PollingLoop

  returnPollingLoop:

;   Incrementa contador de mensagens
    ldh r1, #contadorMSGS
    ldl r1, #contadorMSGS

;   r5 <= contadorMSGS
    ld r5, r0, r1

;   Compara contador com 251, se for igual, volta para 0, se nao, incrementa
    ldh r1, #00h
    ldl r1, #251

    sub r1, r5, r1
    jmpzd #contadorMSGSld0

    addi r5, #1

  returncontadorMSGSld0:

    ldh r1, #contadorMSGS
    ldl r1, #contadorMSGS

;   Stores new value of message counter
    st r5, r0, r1

;   Resets CryptoPointer
    ldh r1, #arrayCryptoPointer
    ldl r1, #arrayCryptoPointer
    ld r1, r2, r1 ; r1 <= &CryptoPointer(irqID)
    st r0, r0, r1 ; CryptoPointer(irqID) <= 0

    pop r6
    pop r5
    pop r4
    pop r1

    rts

  contadorMSGSld0:
    xor r5, r5, r5
    jmpd #returncontadorMSGSld0

  callLeCaracter:
    jsrd #LeCaracter
    jmpd #returncallLeCaracter
    
;-------------------------------------------- Funções do Kernel ---------------------------------------------

PrintString: ; Espera endereço da string a ser enviada em r2

; Tabela de registradores:
; r1 = Endereço do transmissor serial
; r3 = Indexador da string do inteiro convertido (buffer)
; r5 = Dado a ser transmitido

    push r1
    push r3
    push r5

    ldh r1, #UART_TX
    ldl r1, #UART_TX
    ld r1, r0, r1
    
    xor r0, r0, r0
    xor r3, r3, r3
    xor r5, r5, r5
    
  tx_loop:
    
;   r5 <= status do tx
    ld r5, r0, r1
    add r5, r0, r5 ; Gera flag
  
    jmpzd #tx_loop ; Espera transmissor estar disponivel
    
;   r5 <= string[r3]
    ld r5, r3, r2
    add r5, r0, r5 ; Gera flag
    
;   Se string[r3] = 0 (terminador de string), volta para caller
    jmpzd #PrintStringReturn
    
;   UART TX <= r5
    st r5, r0, r1
    
;   Incrementa indice
    addi r3, #1
    
;   Transmite proximo caracter
    jmpd #tx_loop
    
PrintStringReturn:
    
    pop r5
    pop r3
    pop r1
    
    rts

IntegerToString: ; Espera inteiro a ser convertido em r2, retorna ponteiro para string em r14
; https://stackoverflow.com/questions/7123490/how-compiler-is-converting-integer-to-string-and-vice-versa

; Tabela de registradores:
; r2 = Inteiro a ser convertido
; r3 = Contador de pushes
; r4 = Contador de pops
; r5 = Dado a ser gravado na memoria
; r10 = Constante 10
; r11 = Resto da divisao por 10

    push r2
    push r3
    push r4
    push r5
    push r10
    push r11
    
    xor r0, r0, r0
    xor r2, r2, r2
    xor r3, r3, r3
    xor r4, r4, r4
    xor r10, r10, r10
    xor r11, r11, r11
    
    ldl r10, #10
    
    ldh r14, #IntegerToStringBuffer
    ldl r14, #IntegerToStringBuffer
    
    addi r3, #8
    
;   Limpa o buffer
  limpaBufferLoop:
    
;   buffer[r3] <= 0
    st r0, r3, r14
    
;   Decrementa indice do buffer
    subi r3, #1
    
;   Limpa proxima posição do buffer
    jmpnd #IntegerToStringStart
    jmpd #limpaBufferLoop
    
IntegerToStringStart:
    
    xor r3, r3, r3
    
    add r2, r0, r2 ; Gera flag
    
    jmpnd #IntegerToStringNegativo
    jmpzd #IntegerToStringZero
    jmpd #IntegerToStringPositivo
      
ConversionLoop:

;   r2 <= r2 / 10, r11 <= r2 % 10
    div r2, r10
    mfh r11
    mfl r2
    
;   r11 <= char[r11]
    addi r11, #48

;   Salva r11 na pilha (string será reordenada)
    push r11
    
;   Incrementa contador de pushes
    addi r3, #1

;   Gera Flag
    add r2, r0, r2
    
    jmpzd #ReverseLoop
    jmpd #ConversionLoop

ReverseLoop:
    
    pop r5
    
    st r5, r4, r14
    
    addi r4, #1
    
    sub r5, r3, r4
    
    jmpzd #IntegerToStringReturn
    jmpd #ReverseLoop
    
IntegerToStringReturn:

    subi r1, #1
    
    pop r11
    pop r10
    pop r5
    pop r4
    pop r3
    pop r2
    
    rts
    
IntegerToStringZero:
    
;   r5 <= '0'   
    ldh r5, #0
    ldl r5, #48

;   Buffer[0] <= '0'
    st r5, r3, r14
    
;   Retorna para caller
    pop r11
    pop r10
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    
    rts
    
IntegerToStringNegativo:

;   r2 <= Inteiro a ser convertido passa a ser positivo
    not r2, r2
    addi r2, #1
    
;   r5 <= '-'
    ldh r5, #0
    ldl r5, #45
    
;   Grava sinal negativo na primeira posição do buffer
    st r5, r0, r14
    
;   Incrementa ponteiro da string
    addi r14, #1
    
;   Retorna para codigo de conversão
    jmpd #ConversionLoop
    
IntegerToStringPositivo:

;   r5 <= '+'
    ldh r5, #0
    ldl r5, #43
    
;   Grava sinal positivo na primeira posição do buffer
    st r5, r0, r14
    
;   Incrementa ponteiro do buffer
    addi r14, #1
    
;   Retorna para codigo de conversão
    jmpd #ConversionLoop


;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------

main:

;; BUBBLE SORT DO CARARA

;* Bubble sort

;*      Sort array in ascending order
;*
;*      Used registers:
;*          r1: points the first element of array
;*          r2: temporary register
;*          r3: points the end of array (right after the last element)
;*          r4: indicates elements swaping (r4 = 1)
;*          r5: array index
;*          r6: array index
;*          r7: element array[r5]
;*          r8: element array[r8]
;*          r9: send count
;*          r10: array size
;*          r11: transmission count
;*
;*********************************************************************

BubbleSort:

    ;halt ; DEBUG, ignora bubble sort

    ; Initialization code
    xor r0, r0, r0          ; r0 <- 0
    xor r11, r11, r11       ; r11 <- 0

    ldh r1, #arraySort      ;
    ldl r1, #arraySort      ; r1 <- &array

    ldh r2, #arraySortSize  ;
    ldl r2, #arraySortSize  ; r2 <- &size
    ld r2, r2, r0           ; r2 <- size
    add r10, r0, r2         ; r10 <- size (to be used on Serial Transmission)

    add r3, r2, r1          ; r3 points the end of array (right after the last element)

    ldl r4, #0              ;
    ldh r4, #1              ; r4 <- 1
    
; Converts array to char and transmits via UART
TX_ARRAY_INICIAL:
    
;   Loops for 50 iterations on IntegerToString function
    
    ld r2, r11, r1          ; r2 <- arraySort[transmissionCount]
    
    jsrd #IntegerToString   ; Converts integer to string
    
    add r2, r0, r14         ; r2 <- Pointer to converted string
    jsrd #PrintString       ; Prints string on UART transmiter
    
    addi r11, #1            ; Increments transmission count
    
    sub r5, r10, r11        ; If transmission count == array size, breaks loop, else iterates again
    
    jmpzd #scan
    jmpd #TX_ARRAY_INICIAL    
    
; Main code
scan:
    addi r4, #0             ; Verifies if there was element swapping
    jmpzd #TX_ARRAY_FINAL   ; If r4 = 0 then no element swapping

    xor r4, r4, r4          ; r4 <- 0 before each pass

    add r5, r1, r0          ; r5 points the first array element

    add r6, r1, r0          ;
    addi r6, #1             ; r6 points the second array element

; Read two consecutive elements and compares them
loop:
    ld r7, r5, r0           ; r7 <- array[r5]
    ld r8, r6, r0           ; r8 <- array[r6]
    sub r2, r8, r7          ; If r8 > r7, negative flag is set
    jmpnd #swap             ; (if array[r5] > array[r6] jump)

; Increments the index registers and verifies if the pass is concluded
continue:
    addi r5, #1             ; r5++
    addi r6, #1             ; r6++

    sub r2, r6, r3          ; Verifies if the end of array was reached (r6 = r3)
    jmpzd #scan             ; If r6 = r3 jump
    jmpd #loop              ; else, the next two elements are compared

; Swaps two array elements (memory)
swap:
    st r7, r6, r0           ; array[r6] <- r7
    st r8, r5, r0           ; array[r5] <- r8
    ldl r4, #1              ; Set the element swapping (r4 <- 1)
    jmpd #continue

; Converts array to char and transmits via UART
TX_ARRAY_FINAL:
    
;   Loops for 50 iterations on IntegerToString function
    
    ld r2, r1, r11          ; r2 <- arraySort[transmissionCount]
    
    jsrd #IntegerToString   ; Converts integer to string
    
    add r2, r0, r14         ; r2 <- Pointer to converted string
    jsrd #PrintString       ; Prints string on UART transmiter
    
    addi r11, #1            ; Increments transmission count
    
    sub r5, r10, r11        ; If transmission count == array size, breaks loop, else iterates again
    
    jmpzd #halt_bubbleSort
    jmpd #TX_ARRAY_FINAL
    
halt_bubbleSort:

    halt                    ; Suspend the execution


;------------------------------------------------SUBROTINAS--------------------------------------------------

; CalculaMagicNumberR8:       DONE
; CalculaCryptoKey:           DONE
; GeraACK:                    DONE
; LeCaracter:            TODO (Enviar para UART)

CalculaMagicNumberR8: ; Retorna em r14 o magicNumber do processador


    ; MagicNumberR8 = a^x * mod q
    ; MagicNumberR8 = 6^x * mod 251

    push r4 ; 251
    push r5 ; x ou Seed
    push r6 ; 6
    push r7 ; Mascara de bit (overflow)
    push r12 ; Temporario
    push r13 ; Temporario

    xor r14, r14, r14 ; Zera o valor de retorno
    addi r14, #01 ; Retorno <= 1

    ldh r4, #00h
    ldl r4, #FBh ; r4 < 251

    ; Carrega a seed
    ldh r5, #contadorMSGS
    ldl r5, #contadorMSGS
    ld r5, r0, r5 ; Carrega o Valor do Contador msg para r5

    ldh r6, #00h
    ldl r6, #06h ; carreaga Seis

    ldh r7, #00h
    ldl r7, #80h ; Mascara [ 0000 0000 1000 0000]

    ; Verifica se a seed é menor que 251
    sub r6, r4, r5   ; Realiza (251 - Seed )
    jmpnd #SeedInvalida
    jmpzd #SeedInvalida  ; caso a seed for Negativa ou Zero

    xor r6, r6, r6
    addi r6, #06h

    addi r5, #00h ; Caso a seed esteja igual a zero
    jmpd #calculoExponencial

  SeedInvalida:
    xor r5, r5, r5 ; Zera a Seed
    jmpd #calculoExponencial

  calculoExponencial: ; DEBUG - r14 sendo atualizado com r6

    jmpzd #retornaMagicNumber

    mul r14, r14
    mfl r14 ;   r14 <= r14^2

    div r14, r4
    mfh r14 ; r14 <= r14^2 mod q

    and r13, r7, r14 ; Comparacao da mascara

    jmpzd #shiftAndJump

  calculoMod:
    mul r14, r6
    mfl r14 ; r14 <= r14 * 6
    div r14, r4
    mfh r14 ; r14 <= r14 * 6 mod 251

  shiftAndJump:
    sr0  r7, r7 ; Shift da mascara
    jmpd #calculoExponencial


  retornaMagicNumber:
    pop r13
    pop r12
    pop r7
    pop r6
    pop r5
    pop r4
    rts


CalculaCryptoKey: ; Retorna em r14 chave criptografica, recebe em r2 magic number do periferico (Se magicNumber = 0, retorna 1)
    ; KEY = a^b mod q
    ; KEY =  MagicNumberR8 ^ magicNumberFromCrypto * mod q
	; Se da pelo calculo de Key = magicNumberR8^magicNumberFromCrypto mod q
    ;push r2 ; magicNumberFromCrypto
	push r3 ; magicNumberR8
    push r4 ; 251
    push r5 ; Mascara
    push r6 ; Seed
    push r13 ; temporario

    ldh r3, #magicNumberR8
    ldl r3, #magicNumberR8
    ld r3, r0, r3   ; r3 <= magicNumberR8

    ldh r4, #00h
	ldl r4, #FBh  ; r3 <= 251

    ldh r5, #00h
    ldl r5, #80h ; Mascara [ 0000 0000 1000 0000]


    ldh r6, #contadorMSGS
    ldl r6, #contadorMSGS
    ld r6, r0, r6 ; Carrega o Valor do Contador msg para r6

    xor r14, r14, r14  ; Zera a key

    add r2, r0, r2
    jmpzd #calculaCryptoKeyRetornaZero ; Se magicNumberFromCrypto == 0, retorna 1

    addi r14, #1    ; Precisa estar em um pra realizar exp
    ;add r14, r3, r0   ; recebe o numero do magicNumberR8
;;-----
    addi r6, #00h ; Caso a seed esteja igual a zero
    jmpd #calculoExponencialKey

  calculoExponencialKey:
    jmpzd #retornaCalculaCryptoKey

    mul r14, r14
    mfl r14 ;   r14 <= r14^2
    div r14, r4
    mfh r14 ; r14 <= r14^2 mod q

    and r13, r5, r2 ; Comparacao da mascara
    jmpzd #shiftAndJumpKey

  calculoModKey:
    mul r14, r6
    mfl r14 ; r14 <= r14 * magicNumberR8 |
    div r14, r4
    mfh r14 ; r14 <= r14 * magicNumberR8 mod 251

  shiftAndJumpKey:
    sr0  r5, r5 ; Shift da mascara
    jmpd #calculoExponencialKey

  calculaCryptoKeyRetornaZero:
    addi r14, #1
    jmpd #retornaCalculaCryptoKey

  retornaCalculaCryptoKey:
    pop r13
    pop r6
    pop r5
    pop r4
	pop r3
    ;pop r2
	rts

GeraACK:              ; Envia pulso de ACK

    push r1
    push r5
    push r6

    xor r0, r0, r0
    xor r1, r1, r1
    xor r5, r5, r5
    xor r6, r6, r6

;   r1 <= &portConfig
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    addi r1, #1
    ld r1, r0, r1       ; Carrega &portConfig

;   r5 <= (Bits de dados como entrada, dataDD saida, outros de acordo)
    ldh r5, #FAh
    ldl r5, #FFh
    st r5, r0, r1

;   r1 <= &portData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1

;   r5 <= dataDD = '1', ACK = '1'
    ldh r5, #05h
    ldl r5, #00h

;   r6 <= dataDD = '1', ACK = '0'
    ldh r6, #01h
    ldl r6, #00h

;   portData <= dataDD = '1', ACK = '1'
    st r5, r1, r0

;   portData <= dataDD = '1', ACK = '0''
    st r6, r1, r0

    pop r6
    pop r5
    pop r1

    rts

LeCaracter:           ; Le caracter atual da porta, salva nos arrays, incrementa ponteiro p/ arrays
                      ; Espera ID do CryptoMessage interrompente em r2 (para gravar caracter atual no array correspondente)

    push r1
    push r4
    push r5
    push r6

    xor r0, r0, r0
    xor r1, r1, r1
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6

;   r1 <= &portConfig
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    addi r1, #1
    ld r1, r0, r1       ; Carrega &portConfig

;   r5 <= (Bits de dados como entrada, dataDD como saida, outros de acordo)
    ldh r5, #FAh
    ldl r5, #FFh
    st r5, r0, r1

;   r1 <= &portData
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1       ; Carrega &portData

;   r5 <= dataDD = IN, ACK = 0 (Habilita Tristate)
    ldh r5, #01h
    ldl r5, #00h
    st r5, r0, r1

;   r5 <= PortData
    ld r5, r0, r1

;   r1 <= arrayEncrypted[irqID]
    ldh r1, #arrayDecrypted
    ldl r1, #arrayDecrypted
    ld r1, r2, r1  ; r1 <= arrayEncrypted(0, 1, 2 ou 3)

;   r4 <= cryptoPointer
    ldh r4, #arrayCryptoPointer
    ldl r4, #arrayCryptoPointer
    ld r4, r2, r4

;   Carrega chave de criptografia
    ldh r6, #cryptoKey
    ldl r6, #cryptoKey
    ld r6, r0, r6

;   Descriptografa dado
    xor r5, r6, r5

;   Zera bit não relevantes
    ldh r6, #0
    ldl r6, #7Fh ; r6 <= "00000000_01111111"
    and r5, r5, r6

;   Salva caracter na string a ser enviada
    ldh r1, #CharString 
    ldl r1, #CharString 
    st r5, r0, r1
    
;   Seta argumento para PrintString
    add r2, r0, r1
    
;   Envia caracter para transmissor serial
    jsrd #PrintString

;   Gera ACK
    jsrd #GeraACK

    pop r6
    pop r5
    pop r4
    pop r1

    rts

.endcode

;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================


;; .org #0300h
.data

; Array de registradores da Porta Bidirecional
; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta:               db #8000h, #8001h, #8002h, #8003h

; Array de registradores do controlador de interrupções
; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ]
arrayPIC:                 db #80F0h, #80F1h, #80F2h

; Endereço do transmissor serial
UART_TX:                  db #8080h

; Vetor com tratadores de interrupção
interruptVector:          db #irq0Handler, #irq1Handler, #irq2Handler, #irq3Handler, #irq4Handler, #irq5Handler, #irq6Handler, #irq7Handler

; IntegerToString
IntegerToStringBuffer:    db #0, #0, #0, #0, #0, #0, #0, #0

; Primeira posição deve ser o caracter a ser enviado, segunda posição deve ser o terminador de string 
CharString:               db #0, #0

; Variaveis p/ criptografia
magicNumberR8:            db #0000h
magicNumberCryptoMessage: db #0000h
cryptoKey:                db #0000h
contadorMSGS:             db #0000h ; Novo seed para geração de magic number

; Arrays a serem indexados com ID da interrupção
arrayDecrypted:           db #arrayDecrypted0, #arrayDecrypted1, #arrayDecrypted2, #arrayDecrypted3
arrayCryptoPointer:       db #CryptoPointer0, #CryptoPointer1, #CryptoPointer2, #CryptoPointer3
arraySaveHighLow:         db #SaveHighLow0, #SaveHighLow1, #SaveHighLow2, #SaveHighLow3

; Variaveis CryptoMessage 0
CryptoPointer0:           db #0000h
arrayDecrypted0:          db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h
saveHighLow0:             db #0001h ; Se = 0, salva caracter na parte baixa, se = 1 salva na parte alta

; Variaveis CryptoMessage 1
CryptoPointer1:           db #0000h
arrayDecrypted1:          db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h
saveHighLow1:             db #0001h ; Se = 0, salva caracter na parte baixa, se = 1 salva na parte alta

; Variaveis CryptoMessage 2
CryptoPointer2:           db #0000h
arrayDecrypted2:          db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h
saveHighLow2:             db #0001h ; Se = 0, salva caracter na parte baixa, se = 1 salva na parte alta

; Variaveis CryptoMessage 3
CryptoPointer3:           db #0000h
arrayDecrypted3:          db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h
saveHighLow3:             db #0001h ; Se = 0, salva caracter na parte baixa, se = 1 salva na parte alta

; Array para aplicação principal (Bubble Sort) de 50 elementos
; Starts in 919 ends 968
arraySort:                db #0050h, #0049h, #0048h, #0047h, #0046h, #0045h, #0044h, #0043h, #0042h, #0041h, #0040h, #0039h, #0038h, #0037h, #0036h, #0035h, #0034h, #0033h, #0032h, #0031h, #0030h, #0029h, #0028h, #0027h, #0026h, #0025h, #0024h, #0023h, #0022h, #0021h, #0020h, #0019h, #0018h, #0017h, #0016h, #0015h, #0014h, #0013h, #0012h, #0011h, #0010h, #0009h, #0008h, #0007h, #0006h, #0005h, #0004h, #0003h, #0002h, #0001h

; Tamanho do array p/ bubble sort (50 elementos)
; Position 969
arraySortSize:            db #50

.enddata
