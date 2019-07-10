.code

;   r1 <= 3 (Identificador do syscall Delayms)
    ldh r1, #0
    ldl r1, #3

;   r2 <= Numero de milisegundos a serem dispediçados em tempo de processador, nesse exemplo, 10
    ldh r2, #0
    ldl r2, #10
    
;   Executa syscall ID 3 (Delayms), em r1, e valor de tempo, em milisegundos, em r2
    syscall

;   Esta instrução só será executada 10 ms após a instrução de syscall anterior
    halt
    
.endcode

.data








.enddata