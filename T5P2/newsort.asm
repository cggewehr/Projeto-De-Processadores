

;------------------------------------------- PROGRAMA PRINCIPAL ---------------------------------------------
.code
main:

    xor r12, r12, r12
    jmpd #BubbleSort

    addi r12, #01h
    jmpd #BubbleSort
    jmpd #main

;; BUBBLE SORT DO CARARA

;* Bubble sort

;*      Sort array in ascending order
;*
;*      Used registers:
;*          r1: points the first element of array
;*          r2: temporary register
;*          r3: points the end of array (right after the last element)
;*          r4: indicates elements swaping (r4 = 1)
;*          r5: array index
;*          r6: array index
;*          r7: element array[r5]
;*          r8: element array[r8]
;*          r9: send count
;*          r10: array size
;*          r11: transmission count
;*          r12: Array Sort Order (0 =  Cresc, 1 = Decres)
;*
;*********************************************************************
aplication:
    xor r12, r12, r12
    jmpd #BubbleSort
    
BubbleSort2:
    addi r12, #01h
    jmpd #BubbleSort
    halt
    jmpd #aplication

BubbleSort:

    ;halt ; DEBUG, ignora bubble sort

    ; Initialization code
    xor r0, r0, r0          ; r0 <- 0
    xor r11, r11, r11       ; r11 <- 0
    

    ldh r1, #arraySort      ;
    ldl r1, #arraySort      ; r1 <- &array

    ldh r2, #arraySortSize  ;
    ldl r2, #arraySortSize  ; r2 <- &size
    ld r2, r2, r0           ; r2 <- size
    
    add r3, r2, r1          ; r3 points the end of array (right after the last element)

    ldl r4, #0              ;
    ldh r4, #1              ; r4 <- 1

    jmpzd #scan
   
; Main code
scan:
    addi r4, #0             ; Verifies if there was element swapping
    jmpzd #end    

    xor r4, r4, r4          ; r4 <- 0 before each pass

    add r5, r1, r0          ; r5 points the first array element

    add r6, r1, r0          ;
    addi r6, #1             ; r6 points the second array element

; Read two consecutive elements and compares them
loop:
    ld r7, r5, r0           ; r7 <- array[r5]
    ld r8, r6, r0           ; r8 <- array[r6]

    add r12, r0, r12        ; Generate flag for order of array
    jmpzd #crescent
    jmpd #decrescent

crescent:
    sub r2, r8, r7          ; If r8 > r7, negative flag is set
    jmpnd #swap             ; (if array[r5] > array[r6] jump)
    jmpd #continue

decrescent:
    sub r2, r7, r8          ; If r8 < r7, negative flag is set
    jmpnd #swap             ; (if array[r5] < array[r6] jump)
    jmpd #continue
    

; Increments the index registers and verifies if the pass is concluded
continue:
    addi r5, #1             ; r5++
    addi r6, #1             ; r6++

    sub r2, r6, r3          ; Verifies if the end of array was reached (r6 = r3)
    jmpzd #scan             ; If r6 = r3 jump
    jmpd #loop              ; else, the next two elements are compared

; Swaps two array elements (memory)
swap:
    st r7, r6, r0           ; array[r6] <- r7
    st r8, r5, r0           ; array[r5] <- r8
    ldl r4, #1              ; Set the element swapping (r4 <- 1)
    jmpd #continue

end:
    add r12, r0, r12      ; Generates flag for order
    jmpzd #BubbleSort2
    jmpd #aplication
    halt                    ; Suspend the execution

.endcode

;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================
;=============================================================================================================


;; .org #0300h
.data

;-------------------------------------------VARIAVEIS DE APLICAÇÃO-------------------------------------------

; Array para aplicação principal (Bubble Sort) de 50 elementos
arraySort:                db #0050h, #0049h, #0048h, #0047h, #0046h, #0045h, #0044h, #0043h, #0042h, #0041h, #0040h, #0039h, #0038h, #0037h, #0036h, #0035h, #0034h, #0033h, #0032h, #0031h, #0030h, #0029h, #0028h, #0027h, #0026h, #0025h, #0024h, #0023h, #0022h, #0021h, #0020h, #0019h, #0018h, #0017h, #0016h, #0015h, #0014h, #0013h, #0012h, #0011h, #0010h, #0009h, #0008h, #0007h, #0006h, #0005h, #0004h, #0003h, #0002h, #0001h

; Tamanho do array p/ bubble sort (50 elementos)
arraySortSize:            db #50

.enddata
