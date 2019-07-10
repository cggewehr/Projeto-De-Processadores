
;   r0 <= 0
    xor r0, r0, r0
    
;   Seta RATE_FREQ_BAUD = 869 (0x364) (57600 baud @ 50 MHz)
    ldh r1, #80h
    ldl r1, #81h
    ldh r5, #03h
    ldl r5, #64h
    st r5, r0, r1

;   r2 <= 48 (ASCII '0')
    ldh r2, #0
    ldl r2, #48
    
;   r1 <= &Ready
    addi r1, #1
    
  WaitFor0Loop: ; Espera dado recebido ser '0'
  
;   r5 <= Ready
    ld r5, r0, r1
    
;   Se r5 - 48 = 0, ultimo caracter foi '0'
    sub r5, r5, r2
    jmpzd #WaitFor0LoopBreak
    jmpd #WaitFor0Loop
    
  WaitFor0LoopBreak:
  
;   Ultimo dado recebido foi '0'
    halt
    