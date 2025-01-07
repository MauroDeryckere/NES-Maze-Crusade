.segment "CODE"
.proc init_chests
    LDA #1
    STA num_chests
    
    ; chest tile
    LDY #7 ; row (map)
    LDX #1 ; col (map)
    STY temp_row
    STX temp_col
    
    ; set chest in buffer
    set_map_tile temp_row, #MAP_END_COL + 1
    set_map_tile #MAP_START_ROW - 1, temp_col
    
    RTS
.endproc