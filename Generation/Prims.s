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
    LDA frontier_listQ1_size ; if empty end algorithm
    BNE :+
        ;return with FF in A reg to show we are done with algorithm
        LDA #$FF
        RTS ;early return if finished
    :

    ;useful for debugging but not necessary for algorithm    
    ; LDA #%11111111
    ; STA used_direction

    ;step one of the agorithm: pick a random frontier cell of the list
    get_random_frontier_tile ;returns col and row in x and y reg respectively | page and offset are maintained in a and b val
    
    ;store row and col in zero page to use in the access function.
    STX frontier_col
    STY frontier_row

    ;store b val in a new value since b will be overwritten in the access map neighbor function
    LDA b_val
    STA frontier_offset


    ;pick a random neighbor of the frontier cell that's in state passage
    ;start a counter for the amt of dirs we can use on temp val (since its not used in any of the macros we call during this section)
    LDA #0
    STA temp

    access_map_frontier_neighbor #TOP_D, frontier_row, frontier_col
    CMP #1 ;we want something in state passage
    BNE :+
        ;valid cell, Jump to next step
        LDA #TOP_D
        PHA ;push direction on stack
        INC temp
    : ;right
    access_map_frontier_neighbor #RIGHT_D, frontier_row, frontier_col
    CMP #1 ;we want something in state passage
    BNE :+
        ;valid cell, Jump to next step
        LDA #RIGHT_D
        PHA ;push direction on stack
        INC temp

    : ;bottom
    access_map_frontier_neighbor #BOTTOM_D, frontier_row, frontier_col
    CMP #1 ;we want something in state passage
    BNE :+
        ;valid cell, Jump to next step
        LDA #BOTTOM_D
        PHA ;push direction on stack
        INC temp        
    : ;left
    access_map_frontier_neighbor #LEFT_D, frontier_row, frontier_col
    CMP #1 ;we want something in state passage
    BNE :+
        ;valid cell, Jump to next step
        LDA #LEFT_D
        PHA ;push direction on stack
        INC temp
    
    ;pick a random direction based on the temp counter
    :
    JSR random_number_generator
    modulo random_seed, temp ;stores val in A reg
    
    ;the total amt of pulls from stack is stored in X    
    LDX temp
    ;the direction idx we want to use is stored in A
    STA temp
    dirloop: 
        PLA
        
        DEX 

        CPX temp
        BNE :+
            STA used_direction
        :

        CPX #0
        BNE dirloop

    ;calculate the cell between picked frontier and passage cell and set this to a passage 
    nextstep: 
    LDA used_direction
    CMP #TOP_D
    BNE :+
        LDA frontier_row
        STA temp_row
        DEC temp_row

        LDA frontier_col
        STA temp_col
        JMP nextnextstep

    :; right
    CMP #RIGHT_D
    BNE :+
        LDA frontier_row
        STA temp_row

        LDA frontier_col
        STA temp_col
        INC temp_col
        JMP nextnextstep

    :; bottom
    CMP #BOTTOM_D
    BNE :+
        LDA frontier_row
        STA temp_row
        INC temp_row

        LDA frontier_col
        STA temp_col
        JMP nextnextstep

    : ;left
    CMP #LEFT_D
    BNE :+
        LDA frontier_row
        STA temp_row

        LDA frontier_col
        STA temp_col
        DEC temp_col
        JMP nextnextstep
    :
    ;wont reach this label in algorithm but useful for debugging 
    

    nextnextstep: 
        ; JSR random_number_generator
        ; modulo random_seed, #02
        ; CLC
        ; ADC #PATH_TILE_1
        ; STA temp

        set_map_tile temp_row, temp_col
        add_to_changed_tiles_buffer temp_row, temp_col, #BROKEN_WALL_TILE

        LDA temp_row
        JSR enqueue
        LDA temp_col
        JSR enqueue


    ;calculate the new frontier cells for the chosen frontier cell and add them
        access_map_frontier_neighbor #LEFT_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP TopN
        :

        ;if exists check
        STY temp_row        
        STX temp_col
        exists_in_Frontier temp_row, temp_col
        CPX #1
        BEQ TopN 

        LDY temp_row
        LDX temp_col

        JSR add_cell

    TopN: ;top neighbor
        access_map_frontier_neighbor #TOP_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP RightN
        :

        ;if exists check
        STY temp_row        
        STX temp_col
        exists_in_Frontier temp_row, temp_col
        CPX #1
        BEQ RightN 

        LDY temp_row
        LDX temp_col

        JSR add_cell

    RightN: ;right neighbor
        access_map_frontier_neighbor #RIGHT_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP BottomN
        :

        ;if exists check
        STY temp_row        
        STX temp_col
        exists_in_Frontier temp_row, temp_col
        CPX #1
        BEQ BottomN

        LDY temp_row
        LDX temp_col

        JSR add_cell

    BottomN: ;bottom neighbor
        access_map_frontier_neighbor #BOTTOM_D, frontier_row, frontier_col
        CMP #0 
        BEQ :+
            JMP end
        :

        ;if exists check
        STY temp_row        
        STX temp_col
        exists_in_Frontier temp_row, temp_col
        CPX #1
        BEQ end

        LDY temp_row
        LDX temp_col

        JSR add_cell
    end: 

    ;remove the chosen frontier cell from the list
    set_map_tile frontier_row, frontier_col
    JSR random_number_generator
    modulo random_seed, #02
    CLC
    ADC #PATH_TILE_1
    STA temp

    add_to_changed_tiles_buffer frontier_row, frontier_col, temp

    ;enqueue these to be updated as an "animation"
    ; LDA frontier_row
    ; JSR enqueue
    ; LDA frontier_col
    ; JSR enqueue

    remove_from_Frontier frontier_offset

    ;return with 0 in A reg to show we are not done with algorithm yet
    LDA #0

    RTS
