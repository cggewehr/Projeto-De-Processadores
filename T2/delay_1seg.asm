
.org #0000h

; Contador de 1 em 1 seg
; Frequência do clk = 50 Mhz
; 50 Mhz = 50.000.000 ciclos por seg
; Pra gastar 50 000 000 ciclos



; nao da pra contar tudo em uma tacada so
; vamos utilizar 2 loops
; 0 - 50 000 e 0 - 25 e o corpo do laço gastando 40 ciclos

.code

main:
    ; reg 0 recebe 0
    xor r0, r0, r0,         ; registrador utilizado pra ajudar no st (r0 <- 0 )
    
    ; seta o SP pra a nova posição
    ldh r15, #7fh
    ldl r15, #ffh           ; carrega o sp para a nova posição
    
    ldsp r15                ; novo sp
    
    ldh r1, #80h     
    ldl r1, #00h            ; carrega no r1 o endereço do disp
    ; primeira coisa a mostrar no disp
    xor r10, r10, r10       ; r10 <- 0
    
    st r10, r0, r1          ; comeca a contagem (disp <- 0 )
    
um_seg:    
    jsrd #contagem
    jsrd #resolve_delay
    addi r10, #1            ; incrementa o display
    st r10, r0, r1          ; Mostra a contagem
    jmpd #um_seg
    halt                    ; nunca chega
   
    
    ; Primeira SUBROTINA, realiza um delay de 50 000 000 ciclos
contagem:
    push r0
    push r1 
    push r2
    
    ldh r1, #c3h
    ldl r1, #00h           ; inicializa o primeiro contador (r1 <- 50 000)
    ldh r2, #00h
    ldl r2, #2fh            ; inicializa o segundo contador (r2 <- 47)
    
; Primeiro laço de repetição 0 - 50 000
loop_1:
    subi r1, #1             ; decremento de r1 ( r1 <= r1 -1)
    
    nop
    nop
    nop
    
    jmpzd #loop_2           ; Pula para o segundo loop
    jmpd #loop_1           ; Realiza mais uma iteração
    
    ; Segundo laço de repetição  0 - 47 
loop_2:
    subi r2, #1             ; decremento de r2 ( r2 <= r2 -1)
    jmpzd #fim              ; finaliza o programa com um delay de 1 seg
    ldh r1, #c3h
    ldl r1, #00h            ; Reinicializa o primeiro contador (r1 <- 50 000)
    jmpd #loop_1            ; retoma o primeiro laço
fim:
    pop r2
    pop r1
    pop r0
    rts                     ; retorna a subrotina



    ; Loop para tratar o delay, repete 8467 vezes
resolve_delay:
    push r0
    ldh r0, #21h
    ldl r0, #13h
    
loop_resolve_delay:
    
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop              ;86 ciclos de delay
    
    subi r0, #1 
    jmpzd #fim_resolve
    jmpd #loop_resolve_delay

fim_resolve:
    pop r0
    rts


.endcode