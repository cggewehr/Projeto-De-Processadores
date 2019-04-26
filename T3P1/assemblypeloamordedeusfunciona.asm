.org #000h
; Carlos Gewehr e Emilio Ferreira
; Tabela de Registradores:
; ------------------------ r00 = 0
; ------------------------ r01 = Valor de retorno de subrotina
; ------------------------ r02 = &PortData
; ------------------------ r03 = &PortConfig
; ------------------------ r04 = &PortEnable
; ------------------------ r05 = Dado a ser lido/escrito
; ------------------------ r06 = Contador de 2ms
; ------------------------ r07 = Valor do contador continuo de 1 seg
; ------------------------ r08 = Valor do contador manual
; ------------------------ r09 = Decimal do contador do display continuo
; ------------------------ r10 = Unidade do contador do display continuo
; ------------------------ r11 = Decimal do contador do display manual
; ------------------------ r12 = Unidade do contador do display manual
; ------------------------ r13 = 500
; ------------------------ r14 = Temporario
; ------------------------ r15 = Contador do Display (0, 1, 2, 3)

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
;net "port_io[9]"  loc = N16;  // Display 0 (Right-most)
;////////////////////////////////////////////////////////////////////
; ID da porta = 0

.code

;---------------------------------------Ponto de Entrada-----------------------------------------------------
;Seta o SP;
;Seta r0 em ZERO
;Seta o endereço de Port DATA
;Seta o endereço de Port CONFIG
;Seta o endereço de Port Enable
;Retorna NADA

main:
;   Seta SP para ultimo endereço no espaço de endereçamento da memória
    ldh r15, #7fh
    ldl r15, #FFh           
    ldsp r15 
	xor r15, r15, r15
    
;   r0 <= 0
	xor r0, r0, r0
	
;	r1 <= 0
	xor r1, r1, r1
	
;	r2 <= &PortData
	ldh r2, #80h
	ldl r2, #00h
	
;	r3 <= &PortConfig
	ldh r3, #80h
	ldl r3, #01h
	
;	r4 <= &PortEnable
	ldh r4, #80h
	ldl r4, #02h
	
;	r6 <= 0 (inicializa contador de 2ms)
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
	
;	r13 <= 500 
	xor r13, r13, r13
	addi r13, #255Dh
	addi r13, #245Dh
    
;	PortConfig <= "00111111_11111111", bit 15 e 14 = entrada, outros = saida
	ldh r5, #3Fh
	ldl r5, #FFh
	st r5, r0, r2

;	PortEnable <= "11011110_11111111", habilita acesso a todos os bits da porta de I/O, menos bit 13 e bit 8
	ldh r5, #CEh
	ldl r5, #FFh
	st r5, r0, r3

;-----------------------------------------Loop do Programa Principal-----------------------------------------	
; Verifica o estado dos botoes e displays de 2 em 2 ms

pollingLoop:

; 	Gasta 2ms de processador	                                                             4 ciclos + delay
	jsrd #delay 
	
;	Incrementa contador de 2ms                                                                       4 ciclos
	addi r6, #01h
	
; 	Le porta ( Verificar estado dos botoes )                                              4 ciclos + lerPorta
	jsrd #lePorta                                                                                    

;	Define valor a ser exibido no contador manual                                        4 ciclos + incManual
 	jsrd #incrementaManual                                                                            
	
;	Incrementa contador de 2 ms                                                                      4 ciclos
	addi r6, #01h         

; 	Se contador de 2 ms = 500, incrementa contador continuo (1 seg)                    8 ciclos + incContinuo
	sub r5, r13, r6
	jsrd #incrementaContinuo
	
;	Determina qual numero sera escrito no display	
;	if display = 0 ou 1, numero a ser convertido = continuo, se display = 2 ou 3, numero a ser convertido = manual	
	
;	Salva r13                                                                                        4 ciclos
	push r13                                                                                        
	
;	Gera flag de zero, se display = 0, pula para displayContinuo                           4 ciclos + jmp (3)
	add r15, r0, r15                                                                                 
	jmpzd #displayContinuo
	
;	Mascara para comparação com numero 1                                                             8 ciclos
	ldh r13, #00h
	ldl r13, #01h
	
