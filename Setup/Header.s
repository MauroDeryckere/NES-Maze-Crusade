.include "Defines.s"

.segment "HEADER"
    INES_MAPPER = 0 ; 0 = NROM
    INES_MIRROR = 1 ; 0 = horizontal mirror/1 = vertical
    INES_SRAM = 0 ; 1 = battery save at $6000-7FFF

    .byte 'N', 'E', 'S', $1A ; ID
    .byte $02 ; 16 KB program bank count
    .byte $01 ; 8 KB program bank count
    .byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
    .byte (INES_MAPPER & %11110000)
    .byte $0 ; additional mapper info - we don't use this
    .byte $4 ; pal mode
    .byte $0, $0, $0, $0, $0, $0 ; padding
              ; PAL mode
.segment "TILES"
    .incbin "Graphics/Tiles.chr"

.segment "VECTORS"
    .word nmi
    .word reset
    .word irq

;*****************************************************************
; 6502 Zero Page Memory (256 bytes)
;*****************************************************************
.segment "ZEROPAGE"
    ;internal (hardware) use flags and values
    nmi_ready:		    	.res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI

    ppu_ctl0:		    	.res 1 ; PPU Control Register 2 Value
    ppu_ctl1:		    	.res 1 ; PPU Control Register 2 Value

    ; HUD sprite 0 hitcheck stuff
    hit_check_enabled:      .res 1 ; do we need to "block" the lines before sprite 0

    frame_counter: 			.res 1

    random_seed:			.res 1 ; Initial seed value | Used internally for random function, do not overwrite

    ;input
    gamepad:		    	.res 2 ; stores the current gamepad values
    gamepad_prev:		    .res 2 ; stores the previous gamepad values
    gamepad_pressed:        .res 2 ; pressed this frame
    gamepad_released:       .res 2 ; released this frame

    ;gameplay flags
    checked_this_frame:     .res 1 ; has code been executed during this frame

    input_game_mode:        .res 1  ; game mode the game was started with
                                    ; 000G HSSS
                                    ; G: gamemode - 0 playing, 1 solving
                                    ; H: is in hard mode / not
                                    ; SSS: which solve mode are we in
                                        ; 0: BFS
                                        ; 1: Left hand rule 
                                        ; 2: Nothing
                                    ; 000: unused, can be used later on


    current_game_mode:      .res 1  ; internal mode that's currently running
                                    ; 0: Start Screen
                                    ; 1: Generating
                                    ; 2: Playing game 
                                    ; 3: Running Solving algorithm
                                    ; 4: Nothing (paused)
    gamemode_store_for_paused:  .res 1 ; stores previous curr_game_mode when pausing 

    has_started:            .res 1  ; internal flag to show whether or not a mode has started, used to only execute the start function once 
    
    ; PLAYER VARIABLES
    player_dir:                 .res 1
    player_row: 			    .res 1
    player_collumn: 		    .res 1
    player_movement_delay_ct:   .res 1 ; also used for animation during generation

    ; SCROLLING
    scroll_x:                   .res 1 ; current nametable x croll

    ; MAZE positions
    start_row: 				.res 1 ; Start tile of the maze
    start_col:				.res 1    
    end_row: 				.res 1 ; End tile of the maze
    end_col:				.res 1

    ; GRAPHICS
    changed_tiles_buffer: 	.res CHANGED_TILES_BUFFER_SIZE ;changed tiles this frame - used for graphics during vblank 
    curr_oam_byte:          .res 1 ; used to maintain the current oam offset, allows flickering when more than 8 sprites are in a line and is easier to stop / start drawing certain sprites.
                                   ; should be reset at start of every frame

    low_byte: 				.res 1 ; used for temporary calculations using high / low bytes 
    high_byte: 				.res 1

    ; frontier list specific
    frontier_list_size:	    .res 1 ; current size of the frontier list
                                   ; Internal use for frontier list, do not overwrite

    ;temporary values used in macros, ... - have to check when you use these in other routines if they arent used anywhere internally
    x_val:					.res 1 ;x and y value stored in zero page for fast accesss when it's necessary to store these
    y_val:					.res 1

    a_val: 					.res 1
    b_val: 					.res 1

    temp_row:				.res 1 ; used in add_to_changed_tiles_buffer
    temp_col:				.res 1

    paddr:              	.res 2 ; 16-bit address pointer
    temp_address:			.res 1 ; temporary offset

    ;temp vals used for prims algorithm loop - only used during a step of prims in the generation loop so possible to overwrite outside of the loop
    frontier_row:			.res 1
    frontier_col:			.res 1
    temp_frontier_row:		.res 1
    temp_frontier_col:		.res 1

    temp: 					.res 1

    ; Queue ptrs
    queue_head:             .res 1
    queue_tail:             .res 1

    ; BFS algorithm
    move_count:             .res 1
    ; nodes_left_layer:       .res 1
    ; nodes_next_layer:       .res 1
    is_backtracking:        .res 1 ; is BFS currently backtracking the path (internal) - will be set to FF when end is reached

    ; SCORE
    score:                  .res 3 ; 3 bytes each storing 0-99 score
    should_update_score:    .res 1 ; "dirty flag" for score, toggled when score changes
    
    ; GAMEPLAY
    ; Map specific - may be moved to normal memory in future if necessary but since we have space in zero page, keep it here.
    num_torches:            .res 1 ; how many torches are there on the current map
    torches_buffer:         .res TORCH_BUFFER_SIZE ; Row, Col for all tourches | row == 0 means there is no item at the current slot

    num_chests:             .res 1 ; how many chests are there on the current map
    chests_buffer:          .res CHEST_BUFFER_SIZE ; Row, Col for all chests | row == 0 means there is no item at the current slot

    ; AUDIO
    temp_sound:             .res 1
    sfx_channel:            .res 1
    sound_played:           .res 1
    sound_played2:          .res 1
    music_flag:             .res 1

    ; TESTING
    ; test_var:               .res 1
;*****************************************************************

.segment "OAM"
    oam: .res 256	; sprite OAM data

.segment "BSS"
    palette: .res 32 ; current palette buffer

;*****************************************************************
; Our default palette table 16 entries for tiles and 16 entries for sprites
;*****************************************************************
.segment "RODATA"
    default_palette:
        .byte $0F,$16,$1C,$2C ; bg0: Maze color | Red (barely used), Teal, Cyan  
        .byte $0F,$0F,$0F,$0F ; bg1: Currently unused
        .byte $0F,$0F,$0F,$0F ; bg2: Currently unused
        .byte $0F,$13,$15,$30 ; bg3: HUD color | Purple (unused), Pink-Red, White
        
        .byte $0F,$1D,$20,$10 ; sp0: Player | Black, White, Light gray
        .byte $0F,$07,$16,$27 ; sp1: Torches | Brown (unused), Orange, Yellow
        .byte $0F,$07,$17,$00 ; sp2: Chests | Dark brown, Light brown, Gray
        .byte $0F,$0F,$0F,$0F ; sp3: Currently unused
;*****************************************************************
