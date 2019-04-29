;============================================================================================================;
; Assembly Trabalho 3 Parte 2 - Contador continuo e Incremento/Decremento de botao Por interrupção
; Carlos Gewehr, Emilio Ferreira
; Projeto de Processadores - UFSM/1
;
; TODO -> * Adicionar os controles para overflow, underflow [contador +99 ou contador -00]
;         * Verificar se o AND, realmente funciona, ou se está funcionando bit a bit
;         * Verificar se o programa trava ou demora demasiado lidando com a interrupção,
;
; REGISTRADORES
; --------------------- r0  = 0
; --------------------- r1  = &arrayPorta
; --------------------- r2  = PARAMETRO para subrotina
; --------------------- r3  = PARAMETRO para subrotina
; --------------------- r10 = Valor do display 0 | unidadeContinuo
; --------------------- r11 = Valor do display 1 | dezenaContinuo
; --------------------- r12 = Valor do display 2 | unidadeManual
; --------------------- r13 = Valor do display 3 | dezenaManual
; --------------------- r14 = Retorno de subrotina
; --------------------- r15 = Retorno de subrotina
;============================================================================================================;
.org #0000h

.code
init: ; Inicialização dos registradores
    ldh r0, #7Fh  ;Carrega o novo valor do SP
    ldl r0, #FFh  ;Carrega o novo valor do SP
    ldsp r0       ;Carrega o novo valor do SP

    ldh r1, #arrayPorta ; Carrega &Porta
    ldl r1, #arrayPorta ; Carrega &Porta

    add r4, r0, r1 ; Carrega indexador de arrayPorta  [ arrayPorta[r4] -> &PortData ]

    ; Seta PortConfig
    addi r4, #01h  ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortConfig ]
    ldh r5, #C0h   ; r5 <= "11000000_00000000"
    ldl r5, #00h   ; bit 15 e 14 = entrada, outros = saida
    st r5, r1, r4  ; PortConfig <= "11000000_00000000"

    ; Seta PortEnable
    addi r4, #01h  ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &PortEnable ]
    ldh r5, #DEh   ; r5 <= "11011110_11111111"
    ldl r5, #FFh   ; Habilita acesso a todos os bits da porta de I/O, menos bit 13 e bit 8
    st r5, r1, r4  ; PortEnable <= "11011110_11111111"

    ; Seta irqtEnable
    addi r4, #01h  ; Atualiza indexador de arrayPorta [ arrayPorta[r4] -> &irqtEnable ]
    ldh r5, #C0h   ; r5 <= "11000000_00000000"
    ldl r5, #00h   ; Habilita a interrupção nos bits 15 e 14
    st r5, r1, r4  ; irqtEnable <= "11000000_00000000"

    xor r10, r10, r10 ; Zera o registrador r10 [ valorDisplay[0] = 0 ]
    xor r11, r11, r11 ; Zera o registrador r11 [ valorDisplay[1] = 0 ]
    xor r12, r12, r12 ; Zera o registrador r12 [ valorDisplay[2] = 0 ]
    xor r13, r13, r13 ; Zera o registrador r13 [ valorDisplay[3] = 0 ]

    xor r0, r0, r0 ; Zera o registrador r0

    jmpd #main
;=============================================================================================================
;_________________________________________INTERRUPT_REQUEST___________________________________________________
InterruptionServiceRoutine:
;InterruptionServiceRoutine:
;    1. Salvamento de contexto
;    2. Verificação da origem da interrupção (polling) e salto para o handler correspondente (jsr)
;    3. Recuperação de contexto
;    4. Retorno (rti)

    push r0  ; Salvamento de contexto da interrupção
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
    push r15
    pushf     ; Salvamento das flags

    xor r0, r0, r0       ; Zera o resgistrador
    ldh r1, #arrayPorta  ; Pega o endereço da porta
    ldl r1, #arrayPorta  ; [ r1 <= &PortData ]
    ld r1, r0, r1        ; Le o valor da porta e salva em r1 [ r1 <= valor lido da porta ]

    ldh r2, #80h ; Carrega mascara para comparação para o botao de Decremento
    ldl r2, #00h ; [ r2 <= "10000000_00000000" ]

    and r3, r1, r2 ; Verificação do botão pressionado, [ Incremento-> r3 <= '0', Decremento-> r3 <= '1' ]
    jmpzd #PushButtonInc_Handler ; Se for zero significa que o botao pressionado foi de incremento
    jmpd #PushButtonDec_Handler  ; Senão o botão pressionado foi o de decremento
	
