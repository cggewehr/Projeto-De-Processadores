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
; ------------------------ r07 = Valor do contador continuo de 1 seg
; ------------------------ r08 = Valor do contador manual
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
	
;	r13 <= 100
	addi r13, r0, #100d
    
;	PortConfig <= "00111111_11111111", bit 15 e 14 = entrada, outros = saida
	ldh r5, #3Fh
	ldl r5, #FFh
	st r5, r0, r2

;	PortEnable <= "11011110_11111111", habilita acesso a todos os bits da porta de I/O, menos bit 13 e bit 8
	ldh r5, #CEh
	ldl r5, #FFh
	st r5, r0, r3

;-----------------------------------------Loop do Programa Principal-----------------------------------------	
; Verifica o estado dos botoes e displays de 10 em 10 ms

pollingLoop:

; 	Gasta 10ms de processador	
	jsr #delay 
	
;	Incrementa contador de 10ms
	addi r6, r0, #01h
	
; 	Le porta ( Verificar estado dos botoes ) 
	jsr #lerPorta

;	Define valor a ser exibido no contador manual
	jsr #incrementaManual
	
;	Incrementa contador de 10 ms
	addi r6, r6, #01h

; 	Se contador de 10 ms = 100, incrementa contador continuo (1 seg)
	sub r5, r13, r6
	jsr #incrementaContinuo

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
    
; compensaTempo, incrementaContinuo, incrementaManual devem ter o mesmo tempo de execução

; --- delay              : TODO
; --- lePorta            :      DONE
; --- compensaTempo      :      DONE
; --- incrementaManual   :      DONE
; --- incrementaContinuo :      DONE
; --- HEXtoDEC           :      DONE
; --- traduzSSD          : TODO
; --- controleSSD        : TODO
; --- escrevePorta       : TODO


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
;                                                                                                            ;
;   EXEMPLO  - r7 = 1A(hex) = 26(dec)                                                                        ;
;                     Inicio     ->  r10(Unidade) = 1A | r9(Dezena) = 0                                      ;
;                     1 iteração ->  r10(Unidade) = 10 | r9(Dezena) = 1                                      ;
;                     2 iteração ->  r10(Unidade) = 6  | r9(Dezena) = 2                                      ;
;                     3 iteração ->  r10(Unidade) = 6  | r9(Dezena) = 2                                      ;
;------------------------------------------------------------------------------------------------------------;
HEXtoDEC:                                                                                                    ;
    add r10, r0, r14       ; Carrega o r14(Numero original) no r10(parte da dezena do contador)              ;
    xor r9, r9, r9         ; Zera r9(dezena)                                                                 ;
                                                                                                             ;
dezena:                    ; Loop que por subtrações sucessivas calcula a dezena                             ;
    subi r10, #0Ah;                                                                                          ;
    jmpzd #fimHEXtoDECzero ; Caso o a Unidade for igual a zero, não é necessario realizar mais uma soma      ;
    jmpnd #fimHEXtoDEC     ; Acabou de calcular a dezena e unidade do numero                                 ;
    addi r9, #01h          ; Incrementa a dezena do numero;                                                  ;
    jmpd #dezenaAUTO       ; Retorna para o loop de calculo de dezena                                        ;
                                                                                                             ;
fimHEXtoDEC:                                                                                                 ;
    addi r10, #0Ah;                                                                                          ;
                                                                                                             ;
fimHEXtoDECzero;                                                                                             ;
    st r9, r0, r9;         ; Salva o valor da dezena em r9                                                   ;
    st r10, r0, r10        ; Salva o valor da unidade em r10                                                 ;
    rts                    ; Retorno da Subrotina                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;escreveSSD;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Escreve Nos Displays e alterna entre eles                                                                  ;
