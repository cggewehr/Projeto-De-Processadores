


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O VIA PIC E TRAPS

; APLICAÇÃO ATUAL:
; TESTE SYSCALL "READ"

; CHANGELOG:
;

; TODO:
;

; OBSERVAÇÕES:
;   - Respeitar o padrão de registradores estabelecidos
;   - Novas adições ao código deve ser o mais modular possível
;   - Subrotinas importantes devem começar com letra maiuscula
;   - Subrotinas auxiliares devem começar com letra minuscula e serem identadas com 2 espaços
;   - Instruções devem ser identadas com 4 espaços

; REGISTRADORES:
; --------------------- r0  = 0
; --------------------- r1  = SYSCALL ID
; --------------------- r2  = Parametro para subrotina
; --------------------- r3  = Parametro para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

; irq[7] = port_io[15] = DISABLED
; irq[6] = port_io[14] = DISABLED
; irq[5] = ṕort_io[13] = DISABLED
; irq[4] = ṕort_io[12] = DISABLED
; irq[3] = OPEN
; irq[2] = OPEN
; irq[1] = UART RX DATA AV
; irq[0] = OPEN

; port_io[15] = OPEN
; port_io[14] = OPEN
; port_io[13] = OPEN
; port_io[12] = OPEN
; port_io[11] = OPEN
; port_io[10] = OPEN
; port_io[9] = OPEN
; port_io[8] = OPEN
; port_io[7] = OPEN
; port_io[6] = OPEN
; port_io[5] = OPEN
; port_io[4] = OPEN
; port_io[3] = OPEN
; port_io[2] = OPEN
; port_io[1] = OPEN
; port_io[0] = OPEN

.org #0000h

.code

;-----------------------------------------------------BOOT---------------------------------------------------

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

;   Seta endereço do tratador de traps
    ldh r0, #TrapsServiceRoutine
    ldl r0, #TrapsServiceRoutine
    ldtsra r0

    xor r0, r0, r0

;   Seta a Mascara do vetor de interrupções (Desabilita todas)
    ldl r4, #02h   ; Atualiza o indexador para carregar a mascara em arrayPIC

    ldh r7, #arrayPIC   ; Carrega o endereço para o vetor de interrupções
    ldl r7, #arrayPIC   ; Carrega o endereço do vetor de interrupções
    ld r7, r4, r7       ; &mask

    ldh r8, #00h
    ldl r8, #02h   ; Carrega a Mascara para o PIC [ r8 <= "0000_0000_0000_0010"]

    st r8, r0, r7  ; arrayPIC [MASK] <= "xxxx_xxxx_0000_0010"

; Array de registradores do controlador de interrupções
; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ] IrqREG(0x80F3) ]
; arrayPIC:                 db #80F0h, #80F1h, #80F2h, #80F3h

;   r1 <= &arrayPorta
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1

    xor r4, r4, r4

;   Seta todos os bits de PortConfig como entrada
    ldl r4, #01h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #FFh   ; r5 <= "11111111_11111111"
    ldl r5, #FFh   ; Seta todos os bits de PortConfig como entrada
    st r5, r1, r4  ; PortConfig <= "11111111_11111111"

;   Desabilita interrupções
    ldl r4, #03h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h   ; Desabilita interrupções
    st r5, r1, r4  ; irqtEnable <= "00000000_00000000"

;   Desabilita portas
    ldl r4, #02h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h   ; Desabilita todos os bits da porta de I/O
    st r5, r1, r4  ; PortEnable <= "00000000_00000000"
    
;   Seta RATE_FREQ_BAUD = 869 (0x364) (57600 baud @ 50 MHz)
    ldh r1, #arrayUART_RX
    ldl r1, #arrayUART_RX
    addi r1, #1
    ld r1, r0, r1  ; r1 <= &RATE_FREQ_BAUD (RX)
    ldh r5, #03h
    ldl r5, #64h   ; Seta BAUD_RATE = 869
    st r5, r0, r1  ;
    
;   Seta RATE_FREQ_BAUD = 869 (0x364) (57600 baud @ 50 MHz)
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #1
    ld r1, r0, r1  ; r1 <= &RATE_FREQ_BAUD (TX)
    ldh r5, #03h
    ldl r5, #64h   ; Seta BAUD_RATE = 869
    st r5, r0, r1  ;
    
;   Starts UART RX buffer @ 0
    ldh r1, #UartRxBufferStart
    ldl r1, #UartRxBufferStart
    st r0, r0, r1

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
; 7. Retorno

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

; irq[7] = port_io[15] = DISABLED
; irq[6] = port_io[14] = DISABLED
; irq[5] = ṕort_io[13] = DISABLED
; irq[4] = ṕort_io[12] = DISABLED
; irq[3] = OPEN
; irq[2] = OPEN
; irq[1] = UART RX DATA AV
; irq[0] = OPEN

; port_io[15] = OPEN
; port_io[14] = OPEN
; port_io[13] = OPEN
; port_io[12] = OPEN
; port_io[11] = OPEN
; port_io[10] = OPEN
; port_io[9] = OPEN
; port_io[8] = OPEN
; port_io[7] = OPEN
; port_io[6] = OPEN
; port_io[5] = OPEN
; port_io[4] = OPEN
; port_io[3] = OPEN
; port_io[2] = OPEN
; port_io[1] = OPEN
; port_io[0] = OPEN

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

;   Salva Contexto
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
    pushf

    xor r0, r0, r0
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6

;   Le ID da interrupção do PIC

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

