.include "Setup/Header.s"

.include "DataStructures/ChangedTileBuffer.s"
.include "DataStructures/DirectionBuffer.s"
.include "DataStructures/FrontierList.s"
.include "DataStructures/Macros.s"
.include "DataStructures/MapBuffer.s"
.include "DataStructures/Queue.s"
.include "DataStructures/StartScreenBuffer.s"
.include "DataStructures/VisitedBuffer.s"

.include "Graphics/Graphics.s"

.include "Util/Util.s"

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
    JSR draw_player_sprite
    
    LDA current_game_mode
    BEQ @draw_start_screen
    JSR display_score
    JMP @skip_start_screen
    
@draw_start_screen:
    LDA has_started
    CMP #1
    BEQ :+
        JSR display_Start_screen
    :   
        JSR draw_title_settings
@skip_start_screen:

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
	LDX #0 ; transfer the 32 bytes to VRAM

    @loop:
        LDA palette, x
        STA PPU_VRAM_IO
        INX
        CPX #32
        BCC @loop


    ; write current scroll and control settings
	LDA #0
	STA PPU_VRAM_ADDRESS1
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
    LDX #0
    palette_loop:
        LDA default_palette, x  ;load palettes
        STA palette, x
        INX
        CPX #32
        BCC palette_loop

    ;clear stuff
    JSR ppu_off
    JSR clear_nametable

    JSR ppu_update

    JSR clear_changed_tiles_buffer

    LDA #1
    STA frame_counter
    ; 0% n == 0, we want to stick in the 1-255 range for our framecounter so that the delays are never off e.g 255%5 , next frame 0%5

    ;set an initial randomseed value - must be non zero
    LDA #$10
    STA random_seed

    ;start with startscreen
    LDA #0
    STA current_game_mode
    STA has_started
            
    ;run test code
    ;JSR test_frontier ;test code
    ;JSR test_queue

    ; edited though startscreen
    ;     000GHSSS
    ; LDA #%00000001
    ; EOR #HARD_MODE_MASK
    ; EOR #GAME_MODE_MASK
    ; STA input_game_mode 

    ; display arrows instead of just red cells
    LDA #1 
    STA display_BFS_directions

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
        INC random_seed  ; Change the random seed as many times as possible per frame
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

        LDA current_game_mode
        ;------------;
        ;   PAUSE    ;
        ;------------;
        @PAUSED: 
            CMP #GAMEMODE_PAUSED
            BNE @TITLESCREEN
                JSR pause_logic
                JMP mainloop

        ;-------------;
        ; TITLESCREEN ;
        ;-------------;
        @TITLESCREEN: 
            CMP #GAMEMODE_TITLE_SCREEN
            BNE @GENERATING
            
            ; as often as possible but after other logic if necessary
            JSR title_screen_input_logic
            LDA current_game_mode
            CMP #GAMEMODE_TITLE_SCREEN
            BNE mainloop

            ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BEQ mainloop
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame
                JSR poll_clear_buffer ; clear buffer if necessary

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
    
            JMP mainloop

        ;------------;
        ; GENERATING ;
        ;------------;
        @GENERATING: 
            CMP #GAMEMODE_GENERATING
            BEQ :+
                JMP PLAYING
            :

            JSR pause_logic ; check if we should pause

            ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BEQ mainloop
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                JSR poll_clear_buffer ; clear buffer if necessary

                ; Have we started the algorithm yet? if not, execute the start function once
                LDA has_started
                CMP #0
                BNE :+

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
                    LDA #1
                    STA has_started
                :

                ;slow down generation if necessary
                modulo frame_counter, #MAZE_GENERATION_SPEED
                CMP #0
                BEQ :+
                    JMP mainloop
                :

                JSR run_prims_maze ; whether or not the algorithm is finished is stored in the A register (0 when not finished)

                ; BROKEN TILES ANIMATION
                LDA player_movement_delay_ct
                CMP #GENERATION_ANIMATION_DELAY
                BEQ :+
                    INC player_movement_delay_ct
                    JMP mainloop
                :
                    JSR dequeue
                    STA temp_row

                    JSR dequeue
                    STA temp_col

                    JSR random_number_generator
                    modulo random_seed, #03
                    CLC
                    ADC #PATH_TILE_1
                    STA temp

                    add_to_changed_tiles_buffer temp_row, temp_col, temp
            ; -------------------------------------------------------------

                JSR is_empty
                CMP #1
                BNE NOT_END_GEN

                ; Has the maze finished generating?
                ; CMP #0
                ; BEQ :++
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

                        JMP mainloop
                    :
                    ; start auto solving
                    LDA #GAMEMODE_SOLVING
                    STA current_game_mode


                NOT_END_GEN: 
                JMP mainloop

        ;---------;
        ; PLAYING ;
        ;---------;
        PLAYING: 
            CMP #GAMEMODE_PLAYING
            BNE @SOLVING

            JSR pause_logic ; check if we should pause

            ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BEQ @SOLVING
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame
                
                JSR poll_clear_buffer ; clear buffer if necessary

                JSR update_player_sprite

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
                    LDA player_collumn
                    CMP end_col
                    BNE @SOLVING

                ; ONLY EXECUTED WHEN END IS REACHED
                ; reset some flags for the next game mode so that they could be reused
                    LDA #0
                    STA has_started

                    add_score #100

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
                JMP mainloop

        ;---------;
        ; SOLVING ;
        ;---------;
        @SOLVING: 
            CMP #GAMEMODE_SOLVING
            BEQ :+
                JMP mainloop
            :

            JSR pause_logic ; check if we should pause

            ; ONCE PER FRAME
            LDA checked_this_frame
            CMP #1
            BNE :+
                JMP mainloop
            :
                LDA #1
                STA checked_this_frame ; set flag so that we only do this once per frame

                JSR poll_clear_buffer ; clear buffer if necessary

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

                    JSR play_when_backtracking

                    JSR step_BFS

                    LDA is_backtracking
                    CMP #$FF                 
                    BEQ @SOLVE_END_REACHED

                    JMP @END_SOLVE_MODES
                @LFR_SOLVE: 
                    CMP #1 ;LFR
                    BNE @END_SOLVE_MODES
                    JSR left_hand_rule

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
                    LDA player_collumn 
                    CMP end_col
                        BNE @END_SOLVE_MODES

                    JMP @SOLVE_END_REACHED
                @END_SOLVE_MODES: 
                    JMP mainloop
                
                @SOLVE_END_REACHED: 
                    LDA #0
                    STA sound_played2

                    add_score #100

                    ; back to generating
                    LDA #GAMEMODE_GENERATING
                    STA current_game_mode
                    LDA #0
                    STA has_started

                    JSR reset_generation

                    JMP mainloop
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

    LDA gamepad_pressed
    AND #PAD_START
    BEQ NOT_GAMEPAD_START

    LDA current_game_mode
    CMP #GAMEMODE_PAUSED
    BNE @is_not_paused
        LDA gamemode_store_for_paused
        STA current_game_mode
        JMP NOT_GAMEPAD_START            
    @is_not_paused:
        STA gamemode_store_for_paused
        LDA #GAMEMODE_PAUSED
        STA current_game_mode

    NOT_GAMEPAD_START:

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
    JSR hide_player_sprite
    JSR clear_changed_tiles_buffer
    JSR clear_maze

    JSR wait_frame
    JSR display_map

    JSR clear_queue

    RTS
.endproc

.proc start_game
    
    LDA input_game_mode
    AND #HARD_MODE_MASK
    CMP #0
    BEQ :+
        JSR display_clear_map
        JSR start_hard_mode
    :
    RTS
.endproc 
;*****************************************************************
