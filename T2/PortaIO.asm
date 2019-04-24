.org #000h
; Carlos Gewehr e Emilio Ferreira
; Tabela de Registradores:
;
; --------------------- r0 = 0
; --------------------- r1 = &PortData
; --------------------- r2 = &PortConfig
; --------------------- r3 = &PortEnable
; --------------------- r4 = Dado a ser lido/escrito
; --------------------- r15 = Stack Pointer

; 0 = Read, 1 = Write
; MSBs = LEDs, LSBs = Switches
; ID da porta = 0

.code

main:
	; Seta SP para ultimo endereço no espaço de endereçamento da memória
	ldh r15, #7fh
    ldl r15, #FFh           
    ldsp r15 
	
	push r0
	push r1
	push r2
	push r3
	push r4
	
entry:
	
;   r0 <= 0
	xor r0, r0, r0
	
;	r1 <= &PortData
	ldh r1, #80h
	ldl r1, #00h
	
;	r2 <= &PortConfig
	ldh r2, #80h
	ldl r2, #01h
	
;	r3 <= &PortEnable
	ldh r3, #80h
	ldl r3, #02h
	
regConfig:
	
;	PortConfig <= "0000000011111111", MSBs = Saída (LEDs), LSBs = Entrada (Switches)
	ldh r4, #00h
	ldl r4, #FFh
	st r4, r0, r2

;	PortEnable <= "1111111111111111", habilita acesso a todos os bits da porta de I/O (8 Switches da placa)
	ldh r4, #FFh
	ldl r4, #FFh
	st r4, r0, r3
	
pollingLoop: ; Repete esse loop infinitamente	
	nop

;   r4 <= PortData
	ld r4, r0, r1
	
;   8 Shifts para a esquerda (Desloca dados dos Switches para seus respectivos LEDs)
	sl0 r4, r4 ;1
	sl0 r4, r4 ;2
	sl0 r4, r4 ;3
	sl0 r4, r4 ;4
	sl0 r4, r4 ;5
	sl0 r4, r4 ;6
	sl0 r4, r4 ;7
	sl0 r4, r4 ;8
	
;	PortData <= r4
	st r4, r0, r1

	jmpd #pollingLoop
	
return: ; Esse trecho de código nunca executa

	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	
	rts
	
.endcode	
