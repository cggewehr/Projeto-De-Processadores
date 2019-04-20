.org #000h
; Carlos Gewehr e Emilio Ferreira
; Tabela de Registradores:
; ------------------------ r00 = 0
; ------------------------ r01 = Valor de retorno de subrotina
; ------------------------ r02 = &PortData
; ------------------------ r03 = &PortConfig
; ------------------------ r04 = &PortEnable
; ------------------------ r05 = Dado a ser lido/escrito
; ------------------------ r06 = Contador de 10ms
; ------------------------ r07 = Contador do display continuo
; ------------------------ r08 = Contador do display manual
; ------------------------ r09 = Decimal do contador do display continuo
; ------------------------ r10 = Unidade do contador do display continuo
; ------------------------ r11 = Decimal do contador do display manual
; ------------------------ r12 = Unidade do contador do display manual
; ------------------------ r13 = 100
; ------------------------ r14 = Temporario
; ------------------------ r15 = PUSH SP, após isso, Temporario

; PortConfig : 0 = Read, 1 = Write

; ///////////////////////////     BASIC    ///////////////////////////
;net "rst" loc = T10;          // SW0 (Right-most)
;net "clk" loc = V10;          // 100MHz board clock

;///////////////////////////     INPUT    ///////////////////////////
;net "port_io[14]" loc = A8;    // BUTTON UP
;net "port_io[15]" loc = C9;    // BUTTON DOWN

;///////////////////////////     OUTPUT   ///////////////////////////
;net "port_io[7]" loc = T17;   // Segment A
;net "port_io[6]" loc = T18;   // Segment B
;net "port_io[5]" loc = U17;   // Segment C
;net "port_io[4]" loc = U18;   // Segment D
;net "port_io[3]" loc = M14;   // Segment E
;net "port_io[2]" loc = N14;   // Segment F
;net "port_io[1]" loc = L14;   // Segment G
;net "port_io[0]" loc = M13;   // Segment P

;net "port_io[12]" loc = P17;  // Display 3 (Left-most) 
;net "port_io[11]" loc = P18;  // Display 2
;net "port_io[10]" loc = N15;  // Display 1
;net "port_io[9]" loc = N16;  // Display 0 (Right-most)
;////////////////////////////////////////////////////////////////////
; ID da porta = 0

.code

;---------------------------------------Ponto de Entrada-----------------------------------------------------
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

;-----------------------------------------Loop do Programa Principal-----------------------------------------	
pollingLoop:
	
	jsr #delay ; Gasta 10ms de processador
	
;	Incrementa contador de 10ms
	addi r6, r0, #01h
	
; 	Le porta ( verificar estado dos botoes ) 
; 	Retorna zero se nenhum botao estiver pressionado, 1 se botao de cima estiver pressionado, -1 se botao de baixo estiver pressionado
	jsr #lerPorta
	
;	Gera flag zero
	add r1, r0, r1
	
;	Ambos os jumps devem voltar para label "return1"
	jmpzd #compensaTempo ; TODO: Verificar return address apos salto
	jmpd #incrementaManual ; Atualiza valor de r8
	
return1:
	
; 	Se contador de 10 ms = 100, r5 <= 0, portanto, pula para subrotina 
	sub r5, r13, r6
	jmpzd #incrementaContinuo
	jmpd #compensaTempo
	
return2:

;	Atualiza valores de r9, r10, r11, r12 conforme os valores de r7 e r8
	jsr #traduzSSD
	
;	Determina em qual display deve ser feita a escrita
	jsr #controleSSD
	
;	Escreve na porta os valores determinados
	jsr #escrevePorta
	
;	Retorna para loop de polling
	jmpd #pollingLoop
	
;----------------------------------- Fim do Programa Principal-----------------------------------------------
; Abaixo estão as subrotinas:

; compensaTempo, incrementaContinuo, incrementaManual devem ter o mesmo tmepo de execução

; --- delay              : TODO
; --- lePorta            : 		DONE
; --- compensaTempo      :      DONE
; --- incrementaManual   : 		DONE
; --- incrementaContinuo :      DONE
; --- traduzSSD          : TODO
; --- controleSSD        : TODO
; --- escrevePorta       : TODO

lePorta:

;	r1 <= Dado da porta
	ld r1, r0, r2
	
	rts
	
compensaTempo:
	
