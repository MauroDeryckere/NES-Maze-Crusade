.include "Setup/Header.s"

.include "Util/Util.s"
.include "Util/Macros.s"

.include "DataStructures/ChangedTileBuffer.s"
.include "DataStructures/DirectionBuffer.s"
.include "DataStructures/ChestBuffer.s"
.include "DataStructures/FrontierList.s"
.include "DataStructures/MapBuffer.s"
.include "DataStructures/Queue.s"
.include "DataStructures/StartScreenBuffer.s"
.include "DataStructures/TorchBuffer.s"
.include "DataStructures/VisitedBuffer.s"

.include "Graphics/Graphics.s"
.include "Graphics/HUD.s"
.include "Graphics/OamSprites.s"
.include "Graphics/PlayerGraphics.s"

.include "Testing/TestCode.s"

; gameplay
.include "Gameplay/HardMode.s"
.include "Gameplay/Player.s"
.include "Gameplay/Score.s"
.include "Gameplay/TitleScreen.s"

; algorithms
.include "Generation/Prims.s"
.include "Solving/LeftHandRule.s"
.include "Solving/BFS.s"

; Include Sound Engine, Sound Effects and Music Data
.include "Audio/famistudio_ca65.s"
.include "Audio/SoundEffects.s"
.include "Audio/GameMusic.s"
.include "Audio/PlayMusic.s"

;*****************************************************************
; Interupts | Vblank
;*****************************************************************
.segment "CODE"
irq:
	RTI

;only caused by vblank right now
.proc nmi
    ;save registers
    PHA
    TXA
    PHA
    TYA
    PHA

    BIT PPU_STATUS    

    ;increase our frame counter (one vblank occurs per frame)
    INC frame_counter
    LDA frame_counter
    BNE :+ 
        ;increase again when 0
        INC frame_counter
    :
    
    LDA #0
    STA checked_this_frame

    JSR draw_background
    
    LDA current_game_mode
    CMP #GAMEMODE_TITLE_SCREEN
    BNE @skip_start_screen
        LDA has_started
        CMP #1
        BEQ :+
            JSR display_Start_screen
        :   
        JSR draw_title_settings
        JMP @skip_hud

    @skip_start_screen: 
        JSR display_score
    @skip_hud: 


    ; transfer sprite OAM data using DMA
	LDX #0
	STX PPU_SPRRAM_ADDRESS
	LDA #>oam
	STA SPRITE_DMA

	; transfer current palette to PPU
	LDA #%10001000 ; set horizontal nametable increment
	STA PPU_CONTROL 
	LDA PPU_STATUS
	LDA #$3F ; set PPU address to $3F00
	STA PPU_VRAM_ADDRESS2
	STX PPU_VRAM_ADDRESS2
	LDX #0 ; transfer the 32 bytes to VRAM

    @loop:
        LDA palette, x
        STA PPU_VRAM_IO
        INX
        CPX #32
        BCC @loop
    ; Reset the scroll (necessary for the split scroll to work)
    LDA #0
	STA PPU_VRAM_ADDRESS1
    LDA #0
	STA PPU_VRAM_ADDRESS1

    LDA ppu_ctl0
	STA PPU_CONTROL
	LDA ppu_ctl1
	STA PPU_MASK

    ; Update sound engine
    JSR famistudio_update

	; flag PPU update complete
	LDX #0
	STX nmi_ready

    ; this essentialy makes this function x amount of scanlines longer (depending on the position of the Sprite 0) 
    ; instead of just waiting additional logic could be executed here given that it doesnt take so long the PPU gets past the point you wish to split screen.
    ; Some mappers allow scanline interupts and could be a "better solution" but the current HUD is limited to some top rows so it is not necessary to switch to a different mapper.
    
    ; Clear buffer last since it does not have to be during vblank
    JSR clear_changed_tiles_buffer

    LDA hit_check_enabled
    BEQ @skip_check

    @Sprite0ClearWait: 
        BIT $2002
        BVS @Sprite0ClearWait

    @Sprite0Wait: 
        BIT $2002
        BVC @Sprite0Wait

    @skip_check: 
        ; write current scroll and control settings
        LDA scroll_x
        STA PPU_VRAM_ADDRESS1
        LDA #0
        STA PPU_VRAM_ADDRESS1

	; restore registers and return
	PLA
	TAY
	PLA
	TAX
	PLA

	RTI
