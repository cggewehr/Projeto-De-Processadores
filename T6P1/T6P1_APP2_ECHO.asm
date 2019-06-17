; PROJETO DE PROCESSADORES - ELC 1094 - PROF. CARARA
; PROCESSADOR R8
; CARLOS GEWEHR E EMILIO FERREIRA

; DESCRIÇÃO:
; APPLICAÇÃO 2 - LE UM CARACTERE DO TERMINAL E MOSTRA ELE NOVAMENTE NA TELA

; APLICAÇÃO ATUAL:
; CARGA DE CODIGO EM MEMORIA RAM POR RECEPTOR SERIAL

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
; --------------------- r2  = PARAMETRO para subrotina
; --------------------- r3  = PARAMETRO para subrotina
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina

.org #0000h

.code

;-----------------------------------------------------BOOT---------------------------------------------------

;   Inicializa ponteiro da pilha para 0x"7FFF" (ultimo endereço no espaço de endereçamento da memoria)
    ldh r0, #7Fh
    ldl r0, #FFh
    ldsp r0
    
;   Inicializa r0
    xor r0, r0, r0

;   Mascara todas interrupções do PIC
    ldh r7, #arrayPIC   ; Carrega endereço da mascara de interrupções
    ldl r7, #arrayPIC   ; 
    ld r7, r4, r7       ; r7 <= &Mask

    st r0, r0, r7       ; Mask <= "xxxx_xxxx_0000_0000"

    ; Array de registradores do controlador de interrupções
    ; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ]
    ; arrayPIC:   db #80F0h,         #80F1h,          #80F2h

;   Carrega em r1 & arrayPorta  ( r1 <= &arrayPorta)
    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta
    ld r1, r0, r1       ; r1 <= PortData

;   Seta todos os bits de PortConfig como entrada
    ldh r4, #00h
    ldl r4, #01h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #FFh   ; r5 <= "11111111_11111111"
    ldl r5, #FFh   ; Seta todos os bits de PortConfig como entrada
    st r5, r1, r4  ; PortConfig <= "11111111_11111111"

;   Desabilita interrupções pela porta
    ldh r4, #00h
    ldl r4, #03h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h   ; Desabilita todas interrupções pela porta
    st r5, r1, r4  ; irqtEnable <= "00000000_00000000"

;   Desabilita porta
    ldl r4, #02h   ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #00h   ; r5 <= "00000000_00000000"
    ldl r5, #00h   ; Desabilita acesso a todos os bits da porta de I/O
    st r5, r1, r4  ; PortEnable <= "00000000_00000000"

;   Pula para o programa principal
    jmpd #main

;_________________________________________________END BOOT___________________________________________________

;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------
main:

;   Inicializa Registrador r0
    xor r0, r0, r0

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
    
;   r6 <= &intACK    
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #1
    ld r6, r0, r1
    
;   r1 <= &irqREG
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #03h  ; r1<= arrayPic[3] = &IrqREG
    ld r1, r0, r1

;   r7 <= Irq(1) Mask
    ldh r7, #0
    ldl r7, #2

DataAVPollingLoop: ; Espera por DATA_AV de UART RX

;   r5 <= irqREG
    ld r5, r0, r1
    
;   Aplica mascara para o bit 1 (DATA_AV)
    and r5, r7, r5           ; Compara a interrupção com a mascara

    jmpzd #DataAVPollingLoop ; Caso for zero, nenhum dado foi recebido

Echo: ;  Le o caractere passado pelo terminal e imprime ele novamente no terminal
;   Pega o caractere de RX_DATA e imprime o mesmo valor em UART_TX

;   r10 <= RX_DATA
    ldh r10, #arrayUART_RX
    ldl r10, #arrayUART_RX    ; r10 <= &&arrayUART_RX
    ld r10, r0, r10           ; r10 <= &RX_DATA
    ld r10, r0, r10           ; r10 <= RX_DATA
    
;   r12 <= &ready
    ldh r12, #arrayUART_TX
    ldl r12, #arrayUART_TX
    addi r12, #2
    ld r12, r0, r12            ; r12 <= &ready

  tx_loop: ; Espera o transmissor estar disponivel

    ld r5, r0, r12 ; r5 <= ready
    add r5, r0, r5 ; Gera Flag
    jmpzd #tx_loop  

;   Escreve em TX_DATA, o dado recebido
    ldh r12, #arrayUART_TX
    ldl r12, #arrayUART_TX
    ld r12, r0, r12 ; r12 <= &TX_DATA

    st r10, r0, r12 ; UART_TX <= r11 (DATA)

  UartRXDataACK: ; ACK UART_RX DATA_AV

;   intACK <= 1 (UART RX)
    ldh r5, #00h
    ldl r5, #01h
    st r5, r0, r6   

    jmpd #DataAVPollingLoop

.endcode

.data
;--------------------------------------------VARIAVEIS DO KERNEL---------------------------------------------

; Array de registradores da Porta Bidirecional
; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta:               db #8000h, #8001h, #8002h, #8003h

; Array de registradores do controlador de interrupções
; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ] IrqREG(0x80F3) ]
arrayPIC:                 db #80F0h, #80F1h, #80F2h, #80F3h

; Array de registradores do controlador de interrupções
; arrayUART_TX [ TX_DATA(0x80A0) | RATE_FREQ_BAUD(0x80A1) | READY(0x80A2) ]
arrayUART_TX:             db #8080h, #8081h, #8082h

; Array de registradores do controlador de interrupções
; arrayUART_RX [ RX_DATA(0x80A0) | RATE_FREQ_BAUD(0x80A1) ]
arrayUART_RX:             db #80A0h, #80A1h


.enddata
