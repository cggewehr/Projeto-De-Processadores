.org #000h
; Carlos Gewehr e Emilio Ferreira
; Tabela de Registradores:
; ------------------------ r0 = 0
; ------------------------ r1 = 1
; ------------------------ r2 = &PortData
; ------------------------ r3 = &PortConfig
; ------------------------ r4 = &PortEnable
; ------------------------ r5 = Dado a ser lido/escrito
; ------------------------ r6 = Contador de 10ms
; ------------------------ r7 = Contador do display continuo
; ------------------------ r8 = Contador do display manual
; ------------------------ r9 = Decimal do contador do display continuo
; ------------------------ r10 = Unidade do contador do display continuo
; ------------------------ r11 = Decimal do contador do display manual
; ------------------------ r12 = Unidade do contador do display manual
; ------------------------ r13 = 100
; ------------------------ r14 = Valor de retorno de subrotina
; ------------------------ r15 = Stack Pointer

; PortConfig : 0 = Read, 1 = Write
; MSBs = LEDs, LSBs = Switches
; ID da porta = 0

.code

main:
;   Seta SP para ultimo endereço no espaço de endereçamento da memória
	ldh r15, #7fh
    ldl r15, #FFh           
    ldsp r15 

;	Push para pilha registradores a serem utilizados no programa
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14

;   r0 <= 0
	xor r0, r0, r0
	
;	r1 <= 1
	addi r1, r0, #01h
	
;	r2 <= &PortData
	ldh r2, #80h
	ldl r2, #00h
	
;	r3 <= &PortConfig
	ldh r3, #80h
	ldl r3, #01h
	
;	r4 <= &PortEnable
	ldh r4, #80h
	ldl r4, #02h
	
;	r6 <= 0 (inicializa contador de 10ms)
	xor r6, r6, r6
	
;	r7 <= 0 (inicializa contador do display continuo)
	xor r7, r7, r7
	
;	r8 <= 0 (inicializa contador do display manual)
	xor r8, r8, r8
	
;	r9 <= 0 (inicializa Decimal do contador do display continuo)
	xor r9, r9, r9

;	r10 <= 0 (inicializa Unidade do contador do display continuo)
	xor r10, r10, r10

;	r11 <= 0 (inicializa Decimal do contador do display manual)
	xor r11, r11, r11
	
;	r12 <= 0 (inicializa Unidade do contador do display manual)
	xor r12, r12, r12

;	PortConfig <= "0000000011111111", MSBs = Saída (LEDs), LSBs = Entrada (Switches)
	ldh r5, #00h
	ldl r5, #FFh
	st r5, r0, r2

;	PortEnable <= "1111111111111111", habilita acesso a todos os bits da porta de I/O 
	ldh r5, #FFh
	ldl r5, #FFh
	st r5, r0, r3
	
loop:
	
	jsr #delay ; Gasta 10ms de processador
	
;	Incrementa contador de 10ms
	addi r6, r0, #01h
	
; 	Le porta ( verificar estado dos botoes ) 
; 	Retorna zero se nenhum botao estiver pressionado, 1 se botao de cima estiver pressionado, -1 se botao de baixo estiver pressionado
	jsr #lerPorta
	
;	Gera flag zero
	add r14, r0, r14
	
;	Ambos os jumps devem voltar para label "return1"
	jmpzd #CompensaTempo ; TODO: Verificar return address apos salto
	jmpd #IncrementaManual ; Atualiza valor de r8
	
return1:
	
; 	Se contador de 10 ms = 100, r5 <= 0
	sub r5, r13, r6
	jmpzd #IncrementaContinuo
	jmpd #CompensaTempo
	
return2:

;	Atualiza valores de r9, r10, r11, r12 conforme os valores de r7 e r8
	jsr #TraduzSSD
	
;	Determina em qual display deve ser feita a escrita
	jsr #ControleSSD
	
;	Escreve na porta os valores determinados
	jsd #EscrevePorta
	
	jmpd #loop
	
;;-----------------------------------Copiado do trabalho anterior-------------------------------------------
pollingLoop: ; Repete esse loop infinitamente	
	nop

;   r5 <= PortData
	ld r5, r0, r2
	
;   16 Shifts para a esquerda (Desloca dados dos Switches para seus respectivos LEDs)
	sl0 r4, r4 ;1
	sl0 r4, r4 ;2
	sl0 r4, r4 ;3
	sl0 r4, r4 ;4
	sl0 r4, r4 ;5
	sl0 r4, r4 ;6
	sl0 r4, r4 ;7
	sl0 r4, r4 ;8
	sl0 r4, r4 ;9
	sl0 r4, r4 ;10
	sl0 r4, r4 ;11
	sl0 r4, r4 ;12
	sl0 r4, r4 ;13
	sl0 r4, r4 ;14
	sl0 r4, r4 ;15
	sl0 r4, r4 ;16
	
;	PortData <= r5
	st r5, r0, r2

	jsrd #pollingLoop
;;-----------------------------------Copiado do trabalho anterior-------------------------------------------	
return: ; Esse trecho de código nunca executa

	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	
	rts
	
.endcode	