;                                                                                                            ;
;   REGISTRADORES - (r5)  Dado a ser escrito na porta    - SAIDA                                             ;
;                   (r7)  Index(dispARRAY)/ContContinuo  - -/ENTRADA                                         ;
;                   (r9)  Valor da dezena Automatica     - SAIDA da HEXtoDEC                                 ;
;                   (r10) Valor da unidade Automatica    - SAIDA da HEXtoDEC                                 ;
;                   (r11) Valor da dezena Manual         - SAIDA da HEXtoDEC                                 ;
;                   (r12) Valor da unidade manual        - SAIDA da HEXtoDEC                                 ;
;                   (r14) Valor do contador Continuo     - ENTRADA                                           ;
;                   (r15) Endereço inicial do DispARRAY  - ENTRADA                                           ;
;                                                                                                            ;
;   RETORNO - Ao final da subrotina deverá ter sido escrito na porta de saida e nos 4 displays de 7 segmentos;
;             os valores de Contador Automatico ( Unidade, Dezena) e Contador Manual( Unidade, Dezena) da    ;
;             Direita para a Esquerda, respectivamente.                                                      ;
;                                                                                                            ;
;   FUNCIONAMENTO - É utiliza a subrotina de HEXtoDEC para adquirir os valores de dezena e unidade de cada   ;
;                   contador e após isso é setada os resgistradores da porta:                                ;
;                   REG_PORT_CONFIG ( 12 bits de saida)                                                      ;
;                   REG_PORT ENABLE ( Habilita para a escrita esss 12 bits)                                  ;
;                   Então é carregado o valor do endereço inicial do array dos valores do disp que é         ;
;                   indexado pelo proprio numero                                                             ;
;                   Finalmente é mostrado nos disp os valores seguidos do delay para vizualização, é feito   ;
;                   para os 4 displays e entao retorna                                                       ;                       
;------------------------------------------------------------------------------------------------------------;
escreveSSD:                                                                                                  ;
    push r5                                                                                                  ;
    push r7                                                                                                  ;
    push r9                                                                                                  ;
    push r10                                                                                                 ;
    push r11                                                                                                 ;
    push r12                                                                                                 ;
    push r14                                                                                                 ;
    push r15          ; Salva o contexto nos registradores que irá alterar                                   ;
                                                                                                             ;
    add r14, r0, r7   ; Carrega em r14 o valor do contador contiuno                                          ;
    jsr #HEXtoDEC     ; Pula na subrotina de transformação de valores hexa pra decimal                       ;
    add r9,  r0, r9   ; Guarda em r9 o valor da dezena do numero r7(continuo)                                ;
    add r10, r0, r10  ; Guarda em r10 o valor da unidade do numero r7(continuo)                              ;
                                                                                                             ;
    add r14, r0, r8   ; carrega em r14 o valor do contador manual                                            ;
    jsr #HEXtoDEC      ; Chama a subrotina de transformação de valores hexa pra decimal                      ;
    add r11, r0, r9   ; Guarda em r11 o valor da dezena do numero r7(continuo)                               ;
    add r12, r0, r10  ; Guarda em r12 o valor da unidade do numero r7(continuo)                              ;
                                                                                                             ;
    ldh r5, #F0h      ;                                                                                      ;
    ldl r5, #00h      ;                                                                                      ;
    st r5, r0, r3     ; PortConfig <= "1111 0000 0000 0000" | (12 downto 0)LSBs = SAIDA                      ;
                                                                                                             ;
    ldh r5, #0Fh      ;                                                                                      ;
    ldl r5, #FFh      ;                                                                                      ;
    st r5, r0, r4     ; PortEnable <= "0000 1111 1111 1111" | Habilita acesso somente aos bits do SSD        ;
                                                                                                             ;                                                                                                         ;
    ldh r15, #array                                                                                          ;
    ldl r15, #array   ; R15 <- endereço inicial do array                                                     ;
                                                                                                             ;
    st r7, r15, r10   ; r7 <= array[Unidade Automatico]                                                      ;
    ldh r5, #01h      ; Primeiro display                                                                     ;
    ldl r5, r7        ; Valor de 8 bits a ser colocado no SSD                                                ;
    st r5, r0, r2     ; PortData <= "0000 0001 & (Valor Unidade Atomatico)" | PRIMEIRO SSD                   ;
                                                                                                             ;
    jsr #delay        ; Pula na subrotina de espera para vizualização nos disps                              ;
                                                                                                             ;
    st r7, r15, r9    ; r7 <= array[Dezena Automatico]                                                       ;
    ldh r5, #02h      ; Segundo display                                                                      ;
    ldl r5, r7        ; Valor de 8 bits a ser colocado no SSD                                                ;
    st r5, r0, r2     ; PortData <= "0000 0010 &  (Valor Dezena Atomatico)" | SEGUNDO SSD                    ;
                                                                                                             ;    
    jsr #delay        ; Pula na subrotina de espera para vizualização nos disps                              ;
                                                                                                             ;
    st r7, r15, r12   ; r7 <= array[Unidade Manual]                                                          ;
    ldh r5, #04h      ; Terceiro display                                                                     ;
    ldl r5, r7        ; Valor de 8 bits a ser colocado no SSD                                                ;
    st r5, r0, r2     ; PortData <= "0000 0100 &  (Valor Unidade Manual)" | TERCEIRO SSD                     ;
                                                                                                             ;
    jsr #delay        ; Pula na subrotina de espera para vizualização nos disps                              ;
                                                                                                             ;
    st r7, r15, r11   ; r7 <= array[Dezena Manual]                                                           ;
    ldh r5, #08h      ; Quarto display                                                                       ;
    ldl r5, r7        ; Valor de 8 bits a ser colocado no SSD                                                ;
    st r5, r0, r2     ;PortData <= "0000 1000 &  (Valor Dezena Manual)" | QUARTO SSD                         ;
                                                                                                             ;
    jsr #delay                                                                                               ;
                                                                                                             ;
    pop r15                                                                                                  ;
    pop r14                                                                                                  ;
    pop r12                                                                                                  ;
    pop r11                                                                                                  ;
    pop r10                                                                                                  ;
    pop r9                                                                                                   ;
    pop r7                                                                                                   ;
    pop r5             ; Retoma o contexto                                                                   ;
    rts                ; REtorna                                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lePorta:
; Retorna Estado do botao 

;	r1 <= Dado da porta
	ld r1, r0, r2
	
;	Gera flag zero para condição de pulo
	add r1, r0, r1
	
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

;	r15 <= Mascara de comparação para BTN DOWN (10000000_00000000)
	ldh r15, #80h
	ldl r15, #00h

;	Se BTN DOWN foi pressionado, r1 <= 0, decrenenta contador
	and r1, r1, r15
	sub r1, r1, r15
	jmpzd #manual--
	
;	Carrega lixo em r15 para manter tempo de execução constante, independente da tomada de branch (11 ciclos)
	ld r15, r0, r0
	ld r15, r0, r0

  returnManual--:
  
;	Restaura valor lido da porta, salva novamente	
	pop r1
	push r1
	
;	r15 <= Mascara de comparação para BTN UP (01000000_00000000)
	ldh r15, #04h
	ldl r15, #00h	

;	Se BTN UP foi pressionado, r1 <= 0, incrementa contador
	and r1, r1, r15
	sub r1, r1, r15
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
	
;	Incrementa contador continuo se passou 1 seg, demorando 72 ciclos

;	Se 1 segundo se passou, nao incrementa contador
	jmpzd #returnContinuo ;3 ciclos 
	
	addi r7, #01h         ;6  ciclos
	ld r15, r0, r0        ;11 ciclos
	ld r15, r0, r0        ;14 ciclos
	nop                   ;17 ciclos
	nop                   ;20 ciclos
	nop                   ;23 ciclos
	nop                   ;26 ciclos
	nop                   ;29 ciclos
	nop                   ;32 ciclos
	nop                   ;35 ciclos
	nop                   ;38 ciclos
	nop                   ;41 ciclos
	nop                   ;44 ciclos
	nop                   ;47 ciclos
	nop                   ;50 ciclos
	nop                   ;53 ciclos
	nop                   ;56 ciclos
	nop                   ;59 ciclos
	nop                   ;62 ciclos
	nop                   ;65 ciclos
	nop                   ;68 ciclos

	rts                   ;72 ciclos
	
  returnContinuo:
  
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
	ld r15, r0, r0        ;68 ciclos

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