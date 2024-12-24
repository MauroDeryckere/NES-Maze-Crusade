;****************************************************************
; Left Hand Rule Solving Algorithm
;****************************************************************
.proc left_hand_rule

    ; draw a different tile wherever the solver has walked - not necessary
    ; ;DRAW CELL
        ; LDA input_game_mode
        ; AND #HARD_MODE_MASK
        ; CMP #0
        ; BEQ :+
        ;     JMP _skip
        ; :
        ;     add_to_changed_tiles_buffer player_row, player_collumn, #2 
        ; _skip: 

    ;MAKE SURE LOCAL DIRECTION IS WITHIN RANGE 0-3
        LDA player_dir
        CMP #$FF        ; Check if A went below 0 (will become $FF due to underflow)
        BNE :+          ; If not $FF, skip wrapping
        LDA #$03        ; Wrap around to 3 if A is $FF
        STA player_dir
        : ;skip  wrap

        LDA player_dir
        CMP #4
        BNE :+
            LDA #0
            STA player_dir
        :

   
    ;DIRECTION SWITCH CASE
    LDA player_dir
    @TOP: 
        CMP #TOP_D      
        BEQ :+
            JMP @RIGHT
        :
        
        LDA player_row
        STA temp_row

        LDA player_collumn
        STA temp_col

        CMP #MAP_START_COL
        BNE :+
            JMP @front_wall_top
        :
        ; check left wall
        DEC temp_col

        get_map_tile_state temp_row, temp_col
        BEQ :+
            ; LDA #LEFT_D
            ; STA player_dir  
            DEC player_dir

            DEC player_collumn
            RTS
        :

        INC temp_col
        
        @front_wall_top: 
        LDA player_row
        CMP #MAP_START_ROW
        BNE :+
            INC player_dir
            RTS
        :

        ; check front wall
        DEC temp_row
        get_map_tile_state temp_row, temp_col
        BEQ :+
            DEC player_row
            RTS
        :
        INC player_dir
        RTS

    @RIGHT: 
        CMP #RIGHT_D      
        BEQ :+
            JMP @BOTTOM
        :

        LDA player_collumn
        STA temp_col
        
        LDA player_row
        STA temp_row

        CMP #MAP_START_ROW
        BNE :+
            JMP @front_wall_right
        :

        DEC temp_row

        ; check left wall
        get_map_tile_state temp_row, temp_col
        BEQ :+
            ; LDA #TOP_D
            ; STA player_dir
            DEC player_dir

            DEC player_row
            RTS
        :

        INC temp_row
        
        @front_wall_right: 
        LDA player_collumn
        CMP #31
        BNE :+
            INC player_dir
            RTS
        :

        ; check front wall
        INC temp_col
        get_map_tile_state temp_row, temp_col
        BEQ :+
            INC player_collumn
            RTS
        :
        INC player_dir
        RTS
    
    @BOTTOM: 
        CMP #BOTTOM_D 
        BEQ :+
            JMP @LEFT
        :
        
        LDA player_row
        STA temp_row

        LDA player_collumn
        STA temp_col

        CMP #31
        BNE :+
            JMP @front_wall_bottom
        :
        ; check left wall
        INC temp_col

        get_map_tile_state temp_row, temp_col
        BEQ :+
            ; LDA #RIGHT_D
            ; STA player_dir  
            DEC player_dir
            
            INC player_collumn
            RTS
        :

        DEC temp_col
        
        @front_wall_bottom: 
        LDA player_row
        CMP #MAP_END_ROW
        BNE :+
            INC player_dir
            RTS
        :

        ; check front wall
        INC temp_row
        get_map_tile_state temp_row, temp_col
        BEQ :+
            INC player_row
            RTS
        :
        INC player_dir
        RTS

    @LEFT: 
        CMP #LEFT_D      
        BEQ :+
            RTS
        :
        
        LDA player_row
        STA temp_row

        LDA player_collumn
        STA temp_col
        CMP #31
        BNE :+
            JMP @front_wall_left
        :

        INC temp_row

        ; check left wall
        get_map_tile_state temp_row, temp_col
        BEQ :+
            ; LDA #BOTTOM_D
            ; STA player_dir  
            DEC player_dir
            INC player_row
            RTS
        :

        DEC temp_row
        
        @front_wall_left: 
        LDA player_collumn
        CMP #MAP_START_COL
        BNE :+
            INC player_dir
            RTS
        :

        ; check front wall
        DEC temp_col
        get_map_tile_state temp_row, temp_col
        BEQ :+
            DEC player_collumn
            RTS
        :
        INC player_dir
        RTS
.endproc
