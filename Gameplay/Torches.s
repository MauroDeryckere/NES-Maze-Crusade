.segment "CODE"
.proc init_torches
    LDA #1
    STA num_torches

    ; will be randomly generated later
    ; torch tile
    LDY #8 ; row (map)
    LDX #1 ; col (map)
    STY temp_row
    STX temp_col

    JSR update_torch_visibility
    JSR draw_background
    JSR clear_changed_tiles_buffer

    ; repeat for other torches

    

    RTS
.endproc

.segment "CODE"
.proc update_torch_visibility
    ; example
    ; RANGE == 3
    ; 0 0 0 A 0 0 0
    ; 0 0 A A A 0 0
    ; 0 L L A R R 0
    ; L L L T R R R
    ; 0 L L B R R 0
    ; 0 0 B B B 0 0
    ; 0 0 0 B 0 0 0

    ; example
    ; RANGE == 4
    ; 0 0 0 0 0 A 0 0 0 0 0
    ; 0 0 0 0 A A A 0 0 0 0
    ; 0 0 0 ? A A A ? 0 0 0
    ; 0 0 ? ? A A A ? ? 0 0
    ; 0 L L L L A R R R R 0
    ; L L L L L T R R R R R
    ; 0 L L L L B R R R R 0
    ; 0 0 ? ? B B B ? ? 0 0
    ; 0 0 0 ? B B B ? 0 0 0
    ; 0 0 0 0 B B B 0 0 0 0
    ; 0 0 0 0 0 B 0 0 0 0 0

    JSR update_visibility_torch_dir

    LDA temp_row
    STA temp_frontier_row ; temp value to fall back on, frontier not in use currently

    LDA temp_col
    STA temp_frontier_col ; temp value to fall back on, frontier not in use currently

    @tiles_below: 
        INC temp_row
        JSR update_visibility_torch_dir
        BEQ @tiles_above

        ; not a wall so check the left / right tiles below
        INC temp_col
        JSR update_visibility_torch_dir
        BEQ :+
            LDA temp_col
            CMP #MAP_END_COL
            BEQ :+

            INC temp_col
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_col
        STA temp_col

        DEC temp_col
        JSR update_visibility_torch_dir
        BEQ :+
            ; bounds check
            LDA temp_col
            CMP #MAP_START_COL
            BEQ :+

            DEC temp_col
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_col
        STA temp_col

        ; in case we go out of bounds
        LDA temp_row
        CMP #MAP_END_ROW
        BEQ @tiles_above

        INC temp_row
        JSR update_visibility_torch_dir
        BEQ @tiles_above

        ; not a wall so check the left / right tile below
        INC temp_col
        JSR update_visibility_torch_dir
        DEC temp_col
        DEC temp_col
        JSR update_visibility_torch_dir
        INC temp_col

        ; in case we go out of bounds
        LDA temp_row
        CMP #MAP_END_ROW
        BEQ @tiles_above

        INC temp_row
        JSR update_visibility_torch_dir

    @tiles_above: 
        ;restore row and col
        LDA temp_frontier_col
        STA temp_col
        LDA temp_frontier_row
        STA temp_row

        DEC temp_row

        JSR update_visibility_torch_dir
        BEQ @tiles_left

        ; not a wall so check the left / right tiles above
        INC temp_col
        JSR update_visibility_torch_dir
        BEQ :+
            LDA temp_col
            CMP #MAP_END_COL
            BEQ :+

            INC temp_col
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_col
        STA temp_col

        DEC temp_col
        JSR update_visibility_torch_dir
        BEQ :+
            ; bounds check
            LDA temp_col
            CMP #MAP_START_COL
            BEQ :+

            DEC temp_col
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_col
        STA temp_col

        ; in case we go out of bounds
        LDA temp_row
        CMP #MAP_START_ROW
        BEQ @tiles_left

        DEC temp_row
        JSR update_visibility_torch_dir
        BEQ @tiles_left
        ; not a wall so check the left / right tile above
        INC temp_col
        JSR update_visibility_torch_dir
        DEC temp_col
        DEC temp_col
        JSR update_visibility_torch_dir
        INC temp_col

        ; in case we go out of bounds
        LDA temp_row
        CMP #MAP_START_ROW
        BEQ @tiles_left

        DEC temp_row

        JSR update_visibility_torch_dir

    @tiles_left: 
        ;restore row and col
        LDA temp_frontier_col
        STA temp_col
        LDA temp_frontier_row
        STA temp_row

        DEC temp_col
        JSR update_visibility_torch_dir
        BEQ @tiles_right
       
        ; not a wall so check the top / bottom tiles to the left
        INC temp_row
        JSR update_visibility_torch_dir
        BEQ :+
            LDA temp_row
            CMP #MAP_END_ROW
            BEQ :+

            INC temp_row
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_row
        STA temp_row

        DEC temp_row
        JSR update_visibility_torch_dir
        BEQ :+
            ; bounds check
            LDA temp_row
            CMP #MAP_START_ROW
            BEQ :+

            DEC temp_row
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_row
        STA temp_row

        ; in case we go out of bounds
        LDA temp_col
        CMP #MAP_START_COL
        BEQ @tiles_right

        DEC temp_col
        JSR update_visibility_torch_dir
        BEQ @tiles_right
        ; not a wall so check the top / bottom tile to the left
        INC temp_row
        JSR update_visibility_torch_dir
        DEC temp_row
        DEC temp_row
        JSR update_visibility_torch_dir
        INC temp_row

        ; in case we go out of bounds
        LDA temp_col
        CMP #MAP_START_COL
        BEQ @tiles_right

        DEC temp_col
        JSR update_visibility_torch_dir

    @tiles_right: 
        ;restore row and col
        LDA temp_frontier_col
        STA temp_col
        LDA temp_frontier_row
        STA temp_row

        INC temp_col
        JSR update_visibility_torch_dir
        BEQ @return
       
        ; not a wall so check the top / bottom tiles to the right
        INC temp_row
        JSR update_visibility_torch_dir
        BEQ :+
            LDA temp_row
            CMP #MAP_END_ROW
            BEQ :+

            INC temp_row
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_row
        STA temp_row

        DEC temp_row
        JSR update_visibility_torch_dir
        BEQ :+
            ; bounds check
            LDA temp_row
            CMP #MAP_START_ROW
            BEQ :+

            DEC temp_row
            JSR update_visibility_torch_dir
        :

        LDA temp_frontier_row
        STA temp_row

        ; in case we go out of bounds
        LDA temp_col
        CMP #MAP_END_COL
        BEQ @return

        INC temp_col
        JSR update_visibility_torch_dir
        BEQ @return
        ; not a wall so check the top / bottom tile to the right
        INC temp_row
        JSR update_visibility_torch_dir
        DEC temp_row
        DEC temp_row
        JSR update_visibility_torch_dir
        INC temp_row

        ; in case we go out of bounds
        LDA temp_col
        CMP #MAP_END_COL
        BEQ @return

        INC temp_col
        JSR update_visibility_torch_dir

    @return: 
        RTS
.endproc

.segment "CODE"
; loads 0 in a if wall, if path $FF
.proc update_visibility_torch_dir
    set_visited temp_row, temp_col
    get_map_tile_state temp_row, temp_col

    BEQ @skip
    ; todo randmise which path tile we use
    add_to_changed_tiles_buffer temp_row, temp_col, #PATH_TILE_1
    LDA #$FF
    JMP @return
    @skip: 
        LDA temp_row
        STA temp
        CMP #MAP_END_ROW
        BEQ @skip_half
        INC temp

        get_map_tile_state temp, temp_col
        BEQ @skip_half
        add_to_changed_tiles_buffer temp_row, temp_col, #SIDE_WALL_HALF_TILE
        LDA #0
        JMP @return

        @skip_half:
        add_to_changed_tiles_buffer temp_row, temp_col, #SIDE_WALL_FULL_TILE
        LDA #0
        JMP @return


    @return:

    RTS
.endproc