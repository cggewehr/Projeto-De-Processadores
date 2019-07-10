.code

;   Seta RATE_FREQ_BAUD = 869 (0x364) (57600 baud @ 50 MHz)
    ldh r1, #arrayUART_TX
    ldl r1, #arrayUART_TX
    addi r1, #1
    ld r1, r0, r1  ; r1 <= &RATE_FREQ_BAUD (TX)
    ldh r5, #03h
    ldl r5, #64h   ; Seta BAUD_RATE = 869
    st r5, r0, r1  

;   r1 <= 0 (Identificador do syscall PrintString)
    ldh r1, #0
    ldl r1, #0

;   r2 <= Ponteiro para string a ser enviada por UART TX
    ldh r2, #StringASerTransmitida
    ldl r2, #StringASerTransmitida
    
;   Executa syscall ID 0 (PrintString), em r1, e ponteiro para string a ser transmitida, em r2
    syscall
    
    halt

.endcode

.data

; Array de registradores do controlador de interrupções
; arrayUART_TX [ TX_DATA(0x8080) | RATE_FREQ_BAUD(0x8081) | READY(0x8082) ]
arrayUART_TX:             db #8080h, #8081h, #8082h

; "String syscall PrintString"
StringASerTransmitida:    db #45h, #78h, #65h, #6dh, #70h, #6ch, #6fh, #20h, #73h, #79h, #73h, #63h, #61h, #6ch, #6ch, #20h, #50h, #72h, #69h, #6eh, #74h, #53h, #74h, #72h, #69h, #6eh, #67h, #0

.enddata