;   Jump para handler
    jsr r1
    
;   ACK Interrupção
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #1
    ld r1, r0, r1 ; r1 <= &IntACK
    st r4, r0, r1 ; IntACK <= ID da Interrupção

;   Recupera contexto
    popf
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

;--------------------------------------------TRATAMENTO DE TRAPS---------------------------------------------

TrapsServiceRoutine:

; 1. Salvamento de contexto
; 2. Ler do reg CAUSE o número da exceção
; 3. Indexar jump table e gravar em algum registrador o endereço do handler
; 4. jsr reg (chama handler)
; 5. Recuperação de contexto
; 6. Retorno

;   Salva Contexto
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
    pushf

;   Le ID da trap

;   r4 <= registrador de causa
    mfc r4

;   r5 <= &trapVector
    ldh r5, #trapVector
    ldl r5, #trapVector

;   r5 <= trapVector[trapID]
    ld r5, r4, r5

;   Jump para handler
    jsr r5

;   Recupera contexto
    popf
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

;-------------------------------------------------HANDLERS---------------------------------------------------

irq0Handler: ; OPEN

    halt

irq1Handler: ; UART RX DATA AV

    jsrd #UartRXDriver
    
    rts

irq2Handler: ; OPEN

    halt

irq3Handler: ; OPEN

    halt

irq4Handler: ; PORT_IO[12]

    halt

irq5Handler: ; PORT_IO[13]

    halt

irq6Handler: ; PORT_IO[14]

    halt

irq7Handler: ; PORT_IO[15]

    halt

trap0Handler: ; NULL POINTER EXCEPTION

    jsrd #NullPointerExceptionDriver

    rts

trap1Handler: ; INVALID INSTRUCTION

    jsrd #InvalidInstructionDriver

    rts

trap2Handler: ; OPEN

    halt

trap3Handler: ; OPEN

    halt

trap4Handler: ; OPEN

    halt

trap5Handler: ; OPEN

    halt

trap6Handler: ; OPEN

    halt

trap7Handler: ; OPEN

    halt

trap8Handler: ; SYSCALL

    jsrd #SyscallDriver

    rts

trap9Handler: ; OPEN

    halt

trap10Handler: ; OPEN

    halt

trap11Handler: ; OPEN

    halt

trap12Handler: ; OVERFLOW

    jsrd #OverflowDriver

    rts

trap13Handler: ; OPEN

    halt

trap14Handler: ; OPEN

    halt

trap15Handler: ; DIVISION BY ZERO

    jsrd #DivisionByZeroDriver

    rts

syscall0Handler: ; PrintString (Transmits a string through UART TX)

    jsrd #PrintString

    rts

syscall1Handler: ; IntegerToString (Converts a given decimal value to a ASCII character)

    jsrd #IntegerToString

    rts

syscall2Handler: ; IntegerToHexString (Converts a given hexadecimal value to a ASCII character)

    jsrd #IntegerToHexString

    rts

syscall3Handler: ; Delay1ms (Waits for "r2" milliseconds, assumes a clock of 50MHz)

    jsrd #Delay1ms

    rts

syscall4Handler: ; IntegerToSSD (Converts a given integer (on r2) to Seven Segment Display encoding : abcdefg.)

    jsrd #IntegerToSSD

    rts
    
syscall5Handler: ; Read (Inserts chars received through UART RX on a given buffer (on r2) of a given size (on r3))

    jsrd #Read
    
    rts
    
