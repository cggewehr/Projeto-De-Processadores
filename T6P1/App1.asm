


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8 
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O

; APLICAÇÃO ATUAL:
; CONTADORES MANUAL E AUTOMATICO ( 1 SEG ) EXIBIDOS EM 4 DISPLAYS DE 7 SEGMENTOS 

; CHANGELOG:
; v0.1 (Gewehr) 01/05/2019 : Versão Inicial 
;   - Define campos de código para: Boot (1ª instrução aponta para main, 2ª para ISR)
;                                   Setup (configuração da porta de I/O e etc)
;                                   Programa Principal
;                                   Subrotinas
;                                   Tratamento de Interrupção
;                                   Drivers

; TODO: (as of v0.1)
;   - Implementar subrotinas HEXtoDEC e Delay2ms

; OBSERVAÇÕES:
;   - O parametro ISR_ADDR deve ser setado para 0x"0001" na instanciação do processador
;   - Respeitar o padrão de registradores estabelecidos
;   - Novas adições ao código deve ser o mais modular possível
;   - Subrotinas importantes devem começar com letra maiuscula
;   - Subrotinas auxiliares devem começar com letra minuscula e serem identada com 2 espaços
;   - Instruções devem ser identadas com 4 espaços

; REGISTRADORES:
; --------------------- r0  = 0
; --------------------- r2  = PARAMETRO para subrotina
; --------------------- r3  = PARAMETRO para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

.org #0000h

.code

;-----------------------------------------------------BOOT---------------------------------------------------

    jmpd #setup                               ;Sempre primeira instrução do programa
    jmpd #InterruptionServiceRoutine          ;Sempre segunda instrução do programa

;---------------------------------------------CONFIGURAÇÃO INICIAL-------------------------------------------

setup:

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
    ldl r8, #C0h   ; Carrega a Mascara para o PIC [ r8 <= "0000_0000_1100_0000"]

    st r8, r0, r7  ; arrayPIC [MASK] <= "xxxx_xxxx_1100_0000"

    ; Array de registradores do controlador de interrupções
    ; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ]
    
    xor r4, r4, r4
    
;   r1 <= &arrayPorta
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1
    
;   Seta PortConfig
    addi r4, #01h  ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #C0h   ; r5 <= "11000000_00000000"
    ldl r5, #00h   ; bit 15 e 14 = entrada, outros = saida
    st r5, r1, r4  ; PortConfig <= "11000000_00000000"

;   Seta irqtEnable
    ldl r4, #03h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #C0h   ; r5 <= "11000000_00000000"
    ldl r5, #00h   ; Habilita a interrupção nos bits 15 e 14
    st r5, r1, r4  ; irqtEnable <= "11000000_00000000"
    
;   Seta PortEnable
    ldl r4, #02h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #DEh   ; r5 <= "11011110_11111111"
    ldl r5, #FFh   ; Habilita acesso a todos os bits da porta de I/O, menos bit 13 e bit 8
    st r5, r1, r4  ; PortEnable <= "11011110_11111111"
    
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

; port_io[15] = BUTTON DOWN
; port_io[14] = BUTTON UP
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

irq1Handler: ; UART RX

    halt

irq2Handler: ; OPEN

    halt

irq3Handler: ; OPEN

    halt

irq4Handler: ; OPEN

    halt

irq5Handler: ; OPEN

    halt

irq6Handler: ; I/O PORT BIT 14 (BUTTON UP)

    jsrd #driverButtonUp
    rts

irq7Handler: ; I/O PORT BIT 15 (BUTTON DOWN)

    jsrd #driverButtonDown
    rts

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

driverButtonUp:

;   Driver incrementa contador manual

    push r1
    push r5
    push r6
    
    xor r0, r0, r0
    xor r1, r1, r1
    xor r5, r5, r5
    xor r6, r6, r6
    
;   r1 <= &contadorManual
    ldh r1, #contadorManual
    ldl r1, #contadorManual
    
;   r5 <= contadorManual
    ld r5, r1, r0
    
;   se contadorManual for == 99, volta para 0
    ldl r6, #99
    sub r6, r5, r6
    jmpzd #driverbuttonupld0
    
;   Incrementa valor de contadorManual
    addi r5, #01h
    
  returndriverbuttonupld0:  
    
;   Atualiza valor de contadorManual
    st r5, r1, r0
    
    pop r6
    pop r5
    pop r1
    
    rts

  driverbuttonupld0:
    xor r5, r5, r5
    jmpd #returndriverbuttonupld0

