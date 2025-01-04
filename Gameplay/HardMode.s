;*****************************************************************
; Hard mode related code
;*****************************************************************
.segment "CODE"
.proc start_hard_mode
    JSR random_number_generator
    AND #%00000011 ; 0-3
    CLC
    ADC #PATH_TILE_1
    STA temp
    add_to_changed_tiles_buffer player_row, player_collumn, temp

    ; In case we want the end to be visible for debugging purposes
    ; add_to_changed_tiles_buffer end_row, end_col, x_val

    JSR clear_visited_buffer

    RTS
.endproc

; whenever the character moves in hard mode we should add any invible tiles to the changed tiles buffer 
; to make them visible during the next vblank
.proc update_visibility
    ;apply current scroll settings to the col
    LDA scroll_x
    LSR
    LSR
    LSR
    CLC
    ADC player_collumn

    STA temp_frontier_col

    above:
        LDA player_row
        CMP #MAP_START_ROW
        BNE :+
            JMP below
        :

        STA frontier_row
        DEC frontier_row

        is_visited frontier_row, temp_frontier_col
        BEQ :+
            JMP below
        :

        set_visited frontier_row, temp_frontier_col

        get_map_tile_state frontier_row, temp_frontier_col
        BEQ a_wall
            JSR random_number_generator
            AND #%00000011 ; 0 - 3
            
            CLC
            ADC #PATH_TILE_1
            STA temp

            add_to_changed_tiles_buffer frontier_row, temp_frontier_col, temp
        JMP below
        a_wall: 
            add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #WALL_TILE
    below:
        LDA player_row
        CMP #MAP_END_ROW
        BNE :+
            JMP left
        :

        STA frontier_row
        INC frontier_row

        is_visited frontier_row, temp_frontier_col
        BEQ :+
            JMP left
        :

        set_visited frontier_row, temp_frontier_col

        get_map_tile_state frontier_row, temp_frontier_col
        BEQ b_wall
            JSR random_number_generator
            AND #%00000011 ; 0 - 3
            
            CLC
            ADC #PATH_TILE_1
            STA temp
            add_to_changed_tiles_buffer frontier_row, temp_frontier_col, temp
        JMP left
        b_wall: 
            add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #WALL_TILE
    
    left: 
        LDA temp_frontier_col
        CMP #MAP_START_COL
        BNE :+
           JMP right
        :

        STA frontier_col
        DEC frontier_col

        is_visited player_row, frontier_col
        BEQ :+
            JMP right
        :

        set_visited player_row, frontier_col


        get_map_tile_state player_row, frontier_col
        BEQ l_wall
            JSR random_number_generator
            AND #%00000011 ; 0 - 3
            
            CLC
            ADC #PATH_TILE_1
            STA temp
            add_to_changed_tiles_buffer player_row, frontier_col, temp
        JMP right
        l_wall: 
            add_to_changed_tiles_buffer player_row, frontier_col, #WALL_TILE

    right: 
        LDA temp_frontier_col
        CMP #MAP_END_COL
        BNE :+
            JMP end
        :

        STA frontier_col
        INC frontier_col

        is_visited player_row, frontier_col
        BEQ :+
            JMP end
        :

        set_visited player_row, frontier_col

        get_map_tile_state player_row, frontier_col
        BEQ r_wall
            JSR random_number_generator
            AND #%00000011 ; 0 - 3

            CLC
            ADC #PATH_TILE_1
            STA temp
            add_to_changed_tiles_buffer player_row, frontier_col, temp
        JMP end
        r_wall: 
            add_to_changed_tiles_buffer player_row, frontier_col, #WALL_TILE
    end: 

    RTS
.endproc
;*****************************************************************