syscall6Handler: ; StringToInteger (ATOI) (Converts a given string (on r2) to an integer (returned on r14)

    jsrd #StringToInteger
    
    rts
    

;-------------------------------------------------DRIVERS----------------------------------------------------

UartRXDriver:
; Register Table: 
; r1 = Address for LD/ST from/into variables
; r5 = Data for LD/ST from/into variables
; r6 = Buffer pointer
; r7 = Buffer indexer

    push r1
    push r5
    push r6
    push r7

    xor r0, r0, r0

;   r5 <= RX DATA
    ldh r1, #arrayUART_RX
    ldl r1, #arrayUART_RX
    ld r1, r0, r1 ; r1 <= &RX_DATA
    ld r5, r0, r1 ; r5 <= RX_DATA
 
;   r1 <= &TX READY
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #2
    ld r1, r0, r1 ; r1 <= &Ready

;   Waits for TX to be available
  UartRXTXReadyLoop:

;   r6 <= TX READY
    ld r6, r0, r1
    add r6, r0, r6
    jmpzd #UartRXTXReadyLoop

;   Transmits received char back to source
  UartRXTXChar:

;   r1 <= &UART TX DATA
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    ld r1, r0, r1

;   TX DATA <= RX DATA
    st r5, r0, r1

  UartRXSetup:

;   r6 <= Address of temp buffer
    ldh r6, #UartRxBuffer
    ldl r6, #UartRxBuffer

;   r7 <= Indexer for temp buffer
    ldh r7, #UartRxBufferIndexer
    ldl r7, #UartRxBufferIndexer
    ld r7, r0, r7

;   Checks if current char is '/n' ( Enter ), if it is, inserts '\0' terminator at current buffer position and flags buffer is available, else, adds current char to buffer
    subi r5, #10 ; Integer 10 is ASCII code for '/n'
    jmpzd #UartRxAppendTerminator
    jmpd #UartRxAppendChar

  UartRxAppendChar:

;   Restores char value and stores it on buffer
    addi r5, #10
    st r5, r6, r7 ; Buffer[BufferIndexer] <= Current Char (not '\n')

;   Signals buffer not ready
    ldh r1, #UartRxBufferFilledFlag
    ldl r1, #UartRxBufferFilledFlag
    st r0, r0, r1

;   Jumps to return
    jmpd #UartRxReturn

  UartRxAppendTerminator:

;   Stores '/0' at current position
    st r0, r6, r7 ; Buffer[BufferIndexer] <= '\0'

;   Signals new string available in buffer
    ldh r1, #UartRxBufferFilledFlag
    ldl r1, #UartRxBufferFilledFlag
    ldh r5, #0
    ldl r5, #1
    st r5, r1, r0

;   Saves current indexer as end of string
    ldh r1, #UartRxBufferEnd
    ldl r1, #UartRxBufferEnd
    st r7, r0, r1

;   r1 <= &TX READY
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #2
    ld r1, r0, r1 ; r1 <= &Ready

  UartRxLoopSendCR: ; Loops while TX is unavailable

    ld r6, r0, r1
    add r6, r0, r6
    jmpzd #UartRxLoopSendCR

;   Sends '/r' character (Carriage Return) through UART TX
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    ld r1, r0, r1 ; r1 <= &TX DATA
    ldh r5, #0
    ldl r5, #13   ; r5 <= '\r'
    st r5, r0, r1
 
;   Jumps to to return
    jmpd #UartRxReturn

  UartRxReturn:
  
;   Increments buffer indexer (if indexer == 80, loops bak to 0)
    addi r7, #1
    ldh r1, #0
    ldl r1, #80
    sub r1, r7, r1 ; r1 <= ++indexer - 80
    jmpzd #UartRxResetsIndexer
    jmpd #UartRxStoreIndexer
    
  UartRxResetsIndexer:
    
    xor r7, r7, r7 ; Indexer <= 0
    
  UartRxStoreIndexer:
    
    ldh r1, #UartRxBufferIndexer ; Indexer < 80
    ldl r1, #UartRxBufferIndexer
    st r7, r0, r1 ; BufferIndexer
  
    pop r7
    pop r6
    pop r5
    pop r1
    
    rts

NullPointerExceptionDriver:

;   Calls PrintError with TrapID = 0
    mfc r2
    mft r3
    jsrd #PrintError

    rts

InvalidInstructionDriver:

;   Calls PrintError with TrapID = 1
    mfc r2
    mft r3
    jsrd #PrintError

    rts

SyscallDriver:

; 1. Ler do reg r1 o número da função solicitada
; 2. Indexar jump table e gravar em algum registrador o endereço da função
; 3. jsr reg (chama função)
; 4. rts

    push r0

;   r0 <= Jump Table
    ldh r0, #syscallJumpTable
    ldl r0, #syscallJumpTable

;   r0 <= Endereço da função solicitada
    ld r0, r1, r0

;   PC <= Função Solicitada
    jsr r0

    pop r0

    rts

OverflowDriver:

;   Calls PrintErro with TrapID = 12
    mfc r2
    mft r3
    jsrd #PrintError

    rts

DivisionByZeroDriver:

;   Calls PrintErro with TrapID = 15
    mfc r2
    mft r3
    jsrd #PrintError

    rts

    
;---------------------------------------------FUNÇÕES DO KERNEL----------------------------------------------

PrintError: ; Prints a given error code (on r2) on a given insruction (r3)

; Register Table:
; r2 = ID of trap
; r3 = ADDR of trap causing instruction
; r4 = Constant 4
; r5 = Temporary for load/store
; r6 = Indexer for error code string and converted string (intToHex)
; r7 = ErrorCodeIndex
; r8 = Temp

;   Saves context
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8

;   Initializes registers
    xor r0, r0, r0
    xor r4, r4, r4
    xor r5, r5, r5
    xor r6, r6, r6
    xor r7, r7, r7
    xor r8, r8, r8

    ldl r4, #3

;   r5 <= trap ID in HEXADECIMAL (1 ASCII character)
    jsrd #IntegerToHexString
    add r5, r4, r14 ; Gets IntegerToHexBuffer [3]
    ld r5, r0, r5

;   r2 <= ADDR of trap causing instruction
    add r2, r0, r3
    subi r2, #01h ; ADDR of trap its get one positon after

;   r14 <= &String with trap causing instruction ADDR in HEXADECIMAL (4 ASCII characters)
    jsrd #IntegerToHexString

;   Initializes ErrorCode String
    ldh r2, #ErrorCode
    ldl r2, #ErrorCode

;   ErrorCode[7] <= ID of trap
    ;st r5, r2, r7

  PrintErrorLoop: ; Copies converted HEX string to ErrorCode string (offsets ConvertedString into ErrorCode by 4)
; Setup first 2 char '0' & 'x'
    xor r7, r7, r7  ; String Index <= 0
    ldh r8, #00h
    ldl r8, #48    ; r8 <= char '0'

;   r2 is &ErrorCode
    st r8, r2, r7 ; ErrorCode[0] = '0'

    ldh r8, #00h
    ldl r8, #78h ; r8 <= char 'x' ASCII[120]

    addi r7, #01h ; Increment ErrorCodeIndex | r7 = 1
    st r8, r2, r7 ; Errocode[1] = 'x'

;String ErrorCode has "0x_______"
;Set trapID
    addi r7, #01h ; Increment ErrorCodeIndex | r7 = 2
    st r5, r2, r7 ; Errocode[2] = 'trapID' in HEXstring

;String ErrorCode has "0xID ______"
; Set ' |' char spacement
    ldh r8, #00h
    ldl r8, #7ch ; r8 <= char '|' ASCII[124]
    addi r7, #01h ; Increment ErrorCodeIndex | r7 = 3
    st r8, r2, r7 ; Errocode[3] =  '|'

;String ErrorCode has "0xID|______"
    ldh r8, #IntegerToHexBuffer
    ldl r8, #IntegerToHexBuffer ; r8 <= &IntegerToHexBuffer

AddrsLoop:
    addi r7, #01h ; Increment ErrorCodeIndex | r7 = 4

    ld r5, r0, r8 ; r5 <= Value IntegerToHexBuffer

    st r5, r2, r7 ; Errocode[4] =  Addrs of error instruction in Hexadecimal

    add r5, r0, r5 ; Generates Flag

    jmpzd #PrintErrorReturn ; When char = 0, end of String

    addi r8, #01h ; r8 <= &IntergerToHexBufer + 1

    jmpd #AddrsLoop ; Jump Over

  PrintErrorReturn:

;   Transmits Error Code                      |   7  | 6 5 4 |       3210        |
;   jsrd #PrintString ; Final string will be: (TrapID) 0 0 0 (ADDR of instruction)

;   Transmits Error Code                      | 0 | 1 |   2   | 3 |        4567        |  8
    jsrd #PrintString ; Final string will be:  '0' 'x'(trapID) '|' (ADDR of instruction)  0
    
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    
;   Sends '/n' and '/l'
    jsrd #PrintString

;   Return to normal execution flow
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2

    rts


PrintString: ; Transmite por UART uma string. Espera endereço da string a ser enviada em r2

; Tabela de registradores:
; r1 = Endereço do transmissor serial
; r2 = Endereço da string a ser enviada
; r3 = Indexador da string do inteiro convertido (buffer)
; r5 = Dado a ser transmitido

    push r1
    push r3
    push r5

    xor r0, r0, r0
    xor r3, r3, r3
    xor r5, r5, r5

    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #2
    ld r1, r0, r1 ; r1 <= &TX READY

  tx_loop:

;   r5 <= status do tx
    ld r5, r0, r1  ; r1 <= TX READY
    add r5, r0, r5 ; Gera flag

    jmpzd #tx_loop ; Espera transmissor estar disponivel
    ;jmpzd #tx_disp ; Espera transmissor estar disponivel
    ;jmpd #tx_loop  ; Transmissor indisponivel

  tx_disp:
  
;   r5 <= string[r3]
    ld r5, r3, r2
    add r5, r0, r5 ; Gera flag

;   Se string[r3] = 0 (terminador de string), volta para caller
    jmpzd #PrintStringReturn

;   UART TX <= r5
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    ld r1, r0, r1 ; r1 <= &TX DATA
    st r5, r0, r1

;   Incrementa indice
    addi r3, #1
    
;   Restaura ponteiro para TX READY em r1 
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #2
    ld r1, r0, r1 ; r1 <= &TX READY   

;   Transmite proximo caracter
    jmpd #tx_loop
    ;jmpd #tx_disp

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
    ;xor r2, r2, r2
    xor r3, r3, r3
    xor r4, r4, r4
    xor r10, r10, r10
    xor r11, r11, r11

    ldl r10, #10

    ldh r14, #IntegerToStringBuffer
    ldl r14, #IntegerToStringBuffer

    addi r3, #07h

;   Limpa o buffer
  limpaBufferLoop:

;   buffer[r3] <= 0
    st r0, r3, r14

;   Decrementa indice do buffer
    subi r3, #01h

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

    subi r14, #1

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
    ;pop r1

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

IntegerToHexString: ; Espera valor a ser convertido em r2, retorna ponteiro para string em r14
; Serve Somente para o Erro do pc, Sempre devolve uma string de 4 posições
; Tabela de registradores:
; r2 = Inteiro a ser convertido ( 16 bits)
; r3 = Constante 16
; r4 = Numeros a ser Convertidos / Temporário para comparacao
; r5 = Indexador do Buffer
; r6 = Endereço da LUT
; r14 = Endereço do Buffer ( Ponteiro para String)

    push r2
    push r3
    push r4
    push r5
    push r6

    ldh r3, #00h
    ldl r3, #10h  ; r3 <= (constante)16

    ;xor r5, r5, r5 ; Zera o indexador do Buffer
    ldh r5, #00h
    ldl r5, #04h   ; Buffer index starts in the last position

    ldh r6, #IntegerToHexStringLUT
    ldl r6, #IntegerToHexStringLUT   ; r6 <= & IntegerToHexStringLUT

    ldh r14, #IntegerToHexBuffer
    ldl r14, #IntegerToHexBuffer   ; r11 <= & IntergerToHexBufer

    xor r4, r4, r4  ; r4 <= ASCII [ 0 ] = NULL = End of string
    st r4, r5, r14  ; IntegerToHexBuffer [r5] = r4
    subi r5, #01h   ; Buffer index <= last -1 Position

    FourBitsConverter:
    add r4, r0, r5  ; r4 <= Indexador
    ;subi r4, #04h   ; Comparação é verdadeira quando o indexador for igual a 4
    jmpnd #ReturnIntegerToHexString ; It's true when r4 is -1

    div r2, r3    ; r2 / 16  ( Divisao por 16 equivale a 4 shifts)
    mfl r2        ; r2 <= parte inteira da divisao r2/16
    mfh r4        ; r4 <= Resto da divisao r2/16 ( 4 bits)

;   Salva em r4 o valor da LUT indexada por r4
    ld r4, r4, r6   ; r4 <= IntegerToHexStringLUT[ ( r4 = resto da divisao)]

    st r4, r5, r14  ; IntegerToHexBuffer [r5] = r4 ( Numero convertido)

    subi r5, #01h   ; Decrementa o Indexador
    jmpd #FourBitsConverter ; Retoma o Loop

    ReturnIntegerToHexString:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2

    rts

Delay1ms: ; Assumes clk = 50MHz (MIGHT CAUSE PROBELMS IF GIVEN NUMBER IS GREATER THAN 2¹⁵, WHICH IS INTERPRETED AS A NEGATIVE NUMBER)
; Register table
; r2 = Number of milliseconds to hold in this function
; r4 = Loop iterator

    push r2
    push r4

  Delay1msloopReset:

;   Iterador do loop de 1ms <= 2500
    ldh r4, #09h
    ldl r4, #C4h

  Delay1msloop:             ; Repeats 2500 times, 20 cycles
    subi r4, #1             ;  4 cycles
    nop                     ;  7 cycles
    nop                     ; 10 cycles
    nop                     ; 13 cycles
    jmpzd #Delay1msloopExit ; 16 cycles
    jmpd #Delay1msloop      ; 20 cycles

  Delay1msloopExit:

    subi r2, #1
    jmpzd #Delay1msReturn
    jmpd #Delay1msloopReset

  Delay1msReturn:

    pop r4
    pop r2

    rts

IntegerToSSD: ; Returns on r14 given integer (on r2) encoded for 7 Segment Display (abcdefg.) (Considers display segments to be active on 0)
; Register table
; r1 = Address of Look Up Table for conversion
; r2 = Integer to be encoded
; r14 = Encoded integer

    push r1

    xor r1, r1, r1
    xor r14, r14, r14

;   r1 <= &arraySSD
    ldh r1, #arraySSD
    ldl r1, #arraySSD

;   r14 <= arraySSD[r2]
    ld r14, r1, r2

    pop r1

    rts

Read: ; Returns on r14, 0 if a string hasnt been received through UART, or the size of said string if the last char received was '\n'
; Register Table:
; r1 = Addr of UART RX buffer filled flag
; r2 = Pointer to string which data from buffer is transfered to
; r3 = Amount of chars to copy from buffer into given string
; r5 = Temp for loading data from buffer and storing it into given string pointer
; r6 = Addr of buffer (filled by UART RX driver)
; r7 = Buffer start position
; r8 = Chars tranfered counter

    push r1
    push r3
    push r5
    push r6
    push r7
    push r8
    
    xor r0, r0, r0
    xor r8, r8, r8
    xor r14, r14, r14

;   Checks if there is new data available on buffer
    ldh r1, #UartRxBufferFilledFlag
    ldl r1, #UartRxBufferFilledFlag
    ld r1, r0, r1
    add r1, r0, r1
    
;   If no new data is available, returns 0, else, transfer buffer into given string pointer (r2) 
    jmpzd #ReadPop
    jmpd #ReadTransferBufferToString
    
  ReadTransferBufferToString:
  
;   Sets new data flag to 0
    ldh r1, #UartRxBufferFilledFlag
    ldl r1, #UartRxBufferFilledFlag
    st r0, r0, r1
  
;   Sets string size as the return value
    add r14, r0, r3
    
;   Loads UART RX buffer address
    ldh r6, #UartRxBuffer
    ldl r6, #UartRxBuffer

;   Loads buffer start position
    ldh r7, #UartRxBufferStart
    ldl r7, #UartRxBufferStart
    ld r7, r0, r7
    
;   Sets buffer reference pointer (buffer pointer + start position)
    add r6, r7, r6
    
  ReadLoop: ; Loops until buffer is transfered into given string pointer

;   r5 <= buffer[r8 + reference]
    ld r5, r6, r8
    
;   string[r8] <= buffer[r8 + reference]
    st r5, r2, r8
    
;   Increments counter
    addi r8, #1
    
;   If counter == Amount of chars to be copied, breaks, else, loops back to ReadLoop
    sub r5, r3, r8
    jmpnd #ReadLoop
    
  ReadReturn:
  
;   Sets new buffer start position, right after current buffer end position
    ldh r1, #UartRxBufferEnd
    ldl r1, #UartRxBufferEnd
    ld r5, r0, r1
    addi r5, #1

;   If new start position = 80, loops back to 0
    ldh r1, #0
    ldl r1, #80
    sub r1, r5, r1
    jmpnd #ReadSetStart
    
;   Only reaches this line if r5 == 80
    xor r5, r5, r5
    
  ReadSetStart:
  
;   Stores new start position value
    ldh r1, #UartRxBufferStart
    ldl r1, #UartRxBufferStart
    st r5, r0, r1
    
  ReadPop:
  
    pop r8
    pop r7
    pop r6
    pop r5
    pop r3
    pop r1

    rts

StringToInteger: ; (Converts a given string (on r2) to an integer (returned on r14)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;STRING TO INTEGER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Given a *String on r2 return the integer value of so in r14                    ;
; Registers used                                                                         ;
;	r3 : String index, runs through the String until String[index] = `0` (end of string) ;
;	r4 : Constant 10, used each time to shift the integer number 10 positions            ;
;   r5 : Offset of ascii, equals to 48                                                   ;
;                                                                                        ;
;  Implementation:                                                                       ;
;     Workflow:                                                                          ;
;        Gets the value of The first element of the string passed in r2, and then        ;
;        compare it whit `0`, the string terminator                                      ;
;        Multiply the return register (r14) whit 10 to generate the decimal value needed ;
;        note that in the first iteration r14 == 0 therefore the multiplication will be 0;
;        Put the value in the string minus ASCII offset in the return register( r14)     ;
;        Increment the String pointer ( r2)                                              ;
;     OFFSET:                                                                            ;
;        In ASCII number zero ( 0 ) starts in postion 48, ergo if the String is `20` the ;
;        first ASCII char `2` will be 50, subtracted of 48 will result in the int value  ;
;        of that char                                                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	push r3  ; Temporary
	push r4  ; Constant 10
	push r5  ; Constant 48 ASCII offset

	; Clean registers
    xor r0, r0, r0    ; r0  <- 0
	xor r3, r3, r3    ; r3  <- 0
	xor r14, r14, r14 ; r14 <- 0
	
	; r4 <- (const) 10
	ldh r4, #00h  
	ldl r4, #0Ah      ; r4 <- 10

	; r5 <- (const) 48
	ldh r5, #00h
	ldl r5, #30h      ; r5 <- 48
	
	; Get the index for the String
	ld r3, r0, r2     ; Gets the value of the String in the First position ( r3<- value of addres r2)
	
  
  ; Loop, iterates r3 ( r2 = *String, r3 = Value String[0] ; r2 != `0` ; r2 ++ ) 
  ; r3 already has the value of string in the first position
  StringToInteger_loop:

    ; Generates flag
	add r3, r0, r3    ; r3 <- Value ( r2) GENERATES FLAG

	; Verifies the end of loop
	jmpzd #StringToInteger_return  ; If the current char is equals to ZERO, end 
	
	; Multiply r14(return integer) and r4 ( const 10)
	mul r14, r4       ; In the first iteration will result in zero
	mfl r14           ; r14 <- Interger part of division

	; r3 <- r3 - 48( ASCII offset)
	sub r3, r3, r5     ; r3 <- Int value
	
	; r14 <- String[index] - 48 (offset of Ascii)
	add r14, r14, r3   ; r14 <- Value converted from string to integer
	
	; Gets the next memory position of the string
	addi r2, #01h     ; String ++ 
	
	; r3 <- r2[index]
	ld r3, r0, r2     ; r3 <- Value of address[r2+index]
  
	; Restart the iteration
	jmpd #StringToInteger_loop 
	
  StringToInteger_return:
	pop r5
	pop r4
	pop r3
	rts

; IMPLEMENTAR
    

;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------

main:

RequestSize:

;   Request size of array to be ordered
    ldh r1, #0
    ldl r1, #0
    ldh r2, #stringTamanho
    ldl r2, #stringTamanho
    syscall ; PrintString     
    
;   Gets array size from terminal
    ldh r1, #0
    ldl r1, #5
    ldh r2, #stringTemp
    ldl r2, #stringTemp
    ldh r3, #0
    ldl r3, #3
    
  RequestSizeReadLoop:
  
;   Keeps calling Read until it returns a valid value
    syscall
    add r14, r0, r14
    jmpzd #RequestSizeReadLoop
    
;   Converts Size string to integer
    ldh r1, #0
    ldl r1, #6
    add r2, r0, r14
    syscall ; StringToInteger    
    
;   Stores size on its variable
    add r2, r0, r14
    ldh r1, #arraySortSize
    ldl r1, #arraySortSize
    st r2, r0, r1

;   Sets comparison number for RequestElementsLoop iterator   
    add r5, r0, r2

;   Prints new line characters
    ldh r1, #0
    ;ldh r1, #0
    ldl r1, #0
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    syscall ; PrintString     

;   Initializes RequestElementsLoop iterator
    xor r4, r4, r4

RequestElementsLoop:

;   If iterator = size, breaks loop
    sub r1, r4, r5
    jmpzd #RequestOrder

;   Request a new element (first part of request string)
    ldh r1, #0
    ldl r1, #0
    ldh r2, #stringElementoA
    ldl r2, #stringElementoA
    syscall ; PrintString

;   Converts iterator to string
    ldh r1, #0
    ldl r1, #1
    add r2, r0, r4
    syscall ; IntegerToString
    
;   Prints iterator
    ldh r1, #0
    ldl r1, #0
    add r2, r0, r14
    
;   Request a new element (second part of request string)
    ldh r1, #0
    ldl r1, #0
    ldh r2, #stringElementoB
    ldl r2, #stringElementoB
    syscall ; PrintString
    
;   Gets array size from terminal
    ldh r1, #0
    ldl r1, #5
    ldh r2, #stringTemp
    ldl r2, #stringTemp
    ldh r3, #0
    ldl r3, #3
    
  RequestElementsReadLoop:
  
;   Keeps calling Read until it returns a valid value
    syscall
    add r14, r0, r14
    jmpzd #RequestElementsReadLoop

;   Converts Size string to integer
    ldh r1, #0
    ldl r1, #6
    add r2, r0, r14
    syscall ; StringToInteger
    
;   Stores new element in array to be sorted
    ldh r1, #arraySort
    ldl r1, #arraySort
    st r14, r1, r4
    
;   Prints new line characters
    ldh r1, #0
    ;ldh r1, #0
    ldl r1, #0
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    syscall ; PrintString    
    
;   Increments iterator
    addi r4, #1

    jmpd #RequestElementsLoop
    
RequestOrder: 

;   Request type of sorting order (0 for increasing, 1 for decreasing)
    ldh r1, #0
    ldl r1, #0
    ldh r2, #stringOrdenacao
    ldl r2, #stringOrdenacao
    syscall ; PrintString
    
;   Gets array size from terminal
    ldh r1, #0
    ldl r1, #5
    ldh r2, #stringTemp
    ldl r2, #stringTemp
    ldh r3, #0
    ldl r3, #3
    
  RequestOrderReadLoop:
  
;   Keeps calling Read until it returns a valid value
    syscall
    add r14, r0, r14
    jmpzd #RequestOrderReadLoop

;   Converts Order string to integer
    ldh r1, #0
    ldl r1, #6
    add r2, r0, r14
    syscall ; StringToInteger
    
;   r12 <= sort order
    add r12, r0, r14
    
    
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
;*          r12: Array sort order (0 = Increasing, 1 = Decreasing)
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

    add r10, r0, r2         ; r10 <- arraySortsize (to be used on Serial Transmission)

    add r3, r2, r1          ; r3 points the end of array (right after the last element)

    ;ldl r4, #0              ;
    ;ldh r4, #1              ; r4 <- 1
    ldh r4, #0
    ldl r4, #1

; Converts array to char and transmits via UART
TX_ARRAY_INICIAL:

    ld r2, r11, r1          ; r2 <- arraySort[transmissionCount]

    ldh r1, #0
    ldl r1, #1
    syscall                 ; Converts integer to string

    add r2, r0, r14         ; r2 <- Pointer to converted string

    ldh r1, #0
    ldl r1, #0
    syscall                 ; Prints string on UART transmiter
    
    ldh r1, #0
    ldh r1, #0
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    syscall                 ; New line

    addi r11, #1            ; Increments transmission count

    sub r5, r10, r11        ; If transmission count == array size, breaks loop, else iterates again

    ldh r1, #arraySort
    ldl r1, #arraySort      ; r1 <- &array

    jmpzd #delayBeforeSort
    jmpd #TX_ARRAY_INICIAL

; Delays for 100 ms
delayBeforeSort:

    push r1
    push r2
    
    ldh r1, #0
    ldl r1, #3
    ldh r2, #0
    ldl r2, #100
    syscall ; Delay

    ldh r1, #0
    ;ldh r1, #0
    ldl r1, #0
    
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    syscall ; Nova Linha
    
    pop r2
    pop r1

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

    add r12, r0, r12        ; Generate flag for order of array
    jmpzd #increasing
    jmpd #decreasing

increasing:
    sub r2, r8, r7          ; If r8 > r7, negative flag is set
    jmpnd #swap             ; (if array[r5] > array[r6] jump)
    jmpd #continue

decreasing:
    sub r2, r7, r8          ; If r8 < r7, negative flag is set
    jmpnd #swap             ; (if array[r5] < array[r6] jump)
    jmpd #continue

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

    xor r11, r11, r11
    ldh r1, #arraySort
    ldl r1, #arraySort

; Loops for 50 iterations on IntegerToString function
TX_ARRAY_FINAL_LOOP:

    ld r2, r1, r11          ; r2 <- arraySort[transmissionCount]

    ldh r1, #0
    ldl r1, #1
    syscall                 ; Converts integer to string

    add r2, r0, r14         ; r2 <- Pointer to converted string

    ldh r1, #0
    ldl r1, #0
    syscall                 ; Prints string on UART transmiter
    
    ldh r1, #0
    ;ldh r1, #0
    ldl r1, #0
    ldh r2, #stringNovaLinha
    ldl r2, #stringNovaLinha
    syscall                 ; New line

    addi r11, #1            ; Increments transmission count

    sub r5, r10, r11        ; If transmission count == array size, breaks loop, else iterates again

    ldh r1, #arraySort
    ldl r1, #arraySort      ; r1 <- &array

    jmpzd #delayAfterSort
    jmpd #TX_ARRAY_FINAL_LOOP

delayAfterSort:

;   Delays for 100 ms
    push r1
    push r2
    ldh r1, #0
    ldl r1, #3
    ldh r2, #0
    ldl r2, #100
    syscall
    pop r2
    pop r1

    jmpd #main

.endcode

;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================

.data

;--------------------------------------------VARIAVEIS DO KERNEL---------------------------------------------

; Array de registradores da Porta Bidirecional
; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta:               db #8000h, #8001h, #8002h, #8003h

; Array de registradores do controlador de interrupções
; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ] IrqREG(0x80F3) ]
arrayPIC:                 db #80F0h, #80F1h, #80F2h, #80F3h