driverButtonDown:

;   Driver decrementa contador manual

    push r1
    push r5
    
    xor r0, r0, r0
    xor r1, r1, r1
    xor r5, r5, r5
    
;   r1 <= &contadorManual
    ldh r1, #contadorManual
    ldl r1, #contadorManual
    
;   r5 <= contadorManual
    ld r5, r1, r0
    add r5, r0, r5 ; Gera flag
    jmpzd #driverbuttondownld99
    
;   Decrementa valor de contadorManual
    subi r5, #01h
    
  returndriverbuttondownld99:  
    
;   Atualiza valor de contadorManual
    st r5, r1, r0
    
    pop r5
    pop r1
    
    rts

  driverbuttondownld99:
    ldl r5, #99
    jmpzd #returndriverbuttondownld99

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
    
;----------------------------------------------LOOP PRINCIPAL------------------------------------------------

main:

;   Exibe no Display 0 (mais à direita) a unidade do contador de 1 seg durante 2 ms
    jsrd #Display0
    jsrd #Delay2ms
    
;   Exibe no Display 1 a dezena do contador de 1 seg durante 2 ms
    jsrd #Display1
    jsrd #Delay2ms
    
;   Exibe no Display 2 a unidade do contador manual durante 2 ms
    jsrd #Display2
    jsrd #Delay2ms
    
;   Exibe no Display 3 (mais à esquerda) a dezena do contador manual durante 2 ms
    jsrd #Display3
    jsrd #Delay2ms
    
;   Se passado 1 seg, incrementa contador de 1 seg
    jsrd #IncrementaContinuo
    
;   Volta ao inicio
    jmpd #main
    
;------------------------------------------------SUBROTINAS--------------------------------------------------
    
; Display0:                DONE   
; Display1:                DONE   
; Display2:                DONE   
; Display3:                DONE   
; Delay2ms:                DONE
; HEXtoDEC:                DONE
; DECtoSSD:                DONE
; IncrementaContinuo:      DONE
    
Display0:
 
;REGISTRADORES:
; - r1: &arrayDisp
; - r2: &contadorContinuo, contadorContinuo
; - r5: Dado a ser escrito
; - r6: Endereço do registrador de dados da porta

    push r1
    push r2
    push r5
    push r6
    
    xor r1, r1, r1
    xor r2, r2, r2
    xor r5, r5, r5
    xor r6, r6, r6
    
;   r1 <= &arrayDisp
    ldh r1, #arrayDisp
    ldl r1, #arrayDisp
    
;   r5 <= Codigo do Display 0 ( arrayDisp[0] )
    ld r5, r0, r1
    
;   r2 <= &contadorContinuo  (ponteiro)
    ldh r2, #contadorContinuo
    ldl r2, #contadorContinuo
    
;   r2 <= contadorContinuo   (valor)
    ld r2, r0, r2
    
;   passa contadorContinuo como argumento para HEXtoDEC
    jsrd #HEXtoDEC
    
;   r2 <= valor da unidade da conversão decimal de contadorContinuo(r14 contem dezena, r15 contem unidade)
    xor r2, r2, r2
    add r2, r0, r15
    
;   Converte decimal para codigo do display de 7 segmentos (r14 contem numero convertido)
    jsrd #DECtoSSD
    
;   r5 <= Dado pronto para ser escrito na porta
    add r5, r5, r14
    
;   r6 <= &arrayPorta
    ldh r6, #arrayPorta
    ldh r6, #arrayPorta
    ld r6, r0, r6
    
;   PortData <= Display0 + Numero
    st r5, r0, r6
    
    pop r6
    pop r5
    pop r2
    pop r1
    
    rts
    
Display1:

;REGISTRADORES:
; - r1: &arrayDisp
; - r2: &contadorContinuo, contadorContinuo
; - r5: Dado a ser escrito
; - r6: Endereço do registrador de dados da porta
    
    push r1
    push r2
    push r5
    push r6
    
    xor r1, r1, r1
    xor r2, r2, r2
    xor r5, r5, r5
    xor r6, r6, r6
    
;   r1 <= &arrayDisp
    ldh r1, #arrayDisp
    ldl r1, #arrayDisp
    
;   r5 <= Codigo do Display 1 ( arrayDisp[1] )
    addi r1, #01h
    ld r5, r0, r1
    
