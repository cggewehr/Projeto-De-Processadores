


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8 
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O VIA PIC

; APLICAÇÃO ATUAL:
; CONTADORES MANUAL E AUTOMATICO ( 1 SEG ) EXIBIDOS EM 4 DISPLAYS DE 7 SEGMENTOS 

; CHANGELOG:
; v0.1 (Gewehr) 01/05/2019 : Versão Inicial 
;

; TODO: 
;

; OBSERVAÇÕES:
;   - Respeitar o padrão de registradores estabelecidos
;   - Novas adições ao código deve ser o mais modular possível
;   - Subrotinas importantes devem começar com letra maiuscula e não serem identadas
;   - Subrotinas auxiliares devem começar com letra minuscula e serem identada com 2 espaços
;   - Instruções devem ser identadas com 4 espaços

; REGISTRADORES:
; --------------------- r0  = 0
; --------------------- r1  = ID de SYSCALL
; --------------------- r2  = Parametro para subrotina
; --------------------- r3  = Parametro para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

.org #0000h

.code

;-----------------------------------------------------BOOT---------------------------------------------------

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

; irq[7] = port_io[15] = BUTTON DOWN
; irq[6] = port_io[14] = BUTTON UP
; irq[5] = ṕort_io[13] = MASKED
; irq[4] = ṕort_io[12] = MASKED
; irq[3] = OPEN
; irq[2] = OPEN
; irq[1] = UART RX DATA AV = MASKED
; irq[0] = OPEN

; port_io[15] = BUTTON DOWN
; port_io[14] = BUTTON UP
; port_io[13] = OPEN
; port_io[12] = DISPLAY 3 (LEFT-MOST)
; port_io[11] = DISPLAY 2
; port_io[10] = DISPLAY 1
; port_io[9]  = DISPLAY 0 (RIGHT-MOST)
; port_io[8]  = OPEN
; port_io[7]  = SEGMENT A
; port_io[6]  = SEGMENT B
; port_io[5]  = SEGMENT C
; port_io[4]  = SEGMENT D
; port_io[3]  = SEGMENT E
; port_io[2]  = SEGMENT F
; port_io[1]  = SEGMENT G
; port_io[0]  = SEGMENT P

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
    ldl r6, #arrayPorta
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
    ldl r6, #arrayPorta
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
    ldl r6, #arrayPorta
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
    ldl r6, #arrayPorta
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

  loop:              ; Repete 2500 vezes, 20 ciclos
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
    ldl r5, #99
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

; Vetor com tratadores de interrupção
interruptVector:          db #irq0Handler, #irq1Handler, #irq2Handler, #irq3Handler, #irq4Handler, #irq5Handler, #irq6Handler, #irq7Handler

;-------------------------------------------VARIAVEIS DE APLICAÇÃO-------------------------------------------

; Contadores
contadorContinuo: db #0000h
contadorManual:   db #0000h
contador8ms:      db #0000h

; array SSD representa o array de valores a serem postos nos displays de sete seg
;                           |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
arraySSD:                 db #03h, #9fh, #25h, #0dh, #99h, #49h, #41h, #1fh, #01h, #09h

; Array que escolhe qual disp sera utilizado  Mais da direita -> Mais da esquerda
arrayDisp:  db #1C00h, #1A00h, #1600h, #0E00h

; Array que retorna dezena do numero indexador
arrayDEC:   db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h  

; Array que retorna unidade do numero indexador               
arrayUNI:   db #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h,#0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h

.enddata
