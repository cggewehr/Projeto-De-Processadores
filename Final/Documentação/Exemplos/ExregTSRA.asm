
;   r1 <= &TrapsServiceRoutine (TSR)
    ldh r1, #TrapsServiceRoutine
    ldl r1, #TrapsServiceRoutine
    
;   regTSRA <= &TrapsServiceRoutine
    ldtsra r1
    
;   Nesse ponto regTSRA contém o endereço da TSR
    nop
    