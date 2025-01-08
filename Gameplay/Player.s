;*****************************************************************
; Player
;*****************************************************************
;update player position with player input
.proc update_player_position
    ; PLAYER MOVEMENT
    @MOVEMENT: 
    ;check if delay is reached otherwise update delay
    LDA player_movement_delay_ct
    BEQ :+
        DEC player_movement_delay_ct
        JMP @NOT_MOVEMENT_INPUT 
    :

    @GAMEPAD_DOWN:
        LDA gamepad
        AND #PAD_D
        BEQ @GAMEPAD_UP 
            ; update the player direction
            LDA #BOTTOM_D
            STA player_dir 

            ;--------------------------------------------------------------
            ;COLLISION DETECTION
            ;--------------------------------------------------------------
            ;bounds check first
            LDA player_row
            CMP #MAP_END_ROW
            BEQ @GAMEPAD_UP    

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

            BEQ @HitDown
                ; otherwise keep now changed value
                ; reset cooldown
                LDA #PLAYER_MOVEMENT_DELAY
                STA player_movement_delay_ct
                JMP @NOT_MOVEMENT_INPUT 

            @HitDown: ; sprite collided with wall
                DEC player_row

    @GAMEPAD_UP: 
        LDA gamepad
        AND #PAD_U
        BNE :+
            JMP @GAMEPAD_LEFT
        :
            ; change player direction
            LDA #TOP_D
            STA player_dir

            ;--------------------------------------------------------------
            ;COLLISION DETECTION
            ;--------------------------------------------------------------
            ; bounds check first
            LDA player_row
            CMP #MAP_START_ROW
            BEQ @GAMEPAD_LEFT 

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

            BEQ @HitUp
                ;otherwise keep now changed value
                ; Reset cooldown
                LDA #PLAYER_MOVEMENT_DELAY
                STA player_movement_delay_ct
                JMP @NOT_MOVEMENT_INPUT 

            @HitUp: ; sprite collided with wall
                INC player_row

    @GAMEPAD_LEFT: 
        LDA gamepad
        AND #PAD_L
        BEQ @GAMEPAD_RIGHT
            ; change player direction
            LDA #LEFT_D
            STA player_dir

            ;--------------------------------------------------------------
            ;COLLISION DETECTION
            ;--------------------------------------------------------------
            ; bounds check first
            LDA player_collumn
            CMP #MAP_START_COL
            BEQ  @GAMEPAD_RIGHT

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

            BEQ @HitLeft
                ; otherwise keep now changed value
                ; reset cooldown
                LDA #PLAYER_MOVEMENT_DELAY
                STA player_movement_delay_ct

                LDA player_collumn
                CMP #CAMERA_START_SCROLL_LEFT
                BCS :+
                    LDA scroll_x
                    BEQ :+
                        SEC
                        SBC #8
                        STA scroll_x
                        INC player_collumn
                :
            JMP @NOT_MOVEMENT_INPUT 
        
            @HitLeft: ; sprite collided with wall
                INC player_collumn

    @GAMEPAD_RIGHT:     
        LDA gamepad
        AND #PAD_R
        BEQ @NOT_MOVEMENT_INPUT
            ; change player direction
            LDA #RIGHT_D
            STA player_dir

            ;--------------------------------------------------------------
            ;COLLISION DETECTION
            ;--------------------------------------------------------------
            ; bounds check first
            LDA player_collumn
            CMP #MAP_END_COL
            BEQ @NOT_MOVEMENT_INPUT

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

            BEQ @HitRight
                ; otherwise keep now changed value
                ; reset cooldown
                LDA #PLAYER_MOVEMENT_DELAY
                STA player_movement_delay_ct

                LDA player_collumn
                CMP #CAMERA_START_SCROLL_RIGHT 
                BCC :+
                    LDA scroll_x
                    CMP #248
                    BEQ :+
                        CLC
                        ADC #8
                        STA scroll_x
                        DEC player_collumn
                :

                JMP @NOT_MOVEMENT_INPUT 
            @HitRight: ; sprite collided with wall
                DEC player_collumn

    @NOT_MOVEMENT_INPUT: 
        ; PLAYER INTERACT
        @GAMEPAD_A: 
            LDA gamepad
            AND #PAD_A
            BNE :+
                JMP @RETURN
            :
        ;        LDA player_collumn
        

                LDA player_dir
                CMP #TOP_D
                BEQ :+
                    JMP @not_top_d
                :
                    ; LDA player_row
                    ; STA temp_row
                    ; CMP #MAP_START_ROW
                    ; BNE :+
                    ;     JMP @RETURN
                    ; :

                    ; DEC temp_row
                    ; get_map_tile_state temp_row, #MAP_END_COL + 1
                    ; BNE :+
                    ;     JMP @RETURN
                    ; :

                    ; get_map_tile_state #MAP_START_ROW - 1, player_collumn
                    ; BNE :+
                    ;     JMP @RETURN
                    ; :

                    ; LDA #5
                    ; JSR add_score

                @not_top_d: 

                CMP #RIGHT_D
                BNE :+
                :
                CMP #BOTTOM_D
                BNE :+
                :
                CMP #LEFT_D

            
    @RETURN: 
    RTS
.endproc
;*****************************************************************