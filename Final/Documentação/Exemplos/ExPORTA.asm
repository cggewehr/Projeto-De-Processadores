
;   r0 <= 0
    xor r0, r0, r0

;   r1 <= 0xFF00 = 1111111100000000
    ldh r1, #FFh
    ldl r1, #0
    
;   r2 <= 0xAAAA = 1010101010101010
    ldh r2, #AAh
    ldl r2, #AAh
    
;   r3 <= 0x5555 = 0101010101010101
    ldh r3, #55h
    ldl r3, #55h
    
;   r4 <= 0xC000 = 1100000000000000
    ldh r4, #C0h
    ldl r4, #00h
    
;   r5 <= 0x8003 = &portIRQ
    ldh r5, #80h
    ldl r5, #03h

;   portIRQ <= 0xC000 (Habilta geração de interrupção por bits 15 e 14)
    st r4, r0, r5
    
;   r5 <= 0x8002 = &portEnable
    subi r5, #1

;   portEnable <= 0xFF00 (Habilita bits mais significativos da Porta de E/S)
    st r1, r0, r5

;   r5 <= 0x8001 = &portConfig
    subi r5, #1
    
;   portConfig <= 0xAAAA (Seta bits impares como entrada e bits pares como saida)
    st r2, r0, r5
    
;   r5 <= 0x8000 = &portData
    subi r5, #1
    
;   portData <= 0x5555 (Escreve 1 nos bits pares, setados como saida) (Escrita so é efetivada nos bits mais significativos)
    st r3, r0, r5
    