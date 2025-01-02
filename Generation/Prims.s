;*****************************************************************
; The main algorithm loop (prims)
;*****************************************************************
;subroutine to add a cell to the frontierlist after accessing the neighbor and checking if it is valid
.segment "CODE"
.proc add_cell
    STX x_val
    STY y_val
    
    add_to_Frontier y_val, x_val
    add_to_changed_tiles_buffer y_val, x_val, #FRONTIER_WALL_TILE

    RTS
.endproc  

.proc start_prims_maze
    ; step 0 of the maze generation, set a random cell as passage and calculate its frontier cells
    JSR random_number_generator

    ; ensure the row is always even so that there is a border at the bottom and top
    modulo random_seed, #27 ; 27 because we dont want row 0 and dont want row 28 (28 + 1 == 29 -> uneven + 1 == out of bounds (30))

    ; dont include row 0
    STA start_row
    INC start_row
    modulo start_row, #2
    
    CLC
    ADC start_row
    STA start_row

    ; col
    ; temporarily guarantee even col to ensure end border is always at left side.
    JSR random_number_generator
    modulo random_seed, #30 ; dont include 31 - out of bounds when increasing
    STA start_col
    modulo start_col, #2
    CMP #0
    BNE :+
        INC start_col
    :

    ;set the even col flag (new system always has an even row)
    LDA #0
    STA odd_frontiers

    LDA start_col
    CMP #0
    BEQ end_col_check ;when zero were even  

    modulo start_col, #2
    CMP #0
    BEQ end_col_check
        LDA #1
        STA odd_frontiers
    end_col_check:

    set_map_tile start_row, start_col

    add_to_changed_tiles_buffer start_row, start_col, #BROKEN_WALL_TILE

    LDA start_row
    JSR enqueue
    LDA start_col
    JSR enqueue

    access_map_frontier_neighbor #LEFT_D, start_row, start_col
    CMP #0 
    BNE TopN

    JSR add_cell

    TopN: ;top neighbor
        access_map_frontier_neighbor #TOP_D, start_row, start_col
        CMP #0 
        BNE RightN

        JSR add_cell

    RightN: ;right neighbor
        access_map_frontier_neighbor #RIGHT_D, start_row, start_col
        CMP #0 
        BNE BottomN

        JSR add_cell

    BottomN: ;bottom neighbor
        access_map_frontier_neighbor #BOTTOM_D, start_row, start_col
        CMP #0
        BNE End

        JSR add_cell
 
    End: ;end

   RTS
.endproc