;   r2 <= &contadorContinuo  (ponteiro)
    ldh r2, #contadorContinuo
    ldl r2, #contadorContinuo
    
;   r2 <= contadorContinuo   (valor)
    ld r2, r0, r2
    
;   passa contadorContinuo como argumento para HEXtoDEC
    jsrd #HEXtoDEC
    
;   r2 <= valor da dezena da conversão decimal de contadorContinuo (r14 contem dezena, r15 contem unidade)
    xor r2, r2, r2
    add r2, r0, r14
    
;   Converte decimal para codigo do display de 7 segmentos (r14 contem numero convertido)
    jsrd #DECtoSSD
    
;   r5 <= Dado pronto para ser escrito na porta
    add r5, r5, r14
    
;   r6 <= &arrayPorta
    ldh r6, #arrayPorta
    ldh r6, #arrayPorta
    ld r6, r0, r6
    
;   PortData (arrayDisp[0]) <= Display0 + Numero
    st r5, r0, r6
    
    pop r6
    pop r5
    pop r2
    pop r1
    
    rts
    
Display2:

;REGISTRADORES:
; - r1: &arrayDisp
; - r2: &contadorManual, contadorManual
; - r5: Dado a ser escrito
; - r6: Endereço do registrador de dados da porta
    
    push r1
    push r2
    push r5
    push r6
    
    xor r1, r1, r1
    xor r2, r2, r2
    xor r5, r5, r5
    xor r6, r6, r6
    
;   r1 <= &arrayDisp
    ldh r1, #arrayDisp
    ldl r1, #arrayDisp
    
;   r5 <= Codigo do Display 2 ( arrayDisp[2] )
    addi r1, #02h
    ld r5, r0, r1
    
;   r2 <= &contadorManual  (ponteiro)
    ldh r2, #contadorManual
    ldl r2, #contadorManual
    
;   r2 <= contadorManual   (valor)
    ld r2, r0, r2
    
;   passa contadorManual como argumento para HEXtoDEC
    jsrd #HEXtoDEC
    
;   r2 <= valor da unidade da conversão decimal de contadorContinuo (r14 contem dezena, r15 contem unidade)
    xor r2, r2, r2
    add r2, r0, r15
    
;   Converte decimal para codigo do display de 7 segmentos (r14 contem numero convertido)
    jsrd #DECtoSSD
    
;   r5 <= Dado pronto para ser escrito na porta
    add r5, r5, r14
    
;   r6 <= &arrayPorta
    ldh r6, #arrayPorta
    ldh r6, #arrayPorta
    ld r6, r0, r6
    
;   PortData (arrayDisp[0]) <= Display0 + Numero
    st r5, r0, r6
    
    pop r6
    pop r5
    pop r2
    pop r1
    
    rts
    
Display3:

;REGISTRADORES:
; - r1: &arrayDisp
; - r2: &contadorManual, contadorManual
; - r5: Dado a ser escrito
; - r6: Endereço do registrador de dados da porta
    
    push r1
    push r2
    push r5
    push r6
    
    xor r1, r1, r1
    xor r2, r2, r2
    xor r5, r5, r5
    xor r6, r6, r6
    
;   r1 <= &arrayDisp
    ldh r1, #arrayDisp
    ldl r1, #arrayDisp
    
;   r5 <= Codigo do Display 3 ( arrayDisp[3] )
    addi r1, #03h
    ld r5, r0, r1
    
;   r2 <= &contadorManual  (ponteiro)
    ldh r2, #contadorManual
    ldl r2, #contadorManual
    
;   r2 <= contadorManual   (valor)
    ld r2, r0, r2
    
;   passa contadorManual como argumento para HEXtoDEC
    jsrd #HEXtoDEC
    
;   r2 <= valor da dezena da conversão decimal de contadorContinuo (r14 contem dezena, r15 contem unidade)
    xor r2, r2, r2
    add r2, r0, r14
    
;   Converte decimal para codigo do display de 7 segmentos (r14 contem numero convertido)
    jsrd #DECtoSSD
    
;   r5 <= Dado pronto para ser escrito na porta
    add r5, r5, r14
    
;   r6 <= &arrayPorta
    ldh r6, #arrayPorta
    ldh r6, #arrayPorta
    ld r6, r0, r6
    
;   PortData (arrayDisp[0]) <= Display0 + Numero
    st r5, r0, r6
    
    pop r6
    pop r5
    pop r2
    pop r1
    
    rts
    
