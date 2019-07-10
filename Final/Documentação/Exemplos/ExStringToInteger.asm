
;   r1 <= 6 (Identificador do syscall StringToInteger)
    ldh r1, #0
    ldl r1, #6
    
;   r2 <= Ponteiro para string onde numero a ser convertido está localizado
    ldh r2, #stringNumeroEmASCII
    ldl r2, #stringNumeroEmASCII

;   Executa syscall ID 6 (StringToInteger), em r1, e ponteiro para string com valor a ser convertido, em r2
    syscall
    
;   Supondo que "stringNumeroEmASCII" aponte para ('5', '2', '0', '\0'), após o syscall r14 conterá o valor 520
    halt
    