.segment "CODE"
.proc init_chests
    LDA #1
    STA num_chests

    ; chest tile
    LDY #7 ; row (map)
    LDX #1 ; col (map)
    ; STY temp_row
    ; STX temp_col

    RTS
.endproc