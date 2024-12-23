;*****************************************************************
; Player
;*****************************************************************
;update player position with player input
.proc update_player_sprite
    ;check is delay is reached
    LDA player_movement_delay_ct
    BEQ :+
        DEC player_movement_delay_ct
        RTS
    :

    LDX #4
    STX frontier_offset

    GAMEPAD_DOWN:
    lda gamepad
    and #PAD_D
    beq NOT_GAMEPAD_DOWN 
        ;bounds check first
        LDA player_row
        CMP #MAP_ROWS - 1
        BNE :+
            JMP NOT_GAMEPAD_DOWN    
        :  

        LDA #BOTTOM
        STA player_dir 

        ;--------------------------------------------------------------
        ;COLLISION DETECTION
        ;--------------------------------------------------------------
        INC player_row
        
        LDA scroll_x
        LSR
        LSR
        LSR
        CLC
        ADC player_collumn
        STA temp

        get_map_tile_state player_row, temp ;figure out which row and colom is needed
        ; a register now holds if the sprite is in a non passable area (0) or passable area (non zero)


        BEQ HitDown
            ;otherwise keep now changed value
            ; JMP NOT_GAMEPAD_DOWN
            LDA #PLAYER_MOVEMENT_DELAY
            STA player_movement_delay_ct
            RTS
        HitDown: 
            ;sprite collided with wall
            DEC player_row

    NOT_GAMEPAD_DOWN: 
    lda gamepad
    and #PAD_U
    beq NOT_GAMEPAD_UP
        ;bounds check first
        LDA player_row
        CMP #1
        BNE :+
            JMP NOT_GAMEPAD_UP
        :   
        CMP #0
        BNE :+
            JMP NOT_GAMEPAD_UP
        :   

        LDA #TOP
        STA player_dir

        ;--------------------------------------------------------------
        ;COLLISION DETECTION
        ;--------------------------------------------------------------
        DEC player_row

        LDA scroll_x
        LSR
        LSR
        LSR
        CLC
        ADC player_collumn
        STA temp

        get_map_tile_state player_row, temp ;figure out which row and colom is needed
        ; a register now holds if the sprite is in a non passable area (0) or passable area (non zero)

        BEQ HitUp
            ;otherwise keep now changed value
           ; JMP NOT_GAMEPAD_UP
            LDA #PLAYER_MOVEMENT_DELAY
            STA player_movement_delay_ct
            RTS
        HitUp: 
            ;sprite collided with wall
            INC player_row

    NOT_GAMEPAD_UP: 
    lda gamepad
    and #PAD_L
    beq NOT_GAMEPAD_LEFT
        ;gamepad left is pressed

        ;bounds check first
        LDA player_collumn
        BNE :+
            JMP NOT_GAMEPAD_LEFT
        :

        LDA #LEFT
        STA player_dir

        ;--------------------------------------------------------------
        ;COLLISION DETECTION
        ;--------------------------------------------------------------
        DEC player_collumn

        LDA scroll_x
        LSR
        LSR
        LSR
        CLC
        ADC player_collumn
        STA temp

        get_map_tile_state player_row, temp ;figure out which row and colom is needed
        ; a register now holds if the sprite is in a non passable area (0) or passable area (non zero)

        BEQ HitLeft
            LDA #PLAYER_MOVEMENT_DELAY
            STA player_movement_delay_ct
            ;otherwise keep now changed value
            ;JMP NOT_GAMEPAD_LEFT
            LDA player_collumn
            CMP #8
            BCS :+
                LDA scroll_x
                BEQ :+
                    SEC
                    SBC #8
                    STA scroll_x
                    INC player_collumn
            :

        RTS

        HitLeft: 
            ;sprite collided with wall
            INC player_collumn

    NOT_GAMEPAD_LEFT:     
    lda gamepad
    and #PAD_R
    beq NOT_GAMEPAD_RIGHT
        ;bounds check first
        LDA player_collumn
        CMP #MAP_COLUMNS - 1
        BNE :+
            JMP NOT_GAMEPAD_RIGHT
        :

        LDA #RIGHT
        STA player_dir

        ;--------------------------------------------------------------
        ;COLLISION DETECTION
        ;--------------------------------------------------------------
        INC player_collumn
        
        LDA scroll_x
        LSR
        LSR
        LSR
        CLC
        ADC player_collumn
        STA temp

        get_map_tile_state player_row, temp ;figure out which row and colom is needed
        ; a register now holds if the sprite is in a non passable area (0) or passable area (non zero)

        BEQ HitRight
            ;otherwise keep now changed value
            ;JMP NOT_GAMEPAD_RIGHT
            LDA #PLAYER_MOVEMENT_DELAY
            STA player_movement_delay_ct

            LDA player_collumn
            CMP #24
            BCC :+
                LDA scroll_x
                CMP #248
                BEQ :+
                    CLC
                    ADC #8
                    STA scroll_x
                    DEC player_collumn
            :

            RTS 
        HitRight: 
            ;sprite collided with wall
            DEC player_collumn

    NOT_GAMEPAD_RIGHT: 
        ;neither up, down, left, or right is pressed
    RTS
.endproc
;*****************************************************************