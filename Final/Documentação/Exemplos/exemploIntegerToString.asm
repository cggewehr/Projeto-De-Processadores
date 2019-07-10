.code

;   r1 <= 1 (Identificador do syscall IntegerToString)
    ldh r1, #0
    ldl r1, #1

;   r2 <= Numero a ser convertido, no caso, 890
    ldh r2, #03h
    ldl r2, #7ah
    
;   Executa syscall ID 1 (IntegerToString), em r1, e valor inteiro a ser convertido, em r2
    syscall

;   Nesse ponto, encontra-se em r14 um ponteiro para uma string contendo os caracteres: ( ‘8’, ‘9’, ‘0’ e ‘\0’)
    halt
    
.endcode

.data








.enddata