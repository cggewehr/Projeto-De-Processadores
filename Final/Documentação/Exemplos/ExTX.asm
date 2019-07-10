
;   r0 <= 0
    xor r0, r0, r0
    
;   Seta RATE_FREQ_BAUD = 869 (0x364) (57600 baud @ 50 MHz)
    ldh r1, #80h
    ldl r1, #81h
    ldh r5, #03h
    ldl r5, #64h
    st r5, r0, r1
    
;   r1 <= &Ready
    ldh r1, #80h
    ldl r1, #82h
    
  ReadyLoop: ; Espera transmissor estar disponível
  
;   r5 <= Ready
    ld r5, r0, r1
    add r5, r0, r5 ; Gera flag de resultado nulo
    jmpzd #ReadyLoop
    
;   r1 <= &TX_DATA
    ldh r1, #80h
    ldl r1, #80h
    
;   r5 <= 48 (ASCII '0')
    ldh r5, #0
    ldh r5, #48
    
;   Transmite caracter '0' (TX_DATA <= '0')
    st r5, r0, r1
    