;	Se display = 1, pula para displayContinuo                                                  8 ciclos + (8)
	and r13, r13, r15
	sub r13, r13, r15
	jmpzd #displayContinuo
	jmpd #displayManual
	
returnDisplayContinuoManual:

;	Restaura r13	                                                                                 4 ciclos
	pop r13 
	
;	Escreve na porta os valores determinados
	jsrd #escreveSSD
	
;	Incrementa contador do display	                                                                 4 ciclos
	addi r15, #01h                                                                                   
	
;   Salva r13	                                                                                     4 ciclos
	push r13

;	r13 <= mascara de comparação (00000000_00000100)                                                 8 ciclos
	ldh r13, #00h
	ldl r13, #04h

;	Se contador de display == 4, contador de display <= 0                                    8 ciclos + jmp(3)
	and r13, r13, r15
	sub r13, r13, r15
	jmpzd #setaDisplayZero
	
returnDisplayZero:
;	Restaura r13                                                                                     4 ciclos
	pop r13
	
;	Retorna para loop de polling                                                                     4 ciclos
	jmpd #pollingLoop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	
setaDisplayZero:     
                                                                                 
;   display <= 0                                                                             4 ciclos + jmp(4)
	xor r15, r15, r15 
	jmpd #returnDisplayZero
	
displayContinuo:
	
;	Argumento para HEXtoDEC = contador Continuo de 1 seg                                     4 ciclos + jmp(4)
	add r14, r0, r7
	jmpd #returnDisplayContinuoManual
	
displayManual:

;	Argumento para HEXtoDEC = contador manual                                                4 ciclos + jmp(4)
	add r14, r0, r8
	jmpd #returnDisplayContinuoManual
	
;----------------------------------- Fim do Programa Principal-----------------------------------------------
; Abaixo estão as subrotinas:
    
; compensaTempo, incrementaContinuo, incrementaManual devem ter o mesmo tempo de execução

; --- delay              :      DONE                                                           100 001 ciclos
; --- lePorta            :      DONE                                                                 8 ciclos
; --- compensaTempo      :      DONE                                                                72 ciclos
; --- incrementaManual   :      DONE                                                                72 ciclos
; --- incrementaContinuo :      DONE                                                                72 ciclos
; --- HEXtoDEC           :      DONE                                                               125 ciclos
; --- escreveSSD         :      DONE                                                               130 ciclos


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEXtoDEC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recebe um valore (HEX) se separas ele  em decimal(DEC) e Unidade(DEC)                                      ;
;                                                                                                            ;
;   REGISTRADORES - (r14) NumeroOriginal - ENTRADA                                                           ;
;                   (r9)  DECIMAL        - SAIDA                                                             ;
;                   (r10) UNIDADE        - SAIDA                                                             ;
;                                                                                                            ;
;   RETORNO - Ao final da subrotina os valores de r9, r10, irao representar a dezena e unidade do numero     ;
;             respectivamente                                                                                ;
;                                                                                                            ;
;   FUNCIONAMENTO - Primeiramente carrega os valores a serem traduzidos de HEX para DEC nos registradores    ;
;                   de dezena, apois isso é iniciado um loop de subtrações sucessivas onde a cada iteração   ;
;                   é diminuido 10(decimal)/A(HEX) do valor total, quando o valor se apresentar zero,        ;
;                   finalizao loop e quando se apresentar negativo (ex -3, soma-se 10, -3+10 = 7) e          ;
;                   finaliza o loop                                                                          ;

;------------------------------------------------------------------------------------------------------------;
; ciclos = (multiplos de 10) = 22*(decimal) + 16 | MULTIPLOS DE 10 (0, 10, 20, 30, 40, ..., 90) 
; ciclos =     (resto)       = 22*(decimal) + 27 | QUALQUER OUTRO NUMERO(1, 22, 33, 44, ..., 99)
HEXtoDEC:   
           
    xor r9, r9, r9         ; Zera r9(dezena)                                                         
    add r10, r0, r14       ; Carrega o r14(Numero original) no r10(parte da unidade do contador)     8 ciclos             

