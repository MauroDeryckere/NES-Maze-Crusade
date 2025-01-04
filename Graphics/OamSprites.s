.segment "CODE"
.proc update_oam
    ; setup torch in map buffer
    set_map_tile #0, #1
    set_map_tile #8, #MAP_END_COL + 1

    ; be randomly generated later
    JSR update_torch_visibility

    ; Torches / lamps
    LDX #OAM_PLAYER_BYTE_END

    ; calculate x pos first to know if this torch is off screen
    LDA #8
    SEC
    SBC scroll_x 
    TAY
    BCC @off_screen
    JMP @on

    ; Hide sprite off screen
    @off_screen: 
        ;Y coordinate
        LDA #$FF
        STA oam, X
        RTS
    @on: 

    ;Y coordinate
    LDA #64 
    STA oam, X
    INX

    ;Tile pattern index
    LDA #TORCH_TILE
    STA oam, X
    INX

    ;Sprite attributes
    LDA #%00000001
    STA oam, X
    INX

    ;X coordinate
    TYA
    STA oam, X
    INX

    RTS
.endproc

.proc update_torch_visibility
    ;torch tile
    LDY #8
    LDX #1
    STY temp_row
    STX temp_col
    ; torch tile
    JSR update_visibility_torch_dir

    ; above
    DEC temp_row
    JSR update_visibility_torch_dir

    ; left
    INC temp_row
    DEC temp_col
    JSR update_visibility_torch_dir

    ; right
    INC temp_col
    INC temp_col
    JSR update_visibility_torch_dir

    ; below
    DEC temp_col
    INC temp_row
    JSR update_visibility_torch_dir

    RTS
.endproc

.proc update_visibility_torch_dir
    set_visited temp_row, temp_col
    get_map_tile_state temp_row, temp_col

    BEQ @skip
    add_to_changed_tiles_buffer temp_row, temp_col, #PATH_TILE_1
    JMP @skip_2
    @skip: 
    add_to_changed_tiles_buffer temp_row, temp_col, #WALL_TILE
    @skip_2:

    RTS
.endproc