
;   r0 <= 0
    xor r0, r0, r0

;   r1 <= 0x00C0 = "00000000_11110000" (Habilita apenas interrupções geradas pela porta de E/S)
    ldh r1, #00h
    ldl r1, #C0h
    
;   r2 <= 0x80F2 = &Mask
    ldh r2, #80h
    ldl r2, #F2h
    
;   Mask <= 0x00C0
    st r1, r0, r2
    