; Array de registradores do controlador de interrupções
; arrayUART_TX [ TX_DATA(0x8080) | RATE_FREQ_BAUD(0x8081) | READY(0x8082) ]
arrayUART_TX:             db #8080h, #8081h, #8082h

; Array de registradores do controlador de interrupções
; arrayUART_TX [ RX_DATA(0x80A0) | RATE_FREQ_BAUD(0x80A1) ]
arrayUART_RX:             db #80A0h, #80A1h

; Vetor com tratadores de interrupção
interruptVector:          db #irq0Handler, #irq1Handler, #irq2Handler, #irq3Handler, #irq4Handler, #irq5Handler, #irq6Handler, #irq7Handler

; Vetor com tratadores de traps
trapVector:               db #trap0Handler, #trap1Handler, #trap2Handler, #trap3Handler, #trap4Handler, #trap5Handler, #trap6Handler, #trap7Handler, #trap8Handler, #trap9Handler, #trap10Handler, #trap11Handler, #trap12Handler, #trap13Handler, #trap14Handler, #trap15Handler,

; Vetor com endereços das chamadas de sistema
syscallJumpTable:         db #syscall0Handler, #syscall1Handler, #syscall2Handler, #syscall3Handler, #syscall4Handler, #syscall5Handler, #syscall6Handler

