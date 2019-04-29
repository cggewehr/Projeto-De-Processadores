;;; Interrupt Service Request ;;;
;;; Carlos Gewehr e Emilio Ferreira ;;;

;InterruptionServiceRoutine:
;    1. Salvamento de contexto
;    2. Verificação da origem da interrupção (polling) e 
;       salto para o handler correspondente (jsr)
;    3. Recuperação de contexto
;    4. Retorno (rti)

;Tabela de Registradores:
;r0 = 0
;r10 = 1

InterruptionServiceRoutine:

;	Pushes context
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
	push r15
	pushf
	
;	Register Initialization

	xor r0, r0, r0
	
	xor r10, r10, r10
	addi r10, #01h


;	Returns on r4 if button UP was pressed, r4 = 1 if button was pressed, else r4 = 0
	jsrd #findButtonUPStatus
	
;	If r4 == 1 calls driver for button UP action
	and r4, r4, r10
	sub r4, r4, r10
	jmpzd #callDriverButtonUp

  returnDriverButtonUp:

;	Returns on r4 if button DOWN was pressed, r4 = 1 if button was pressed, else r4 = 0
	jsrd #findButtonDOWNStatus
	
;   If r4 == 1 calls driver for button UP action
	and r4, r4, r10
	sub r4, r4, r10
	
	jmpzd #callDriverButtonDown

  returnDriverButtonDown:

;	Retrieves context
	popf
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
	pop r0

;	Returns to normal execution flow
	rti
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

callDriverButtonUp:
	jsrd #driverButtonUp
	jmpd #returnDriverButtonUp
	
callDriverButtonDown:
	jsrd #driverButtonDown
	jmpd #returnDriverButtonDown