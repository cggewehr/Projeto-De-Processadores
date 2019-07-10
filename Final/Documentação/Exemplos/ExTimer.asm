
;   r1 <= 7 (Identificador do syscall SetTimer)
    ldh r1, #00h
    ldl r1, #07h

;   r2 <= Periodo em microsegundos
    ldh r2, #0
    ldl r2, #200

;   r3 <= Flag de periodicidade do timer
    ldh r3, #0
    ldl r3, #1

;   r4 <= Ponteiro para função de callback
    ldh r4, #TimerCallback
    ldl r4, #TimerCallback

;   r5 <= Flag de callback
    ldh r5, #0
    ldl r5, #1
    
;   A cada 200 us será lançada uma nova interrupção e executada a subrotina "TimerCallback"
    syscall
    