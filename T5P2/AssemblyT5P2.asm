


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O VIA PIC E TRAPS

; APLICAÇÃO ATUAL:
; TESTE DE TRAPS

; CHANGELOG:
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
; --------------------- r1  = SYSCALL ID
; --------------------- r2  = PARAMETRO para subrotina
; --------------------- r3  = PARAMETRO para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

;////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
;    ldh r0, #7Fh
;    ldl r0, #FFh
;    ldsp r0

;   Inicializa ponteiro da pilha para 0x"03E6" (ultimo endereço no espaço de endereçamento da memoria)
    ldh r0, #03h
    ldl r0, #E6h
    ldsp r0

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
    ldl r8, #00h   ; Carrega a Mascara para o PIC [ r8 <= "0000_0000_0000_0000"]

    st r8, r0, r7  ; arrayPIC [MASK] <= "xxxx_xxxx_0000_0000"

    ; Array de registradores do controlador de interrupções
    ; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ]
    ;arrayPIC:                 db #80F0h, #80F1h, #80F2h

;   r1 <= &arrayPorta
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1

    xor r4, r4, r4

;   Seta todos os bits de PortConfig como entrada
    ldl r4, #01h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #FFh   ; r5 <= "11111111_11111111"
    ldl r5, #FFh   ; bits 7 a 0 inicialmente são entrada, espera interrupção
    st r5, r1, r4  ; PortConfig <= "11111111_11111111"

;   Desabilita interrupções
    ldl r4, #03h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h   ; Habilita a interrupção nos bits 12 a 15
    st r5, r1, r4  ; irqtEnable <= "00000000_00000000"

;   Desabilita portas
    ldl r4, #02h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h    ; Desabilita acesso a todos os bits da porta de I/O
    st r5, r1, r4  ; PortEnable <= "00000000_00000000"

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

irq1Handler: ; OPEN

    halt

irq2Handler: ; OPEN

    halt

irq3Handler: ; OPEN

    halt

irq4Handler: ; OPEN

    halt

irq5Handler: ; OPEN

    halt

irq6Handler: ; OPEN

    halt

irq7Handler: ; OPEN

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

;-------------------------------------------------DRIVERS----------------------------------------------------

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
; r4 = constant 4
; r5 = Temporary for load/store
; r6 = Indexer for error code string and converted string (intToHex)
; r7 = constant 7
; r8 = constant 8

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

    ldl r4, #4
    ldl r7, #7
    ldl r8, #8

;   r5 <= trap ID in HEXADECIMAL (1 ASCII character)
    jsrd #IntegerToHexString
    add r5, r0, r14
    ld r5, r0, r5

;   r2 <= ADDR of trap causing instruction
    add r2, r0, r3

;   r14 <= ADDR of trap causing instruction in HEXADECIMAL (4 ASCII characters)
    jsrd #IntegerToHexString

;   Initializes ErrorCode String
    ldh r2, #ErrorCode
    ldl r2, #ErrorCode

;   ErrorCode[7] <= ID of trap
    st r5, r2, r7

  PrintErrorLoop: ; Copies converted HEX string to ErrorCode string (offsets ConvertedString into ErrorCode by 4)

;   If string index = 4, returns, else, inserts another character (r4 is always = 4)
    sub r5, r6, r4 ; r5 is treated as temporary, will be used to read values from converted string and storing them into the final string (to be printed)
    jmpzd #PrintErrorReturn

;   r5 <= Char of ADDR of trap causing instruction[r6]
    ld r5, r6, r14

;   ErrorCode[r6] <= r5
    st r5, r6, r2

;   Increments Indexer
    addi r6, #1

    jmpd #PrintErrorReturn

  PrintErrorReturn:

;   Transmits Error Code                      |   7  | 6 5 4 |       3210        |
    jsrd #PrintString ; Final string will be: (TrapID) 0 0 0 (ADDR of instruction)

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

    ldh r1, #UART_TX
    ldl r1, #UART_TX
    ld r1, r0, r1

  tx_loop:

;   r5 <= status do tx
    ld r5, r0, r1
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
    st r5, r0, r1

;   Incrementa indice
    addi r3, #1

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

    xor r5, r5, r5 ; Zera o indexador do Buffer

    ldh r6, #IntegerToHexStringLUT
    ldl r6, #IntegerToHexStringLUT   ; r6 <= & IntegerToHexStringLUT

    ldh r14, #IntegerToHexBuffer
    ldl r14, #IntegerToHexBuffer   ; r11 <= & IntergerToHexBufer

    FourBitsConverter:
    add r4, r0, r5  ; r4 <= Indexador
    subi r4, #04h   ; Comparação é verdadeira quando o indexaro for igual a 4
    jmpzd #ReturnIntegerToHexString

    div r2, r3    ; r2 / 16  ( Divisao por 16 equivale a 4 shifts)
    mfl r2        ; r2 <= parte inteira da divisao r2/16
    mfh r4        ; r4 <= Resto da divisao r2/16 ( 4 bits)

