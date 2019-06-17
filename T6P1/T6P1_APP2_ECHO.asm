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

;   Seta a Mascara do vetor de interrupções (Desabilita todas menos DATA_AV_UART_Rx)
    ldh r4, #00h
    ldl r4, #02h        ; Atualiza o indexador para carregar a mascara em arrayPIC

    ldh r7, #arrayPIC   ; Carrega endereço da mascara de interrupções
    ldl r7, #arrayPIC   ; 
    ld r7, r4, r7       ; &mask ; ArryaPic na terceira Posição

    ldh r8, #00h
    ldl r8, #02h        ; Carrega a Mascara para o PIC [ r8 <= "0000_0000_0000_0000"]

    st r8, r0, r7       ; arrayPIC [MASK] <= "xxxx_xxxx_0000_0010"

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

;   Inicializa Registrador 
    xor r0, r0, r0
    
;   r1 <= &irqREG
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #3
    ld r1, r0, r1

;   r6 <= &intACK    
    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #1
    ld r6, r0, r1
    
;   r7 <= Irq(1) Mask
    ldh r7, #0
    ldl r7, #2

;   Pula para o programa principal
    jmpd #main

;___________________________________________________END BOOT_________________________________________________

;-------------------------------------------------HANDLERS---------------------------------------------------

Echo: ;  Le o caractere passado pelo terminal e imprime ele novamente no terminal
;   Pega o caractere do  RX_DATA e imprime o mesmo valor no UART_TX
;
;   Register Table:
;       r1: Data recebida pelo modulo RX em RX_DATA
;       r2: Endereço do modulo &UART_TX
;       r5: Estado do transmissor / ACK
;       r6: Endereco do &IntACK

    push r1
    push r2
    push r5
    push r6

;   r1 <= RX_DATA
    ldh r1, #arrayUART_RX
    ldl r1, #arrayUART_RX    ; r1 <= &&arrayUART_RX [RX_DATA]
    ld r1, r0, r1            ; r1 <= &RX_DATA [RX_DATA]
    ld r1, r0, r1            ; r1 <= RX_DATA
    
;   r2 <= UART_TX
    ldh r2, #UART_TX
    ldl r2, #UART_TX
    ld r2, r0, r2            ; r2 <= &UART_TX

;   r6 <= &intACK    
    ldh r6, #arrayPIC
    ldl r6, #arrayPIC        ; r6 <= &arrayPIC
    addi r6, #1              ; r6 <= &arrayPIC[IntACK]

  tx_loop: ; Verifica o estado do transmissor

    ld r5, r0, r2
    add r5, r0, r5 ; Gera Flag
    
    jmpzd #tx_loop  ; Espera o transmissor estar disponivel

;   Escreve em TX_DATA, o dado recebido
    st r1, r0, r2 ; UART_TX <= r1(DATA)

  UartRXDataACK:   ; Manda o ACK

;   intACK <= 1 (UART RX)
    ldh r5, #00h
    ldl r5, #01h
    st r5, r0, r6

    pop r6
    pop r5
    pop r2
    pop r1    

;   Returns to polling loop
    rts

;________________________________________________END HANDLERS________________________________________________

;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------
main:
;   Seta RATE_FREQ_BAUD = 57600 

    ldh r1, #arrayUART_RX
    ldl r1, #arrayUART_RX
    addi r1, #1
    ld r1, r0, r1    ; r1 <= &RATE_FREQ_BAUD
    ldh r5, #E1h
    ldl r5, #00h   ; Seta Baud com 57600
    st r5, r0, r1  ;

    ldh r1, #arrayPIC
    ldl r1, #arrayPIC
    addi r1, #03h  ; r1<= arrayPic[3] = IrqREG

;   r7 <= Irq Mask
    ldh r7, #0
    ldl r7, #2

loop: 
;   r5 <= irqREG
    ld r5, r0, r1
    and r5, r7, r5   ; Compara a interrupção com a mascara

    jmpzd #loop      ; Caso for zero Interrupção Não aconteceu

    jsrd #Echo 

    jmpd #loop


.endcode


.data
;--------------------------------------------VARIAVEIS DO KERNEL---------------------------------------------

; Array de registradores da Porta Bidirecional
; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta:               db #8000h, #8001h, #8002h, #8003h

; Array de registradores do controlador de interrupções
; arrayPIC [ IrqID(0x80F0) | IntACK(0x80F1) | Mask(0x80F2) ] IrqREG(0x80F3) ]
arrayPIC:                 db #80F0h, #80F1h, #80F2h, #80F3h

; Endereço do transmissor serial
UART_TX:                  db #8080h

; Array de registradores do controlador de interrupções
; arrayUART_RX [ RX_DATA(0x80A0) | RATE_FREQ_BAUD(0x80A1) ]
arrayUART_RX:             db #80A0h, #80A1h


.enddata
