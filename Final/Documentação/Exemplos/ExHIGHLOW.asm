
;   r1 <= 255
    ldh r1, #0
    ldl r1, #255
    
;   r2 <= 33
    ldh r2, #0
    ldl r2, #33
    
;   r1 * r2 = 8415 = 0x20DF (regHIGH <= 0x20, regLOW <= 0xDF)
    mul r1, r2
    
;   r11 <= 0x20
    mfh r11
    
;   r12 <= 0xDF
    mfl r12
    
;   Nesse ponto r11 contem a parte alta da multiplicação entre r1 e r2, e r12 a parte baixa
    nop
    
;   r1 / r2, quociente = 7, resto = 24
    div r1, r2
    
;   r11 <= 24
    mfh r11
    
;   r12 <= 7
    mfl r12
    
;   Nesse ponto r11 contem o resto da divisão entre r1 e r2, e r12 o quociente
    nop
    