; IntegerToString
IntegerToStringBuffer:    db #0, #0, #0, #0, #0, #0, #0, #0

; IntegerToHexString Look Up Table (returns indexer value in HEXADECIMAL IN UPPERCASE)
;                             0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
IntegerToHexStringLUT:    db #48, #49, #50, #51, #52, #53, #54, #55, #56, #57, #65, #66, #67, #68, #69, #70
IntegerToHexBuffer:       db #0, #0, #0, #0, #0

; Buffer para transmissao de codigo de erro (8 chars + string trailer)
ErrorCode:                db #0, #0, #0, #0, #0, #0, #0, #0, #0

; Codifica o numero indexante em segmentos de um display de 7 segmentos
;                           |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  A  |  B  |  C  |  D  |  E  |  F  |
arraySSD:                 db #03h, #9fh, #25h, #0dh, #99h, #49h, #41h, #1fh, #01h, #09h, #11h, #b1h, #63h, #85h, #61h, #71h

; String contendo caracteres de nova linha e carriage return
stringNovaLinha:          db #10, #13, #0

; Buffer for READ syscall (80 positions)
UartRxBuffer:             db #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0 #0, #0, #0, #0, #0, #0, #0, #0, #0, #0 #0, #0, #0, #0, #0, #0, #0, #0, #0, #0 #0, #0, #0, #0, #0, #0, #0, #0, #0, #0 #0, #0, #0, #0, #0, #0, #0, #0, #0, #0 #0, #0, #0, #0, #0, #0, #0, #0, #0, #0

