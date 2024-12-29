; populate oam buffer with player sprite
.segment "CODE"
.proc draw_player_sprite
    ;SPRITE 0 - player
    LDX #OAM_PLAYER_BYTE_START

    LDA player_row ;Y coordinate
    ASL
    ASL
    ASL
    STA oam, X
    INX

    LDA #$D0   ;tile pattern index
    CLC
    ADC player_dir

    STA oam, X
    INX 
 
    LDA #%00000000 ;flip bits to set certain sprite attributes
    STA oam, X
    INX

    
    LDA player_collumn   ;X coordinate
    ASL
    ASL
    ASL
    TAY

    ; 4 pixel offset in titlescreen
    LDA current_game_mode
    CMP #0
    BNE :+
        TYA
        SEC
        SBC #4
        CLC
        TAY
    :

    TYA
    STA oam, X
    INX
    RTS

.endproc

;simply hides the sprite off screen
.proc hide_player_sprite
    LDX #OAM_PLAYER_BYTE_START
    LDA #$FE       ; Y-coordinate off-screen
    STA oam, X      ; Write to OAM  
    RTS
.endproc