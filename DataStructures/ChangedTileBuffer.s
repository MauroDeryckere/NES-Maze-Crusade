; Vblank buffer contains the row and column of the tile on the background
; Stores 3 bytes per tile, high byte of location low byte of location and the tile from the tilesheet we're using.
;*****************************************************************
.macro add_to_changed_tiles_buffer Row, Col, TileID
    LDA Row
    STA temp_row

    LDX TileID

    LDA Col
    STA temp_col

    CMP #32
    BCC n0
        SEC
        SBC #32
        STA temp_col
       
        JSR add_to_changed_tiles_buffer_n1
        JMP return

    .local n0
    n0:
        JSR add_to_changed_tiles_buffer_nO
        
    .local return
    return: 

.endmacro
;*****************************************************************

;nametable 0
.proc add_to_changed_tiles_buffer_nO
    LDY #0
    @loop:

        LDA changed_tiles_buffer, y
        CMP #$FF
        BEQ @add_vals
        
        INY
        INY
        INY

        CPY #CHANGED_TILES_BUFFER_SIZE
        BNE @loop

    @add_vals:
        LDA #0
        STA high_byte
        LDA temp_row
        STA low_byte
        
        CLC
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2 == 32
        ROL high_byte

        LDA #NAME_TABLE_0_ADDRESS_HIGH ;add high byte
        ADC high_byte
        STA changed_tiles_buffer, Y
        
        ;col
        INY
        LDA temp_col
        ADC low_byte 
        STA changed_tiles_buffer, Y

        ;tile Id
        INY
        STX changed_tiles_buffer, Y

        RTS
.endproc

; Row, Col, TileID
;nametable 1
.proc add_to_changed_tiles_buffer_n1 
    LDY #0
    @loop:

        LDA changed_tiles_buffer, y
        CMP #$FF
        BEQ @add_vals
        
        INY
        INY
        INY

        CPY #CHANGED_TILES_BUFFER_SIZE
        BNE @loop

    @add_vals:
        LDA #0
        STA high_byte
        LDA temp_row
        STA low_byte
        
        CLC
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2
        ROL high_byte
        ASL low_byte ;x2 == 32
        ROL high_byte

        LDA #NAME_TABLE_1_ADDRESS_HIGH ;add high byte
        ADC high_byte
        STA changed_tiles_buffer, Y
        
        ;col
        INY
        LDA temp_col
        ADC low_byte 
        STA changed_tiles_buffer, Y

        ;tile Id
        INY
        STX changed_tiles_buffer, Y

        RTS
.endproc

.segment "CODE"
.proc poll_clear_buffer
    LDA should_clear_buffer
    BEQ :+
        JSR clear_changed_tiles_buffer
        LDA #0
        STA should_clear_buffer
    :
    RTS
.endproc

.proc clear_changed_tiles_buffer
    LDY #0
    
    @loop: 
        LDA #$FF
        STA changed_tiles_buffer, Y

        INY
        CPY #CHANGED_TILES_BUFFER_SIZE
    BNE @loop

    RTS
.endproc