Delay2ms: 

    push r4
    
    xor r4, r4, r4
    
;   iterador do loop <= 5000
    ldh r4, #13h
    ldl r4, #88h
  
  loopDentro:        ; Repete 2500 vezes, 20 ciclos
    subi r4, #1      ;  4 ciclos
    nop              ;  7 ciclos
    nop              ; 10 ciclos
    nop              ; 13 ciclos
    jmpzd #loopExit  ; 16 ciclos
    jmpd #loop       ; 20 ciclos

  loopExit:
    
    pop r4
    
    rts
    
HEXtoDEC: ; Divide em parte decimal e parte unitaria o numero passado como parametro (em r2)

; REGISTRADORES: 
; - r2: Numero a ser convertido
; - r14: Dezena do numero convertido  (arrayDEC[Numero a ser convertido])
; - r15: Unidade do numero convertido  (arrayDEC[Numero a ser convertido])

;   r14 <= &arrayDEC    
    ldh r14, #arrayDEC
    ldl r14, #arrayDEC
    
;   r14 <= arrayDEC[r2]
    ld r14, r14, r2
    
;   r15 <= &arrayUNI
    ldh r15, #arrayUNI
    ldl r15, #arrayUNI
    
;   r15 <= arrayUNI[r2]
    ld r15, r15, r2
    
    rts                    

DECtoSSD: ; Recebe numero a ser convertido em r2, retorna numero convertido em r14

;REGISTRADORES:
; - r1: &arraySSD
; - r14: Codigo do display de 7 segmentos do numero passado como argumento

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

IncrementaContinuo:

;REGISTRADORES:
; - r1: &contador8ms, &contadorContinuo
; - r4: contador8ms, contadorContinuo         (Registrador que afetua escrita em memoria)
; - r5: Constante 126 (Mascara de comparação)
    
    push r1
    push r4
    push r5
    
    xor r1, r1, r1
    xor r4, r4, r4
    xor r5, r5, r5
    
;   r1 <= &contador8ms
    ldh r1, #contador8ms
    ldl r1, #contador8ms
    
;   r4 <= contador8ms
    ld r4, r0, r1

;   contador8ms++
    addi r4, #01h
    
;   Salva novo valor de contador8ms
    st r4, r0, r1

;   Se novo valor = 126, zera contador de 8 ms e incrementa contador de 1 seg
    
;   r5 <= 126
    ldl r5, #126

;   Se contador8ms == 126
    and r4, r4, r5
    sub r4, r4, r5
    jmpzd #incrementa1seg

  returnIncrementa1seg:    
 
    pop r5
    pop r4
    pop r1
    
    rts
    
  incrementa1seg: 
    
;   r1 <= &contadorContinuo
    ldh r1, #contadorContinuo
    ldl r1, #contadorContinuo
    
;   r4 <= contadorContinuo
    ld r4, r0, r1
 
;   
    ldh r5, #0
    ldh r5, #99
    sub r5, r4, r5
    jmpzd #incrementa1segld0
    
;   contadorContinuo++
    addi r4, #01h
    
  returnincrementa1segld0:
  
;   Salva novo valor de contadorContinuo
    st r4, r0, r1
    
;   r1 <= &contador8ms
    ldh r1, #contador8ms
    ldl r1, #contador8ms 

;   r4 <= contador8ms
    ld r4, r0, r1

;   contador8ms = 0
    xor r4, r4, r4
    
;   Salva novo valor de contador8ms
    st r4, r0, r1
    
    jmpd #returnIncrementa1seg
    
  incrementa1segld0:
    xor r4, r4, r4
    jmpd #returnincrementa1segld0

.endcode

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
IntegerToHexBuffer:       db #0, #0, #0, #0, #0

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

; Contadores
contadorContinuo: db #0000h
contadorManual:   db #0000h
contador8ms:      db #0000h

; array SSD representa o array de valores a serem postos nos displays de sete seg
             ;|  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
arraySSD:   db #03h, #9fh, #25h, #0dh, #99h, #49h, #41h, #1fh, #01h, #09h

; Array que escolhe qual disp sera utilizado  Mais da direita -> Mais da esquerda
arrayDisp:  db #1E00h, #1A00h, #1600h, #0E00h

; Array que retorna dezena do numero indexador
arrayDEC:   db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h  

; Array que retorna unidade do numero indexador               
arrayUNI:   db #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h,#0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h

.enddata