.endproc

.proc calculate_prims_start_end
; START POSITION
    ; chosen side for start stored in temp_row
    ; 0: col
    ; 1: top row
    ; 2: bottom row

    ; randomly pick between top and bottom row and the col (depending on even / unven frontier start col)
    JSR random_number_generator
    AND #%00000001
    BEQ :++
        ; if even we'll pick from the 2 rows
        JSR random_number_generator
        AND #%00000001
        BEQ :+
            LDA #2
            STA temp_row
            JMP rowloop_bottom
        :
        LDA #1 
        STA temp_row
        JMP rowloop_top
    :
    ; pick a column start pos if uneven
    LDA #0
    STA temp_row

    LDA odd_frontiers
    ;are cols odd
    BNE :+
        JMP colloop_e_start
    :

    colloop_ue_start:
        JSR random_number_generator
        modulo random_seed, #28
        STA temp
        INC temp ;exclude row 0

        get_map_tile_state temp, #2 
        BEQ colloop_ue_start

        set_map_tile temp, #0
        add_to_changed_tiles_buffer temp, #0, #PATH_TILE_1
        
        LDA #0
        STA player_collumn
        STA start_col
        LDA temp
        STA player_row
        STA start_row

        JMP END_STARTPOS

    colloop_e_start:
        JSR random_number_generator
        modulo random_seed, #28
        STA temp
        INC temp ;exclude row 0

        get_map_tile_state temp, #30
        BEQ colloop_e_start

        set_map_tile temp, #31
        add_to_changed_tiles_buffer temp, #31, #PATH_TILE_1

        LDA #31
        STA player_collumn
        STA start_col
        LDA temp
        STA start_row
        STA player_row

        JMP END_STARTPOS

    ;uneven row means empty border at top
    ;randomly generate a start tile until we find a valid one in row 2 (valid means a walkable tile below)
    rowloop_top:
        JSR random_number_generator
        modulo random_seed, #29
        STA temp
        INC temp

        get_map_tile_state #2, temp
        BEQ rowloop_top

        set_map_tile #1, temp
        add_to_changed_tiles_buffer #1, temp, #PATH_TILE_1
        LDA #1
        STA player_row
        STA start_col
        LDA temp
        STA start_row
        STA player_collumn

        JMP END_STARTPOS

    ;use border at bottom 
    ;randomly generate a start tile until we find a valid one in row 28 (valid means a walkable tile above)
    rowloop_bottom:
        JSR random_number_generator
        modulo random_seed, #29
        STA temp
        INC temp

        get_map_tile_state #28, temp
        BEQ rowloop_bottom

        set_map_tile #29, temp
        add_to_changed_tiles_buffer #29, temp, #PATH_TILE_1

        LDA #29
        STA player_row
        STA start_col
        LDA temp
        STA start_row
        STA player_collumn
    END_STARTPOS:

; END POSITION
    ; depending on the chosen start pos (top or bottom)    
    LDA temp_row
    CMP #0
    BNE :+
        JMP skip_col_option
    : 

    ; pick between remaining row and col generation
    JSR random_number_generator
    AND #%00000001
    BEQ :++
        ; 1 means row generation, pick the correct one
        skip_col_option: 
        LDA temp_row
        CMP #1
        BEQ :+
            JMP top_row_end 
        :
        JMP bottom_row_end
    :

    ; 0 == col generation
    col_check: 
        LDA odd_frontiers
        ;are cols odd
        BNE :+
            JMP colloop_e
        :

    colloop_ue:
        JSR random_number_generator
        modulo random_seed, #28
        STA temp
        INC temp ;exclude row 0

        get_map_tile_state temp, #1 
        BEQ colloop_ue

        set_map_tile temp, #0
        add_to_changed_tiles_buffer temp, #0, #PATH_TILE_END_R
        
        LDA temp
        STA end_row

        TAX
        INX
        STX temp
        add_to_changed_tiles_buffer temp, #0, #FRONTIER_WALL_TILE

        LDX end_row
        DEX
        STX temp
        add_to_changed_tiles_buffer temp, #0, #FRONTIER_WALL_TILE

        LDA #0
        STA end_col

        JMP end

    colloop_e:
        JSR random_number_generator
        modulo random_seed, #28
        STA temp
        INC temp ;exclude row 0

        get_map_tile_state temp, #30
        BEQ colloop_e

        set_map_tile temp, #31
        add_to_changed_tiles_buffer temp, #31, #PATH_TILE_END_L

        LDA temp
        STA end_row

        TAX
        INX
        STX temp
        add_to_changed_tiles_buffer temp, #31, #FRONTIER_WALL_TILE

        LDX end_row
        DEX
        STX temp
        add_to_changed_tiles_buffer temp, #31, #FRONTIER_WALL_TILE

        LDA #31
        STA end_col
        
        JMP end

    top_row_end: 
        rowloop_top_end:
            JSR random_number_generator
            modulo random_seed, #29
            STA temp
            INC temp

            get_map_tile_state #2, temp
            BEQ rowloop_top_end

            set_map_tile #1, temp
            add_to_changed_tiles_buffer #1, temp, #PATH_TILE_END_R
            LDA #1
            STA end_row
            LDA temp
            STA end_col

            TAX
            INX
            STX temp
            add_to_changed_tiles_buffer #1, temp, #FRONTIER_WALL_TILE

            LDX end_col
            DEX
            STX temp
            add_to_changed_tiles_buffer #1, temp, #FRONTIER_WALL_TILE

            JMP end

    bottom_row_end: 
        rowloop_bottom_end:
            JSR random_number_generator
            modulo random_seed, #29
            STA temp
            INC temp

            get_map_tile_state #28, temp
            BEQ rowloop_bottom_end

            set_map_tile #29, temp
            add_to_changed_tiles_buffer #29, temp, #PATH_TILE_END_L
            LDA #29
            STA end_row
            LDA temp
            STA end_col

            TAX
            INX
            STX temp
            add_to_changed_tiles_buffer #29, temp, #FRONTIER_WALL_TILE

            LDX end_col
            DEX
            STX temp
            add_to_changed_tiles_buffer #29, temp, #FRONTIER_WALL_TILE


    end: 
    RTS
.endproc
;*****************************************************************