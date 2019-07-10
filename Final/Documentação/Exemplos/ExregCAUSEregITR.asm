
;   r1 <= &TrapsServiceRoutine (TSR)
    ldh r1, #TrapsServiceRoutine
    ldl r1, #TrapsServiceRoutine
    
;   regTSRA <= &TrapsServiceRoutine
    ldtsra r1
    
;   r1 <= 0x7FFF = 32767 (Maior numero representavel em complemento de 2 com 16 bits)
    ldh r1, #7Fh
    ldl r1, #FFh
    
;   r1 <= 0x8000 = -32768 (Signed) (Overflow)
    addi r1, #1
    
;    No estado de busca dessa instrução será identificada uma trap de código 12 (Overflow)
;   em regCAUSE estará contido o valor 12 (ID da trap) e em regITR o endereço de memória da instrução addi + 1
;   Também deve-se notar que está instrução somente será executada após o tratamento da trap gerada
    nop
    
;   r2 <= Identificador da ultima trap gerada (12, Overflow)
    mfc r2
    
;   r3 <= Endereço da ultima instrução a gerar uma trap + 1 (&(addi r1, #1) + 1 = &(nop) )
    mft r3
    