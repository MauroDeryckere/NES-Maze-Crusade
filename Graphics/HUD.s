.segment "CODE"
.proc init_HUD
    JSR ppu_off
    
    ; Set the HUD attribute tables
    vram_set_address (ATTRIBUTE_TABLE_0_ADDRESS)
    LDY #SCREEN_COLS / 4
    LDA #%00001111
    @attloop: 
        STA PPU_VRAM_IO  
        DEY
        BNE @attloop

    vram_set_address (ATTRIBUTE_TABLE_1_ADDRESS)
    LDY #SCREEN_COLS / 4
    LDA #%00001111
    @attloop2: 
        STA PPU_VRAM_IO  
        DEY
        BNE @attloop2
    ; ------------------------------

    ; Set the HUD BG tiles
    vram_set_address (NAME_TABLE_0_ADDRESS)
    LDY #MAP_START_ROW - 1
    LDA #HUD_BG_TILE
    @rloop:
    LDX #SCREEN_COLS
        @loop: 
            STA PPU_VRAM_IO
            DEX
            BNE @loop
        DEY
        BNE @rloop

    LDA #HUD_DIVIDOR_TILE
    LDX #SCREEN_COLS
        @loop_: 
            STA PPU_VRAM_IO
            DEX
            BNE @loop_

    vram_set_address (NAME_TABLE_1_ADDRESS)
    LDY #MAP_START_ROW - 1
    LDA #HUD_BG_TILE
    @rloop2: 
    LDX #SCREEN_COLS
        @loop2: 
            STA PPU_VRAM_IO
            DEX
            BNE @loop2
        DEY
    BNE @rloop2

    LDA #HUD_DIVIDOR_TILE
    LDX #SCREEN_COLS
        @loop2_: 
            STA PPU_VRAM_IO
            DEX
            BNE @loop2_
    ; -----------------------------------------




    LDA #1
    STA should_update_score
    JSR display_score

    JSR init_hp_bar

    JSR ppu_update
    RTS
.endproc

.proc display_hp_bar
    ;TOOD
    
    ; LDA #NAME_TABLE_0_ADDRESS_HIGH
    ; STA PPU_VRAM_ADDRESS2
    ; LDA #NAME_TABLE_0_ADDRESS_LOW
    ; STA PPU_VRAM_ADDRESS2

    ; LDA #HP_BAR_FILLED_LEFT
    ; STA PPU_VRAM_IO
    ; LDA #HP_BAR_FILLED_LEFT + 1
    ; STA PPU_VRAM_IO
    ; LDA #HP_BAR_LEFT+2
    ; STA PPU_VRAM_IO
    ; LDA #HP_BAR_LEFT+2
    ; STA PPU_VRAM_IO
    ; LDA #HP_BAR_LEFT+2
    ; STA PPU_VRAM_IO
    ; LDA #HP_BAR_LEFT+3
    ; STA PPU_VRAM_IO

    RTS
.endproc

.proc init_hp_bar
    ;TODO
    RTS
.endproc

.proc add_hp_bar_to_changed_tiles
      ; TODO
    RTS
.endproc

;display the score
.proc display_score
    LDA should_update_score
    BNE :+
        RTS
    :

    vram_set_address (NAME_TABLE_0_ADDRESS + 0 * 32 + 15)

    LDA score + 2
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    ADC #$40
    STA PPU_VRAM_IO
    TXA
    ADC #$40
    STA PPU_VRAM_IO

    LDA score + 1
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    ADC #$40
    STA PPU_VRAM_IO
    TXA
    ADC #$40
    STA PPU_VRAM_IO

    LDA score
    JSR dec99_to_bytes ; tens in X, ones in A

    CLC
    ADC #$40
    STA PPU_VRAM_IO
    TXA
    ADC #$40
    STA PPU_VRAM_IO

    LDA #0
    ADC #$40
    STA PPU_VRAM_IO
    STA PPU_VRAM_IO

    LDA #0
    STA should_update_score

    vram_clear_address

    RTS
.endproc
;*****************************************************************