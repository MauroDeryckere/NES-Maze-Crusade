.segment "CODE"
.proc update_oam
    ; just simple test for now, torches will actually do something and be randomly generated later


    ; Torches / lamps
    LDX curr_oam_byte

    ; calculate x pos first to know if this torch is off screen
    LDA #8
    SEC
    SBC scroll_x
    TAY
    CMP #0
    BMI @off_screen

    JMP @on

    @off_screen: 
        ;Y coordinate
        LDA $FE
        STA oam, X
        INX

        ;Tile pattern index
        LDA #TORCH_TILE
        STA oam, X
        INX

        ;Sprite attributes
        LDA #%00000001
        STA oam, X
        INX

        ;X coordinate
        TYA
        STA oam, X
        INX


        RTS

    @on: 

    ;Y coordinate
    LDA #64 
    STA oam, X
    INX

    ;Tile pattern index
    LDA #TORCH_TILE
    STA oam, X
    INX

    ;Sprite attributes
    LDA #%00000001
    STA oam, X
    INX

    ;X coordinate
    TYA
    STA oam, X
    INX

    RTS
.endproc