.proc run_prims_maze
    LDA frontier_list_size ; if empty end algorithm
    BNE :+
        ;return with FF in A reg to show we are done with algorithm
        LDA #$FF
        RTS ;early return if finished
    :

    ;step one of the agorithm: pick a random frontier cell of the list
    get_random_frontier_tile ;returns col and row in x and y reg respectively offset is maintained in b val
    
    ;store row and col in zero page to use in the access function.
    STX frontier_col
    STY frontier_row

    ;store b val (offset) in a new value since b will be overwritten in the access map neighbor function
    LDA b_val
    PHA

    ;pick a random neighbor of the frontier cell that's in state passage
    ;start a counter for the amt of dirs we can use in temp val (since its not used in any of the macros we call during this section)
    LDA #0
    STA temp_frontier_col

    LDA #$FF
    ; directions buffer is not in use rn so okay to use for this purpose
    STA DIRECTIONS_ADDRESS + 100
    STA DIRECTIONS_ADDRESS + 101
    STA DIRECTIONS_ADDRESS + 102
    STA DIRECTIONS_ADDRESS + 103
    
    access_map_frontier_neighbor #TOP_D, frontier_row, frontier_col
    CMP #1
    ; we want something in state passage
    BNE :+
        LDA #TOP_D
        STA DIRECTIONS_ADDRESS + 100
    : ;right
    access_map_frontier_neighbor #RIGHT_D, frontier_row, frontier_col
    CMP #1
    ; we want something in state passage
    BNE :+
        LDA #RIGHT_D
        STA DIRECTIONS_ADDRESS + 101
    : ;bottom
    access_map_frontier_neighbor #BOTTOM_D, frontier_row, frontier_col
    CMP #1
    ; we want something in state passage
    BNE :+
        LDA #BOTTOM_D
        STA DIRECTIONS_ADDRESS + 102
    : ;left
    access_map_frontier_neighbor #LEFT_D, frontier_row, frontier_col
    CMP #1
    ; we want something in state passage
    BNE :+
        LDA #LEFT_D
        STA DIRECTIONS_ADDRESS + 103
    : ;end

    ;some pseudo randomisation
    LDA frame_counter
    AND #%00000001
    BEQ @skip_0

    LDY #103
    @dir_loop_0: 
        LDA DIRECTIONS_ADDRESS, y
        DEY
        CMP #$FF
        BEQ @dir_loop_0

    JMP @skip_1
    @skip_0: 

    LDY #100
    @dir_loop: 
        LDA DIRECTIONS_ADDRESS, y
        INY
        CMP #$FF
        BEQ @dir_loop

    @skip_1: 

    STA a_val

    ;calculate the cell between picked frontier and passage cell and set this to a passage 
    @pick_frontier: 
        LDA a_val ; used direction
        CMP #TOP_D
        BNE :+
            LDA frontier_row
            STA temp_frontier_row
            DEC temp_frontier_row

            LDA frontier_col
            STA temp_frontier_col
            JMP nextnextstep

        :; right
        CMP #RIGHT_D
        BNE :+
            LDA frontier_row
            STA temp_frontier_row

            LDA frontier_col
            STA temp_frontier_col
            INC temp_frontier_col
            JMP nextnextstep

        :; bottom
        CMP #BOTTOM_D
        BNE :+
            LDA frontier_row
            STA temp_frontier_row
            INC temp_frontier_row

            LDA frontier_col
            STA temp_frontier_col
            JMP nextnextstep

        : ;left
        CMP #LEFT_D
        BNE :+
            LDA frontier_row
            STA temp_frontier_row

            LDA frontier_col
            STA temp_frontier_col
            DEC temp_frontier_col
            JMP nextnextstep
        :
        ;wont reach this label in algorithm but useful for debugging 
    

    nextnextstep: 
        ; JSR random_number_generator
        ; modulo random_seed, #02
        ; CLC
        ; ADC #PATH_TILE_1
        ; STA temp

        set_map_tile temp_frontier_row, temp_frontier_col
        add_to_changed_tiles_buffer temp_frontier_row, temp_frontier_col, #BROKEN_WALL_TILE

        LDA temp_frontier_row
        JSR enqueue
        LDA temp_frontier_col
        JSR enqueue


    ;calculate the new frontier cells for the chosen frontier cell and add them
        access_map_frontier_neighbor #LEFT_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP TopN
        :

        ;if exists check
        STY temp_frontier_row        
        STX temp_frontier_col
        exists_in_Frontier temp_frontier_row, temp_frontier_col
        CPX #1
        BEQ TopN 

        LDY temp_frontier_row
        LDX temp_frontier_col

        JSR add_cell

    TopN: ;top neighbor
        access_map_frontier_neighbor #TOP_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP RightN
        :

        ;if exists check
        STY temp_frontier_row        
        STX temp_frontier_col
        exists_in_Frontier temp_frontier_row, temp_frontier_col
        CPX #1
        BEQ RightN 

        LDY temp_frontier_row
        LDX temp_frontier_col

        JSR add_cell

    RightN: ;right neighbor
        access_map_frontier_neighbor #RIGHT_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP BottomN
        :

        ;if exists check
        STY temp_frontier_row        
        STX temp_frontier_col
        exists_in_Frontier temp_frontier_row, temp_frontier_col
        CPX #1
        BEQ BottomN

        LDY temp_frontier_row
        LDX temp_frontier_col

        JSR add_cell

    BottomN: ;bottom neighbor
        access_map_frontier_neighbor #BOTTOM_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP end
        :

        ;if exists check
        STY temp_frontier_row        
        STX temp_frontier_col
        exists_in_Frontier temp_frontier_row, temp_frontier_col
        CPX #1
        BEQ end

        LDY temp_frontier_row
        LDX temp_frontier_col

        JSR add_cell
    end: 

    ;remove the chosen frontier cell from the list
    set_map_tile frontier_row, frontier_col
    
    JSR random_number_generator
    AND #%00000011 ; 0-3
    CLC
    ADC #PATH_TILE_1
    STA temp

    add_to_changed_tiles_buffer frontier_row, frontier_col, temp
    ;enqueue these to be updated as an "animation"
    ; LDA frontier_row
    ; JSR enqueue
    ; LDA frontier_col
    ; JSR enqueue

    PLA 
    STA temp
    remove_from_Frontier temp

    ;return with 0 in A reg to show we are not done with algorithm yet
    LDA #0

    RTS
.endproc

.proc calculate_prims_start_end
    ; very simple start and end for now, testing stuff
    @startl: 
        JSR random_number_generator
        AND #%00011111

        STA temp

        get_map_tile_state #MAP_START_ROW + 1, temp
        BEQ @startl

        set_map_tile #MAP_START_ROW, temp
        add_to_changed_tiles_buffer #MAP_START_ROW, temp, #PATH_TILE_1

        LDA temp
        STA player_collumn
        STA start_col
        LDA #MAP_START_ROW
        STA player_row
        STA start_row

    @endl: 
        JSR random_number_generator
        AND #%00001111

        STA temp

        get_map_tile_state temp, #MAP_START_COL + 1
        BEQ @endl

        set_map_tile temp, #MAP_START_COL
        add_to_changed_tiles_buffer temp, #MAP_START_COL, #PATH_TILE_END

        LDA temp
        STA end_row
        LDA #MAP_START_COL
        STA end_col

        INC temp
        add_to_changed_tiles_buffer temp, #MAP_START_COL, #FRONTIER_WALL_TILE
        DEC temp
        DEC temp
        add_to_changed_tiles_buffer temp, #MAP_START_COL, #FRONTIER_WALL_TILE
    RTS
.endproc
;*****************************************************************