; Pointer for UartRxBuffer
UartRxBufferIndexer:      db #0

; Filled buffer flag
UartRxBufferFilledFlag:   db #0

; Indexes start of current string in circular buffer
UartRxBufferStart:        db #0

; Indexes ending of current string in circular buffer
UartRxBufferEnd:          db #0

;-------------------------------------------VARIAVEIS DE APLICAÇÃO-------------------------------------------

; Array para aplicação principal (Bubble Sort) de 50 elementos
arraySort:                db #50, #49, #48, #47, #46, #45, #44, #43, #42, #41, #40, #39, #38, #37, #36, #35, #34, #33, #32, #31, #30, #29, #28, #27, #26, #25, #24, #23, #22, #21, #20, #19, #18, #17, #16, #15, #14, #13, #12, #11, #10, #9, #8, #7, #6, #5, #4, #3, #2, #1  
;arraySort:                db #0050h, #0049h, #0048h, #0047h, #0046h, #0045h, #0044h, #0043h, #0042h, #0041h, #0040h, #0039h, #0038h, #0037h, #0036h, #0035h, #0034h, #0033h, #0032h, #0031h, #0030h, #0029h, #0028h, #0027h, #0026h, #0025h, #0024h, #0023h, #0022h, #0021h, #0020h, #0019h, #0018h, #0017h, #0016h, #0015h, #0014h, #0013h, #0012h, #0011h, #0010h, #0009h, #0008h, #0007h, #0006h, #0005h, #0004h, #0003h, #0002h, #0001h

