;*****************************************************************
; Hard mode related code
;*****************************************************************
.segment "CODE"
.proc start_hard_mode
    ; "Fog of War effect"
    JSR display_clear_map
    JSR clear_visited_buffer

    JSR ppu_off    
    ; Torches
    JSR update_torch_visibility

    JSR draw_background
    JSR clear_changed_tiles_buffer

    JSR ppu_update

    JSR random_number_generator
    AND #%00000011 ; 0-3
    CLC
    ADC #PATH_TILE_1
    STA temp
    add_to_changed_tiles_buffer player_row, player_collumn, temp

    JSR update_visibility

    ; In case we want the end to be visible for debugging purposes
    ; add_to_changed_tiles_buffer end_row, end_col, x_val

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
            LDA frontier_row
            CMP #MAP_END_ROW
            BEQ @skip_a
            STA temp
            INC temp

            get_map_tile_state temp, temp_frontier_col
            BEQ @full_a

            @skip_a: 
                add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #SIDE_WALL_HALF_TILE
                JMP below

            @full_a: 
                add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #SIDE_WALL_FULL_TILE
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
            LDA frontier_row
            CMP #MAP_END_ROW
            BEQ @skip_b
            STA temp
            INC temp

            get_map_tile_state temp, temp_frontier_col
            BEQ @full_b

            @skip_b: 
                add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #SIDE_WALL_HALF_TILE
                JMP left

            @full_b: 
                add_to_changed_tiles_buffer frontier_row, temp_frontier_col, #SIDE_WALL_FULL_TILE
    
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
            LDA player_row
            CMP #MAP_END_ROW
            BEQ @skip_l
            STA temp
            INC temp

            get_map_tile_state temp, frontier_col
            BEQ @full_l

            @skip_l: 
                add_to_changed_tiles_buffer player_row, frontier_col, #SIDE_WALL_HALF_TILE
                JMP right

            @full_l: 
                add_to_changed_tiles_buffer player_row, frontier_col, #SIDE_WALL_FULL_TILE


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
            LDA player_row
            CMP #MAP_END_ROW
            BEQ @skip_r
            STA temp
            INC temp

            get_map_tile_state temp, frontier_col
            BEQ @full_r

            @skip_r: 
                add_to_changed_tiles_buffer player_row, frontier_col, #SIDE_WALL_HALF_TILE
                JMP end

            @full_r: 
                add_to_changed_tiles_buffer player_row, frontier_col, #SIDE_WALL_FULL_TILE

    end: 

    RTS
.endproc
;*****************************************************************
