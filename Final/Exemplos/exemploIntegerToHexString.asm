.code

;   r1 <= 2 (Identificador do syscall IntegerToHexString)
    ldh r1, #0
    ldl r1, #2

;   r2 <= Numero a ser convertido, no caso, 255
    ldh r2, #0
    ldl r2, #255
    
;   Executa syscall ID 2 (IntegerToHexString), em r1, e valor inteiro a ser convertido, em r2
    syscall

;   Nesse ponto, encontra-se em r14 um ponteiro para uma string contendo os caracteres: ( ‘F’, ‘F’, e ‘\0’)
    halt
    
.endcode

.data








.enddata