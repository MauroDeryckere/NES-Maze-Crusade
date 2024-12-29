.segment "CODE"
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
    LDA #SCORE_DIGIT_OFFSET
    STA low_byte
    
    LDA score_low

    CLC
    CMP #$0A
    BCC skip_modulo

    modulo score_low, #$0A  ;skip modulo if smaller than 10

    STA a_val               ;store remainder for later

    skip_modulo:

    LDX #OAM_SCORE_BYTE_START
    JSR draw_digit
    CLC
    LDA low_byte
    SEC
    SBC #8
    STA low_byte    

    LDA score_low
    SEC
    SBC a_val

    divide10 score_low

    LDX #OAM_SCORE_BYTE_START + 4
    JSR draw_digit
    CLC
    LDA low_byte
    SEC
    SBC #8
    STA low_byte
    
    LDA score_high

    CLC
    CMP #$0A
    BCC skip_modulo2

    modulo score_high, #$0A  ;skip modulo if smaller than 10

    STA a_val               ;store remainder for later

    skip_modulo2:

    LDX #OAM_SCORE_BYTE_START + 8
    JSR draw_digit
    CLC
    LDA low_byte
    SEC
    SBC #8
    STA low_byte    

    LDA score_high
    SEC
    SBC a_val

    divide10 score_high

    LDX #OAM_SCORE_BYTE_START + 12
    JSR draw_digit   
    RTS
.endproc

;draws the digit stored in a reg
.proc draw_digit
    ;convert digit 0-9 to correct tile index
    CLC
    ADC #64        ; get correct tile ID  
    TAY

    LDA #0 ;Y coordinate
    STA oam, X
    INX

    TYA
    STA oam, X
    INX 

    LDA #%00000001 ;flip bits to set certain sprite attributes
    STA oam, X
    INX


    LDA low_byte   ;X coordinate
    STA oam, X
    INX

    RTS
.endproc
;*****************************************************************