.endproc
;*****************************************************************

;*****************************************************************
; init
;*****************************************************************
.segment "CODE"
.proc init
    LDA ppu_ctl0           ; Load the current PPU_CONTROL value
    AND #%01111111         ; Clear Bits 3 and 4 (sprite and background table select)
    ORA #%00001000         ; Set Bit 3 (sprites to Pattern Table 1), clear Bit 4 (background to Pattern Table 0)
    STA ppu_ctl0           ; Store back to ppu_ctl0 (this is now the new PPU_CONTROL value)    

    LDX #0
    palette_loop:
        LDA default_palette, x  ;load palettes
        STA palette, x
        INX
        CPX #32
        BCC palette_loop

    ; clear stuff
    JSR ppu_off
    JSR clear_nametable_0
    JSR clear_nametable_1

    JSR ppu_update

    JSR clear_changed_tiles_buffer

    LDA #1
    STA frame_counter
    ; 0% n == 0, we want to stick in the 1-255 range for our framecounter so that the delays are never off e.g 255%5 , next frame 0%5
    ; this does mean that when you do things every other frame (checkin last bit) result could be slightly off

    ;set an initial randomseed value - must be non zero
    LDA #$10
    STA random_seed

    ; "reset" score
    LDA #0
    STA score
    STA score + 1
    STA score + 2

    ; start with startscreen "gamemode"
    LDA #GAMEMODE_TITLE_SCREEN
    STA current_game_mode
    ; reset has started flag
    LDA #0
    STA has_started

    ; audio initialisations
    ;-----------------------------------------
    ;INITIALIZE MUSIC
    ;-----------------------------------------
    lda #1 
    ldx #.lobyte(music_data_duck_tales)
    ldy #.hibyte(music_data_duck_tales)
    jsr famistudio_init

    ;-----------------------------------------
    ;INITIALIZE SOUNDEFFECTS
    ;-----------------------------------------
    ldx #.lobyte(sounds)
    ldy #.hibyte(sounds)
    jsr famistudio_sfx_init

    ; scrolling / camera stuff
    ; Y pos
    LDX #0
    LDA #21 ; up until third row == blocked
    STA oam, X

    ; Tile ID - can be replaced with something else we just need sprite 0 to be there to block the HUD 
    INX
    LDA #TOPDOWN_WALL_TILE
    STA oam, X

    ; attributes
    INX 
    LDA #0
    STA oam, X

    ; X pos
    INX 
    LDA #240
    STA oam, X

    ; disabled by default
    LDA #0
    STA hit_check_enabled
    STA scroll_x


    ; run test code if testing
    ;JSR test_frontier 
    ;JSR test_queue

    RTS
.endproc
;*****************************************************************