PushButtonDec: ; Interrupção de botão de decremento
	jsr #PushButtonDec_Handler ; Chama subrotina de tratamento de interrupção
	jmpd #return_InterruptionServiceRoutine  ; Acaba a interrupção

PushButtonInc: ; Interrupção de botão de incremneto
	jsr #PushButtonInc_Handler ; Chama subrotina de tratamento de interrupção
	jmpd #return_InterruptionServiceRoutine  ; Acaba a interrupção
	
;_________________________________________DECREMENTO__________________________________________________________
; Subrotina de tratamento de interrupção, decrementa o contador manual
; Não recebe parametros e não retorna nada
PushButtonDec_Handler:
    add r12, r0, r0 ; R12 + 0 para gerar flags
    jmpzd #decrementa_Manual_unidade_zero ; Unidade é igual a zero, logo precisamos decrementar a dezena
    subi r12, #01h ; Decrementa unidadeManual em uma unidade
    jmpd #return_PushButtonDec_Handler ; Retorna
decrementa_Manual_unidade_zero: ; Decrementa a dezenaManual e seta a unidadeManual em 9
    subi r13, #01h ; Decrementa a dezenaManual em 1 [r13 --]
    addi r12, #09h ; Seta a unidadeManual para 9 [r12 <= 9]
    jmpd #return_PushButtonDec_Handler ; retorna
return_PushButtonDec_Handler:
	rts ; Retorna da subrotina

;_________________________________________INCREMENTO__________________________________________________________
; Subrotina de tratamento de interrupção, incrementa o contador manual
; Não recebe parametros e não retorna nada
PushButtonInc_Handler:
    ldh r4, #00h  ; Mascara de comparação com o numero 10
    ldh r4, #0Ah  ; [r7 <= '00000000_00001010']
    and r5, r12, r4 ; Comparação da unidadeManual com o numero 10
    jmpzd #incrementa_Manual_unidade ; Caso o numero seja diferente de 10, pula para incrementar unidade
    xor r12, r12, r12 ; Zera a unidadeManual
    addi r13, #01h  ; Incrementa a dezenaManual
    jmpd #return_PushButtonInc_Handler ; Retorna
incrementa_Manual_unidade:  ; Incrementa a unidadeManual
    addi r12, #01h ; Incrementa a unidadeManual em 1 [r10 ++]
    jmpd #return_PushButtonInc_Handler ; Retorna
return_PushButtonInc_Handler:
	rts ; Retorna da subrotina


return_InterruptionServiceRoutine:
    popf    ; Recuperação das flags
    pop r15
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
    pop r0  ; Recuperação de contexto
    rti     ; Retorna para execução normal
;_____________________________________________________________________________________________________________
;=============================================================================================================

;_________________________________________MAIN [LOOP INFINITO]________________________________________________
main:
    jsrd #contador_1_seg ; Conta 1 seg utilizando tempo de display
    jsrd #incrementa_Continuo ; Incrementa o contador continuo
    halt ; debug
    jmpd #main ; Loop infinito

;_________________________________________CONTADOR_1_SEG______________________________________________________
contador_1_seg: ; Executa a função de display 84 vezes, totalizando 100ms
    push r8  ; Iterador do loop
    ldh r8, #00h
    ldl r8, #55h ; Carrega valor de iteração do loop [r8 <= 85]
loop_1_s: ; Realiza 100 iterações de 10 ms cada, totalizando 1 seg
    subi r8, #01h   ; Decrementa a variavel de comparação  [r8 --]
    jmpzd #return_contador_1_seg ; Caso for igual a zero finaliza a função
    jsrd #display_loop ; Chama a subrotina que escreve no display
    jmpd #loop_1_s     ; A cada iteração 10 ms se passaram
return_contador_1_seg: ; Retorna a função para aonde foi chamada
    pop r8        ; Restaura o contexto
    rts           ; Retorna da subrotina
;

;_________________________________________INCREMENTA_CONTINUO_________________________________________________
; Realiza o incremento do contador continuo
; Não recebe parametros e não retorna nada
incrementa_Continuo:
    push r7 ; Mascara de comparação com o numero 10
    ldh r7 #00h ;
    ldl r7 #0Ah ; [r7 <= '00000000_00001010]
    and r7, r10, r7 ; Comparação do contador unidadeContinuo com o numero 10
    jmpzd #incrementa_Continuo_unidade ; caso o valor da unidadeContinuo não seja igual a 10 [r7 == 0Ah]
    xor r10, r10, r10 ; Numero é igual a 10, zera a unidade [unidadeContinuo = 0, r10 <= '0']
    addi r11, #01h    ; incrementa a dezenaContinuo, dezenaContinuo += 1 [r11 ++]
    jmpd #return_incrementa_Continuo ; Finaliza a função
