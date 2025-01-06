.segment "CODE"
.proc init_HUD
    JSR ppu_off
    
    ; Set the HUD attribute table
    vram_set_address (ATTRIBUTE_TABLE_0_ADDRESS)
    LDY #SCREEN_COLS / 4
    LDA #%00001111
    @attloop: 
        STA PPU_VRAM_IO  
        DEY
        BNE @attloop

    ; Set the HUD top row

    vram_set_address (NAME_TABLE_0_ADDRESS + 0 * 32 + 0)
    assign_16i paddr, HUD_row_0
    JSR write_consecutive_tiles

    LDA #HUD_DIVIDOR_TILE
    LDX #SCREEN_COLS
        @loop_: 
            STA PPU_VRAM_IO
            DEX
            BNE @loop_
    ; -----------------------------------------

    LDA #1
    STA should_update_score
    JSR display_score

    JSR ppu_update
    RTS
.endproc

;display the score
.proc display_score
    LDA should_update_score
    BNE :+
        RTS
    :

    vram_set_address (NAME_TABLE_0_ADDRESS + 1 * 32 + 13)

    LDA score + 2
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    TAY
    TXA
    ADC #$40
    STA PPU_VRAM_IO
    TYA
    ADC #$40
    STA PPU_VRAM_IO

    LDA score + 1
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    TAY
    TXA
    ADC #$40
    STA PPU_VRAM_IO
    TYA
    ADC #$40
    STA PPU_VRAM_IO

    LDA score
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    TAY
    TXA
    ADC #$40
    STA PPU_VRAM_IO
    TYA
    ADC #$40
    STA PPU_VRAM_IO

    LDA #0
    ADC #$40
    STA PPU_VRAM_IO

    LDA #0
    STA should_update_score

    RTS
.endproc

HUD_row_0: 
.byte $72, $71, $71, $57, $54, $50, $5B, $63, $57, $71, $71, $75, $72, $71, $62, $52, $5E, $61, $54, $71, $75, $72, $58, $5D, $65, $54, $5D, $63, $5E, $61, $68, $75
HUD_row_1:
.byte $70, $D1, $78, $78, $78 ,$78, $78, $78, $78, $78, $78, $74, $70, $02, $02, $02, $02, $02, $02, $02, $74, $70, $02, $02, $02, $02, $02, $02, $02, $02, $02, $74, 0