;	Executa 72 ciclos
	nop 			;3  ciclos
	nop 			;6  ciclos
	nop 			;9  ciclos
	nop				;12 ciclos
	nop 			;15 ciclos
	nop 			;18 ciclos
	nop 			;21 ciclos
	nop 			;24 ciclos
	nop 			;27 ciclos
	nop 			;30 ciclos
	nop 			;33 ciclos
	nop 			;36 ciclos
	nop 			;39 ciclos
	nop 			;42 ciclos
	nop 			;45 ciclos
	nop 			;48 ciclos
	nop 			;51 ciclos
	nop 			;54 ciclos
	nop 			;57 ciclos
	nop 			;60 ciclos
	ld r15, r0, r0  ;64 ciclos
	ld r15, r0, r0  ;68 ciclos
	
	rts             ;72 ciclos

incrementaManual:
;net "port_io[14]" loc = A8;    // BUTTON UP
;net "port_io[15]" loc = C9;    // BUTTON DOWN
	
;	4PUSH/POP + 10ARITIMETICAS + 2 JUMPS + RTS
;	4x4 + 10x3 + 2x11 + 4 (Assume jumps sempre not taken)
;	16 + 30 + 22 + 4
;	72 ciclos de execução
	
;	Pilha <= Valor lido da porta
	push r1
	
;	r14 <= 1
	xor r14, r14, r14
	addi r14, r0, #01h

;	r15 <= Mascara de comparação para BTN DOWN (00000000_00000001)
	ldh r15, #00h
	ldl r15, #01h

;	Se BTN DOWN foi pressionado, r1 <= 0, decrenenta contador
	and r1, r1, r15
	subi r1, #01h
	jmpzd #manual--
	
;	Carrega lixo em r15 para manter tempo de execução constante, independente da tomada de branch (11 ciclos)
	ld r15, r0, r0
	ld r15, r0, r0

  returnManual--:
  
;	Restaura valor lido da porta, salva novamente	
	pop r1
	push r1
	
;	r15 <= Mascara de comparação para BTN UP (00000000_00000010)
	ldh r15, #00h
	ldl r15, #02h	

;	Se BTN UP foi pressionado, r1 <= 0, incrementa contador
	and r1, r1, r15
	subi r1, #02h
	jmpzd #manual++
	
;	Carrega lixo em r15 para manter tempo de execução constante, independente da tomada de branch (11 ciclos)
	ld r15, r0, r0
	ld r15, r0, r0

  returnManual++:

;	Restaura valor lido da porta
	pop r1
	
	rts
	
;------------------------------------ AUXILIARES incrementaManual -------------------------------------------

manual--:
	
;	Contador display manual --
	subi r8, #01h
	jmp #returnManual--
	
manual++:
	
;	Contador display manual ++
	addi r8, #01h
	jmp #returnManual++

;------------------------------------ AUXILIARES incrementaManual -------------------------------------------

incrementaContinuo:
	
;	Incrementa contador continuo, demorando 72 ciclos
	addi r7, #01h    ;3  ciclos
	ld r15, r0, r0   ;7  ciclos
	ld r15, r0, r0   ;11 ciclos
	nop              ;14 ciclos
	nop              ;17 ciclos
	nop              ;20 ciclos
	nop              ;23 ciclos
	nop              ;26 ciclos
	nop              ;29 ciclos
	nop              ;32 ciclos
	nop              ;35 ciclos
	nop              ;38 ciclos
	nop              ;41 ciclos
	nop              ;44 ciclos
	nop              ;47 ciclos
	nop              ;50 ciclos
	nop              ;53 ciclos
	nop              ;56 ciclos
	nop              ;59 ciclos
	nop              ;62 ciclos
	nop              ;65 ciclos
	nop              ;68 ciclos
	
	rts              ;72 ciclos
	
;;-----------------------------------Copiado do trabalho anterior--------------------------------------------
;pollingLoop: ; Repete esse loop infinitamente	
	nop

;   r5 <= PortData
	ld r5, r0, r2
	
;   8 Shifts para a esquerda (Desloca dados dos Switches para seus respectivos LEDs)
	sl0 r4, r4 ;1
	sl0 r4, r4 ;2
	sl0 r4, r4 ;3
	sl0 r4, r4 ;4
	sl0 r4, r4 ;5
	sl0 r4, r4 ;6
	sl0 r4, r4 ;7
	sl0 r4, r4 ;8
	
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
