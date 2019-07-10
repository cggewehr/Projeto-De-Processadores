.code

;   r1 <= 4 (Identificador do syscall IntegerToSSD)
    ldh r1, #0
    ldl r1, #4

;   r2 <= Numero a ser codificado, neste exemplo, 8
    ldh r2, #0
    ldl r2, #8
    
;   Executa syscall ID 4 (IntegerToSSD), em r1, e valor inteiro a ser codificado, em r2
    syscall

;   Neste ponto r14 contem o numero 8 codificado (r14 = xxxxxxxx00000001)
    halt
    
.endcode

.data








.enddata