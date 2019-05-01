


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

;   Inicializa ponteiro da pilha para 0x"7FFF" (ultimo endereço no espaço de endereçamento da memoria
    ldh r0, #7Fh
    ldl r0, #FFh
    ldsp r0
    
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
    
;   r1 <= &arrayPorta
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta

    add r4, r0, r1 ; Carrega indexador de arrayPorta  [ arrayPorta[r4] -> &PortData ]
    
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

    jmpd #main
    
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
    
;   PortData (arrayDisp[0]) <= Display0 + Numero
    st r5, r0, r6
    
    pop r6
    pop r5
    pop r2
    pop r1
    
    rts
    
Delay2ms: 

; Tclk = 20 ns, deve iterar por 50 000 000 = 50x10^6 ciclos

; 50 * 1x10^6 = 10^3 * (20 * 2500) = (40 * 25) * (20 * 2500)

    push r4
    push r5
    
    xor r4, r4, r4
    xor r5, r5, r5
    
;   iterador do loop de dentro <= 2500
    ldh r4, #09h
    ldl r4, #C4h
    
;   iterador do loop de fora <= 25
    ldl r5, #25
    
  loopFora:          ; Repete 25 vezes, 40 ciclos
    nop              ;  3 ciclos
    nop              ;  6 ciclos
    nop              ;  9 ciclos
    nop              ; 12 ciclos
    nop              ; 15 ciclos
    nop              ; 18 ciclos
    nop              ; 21 ciclos
    ldh r4, #09h     ; 25 ciclos
    ldl r4, #C4h     ; 29 ciclos
    subi r5, #1      ; 33 ciclos 
    jmpzd #loopExit  ; 36 ciclos
    jmpd #loopDentro ; 40 ciclos
  
  loopDentro:        ; Repete 2500 vezes, 20 ciclos
    subi r4, #1      ;  4 ciclos
    nop              ;  7 ciclos
    nop              ; 10 ciclos
    nop              ; 13 ciclos
    jmpzd #loopFora  ; 16 ciclos
    jmpd #loopDentro ; 20 ciclos

  loopExit:
    
    pop r5
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
    
;   contadorContinuo++
    addi r4, #01h
    
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
    
;-----------------------------------------TRATAMENTO DE INTERRUPÇÃO------------------------------------------

InterruptionServiceRoutine: 

;    1. Salvamento de contexto
;    2. Verificação da origem da interrupção (polling) e salto para o driver correspondente (jsr)
;    3. Recuperação de contexto
;    4. Retorno (rti)

;///////////////////////////     INPUT    ///////////////////////////
;net "port_io[14]" loc = A8;    // BUTTON UP
;net "port_io[15]" loc = C9;    // BUTTON DOWN

; Interrupção pode ser gerada por bit 15 e bit 14

;   Salva contexto
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
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; LEITURA DO DADO DA PORTA, NAO MUDAR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
   
;   r1 <= &PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    
;   r5 <= PortData
    ld r5, r0, r1
    
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; LEITURA DO DADO DA PORTA, NAO MUDAR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     

;   Carrega mascara de comparação para BTN UP (bit 15)
    ldh r1, #80h
    ldl r1, #00h
    
;   Se operação com mascara resultar em 0, botao foi pressionado
    and r1, r1, r5
    sub r1, r1, r5
    jmpzd #callDriverButtonUp

  returnCallDriverButtonUp:
  
;   Carrega mascara de comparação para BTN DOWN (bit 14)
    ldh r1, #40h
    ldl r1, #00h    

;   Se operação com mascara resultar em 0, botao foi pressionado
    and r1, r1, r5
    sub r1, r1, r5
    jmpzd #callDriverButtonDown   
    
  returnCallDriverButtonDown:
    
;   ADICIONAR AQUI TRATAMENTO PARA NOVOS GERADORES DE INTERRUPÇÃO
    
    
    

;   Recupera contexto
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

;--------------------------------------------------DRIVERS---------------------------------------------------

;;;;;;;; CHAMADAS P/ DRIVERS

callDriverButtonUp:
    jsrd #driverButtonUp
    jmpd #returnCallDriverButtonUp
    
callDriverButtonDown:
    jsrd #driverButtonDown
    jmpd #returnCallDriverButtonDown
    
;;;;;;;;; DRIVERS

driverButtonUp:

;   Driver incrementa contador manual

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
    
;   Incrementa valor de contadorManual
    addi r5, #01h
    
;   Atualiza valor de contadorManual
    st r5, r1, r0
    
    pop r5
    pop r1
    
    rts

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
    
;   Decrementa valor de contadorManual
    subi r5, #01h
    
;   Atualiza valor de contadorManual
    st r5, r1, r0
    
    pop r5
    pop r1
    
    rts

.endcode

.data
; array de regs da Porta Bidirecional

; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta: db #8000h, #8001h, #8002h, #8003h

; array SSD representa o array de valores a serem postos nos displays de sete seg
             ;|  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
arraySSD:   db #03h, #9fh, #25h, #0dh, #99h, #49h, #21h, #1fh, #01h, #09h

; Array que escolhe qual disp sera utilizado  Mais da direita -> Mais da esquerda
arrayDisp:  db #0200h, #0400h, #0800h, #1000h

; Array que retorna dezena do numero indexador
arrayDEC:   db #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0000h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0001h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0002h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0003h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0004h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0005h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0006h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0007h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0008h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h, #0009h  

; Array que retorna unidade do numero indexador               
arrayUNI:   db #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h, #0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h,#0000h, #0001h, #0002h, #0003h, #0004h, #0005h, #0006h, #0007h, #0008h, #0009h  

; Contadores
contadorContinuo : db #0000h
contadorManual   : db #0000h
contador8ms      : db #0000h

.enddata
