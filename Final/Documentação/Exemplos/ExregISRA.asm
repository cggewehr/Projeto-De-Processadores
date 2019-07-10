
;   r1 <= &InterruptionServiceRoutine (ISR)
    ldh r1, #InterruptionServiceRoutine
    ldl r1, #InterruptionServiceRoutine
    
;   regISRA <= &InterruptionServiceRoutine
    ldisra r1
    
;   Nesse ponto regISRA contém o endereço da ISR
    nop
    