;*****************************************************************
; Main Gameloop
;*****************************************************************
.segment "CODE"
.proc main
    JSR init
    
    mainloop:
        INC random_seed  ; Change the random seed as many times as possible per frame (this results in more randomness)
        ;------------;
        ;   INPUT    ;
        ;------------;
        @INPUT: 
            JSR gamepad_poll ; poll input as often as possible

            ; newly pressed buttons: not held last frame, and held now
            LDA gamepad_prev
            EOR #%11111111
            AND gamepad
            STA gamepad_pressed

            LDA gamepad_prev + 1
            EOR #%11111111
            AND gamepad + 1
            STA gamepad_pressed + 1

            ; newly released buttons: not held now, and held last frame
            LDA gamepad
            EOR #%11111111
            AND gamepad_prev
            STA gamepad_released

            LDA gamepad + 1
            EOR #%11111111
            AND gamepad_prev + 1
            STA gamepad_released + 1

        ;-------------;
        ; TITLESCREEN ;
        ;-------------;
        @TITLESCREEN:             
            LDA current_game_mode
            CMP #GAMEMODE_TITLE_SCREEN
            BNE @PAUSED
            
            JSR title_screen_input_logic

            LDA current_game_mode
            CMP #GAMEMODE_TITLE_SCREEN
            BNE @PAUSED


        ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BEQ mainloop
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                ; Have we started the start screen yet? if not, execute the start function once
                LDA has_started
                CMP #0
                BNE :+
                    JSR init_title_screen
                    
                    LDA #1
                    STA has_started
                    JMP mainloop
                :
                JSR step_title_update
                JSR update_oam

            JMP mainloop

        ;------------;
        ;   PAUSE    ;
        ;------------;
        @PAUSED: 
            JSR pause_logic

        ;------------;
        ; GENERATING ;
        ;------------;
        @GENERATING: 
            LDA current_game_mode
            CMP #GAMEMODE_GENERATING
            BEQ :+
                JMP PLAYING
            :

        ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BNE :+
                JMP mainloop
            :
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                ; Have we started the algorithm yet? if not, execute the start function once
                LDA has_started
                CMP #0
                BNE :+++  
                    LDA #0
                    STA player_movement_delay_ct
                    ;------------------------
                    ;PAUSE TITLE SCREEN MUSIC
                    ;------------------------
                    LDA #1
                    JSR pause_music

                    ;PLAY MAZE GENERATION SOUND ONCE WHEN GENERATING
                    LDA #FAMISTUDIO_SFX_CH0
                    STA sfx_channel
                    LDA #0
                    JSR play_sound_effect

                    JSR start_prims_maze

                    LDX start_col
                    : ;loop
                    CPX #20
                    BCC :+

                    LDA scroll_x
                    CLC
                    ADC #8
                    STA scroll_x

                    DEX
                    JMP :-
                    :

                    LDA #1
                    STA has_started
                :

                ;slow down generation if necessary
                ; modulo frame_counter, #MAZE_GENERATION_SPEED
                ; CMP #0
                ; BEQ :+
                ;     JMP mainloop
                ; :

                LDA scroll_x
                CMP #248
                BEQ :+
                    INC scroll_x
                :

                JSR run_prims_maze
                JSR run_prims_maze

                JSR update_oam

                ; BROKEN TILES ANIMATION
                LDA player_movement_delay_ct
                CMP #GENERATION_ANIMATION_DELAY
                BEQ :+
                    INC player_movement_delay_ct
                    JMP mainloop
                :
                    JSR is_empty
                    CMP #1
                    BNE :+
                        JMP SKIP_DEQ	
                    :

                    JSR dequeue
                    STA frontier_row

                    JSR dequeue
                    STA frontier_col

                    JSR random_number_generator
                    AND #%00000011
                    CLC
                    ADC #PATH_TILE_1
                    STA temp

                    add_to_changed_tiles_buffer frontier_row, frontier_col, temp

                    JSR is_empty
                    CMP #1
                    BNE :+
                        JMP SKIP_DEQ
                    :

                    JSR dequeue
                    STA frontier_row

                    JSR dequeue
                    STA frontier_col

                    JSR random_number_generator
                    AND #%00000011
                    CLC
                    ADC #PATH_TILE_1
                    STA temp

                    add_to_changed_tiles_buffer frontier_row, frontier_col, temp
                    SKIP_DEQ: 
            ; -------------------------------------------------------------

                ; Has the maze finished generating?
                JSR is_empty
                CMP #1
                BNE NOT_END_GEN

                LDA frontier_list_size
                BNE NOT_END_GEN

                LDA scroll_x
                CMP #248
                BNE NOT_END_GEN

                END_GEN:                     
                    JSR calculate_prims_start_end

                    ; reset some flags for the next game mode so that they could be reused
                    LDA #0
                    STA has_started

                    ; Select correct gamemode after generating  
                    LDA input_game_mode
                    AND #GAME_MODE_MASK
                    CMP #GAME_MODE_MASK
                    BEQ :+
                        LDA #GAMEMODE_PLAYING
                        STA current_game_mode

                        ;reset player movement delay since we used it for the animation
                        LDA #0
                        STA player_movement_delay_ct

                        LDA #0
                        STA scroll_x
                        
                        JMP mainloop
                    :
                    ;reset player movement delay since we used it for the animation
                    LDA #0
                    STA player_movement_delay_ct

                    ; start auto solving
                    LDA #GAMEMODE_SOLVING
                    STA current_game_mode

                    LDA #0
                    STA scroll_x

                NOT_END_GEN: 
                JMP mainloop

        ;---------;
        ; PLAYING ;
        ;---------;
        PLAYING: 
            LDA current_game_mode
            CMP #GAMEMODE_PLAYING
            BNE @SOLVING

        ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BEQ @SOLVING
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                JSR update_player_position
                JSR update_oam

                ; Have we started the game yet? if not, execute the start function once
                LDA has_started
                CMP #0
                BNE :+ 
                    ;------------------------
                    ;PLAY TITLE SCREEN MUSIC
                    ;------------------------
                    LDA #1
                    JSR play_music   

                    JSR start_game
                    LDA #1
                    STA has_started ;set started to 1 so that we start drawing the sprite
                :
                
                ; are we in hard mode?
                LDA input_game_mode
                AND #HARD_MODE_MASK
                CMP #0
                BEQ :+
                    JSR update_visibility
                :

                ; Has the player reached the end?
                    LDA player_row
                    CMP end_row
                    BNE @SOLVING

                    LDA scroll_x
                    LSR
                    LSR
                    LSR
                    STA temp
                    LDA player_collumn
                    CLC
                    ADC temp

                    CMP end_col
                    BNE @SOLVING

                ; ONLY EXECUTED WHEN END IS REACHED
                ; reset some flags for the next game mode so that they could be reused
                    LDA #0
                    STA has_started

                    LDA #10
                    JSR add_score

                    ;------------------------
                    ;PLAY SOUND EFFECT AND STOP PREVIOUS
                    ;------------------------
                    LDA #2
                    JSR stop_music
                    
                    LDA #1
                    JSR play_sound_effect

                    JSR tiny_delay_for_music

                    ; back to generating
                    LDA #GAMEMODE_GENERATING 
                    STA current_game_mode
                    JSR reset_generation

                    LDA #1
                    STA checked_this_frame

                JMP mainloop

        ;---------;
        ; SOLVING ;
        ;---------;
        @SOLVING: 
            LDA current_game_mode
            CMP #GAMEMODE_SOLVING
            BEQ :+
                JMP mainloop
            :

            ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BNE :+
                JMP mainloop
            :
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                ; Have we started the solving algorithm yet? if not, execute the start function once
                LDA has_started
                CMP #0
                BNE :++++ 
                    ;------------------------
                    ;PAUSE TITLE SCREEN MUSIC
                    ;------------------------
                    LDA #2
                    JSR play_music

                    ;select the solving mode based on hard mode or not
                    LDA input_game_mode
                    AND #CLEAR_SOLVING_MODE_MASK
                    STA input_game_mode

                    LDA input_game_mode
                    AND #HARD_MODE_MASK
                    CMP #0
                    BEQ :+
                        LDA input_game_mode
                        ORA #LHR_MODE_MASK
                        STA input_game_mode
                    :

                    ;which solve mode do we have to start in?
                    LDA input_game_mode
                    AND #SOLVE_MODE_MASK
                    CMP #0 ;BFS
                    BNE :+ 
                        JSR start_BFS
                        JMP :++
                    :
                    CMP #1 ;left hand
                    BNE :+
                        ;start left hand
                        ; are we in hard mode?
                        LDA input_game_mode
                        AND #HARD_MODE_MASK
                        CMP #0
                        BEQ :+
                            JSR display_clear_map
                            JSR start_hard_mode
                    :
                    LDA #1
                    STA has_started 
                :

                ; execute one step of the algorithm
                LDA input_game_mode
                AND #SOLVE_MODE_MASK
                @BFS_SOLVE: 
                    CMP #0 ;BFS
                    BNE @LFR_SOLVE

                    JSR update_player_position

                    JSR play_when_backtracking

                    JSR step_BFS

                    LDA is_backtracking
                    CMP #$FF                 
                    BEQ @SOLVE_END_REACHED

                    JMP @END_SOLVE_MODES
                @LFR_SOLVE: 
                    CMP #1 ;LFR
                    BNE @END_SOLVE_MODES

                    modulo frame_counter, #LHR_DELAY
                    CMP #0
                    BEQ :+
                        JMP mainloop
                    :

                    JSR left_hand_rule
                    JSR update_oam

                    ; are we in hard mode?
                    LDA input_game_mode
                    AND #HARD_MODE_MASK
                    CMP #0
                    BEQ :+
                        JSR update_visibility
                    :

                    ; check if player reached end
                    LDA player_row
                    CMP end_row
                    BNE @END_SOLVE_MODES

                    LDA scroll_x
                    LSR
                    LSR
                    LSR
                    STA temp
                    LDA player_collumn
                    CLC
                    ADC temp
                    CMP end_col
                    BNE @END_SOLVE_MODES

                    JMP @SOLVE_END_REACHED
                @END_SOLVE_MODES:
                    JMP mainloop
                
                @SOLVE_END_REACHED: 
                    LDA #0
                    STA sound_played2

                    LDA #10
                    JSR add_score 
                    
                    ; back to generating
                    LDA #GAMEMODE_GENERATING
                    STA current_game_mode
                    LDA #0
                    STA has_started

                    LDA #1
                    STA checked_this_frame

                    JSR reset_generation
                    JMP mainloop

       ; RTS
