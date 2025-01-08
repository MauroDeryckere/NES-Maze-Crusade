.segment "CODE"
.proc init_chests    
    ; chest tile
    LDY #7 ; row (map)
    LDX #1 ; col (map)

    STY temp_row
    STX temp_col
    
    JSR add_to_chest_buffer

    ; chest tile
    LDY #9 ; row (map)
    LDX #1 ; col (map)

    STY temp_row
    STX temp_col
    
    JSR add_to_chest_buffer
    
    RTS
.endproc