
;   r1 <= 7 (Identificador do syscall SetTimer)
    ldh r1, #00h
    ldl r1, #07h

;   r2 <= Periodo em microsegundos
    ldh r2, #0
    ldl r2, #200

;   r3 <= Flag de periodicidade do timer
    ldh r3, #0
    ldl r3, #0

;   r5 <= Flag de callback
    ldh r5, #0
    ldl r5, #0
    
;   Em uma diferença de tempo de 200 us será lançada uma interrupção (não periódica)
    syscall
    
;   r1 <= 8 (Identificador do syscall WaitForTimer)
    ldh r1, #0
    ldh r1, #8
    
  WaitForTimerLoop:
  
;   Executa syscall ID 7 (WaitForTimer)
    syscall
    add r14, r0, r14 ; Gera flag de resultado nulo
    jmpzd #WaitForTimerLoop
    
;   Somente executa esta instrução se passados 200 us desde o primeiro syscall (SetTimer)
    halt
    