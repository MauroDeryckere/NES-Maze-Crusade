.segment "CODE"
.proc update_oam
    ; reset the oam byte counter
    LDX #OAM_PLAYER_BYTE_END
    STX curr_oam_byte 

    LDA current_game_mode
    CMP #GAMEMODE_GENERATING
    BEQ :+
        JSR draw_player_sprite
        JMP :++
    :
        JSR hide_player_sprite
    :
    
    JSR clear_oam

    LDA current_game_mode
    CMP #GAMEMODE_PLAYING
    BNE @skip_draw_calls
        JSR draw_torches
        JSR draw_chests
    @skip_draw_calls: 

    RTS
.endproc

.segment "CODE"
; "clears" everything past cur_oam_byte 
.proc clear_oam
    LDA #255
    LDX curr_oam_byte
    @clear_oam:
        STA oam, X
        INX
        INX
        INX
        INX
        BNE @clear_oam
    RTS
.endproc

.segment "CODE"
.proc draw_torches
    LDA num_torches
    BNE @torch_loop
    RTS

    ; just a single torch currently 
    ; Torches / lamps
    @torch_loop:
        LDX curr_oam_byte
        ; calculate x pos first to know if this torch is off screen
        LDA #8
        SEC
        SBC scroll_x 
        TAY
        BCC @off_screen
        JMP @on_screen

        ; Hide sprite when torch is off screen
        @off_screen: 
            RTS
        @on_screen: 

        ;Y coordinate
        LDA #63 
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

        @end: 
            ; adjust curr oam byte
            LDA num_torches
            ASL
            ASL
            CLC
            ADC curr_oam_byte
            STA curr_oam_byte
            RTS
.endproc

.segment "CODE"
.proc draw_chests
    LDA num_chests
    BNE @chest_loop
    RTS

    ; just a single torch currently 
    ; Torches / lamps
    @chest_loop:
        LDX curr_oam_byte
        ; calculate x pos first to know if this torch is off screen
        LDA #8
        SEC
        SBC scroll_x 
        TAY
        BCC @off_screen
        JMP @on_screen

        ; Hide sprite when torch is off screen
        @off_screen: 
            RTS
        @on_screen: 

        ;Y coordinate
        LDA #55
        STA oam, X
        INX

        ;Tile pattern index
        LDA #CHEST_TILE
        STA oam, X
        INX

        ;Sprite attributes
        LDA #%00000010
        STA oam, X
        INX

        ;X coordinate
        TYA
        STA oam, X
        INX

        @end: 
            ; adjust curr oam byte
            LDA num_torches
            ASL
            ASL
            CLC
            ADC curr_oam_byte
            STA curr_oam_byte
            RTS
.endproc