;   Salva em r4 o valor da LUT indexada por r4
    ld r4, r4, r6   ; r4 <= IntegerToHexStringLUT[ ( r4 = resto da divisao)]
    st r4, r5, r14  ; IntegerToHexBuffer [r5] = r4 ( Numero convertido)

    addi r5, #01h   ; Incrementa o Indexador
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

  Delay1msloop:             ; Repete 2500 vezes, 20 ciclos
    subi r4, #1             ;  4 ciclos
    nop                     ;  7 ciclos
    nop                     ; 10 ciclos
    nop                     ; 13 ciclos
    jmpzd #Delay1msloopExit ; 16 ciclos
    jmpd #Delay1msloop      ; 20 ciclos

  Delay1msloopExit:

    subi r2, #1
    jmpzd #Delay1msReturn
    jmpd #Delay1msloopReset

  Delay1msReturn:

    pop r4
    pop r2

    rts

IntegerToSSD: ; Returns on r14 given integer (on r2) encoded for 7 Segment Display (abcdefg.)
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

;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------

main:
    xor r12, r12, r12  ; Sets Order for sort
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
;*          r12: Array sort order (0 = Cresc, 1 = Decres)
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

    ldl r4, #0              ;
    ldh r4, #1              ; r4 <- 1

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
    syscall
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
    jmpzd #crescent
    jmpd #decrescent

crescent:
    sub r2, r8, r7          ; If r8 > r7, negative flag is set
    jmpnd #swap             ; (if array[r5] > array[r6] jump)
    jmpd #continue

decrescent:
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

    addi r11, #1            ; Increments transmission count

    sub r5, r10, r11        ; If transmission count == array size, breaks loop, else iterates again

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

ForçaExceçaoAdd:

    ldh r5, #7Fh
    ldl r5, #FFh
    add r5, r5, r5

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

ForçaExceçaoAddi:

    ldh r5, #7Fh
    ldl r5, #FFh
    addi r5, #1

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

ForçaExceçaoSub:

    ldh r4, #FFh
    ldl r4, #FFh

    ldh r5, #FFh
    ldl r5, #FFh

    sub r5, r4, r5

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

ForçaExceçaoSubi:

    ldh r5, #FFh
    ldl r5, #FFh
    subi r5, #1

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

TrocaOrdemBubbleSort:

    add r12, r12, r0
    jmpzd #IncAndJump

;   Next pass order array in Increasing order
    xor r12, r12, r12
    jmpd #BubbleSort

    IncAndJump:

;   Next pass order array in Decreasing order
    addi r12, #1
    jmpd #BubbleSort

.endcode

;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
.org #0258h
.data

;--------------------------------------------VARIAVEIS DO KERNEL---------------------------------------------

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

; Vetor com tratadores de traps
trapVector:               db #trap0Handler, #trap1Handler, #trap2Handler, #trap3Handler, #trap4Handler, #trap5Handler, #trap6Handler, #trap7Handler, #trap8Handler, #trap9Handler, #trap10Handler, #trap11Handler, #trap12Handler, #trap13Handler, #trap14Handler, #trap15Handler,

; Vetor com endereços das chamadas de sistema
syscallJumpTable:         db #syscall0Handler, #syscall1Handler, #syscall2Handler, #syscall3Handler, #syscall4Handler

; IntegerToString
IntegerToStringBuffer:    db #0, #0, #0, #0, #0, #0, #0, #0

; IntegerToHexString Look Up Table (returns indexer value in HEXADECIMAL IN UPPERCASE)
;                             0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
IntegerToHexStringLUT:    db #48, #49, #50, #51, #52, #53, #54, #55, #56, #57, #65, #66, #67, #68, #69, #70
IntegerToHexBuffer:       db #0, #0, #0, #0
; Buffer para transmissao de codigo de erro (8 chars + string trailer)
ErrorCode:                db #0, #0, #0, #0, #0, #0, #0, #0, #0

; Primeira posição deve ser o caracter a ser enviado, segunda posição deve ser o terminador de string
CharString:               db #0, #0

; array SSD representa o array de valores a serem postos nos displays de sete seg
                           ;|  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
arraySSD:                 db #03h, #9fh, #25h, #0dh, #99h, #49h, #41h, #1fh, #01h, #09h

;                            | D  | E | L  | A |  Y |  /0  |
stringDelay:              db #68, #69, #76, #65, #89, #0

; String contendo caracteres de nova linha e carriage return
stringNovaLinha:          db #10, #13, #0

;-------------------------------------------VARIAVEIS DE APLICAÇÃO-------------------------------------------

; Array para aplicação principal (Bubble Sort) de 50 elementos
arraySort:                db #0050h, #0049h, #0048h, #0047h, #0046h, #0045h, #0044h, #0043h, #0042h, #0041h, #0040h, #0039h, #0038h, #0037h, #0036h, #0035h, #0034h, #0033h, #0032h, #0031h, #0030h, #0029h, #0028h, #0027h, #0026h, #0025h, #0024h, #0023h, #0022h, #0021h, #0020h, #0019h, #0018h, #0017h, #0016h, #0015h, #0014h, #0013h, #0012h, #0011h, #0010h, #0009h, #0008h, #0007h, #0006h, #0005h, #0004h, #0003h, #0002h, #0001h

; Tamanho do array p/ bubble sort (50 elementos)
arraySortSize:            db #50

.enddata
