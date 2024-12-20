.macro vram_set_address newaddress
    lda PPU_STATUS
    lda #>newaddress
    sta PPU_VRAM_ADDRESS2
    lda #<newaddress
    sta PPU_VRAM_ADDRESS2
.endmacro

.macro assign_16i dest, value
    lda #<value
    sta dest+0
    lda #>value
    sta dest+1
.endmacro

.macro vram_clear_address
    lda #0
    sta PPU_VRAM_ADDRESS2
    sta PPU_VRAM_ADDRESS2
.endmacro

.macro set_Carry_to_highest_bit_A
    cmp #%10000000
    bmi :+
    sec
    jmp :++
    :
    clc
    :
.endmacro

; result = value % modulus
; => result is stored in the A register
.macro modulo value, modulus
    LDA value
    SEC

    :
    SBC modulus
    CMP modulus
    BCS :-

.endmacro

.macro multiply10 value
    LDA value
    CLC
    ROL ;x2
    TAX
    ROL ;x2
    ROL ;x2 = x8
    STA a_val
    TXA
    ADC a_val
.endmacro

;remainder currently not stored but can be stored if necessaery (check comment - done label) quotient in A
.macro divide10 value
        ;with help from chatGPT
        LDY #0          ; Initialize Y (Quotient) to 0

        LDA #9
        CLC
        CMP value       ; Check if smaller than 10
        BCS SkipDivide

        LDA value
        SEC             ; Set carry for subtraction
    .local DivideLoop
    DivideLoop:
        SBC #10         ; Subtract 10 from A
        BCC FinishLoop        ; If result is negative, exit loop
        INY             ; Increment Y (Quotient)
        JMP DivideLoop  ; Repeat the loop

    .local SkipDivide
    SkipDivide:
        LDA value
        JMP Done
    .local FinishLoop
    FinishLoop:
        ADC #10
    .local Done
    Done:
        ;TAX   ; Store the remainder (A)
        TYA     ; Store the quotient (Y)

.endmacro