; Tamanho do array p/ bubble sort (50 elementos)
arraySortSize:            db #50

; "Insira tamanho do array a ser ordenado: "
stringTamanho:            db #49h, #6eh, #73h, #69h, #72h, #61h, #20h, #74h, #61h, #6dh, #61h, #6eh, #68h, #6fh, #20h, #64h, #6fh, #20h, #61h, #72h, #72h, #61h, #79h, #20h, #61h, #20h, #73h, #65h, #72h, #20h, #6fh, #72h, #64h, #65h, #6eh, #61h, #64h, #6fh, #3ah, #20h, #0

; "Insira elemento "
stringElementoA:          db #49h, #6eh, #73h, #69h, #72h, #61h, #20h, #65h, #6ch, #65h, #6dh, #65h, #6eh, #74h, #6fh, #20h, #0

; " do array: "
stringElementoB:          db #20h, #64h, #6fh, #20h, #61h, #72h, #72h, #61h, #79h, #3ah, #20h, #0

; "Insira ordenacao do array (0 para crescente, 1 para Decrescente) : "
stringOrdenacao:          db #49h, #6eh, #73h, #69h, #72h, #61h, #20h, #6fh, #72h, #64h, #65h, #6eh, #61h, #63h, #61h, #6fh, #20h, #64h, #6fh, #20h, #61h, #72h, #72h, #61h, #79h, #20h, #28h, #30h, #20h, #70h, #61h, #72h, #61h, #20h, #63h, #72h, #65h, #73h, #63h, #65h, #6eh, #74h, #65h, #2ch, #20h, #31h, #20h, #70h, #61h, #72h, #61h, #20h, #44h, #65h, #63h, #72h, #65h, #73h, #63h, #65h, #6eh, #74h, #65h, #29h, #20h, #3ah, #20h, #0

; String temporaria para dados recebidos atraves de UART RX por terminal
stringTemp:               db #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0

.enddata