dezena:                    ; Loop que por subtrações sucessivas calcula a dezena                             
    jmpzd #fimHEXtoDEC     ; Caso o numero for igual a zero
    subi r10, #0Ah         ; Subtrai 10 do numero orignal                                                            
    jmpnd #menor_de_dez    ; Numero menor que 10   
    addi r9, #01h          ; Incrementa a dezena do numero;
    add r10, r0, r10       ; Carrega novamente r10 para gerar as flags para comparação    
    jmpd #dezena           ; Retorna para o loop de calculo de dezena                                        

menor_de_dez:
    addi r10, #0Ah         ; Como valor é menor que 10, soma-se 10 na unidade para recuperar o valor                                                   
    ;jmpd #fimHEXtoDEC     ; Nao executa a instrução mas passa pro label igual
    
fimHEXtoDEC:                                                                                             
    st r9, r0, r9          ; Salva o valor da dezena em r9                                                   
    st r10, r0, r10        ; Salva o valor da unidade em r10   
    
    rts                    ; Retorno da Subrotina                                                            

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DELAY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; gasta tempo do processador
delay:
; com uma freqencia de 50Mhz, temos que 2 ms = 100 000 ciclos de processador
; um loop com 10 ciclos executado 10 000 vezes
    push r6
    ldh r6, #27h
    ldh r6, #0Eh    ; r6 <= 9998

delay_loop:
    subi r3, #01h      ; decrementa contador                                4 ciclos
    jmpzd #fim_delay   ; casp seja zero, finaliza o delay                   3 ciclos
    jmpd  #delay_loop  ; pula para gastar tempo de processador              4 ciclos
;                                                                ;Total =~ 10 ciclos
fim_delay:    
    pop r6
    nop           ; Adiciona 3 ciclos
    rts           ; retorna subrotina
    
;Ideal = 100 000 ciclos
;Atual = 100 001 ciclos
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;escreveSSD;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

escreveSSD: 
	push r11  ; &arrayDisp
    push r12  ; &arraySSD            
	push r13  ; mascara de comparação para display
    push r14  ; numero                                                                                             
    push r15  ; display (0, 1, 2, 3)                                                                20 ciclos                         
         
	ldh r11, #arrayDisp
	ldl r11, #arrayDisp

;	r11 <= arrayDisp[Display (da iteração atual)]                                                   28 ciclos
	ld r11, r11, r15
	
;	r5 <= display                                                                                   32 ciclos
	xor r5, r5, r5
	add r5, r0, r11
	
;	Desloca bits de enable do display até sua posição                                               40 ciclos
	sl0 r5, r5 ; MSB @ 4
	sl0 r5, r5 ; MSB @ 5
	sl0 r5, r5 ; MSB @ 6
	sl0 r5, r5 ; MSB @ 7
	sl0 r5, r5 ; MSB @ 8
	sl0 r5, r5 ; MSB @ 9
	sl0 r5, r5 ; MSB @ 10
	sl0 r5, r5 ; MSB @ 11
	sl0 r5, r5 ; MSB @ 12

;	r9 <= Dezena, r10 <= unidade                                                                    76 ciclos
	jsrd #HEXtoDEC

;	r13 <= mascara de comparação (00000000_00000001) para determinar se numero é par                80 ciclos
	ldh r13, #00h
	ldl r13, #01h
	
;	Se numero for par, usa unidade, se for impar, usa dezena	                                    84 ciclos
	and r13, r13, r15
	jmpzd #dispPar
	jmpd #dispImpar
;																	  94 ciclos ( em media 6 ciclos p/ jumps)
returnJumpParImpar:
;                    |     15 14    |13|  12 11 10 9  |8| 7 6 5 4 3 2 1 0 |
;	Escreve na porta (entrada_botoes)x(display_enable) x  (dados_display)	
	st r5, r0, r2
	
;	Restaura registradores                                                                          98 ciclos
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11

;   Volta para pollingLoop                                                                         118 ciclos
	rts
;                                                                                           FINAL: 130 ciclos
dispPar:

;	Dado a ser escrito é a unidade do numero passado como argumento para HEXtoDEC
	add r5, r5, r10
	jmpd #returnJumpParImpar
	
dispImpar:

;	Dado a ser escrito é a dezena do numero passado como argumento para HEXtoDEC
	add r5, r5, r9
	jmpd #returnJumpParImpar
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lePorta:
; Retorna Estado do botao 

;	r1 <= Dado da porta
	ld r1, r0, r2
	
;	Retorna para pollingLoop
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
	addi r14, #01h

;	r12 <= Mascara de comparação para BTN DOWN (10000000_00000000)
	ldh r12, #80h
	ldl r12, #00h

;	Se BTN DOWN foi pressionado, r1 <= 0, decrenenta contador
	and r1, r1, r12
	sub r1, r1, r12
	jmpzd #manual--
	
;	Manter tempo de execução constante, independente da tomada de branch (11 ciclos)
	xor r0, r0, r0
    xor r0, r0, r0

  returnManual--:
  
;	Restaura valor lido da porta, salva novamente	
	pop r1
	push r1
	
;	r12 <= Mascara de comparação para BTN UP (01000000_00000000)
	ldh r12, #04h
	ldl r12, #00h	

;	Se BTN UP foi pressionado, r1 <= 0, incrementa contador
	and r1, r1, r12
	sub r1, r1, r12
	jmpzd #manual++
	
;	Manter tempo de execução constante, independente da tomada de branch (11 ciclos)
	xor r0, r0, r0
	xor r0, r0, r0

  returnManual++:

;	Restaura valor lido da porta
	pop r1
	
;	Retorna para pollingLoop
	rts
	
;------------------------------------ AUXILIARES incrementaManual -------------------------------------------

manual--:
	
;	Contador display manual --
	subi r8, #01h
	jmpd #returnManual--
	
manual++:
	
;	Contador display manual ++
	addi r8, #01h
	jmpd #returnManual++

;------------------------------------ AUXILIARES incrementaManual -------------------------------------------

incrementaContinuo:
	
;	Incrementa contador continuo se passou 1 seg, demorando 72 ciclos

;	Se 1 segundo se passou, nao incrementa contador
	jmpzd #returnContinuo ;3 ciclos 

;	Gasta 72 ciclos	
	addi r7, #01h         ;7  ciclos
	xor r0, r0, r0        ;11 ciclos
	xor r0, r0, r0        ;15 ciclos
	nop                   ;18 ciclos
	nop                   ;21 ciclos
	nop                   ;24 ciclos
	nop                   ;27 ciclos
	nop                   ;30 ciclos
	nop                   ;33 ciclos
	nop                   ;36 ciclos
	nop                   ;39 ciclos
	nop                   ;42 ciclos
	nop                   ;45 ciclos
	nop                   ;48 ciclos
	nop                   ;51 ciclos
	nop                   ;54 ciclos
	nop                   ;57 ciclos
	nop                   ;60 ciclos
	xor r0, r0, r0        ;64 ciclos

;	Retorna para pollingLoop
	rts                   ;72 ciclos
	
  returnContinuo:
  
;	Gasta 72 ciclos
	nop                   ;7 ciclos
	nop                   ;10 ciclos
	nop                   ;13 ciclos
	nop                   ;16 ciclos
	nop                   ;19 ciclos
	nop                   ;22 ciclos
	nop                   ;25 ciclos
	nop                   ;28 ciclos
	nop                   ;31 ciclos
	nop                   ;34 ciclos
	nop                   ;37 ciclos
	nop                   ;40 ciclos
	nop                   ;43 ciclos
	nop                   ;46 ciclos
	nop                   ;49 ciclos
	nop                   ;52 ciclos
	nop                   ;55 ciclos
	nop                   ;58 ciclos
	nop                   ;61 ciclos
	nop                   ;64 ciclos
	xor r0, r0, r0        ;68 ciclos
	
;	Retorna para pollingLoop
	rts                   ;72 ciclos
	
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

.data
    ; array SSD representa o array de valores a serem postos nos displays de sete seg
                   ; 0 ,    1,    2,    3,    4,    5,    6,    7,    8,    9
    arraySSD:   db #03h, #9fh, #25h, #0dh, #99h, #49h, #21h, #1fh, #01h, #09h
    ; Array que escolhe qual disp sera utilizado
                   ; Mais da direita -> Mais da esquerda
    arrayDisp:  db #01h, #02h, #04h, #08h
.enddata