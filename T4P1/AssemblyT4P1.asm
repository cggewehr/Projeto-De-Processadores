


; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8 
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; PROCESSADOR R8 COM SUPORTE A INTERRUPÇÕES DE I/O

; APLICAÇÃO ATUAL:
; COMUNICAÇAO COM PERIFERICO "CRYPTOMESSAGE"

; CHANGELOG:
; 

; TODO: (as of v0.1)
;  

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

    jmpd #main
    
;----------------------------------------------LOOP PRINCIPAL------------------------------------------------

main:


    
;------------------------------------------------SUBROTINAS--------------------------------------------------

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


    
;-----------------------------------------TRATAMENTO DE INTERRUPÇÃO------------------------------------------

InterruptionServiceRoutine: 

;    1. Salvamento de contexto
;    2. Verificação da origem da interrupção (polling) e salto para o driver correspondente (jsr)
;    3. Recuperação de contexto
;    4. Retorno (rti)

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
    xor r6, r6, r6
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; LEITURA DO DADO DA PORTA, NAO MUDAR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
   
;   r1 <= &PortData
    ldh r1, #arrayPorta
    ldl r1, #arrayPorta
    ld r1, r0, r1
    
;   r5 <= PortData
    ld r5, r0, r1
    
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; LEITURA DO DADO DA PORTA, NAO MUDAR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     

;   Carrega mascara de comparação para BTN DOWN (bit 15)
    ldh r1, #80h
    ldl r1, #00h
    
;   Se operação com mascara resultar em 0, botao foi pressionado
    and r6, r1, r5
    sub r6, r6, r1
    jmpzd #callDriverBit15

  returnCallDriverBit15:
  
;   Carrega mascara de comparação para BTN DOWN (bit 14)
    ldh r1, #40h
    ldl r1, #00h    

;   Se operação com mascara resultar em 0, botao foi pressionado
    and r6, r1, r5
    sub r6, r6, r1
    jmpzd #callDriverBit14   
    
  returnCallDriverBit14:
    
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

callDriverBit15:
    jsrd #driverButtonDown
    jmpd #returnCallDriverBit15
    
callDriverBit14:
    jsrd #driverButtonUp
    jmpd #returnCallDriverBit14
    
;;;;;;;;; DRIVERS

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

.endcode

.data

; Contadores
contadorContinuo: db #0000h
contadorManual:   db #0000h
contador8ms:      db #0000h

; array de regs da Porta Bidirecional

; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta: db #8000h, #8001h, #8002h, #8003h

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
