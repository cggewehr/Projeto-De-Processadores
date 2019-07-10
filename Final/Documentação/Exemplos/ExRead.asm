
;   r1 <= 5 (Identificador do syscall Read)
    ldh r1, #0
    ldl r1, #5
    
;   r2 <= Ponteiro para string onde dados recebidos deve ser salvos
    ldh r2, #stringRecebeDados
    ldl r2, #stringRecebeDados
    
;   r3 <= Quantidade de caracteres a serem transferidos do buffer de entrada para "stringRecebeDados"
    ldh r3, #0
    ldl r3, #3
    
  ReadLoop:
  
;   Executa instrução syscall enquanto dados não forem transferidos para "stringRecebeDados"
    syscall
    add r14, r0, r14 ; Gera flag de resultado nulo
    jmpzd #ReadLoop
    
;    Somente executa esta instrução quando o valor de retorno do syscall Read for diferente de 0
;   ou seja, enquanto 3 caracteres não forem transferidos do buffer de entrada para "stringRecebeDados"
    halt
    