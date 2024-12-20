 ;*****************************************************************
; Map buffer - visited list 
; same macros as maze buffer but not in zero page. read maze buffer documentation for info
;*****************************************************************
.macro calculate_offset_and_mask_visited Row, Column
    ;Calculate the base address of the row (Row * 4)
    LDA Row
    ASL             ;== times 2
    ASL             ;== times 2
    STA x_val

    ;Calculate the byte offset within the row (Column / 8)
    LDA Column
    LSR
    LSR
    LSR

    ;Add the byte offset to the base row address
    CLC 
    ADC x_val
    STA temp_address ; == byte offset
    
    ; bitmask: 
    ;Clamp the 0-31 Column to 0-7 
    LDA Column
    AND #%00000111

    STA x_val

    LDA #%00000001
    STA y_val

    ;Calculate how many times we should shift
    LDA #7
    SEC
    SBC x_val    
    BEQ :++
    TAX
    
    LDA y_val
    :    
    ASL
    DEX
    BNE :-

    STA y_val
    :
.endmacro

.macro set_visited Row, Col
    calculate_offset_and_mask_visited Row, Col
    
    LDY temp_address
    LDA VISISTED_ADDRESS, Y   
    ORA y_val
    STA VISISTED_ADDRESS, Y

.endmacro

.macro is_visited Row, Col
    calculate_offset_and_mask_visited Row, Col
    
    LDY temp_address
    LDA VISISTED_ADDRESS, Y   
    AND y_val

.endmacro

;*****************************************************************