;*****************************************************************
; Map buffer - directions
; same macros as MapBuffer.s
; additonally there are 2 bits per tile, direction 0-3
;*****************************************************************
; stores offset in temp address
.macro calculate_offset_directions Row, Column
    ;Calculate the base address of the row (Row * 8)
    LDA Row
    SEC
    SBC #1
    
    ASL             ;== times 2
    ASL             ;== times 4
    ASL             ;== times 8
    STA x_val

    ;Calculate the byte offset within the row (Column / 4)
    LDA Column
    LSR
    LSR

    ;Add the byte offset to the base row address
    CLC 
    ADC x_val
    STA temp_address ; == byte offset
.endmacro

.macro set_direction Row, Col, Direction
    calculate_offset_directions Row, Col
    
    LDA Col
    AND #%00000011
    STA x_val

    LDA Direction
    TAY

    LDA #3
    SEC
    SBC x_val
    BEQ :++
    TAX

    ; shift direction to correct position in byte
    LDA Direction
    :
    ASL
    ASL
    DEX
    BNE :-
    
    TAY
    :

    TYA
    TAX

    LDY temp_address
    LDA DIRECTIONS_ADDRESS, Y   
    STX temp_address
    ORA temp_address
    STA DIRECTIONS_ADDRESS, Y
.endmacro

; loads direction in A register
.macro get_direction Row, Col
    calculate_offset_directions Row, Col

    LDY temp_address
    LDA DIRECTIONS_ADDRESS, Y 
    TAY

    ; direction from E.g 11 xx xx xx -> 00 00 00 11
    ; this ensure direction is in the 0-3 range when returning

    ; clamp col
    LDA Col
    AND #%00000011
    STA x_val

    ; how many times should we shift (3 - col)
    LDA #3
    SEC
    SBC x_val
    BEQ :++
    TAX

    TYA
    :
    LSR
    LSR
    DEX
    BNE :-
    TAY

    :
    TYA
    ; final result could still contain other direction bits we only want bit 0 and 1
    AND #%00000011
.endmacro

.proc clear_direction_buffer
    LDX #0
    LDA #0

    @clear_dir: 
        STA DIRECTIONS_ADDRESS, x
        INX
        CPX #DIRECTIONS_BUFFER_SIZE
        BNE @clear_dir
    RTS
.endproc

;*****************************************************************