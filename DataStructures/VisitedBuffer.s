 ;*****************************************************************
; Map buffer - visited list 
; Used in the BFS to track which cells have been visited and haven't been.
; Also used as a buffer to track which cells are visible to the player or not in hard mode 
; to ensure we only update newly visible tiles in the background
;*****************************************************************
.macro calculate_offset_and_mask_visited Row, Column
    ;Calculate the base address of the row (Row * 4)
    LDA Row

    ; Decrease row by 1 - top border is empty so row 1 is actually row 0 in the buffer
    SEC
    SBC #1

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

; sets the bit to 1
.macro set_visited Row, Col
    calculate_offset_and_mask_visited Row, Col
    
    LDY temp_address
    LDA VISISTED_ADDRESS, Y   
    ORA y_val
    STA VISISTED_ADDRESS, Y

.endmacro

; 0 or non zero value
.macro is_visited Row, Col
    calculate_offset_and_mask_visited Row, Col
    
    LDY temp_address
    LDA VISISTED_ADDRESS, Y   
    AND y_val

.endmacro

.proc clear_visited_buffer
    LDX #0
    LDA #0
    
    @clear_cell: 
        STA VISISTED_ADDRESS, x
        INX
        CPX #VISITED_BUFFER_SIZE
        BNE @clear_cell

        RTS
.endproc

;*****************************************************************