incrementa_Continuo_unidade:
    addi r10, #01h ; Incrementa a unidadeContinuo em 1 [r10 ++]
return_incrementa_Continuo:
    pop r7
    rts
;

;_______________________________________________DISPLAY_LOOP__________________________________________________
; Realiza a alternancia e escreve na porta para mostrar os valores respectivos nos respectivos displays
; Não recebe parametros e não retorna nada
display_loop: ; loop principal que executa a leitura e a atualização dos displays| 10 ms
    push r4 ; &arrayDisp
    push r5 ; indexador
    push r9 ; Valor escrito na porta [ "000" & "(12 downto 9)[disp]" & '0' & "(8 downto 0)[Numero]" ]

    ldh r4, #arrayDisp ; Carrega &arrayDisp
    ldl r4, #arrayDisp ; Carrega &arrayDisp

    ; Unidade Continua
    xor r5, r5, r5  ; zera o indexador
    ld r9, r4, r5   ; r9 <= arrayDisp[r5] [r9 <= "00000010_00000000"]
    add r9, r9, r10 ; r9 <= "00000010_00000000" + unidadeContinuo
    st r9, r0, r1   ; PortData <= arrayDisp & unidadeContinuo
    jsrd #display_show_delay ; Fica mostrando o valor por 2.5 ms ~~

    ; Dezena Continuo
    addi r5, #01h   ; Incrementa o indexador
    ld r9, r4, r5   ; r9 <= arrayDisp[r5] [r9 <= "00000100_00000000"]
    add r9, r9, r11 ; r9 <= "00000100_00000000" + dezenaContinuo
    st r9, r0, r1   ; PortData <= arrayDisp & dezenaContinuo
    jsrd #display_show_delay ; Fica mostrando o valor por 2.5 ms ~~

    ; Unidade Manual
    addi r5, #01h   ; Incrementa o indexador
    ld r9, r4, r5   ; r9 <= arrayDisp[r5] [r9 <= "00001000_00000000"]
    add r9, r9, r12 ; r9 <= "00001000_00000000" + unidadeManual
    st r9, r0, r1   ; PortData <= arrayDisp & unidadeManual
    jsrd #display_show_delay ; Fica mostrando o valor por 2.5 ms ~~

    ; Dezena Manual
    addi r5, #01h   ; Incrementa o indexador
    ld r9, r4, r5   ; r9 <= arrayDisp[r5] [r9 <= "00000100_00000000"]
    add r9, r9, r13 ; r9 <= "00010000_00000000" + dezenaManual
    st r9, r0, r1   ; PortData <= arrayDisp & dezenaManual
    jsrd #display_show_delay ; Fica mostrando o valor por 2.5 ms ~~

    pop r9   ; Restaura os valores anteriores dos registradores utilizados
    pop r5
    pop r4
    rts      ; Volta para a função na qual foi chamada
;

;_________________________________________ DISPLAY_SHOW_DELAY_________________________________________________
; Gasta 2.5 ms de processamento para o digito poder ficar aparecendo no display
; Não recebe parametros não retorna nada
display_show_delay: ; Gasta tempo do processador para que o display fique ativo | 2.5 ms
    push r6 ; Contador para delay
    ldh r6, #30h
    ldl r6, #D4h  ; r6 <= 12 500
display_show_delay_loop: ; ~10 ciclos cada intereção
    subi r6, #01h  ; Decrementa o contador para o delay [r6 --]
    jmpzd #return_display_show_delay_loop ; Caso seja zero, acabou o delay [r6 == 0 entao sair]
    jmpd #display_show_delay_loop ; Caso diferente de zero volta para o loop [r6 != 0 entao loop]
return_display_show_delay_loop: ;  Executados ~~ 125 000 ciclos
    pop r6  ; Restaura valor anterior
    rts     ; Volta para a função na qual foi chamada
;_____________________________________________________________________________________________________________
.endcode

.data
; array de regs da Porta Bidirecional
; arrayPorta [ PortData(0x8000) | PortConfig(0x8001) | PortEnable(0x8002) | irqtEnable(0x8003) ]
arrayPorta: db #8000h, #8001h, #8002h, #8003h

; array SSD representa o array de valores a serem postos nos displays de sete seg
             ;|  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |
arraySSD:   db #03h, #9fh, #25h, #0dh, #99h, #49h, #21h, #1fh, #01h, #09h

; Array que escolhe qual disp sera utilizado  Mais da direita -> Mais da esquerda
arrayDisp:  db #0200h, #0400h, #0800h, #1000h
.enddata