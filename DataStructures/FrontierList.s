;*****************************************************************
; Frontier list macros
;*****************************************************************
; offset 0-127
;loads the row in the X register, col in the Y register
.macro access_Frontier offset
    ; Calculate the address of the item in the list
    LDA offset
    ASL

    TAX

    ;row
    LDA FRONTIER_LISTQ1, X
    TAY
    INX

    ;col
    LDA FRONTIER_LISTQ1, X
    TAX

.endmacro

;returns whether or not the row and col pair exist in the frontier list in the X register (1 found, 0 not found)
.macro exists_in_Frontier Row, Col
    LDX #0
    STX temp

    .local loop_p0
    loop_p0:        
        LDX temp
        CPX frontier_listQ1_size
        BNE :+
            LDX #0
            STX temp
            JMP return_not_found
        :
        
        access_Frontier temp
        INC temp
        
        CPY Row
        BEQ :+
            JMP loop_p0
        :
        CPX Col
        BEQ :+
            JMP loop_p0
        :

        JMP return_found

    .local return_not_found
    return_not_found:
        LDX #0
        JMP n

    .local return_found
    return_found:
        LDX #1
        JMP n

    .local n
    n: 
.endmacro

; offset 0-127
; basically uses the "swap and pop" technique of a vector in C++
.macro remove_from_Frontier offset
    ; Calculate the address of the last item in the list
    LDA frontier_listQ1_size

    TAX
    DEX ;decrease size by 1 before multiplying (otherwise we will go out of bounds since size 1 == index 0 )
    TXA

    ASL
    TAX ;calculated address offset for last item in X

    LDA FRONTIER_LISTQ1, X ; store last items in temp values
    STA a_val

    INX
    LDA FRONTIER_LISTQ1, X ; store last items in temp values
    STA b_val

    ; Calculate the address to be removed
    LDA offset
    ASL
    TAX

    LDA a_val
    STA FRONTIER_LISTQ1, X
    INX 
    LDA b_val
    STA FRONTIER_LISTQ1, X


    ; in case you want to replace the garbage at end with FF for debugging (clear values)
    LDA frontier_listQ1_size

    TAX
    DEX ;decrease size by 1 before multiplying (otherwise we will go out of bounds since size 1 == index 0 )
    TXA

    ASL
    TAX ;calculated address offset for last item in X

    LDA #$FF
    STA FRONTIER_LISTQ1, X 
    INX
    LDA #$FF
    STA FRONTIER_LISTQ1, X
    ; ------------------------------------------------------------------------------------


    DEC frontier_listQ1_size
.endmacro

;Defintion of row and col can be found in the map buffer section.
.macro add_to_Frontier Row, Col
    ;multiply current size of Q1 by 2, 2 bytes required per element in list
    LDA frontier_listQ1_size
    ASL

    CMP #%11111110      ;check if it should be added to Q1 or not
    BEQ :+
        
        TAX
        LDA Row
        STA FRONTIER_LISTQ1, X
        INX
        LDA Col
        STA FRONTIER_LISTQ1, X

        INC frontier_listQ1_size   
    :
.endmacro
;*****************************************************************

;stores a random offset into b_val, then calls access_frontier on that tile
.macro get_random_frontier_tile
    ;random number for offset
    JSR random_number_generator

    ;clamp the offset
    modulo random_seed, frontier_listQ1_size
    STA b_val

    access_Frontier b_val
.endmacro

.macro bounds_check_frontier_neighbor Direction, Row, Col
    ;Jump to the correct direction check
    LDA Direction
    CMP #TOP_D
    BEQ :+

    CMP #RIGHT_D
    BEQ :++

    CMP #BOTTOM_D
    BEQ :+++

    CMP #LEFT_D
    BEQ :++++

    : ;top check
    LDA Row
    CMP #MAP_START_ROW + 2
    BCC :++++ ; row < 3
    JMP :+++++ 

    : ;right check
    LDA Col
    CMP #MAP_END_COL - 1
    BCS :+++ ; col >= 60
    JMP :++++ 

    : ;bottom check
    LDA Row
    CMP #MAP_END_ROW - 1
    BCS :++ ; row >= 28
    JMP :+++ 

    : ;left check
    LDA Col
    CMP #MAP_START_COL + 2
    BCC :+ ; col < 2
    JMP :++ 

    : ;out of bounds
    LDA #0 ;0 indicates invalid neighbor
    JMP :++

    : ;in bounds
    LDA #1 ;1 indicates valid neighbor 

    : ;end
.endmacro

; stores the new row and col in Y and X reg
.macro calculate_frontier_neighbor_position Direction, Row, Col
    ;Jump to the correct direction check
    LDA Direction
    CMP #TOP_D
    BEQ :+

    CMP #RIGHT_D
    BEQ :++

    CMP #BOTTOM_D
    BEQ :+++

    CMP #LEFT_D
    BEQ :++++
    
    ;top
    : 
    LDA Row
    SEC
    SBC #2
    TAY
    LDX Col
    JMP :++++

    ;right
    :
    LDA Col
    CLC
    ADC #2
    TAX
    LDY Row
    JMP :+++

    ;bottom
    :
    LDA Row
    CLC
    ADC #2
    TAY
    LDX Col
    JMP :++

    ;left
    :
    LDA Col
    SEC
    SBC #2
    TAX
    LDY Row

    ;end
    :
.endmacro

;Frontier neighbor is not the immediate neighbor but the neighbor at distance == 2 (F 0 1 0 F)
;When there is no valid neighbor, the A register will be set to 255, when there is a valid neighbor it will be set to 0 or 1; 0 when its a wall, 1 when its a passable tiles.
;Row (Y) and Column (X) of the neighbor in Y and X register (useful to add to frontier afterwards) note: these are not set when there is not a valid neighbor; check this first! 
;Direction: The direction of the neighbor we are polling (0-3, defines are stored in the header for this)
;Row: Row index in the map buffer (0 to MAP_ROWS - 1)
;Column: Column index (0 to 31, across 4 bytes per row)
.macro access_map_frontier_neighbor Direction, Row, Column
    bounds_check_frontier_neighbor Direction, Row, Column
    ;Check if A is valid (1)
    BNE :+ ;else return   
        JMP set_invalid
    :
    ;calculate the neighbors row and col
    calculate_frontier_neighbor_position Direction, Row, Column ;returns row in y and col in x register

    ;store before getting state of neighbor
    STX a_val ;col 
    STY b_val ;row

    ;store the new row and col on the stack
    TXA
    PHA
    TYA
    PHA 
        
    get_map_tile_state b_val, a_val
    BNE passable ;if the neighbor is not a wall (wall == 0) it is passable 
    
        ;wall neighbor
        ;restore the neighbors row and col
        PLA
        TAY
        PLA
        TAX

        LDA #0 ;the neighbor is a wall
        JMP return

    .local set_invalid
    set_invalid:
        LDA #%11111111 ;invalid -> max val
        JMP return

    ;in the case of no wall we still have to restore the stack
    .local passable
    passable:
        ;restore the neighbors row and col
        PLA
        TAY
        PLA
        TAX

        LDA #1

    .local return
    return:
.endmacro
;*****************************************************************