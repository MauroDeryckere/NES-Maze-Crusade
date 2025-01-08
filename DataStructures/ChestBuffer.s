.segment "CODE"
; temp row and temp col have to contain values you wish to add
.proc add_to_chest_buffer
    LDX #CHEST_BUFFER_SIZE - 1
    @loop: 
        DEX 
        LDA chests_buffer, X
        BEQ @add_vals
        
        DEX
        BPL @loop

    @add_vals: 
        LDA temp_row
        STA chests_buffer, X
        INX
        LDA temp_col
        STA chests_buffer, X

    @return: 
        RTS
.endproc

.segment "CODE"
; Row in temp_row, col in temp_col
.proc remove_from_chest_buffer
    LDX #CHEST_BUFFER_SIZE - 1
    @loop: 
        LDA chests_buffer, X
        CMP temp_col
        BNE :+
            DEX
            LDA chests_buffer, X
            CMP temp_row
            BEQ @return

            DEX
            BPL @loop
            RTS
        :

        DEX
        BPL @loop
        RTS ; don't remove anything in this case

    @return: 
        LDA #0
        STA chests_buffer, X

        RTS
.endproc

.segment "CODE"
; only clears the row since we use this to know whether or not there is a chest
.proc clear_chest_buffer
    LDX #CHEST_BUFFER_SIZE - 1
    @loop: 
        LDA #0
        DEX
        STA chests_buffer, X
        DEX

        BPL @loop
    RTS
.endproc