.endproc
;*****************************************************************

;*****************************************************************
; Input 
;*****************************************************************
.proc pause_logic
    LDA #DEBUG_MODE 
    BNE :+ ; DEBUG_MODE != 0
        ; can not pause while generating if not in debug build
        LDA current_game_mode
        CMP #GAMEMODE_GENERATING
        BNE :+
            RTS
    :

    LDA gamepad_released
    AND #PAD_START
    BEQ @NOT_GAMEPAD_START

    LDA current_game_mode
    CMP #GAMEMODE_PAUSED
    BNE @is_not_paused
        LDA gamemode_store_for_paused
        STA current_game_mode
        JMP @NOT_GAMEPAD_START            
    @is_not_paused:
        STA gamemode_store_for_paused
        LDA #GAMEMODE_PAUSED
        STA current_game_mode

    @NOT_GAMEPAD_START:

    RTS
.endproc

.segment "CODE"
.proc gamepad_poll
    CLC
    ; https://www.nesdev.org/wiki/Controller_reading_code 
    LDA gamepad
    STA gamepad_prev
    LDA gamepad + 1
    STA gamepad_prev + 1
    
    @readjoy2_safe:
        LDX #0
        JSR @readjoyx_safe  ; X=0: safe read controller 1
        INX
        ; fall through to readjoyx_safe, X=1: safe read controller 2

    @readjoyx_safe:
        JSR @readjoyx

    @reread:
        LDA gamepad, X
        PHA
        JSR @readjoyx
        PLA
        CMP gamepad, X
        BNE @reread
        RTS

    @readjoyx: ; X register = 0 for controller 1, 1 for controller 2
        LDA #$01
        STA JOYPAD1
        STA gamepad, X
        LSR A
        STA JOYPAD1
    @loop:
        LDA JOYPAD1, X
        AND #%00000011  ; ignore bits other than controller
        CMP #$01        ; Set carry if and only if nonzero
        ROL gamepad, X  ; Carry -> bit 0; but 7 -> Carry
        BCC @loop
        RTS
.endproc
;*****************************************************************

;*****************************************************************
; Gameplay
;*****************************************************************
; resets everything necessary so that the maze generation can start again
.proc reset_generation
    JSR clear_changed_tiles_buffer
    JSR clear_maze

    JSR display_map_all_walls

    JSR clear_queue

    LDA #0
    STA scroll_x
    LDA #1
    STA hit_check_enabled

    LDA #0
    STA num_torches

    JSR clear_chest_buffer
    
    JSR clear_oam

    RTS
.endproc

.proc start_game
    LDA input_game_mode
    AND #HARD_MODE_MASK
    CMP #0
    BEQ :+
        JSR start_hard_mode
    :

    LDA #1
    STA hit_check_enabled

    RTS
.endproc 
;*****************************************************************
