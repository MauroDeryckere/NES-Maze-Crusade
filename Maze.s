.include "Setup/Header.s"

.include "DataStructures/Macros.s"
.include "DataStructures/Queue.s"

.include "Graphics/Graphics.s"

.include "Util/Util.s"

.include "Testing/TestCode.s"

; gameplay
.include "Gameplay/HardMode.s"
.include "Gameplay/Score.s"
.include "Gameplay/Player.s"

; algorithms
.include "Generation/Prims.s"
.include "Solving/LeftHandRule.s"
.include "Solving/BFS.s"

;*****************************************************************
; Include Sound Engine, Sound Effects and Music Data
;*****************************************************************
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
    BNE :+ 
        ;increase again when 0
        INC frame_counter
    :

    LDA #0
    STA checked_this_frame

    LDA current_game_mode
    CMP #0
    BEQ draw_start_screen

    JSR draw_background
    JSR draw_player_sprite
    JSR display_score
    
    JMP skip_start_screen
    
draw_start_screen:
    LDA has_started
    CMP #1
    BEQ :+
        ; INC temp_player_collumn ; tep var to maintain how many times weve executed
        JSR display_Start_screen
        ; JSR draw_title
    :   
        JSR draw_player_sprite
        JSR draw_title_settings
skip_start_screen:

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

    ;CALL SOUND PLAY ROUTINE
    jsr famistudio_update

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
        JSR pause_logic ; check if we should pause

        LDA current_game_mode
        ;------------;
        ;   PAUSE    ;
        ;------------;
        @PAUSED: 
            CMP #GAMEMODE_PAUSED
            BNE @TITLESCREEN
                JMP mainloop

        ;-------------;
        ; TITLESCREEN ;
        ;-------------;
        @TITLESCREEN: 
            CMP #GAMEMODE_TITLE_SCREEN
            BNE @GENERATING
            
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

                JSR title_screen_update
            
            JMP mainloop

        ;------------;
        ; GENERATING ;
        ;------------;
        @GENERATING: 
            CMP #GAMEMODE_GENERATING
            BNE @PLAYING

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
                BNE mainloop
                JSR run_prims_maze ; whether or not the algorithm is finished is stored in the A register (0 when not finished)

                ; Has the maze finished generating?
                CMP #0
                BEQ :++
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
                        JMP mainloop
                    :
                    ; start auto solving
                    LDA #GAMEMODE_PLAYING
                    STA current_game_mode
                :
                JMP mainloop

        ;---------;
        ; PLAYING ;
        ;---------;
        @PLAYING: 
            CMP #GAMEMODE_PLAYING
            BNE @SOLVING

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
                    BNE @PLAYING
                    LDA player_collumn
                    CMP end_col
                    BNE @PLAYING

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

    LDA gamepad
    AND #PAD_A
    BEQ A_NOT_PRESSED

    JMP START_CHECK
    A_NOT_PRESSED:

    START_CHECK:
        LDA gamepad     
        AND #PAD_START
        BEQ NOT_GAMEPAD_START

        LDA gamepad_prev            
        AND #PAD_START              
        BNE NOT_GAMEPAD_START
            LDA current_game_mode
            CMP #GAMEMODE_PAUSED
            BNE is_not_paused
                LDA gamemode_store_for_paused
                STA current_game_mode
                JMP EXIT            
            is_not_paused:
                STA gamemode_store_for_paused
                LDA #GAMEMODE_PAUSED
                STA current_game_mode

    NOT_GAMEPAD_START:

    EXIT:
    RTS
.endproc

.segment "CODE"
.proc gamepad_poll
    lda gamepad
    sta gamepad_prev

	; strobe the gamepad to latch current button state
	LDA #1
	STA JOYPAD1
	LDA #0
	STA JOYPAD1
	; read 8 bytes from the interface at $4016
	LDX #8
loop:
    PHA
    LDA JOYPAD1
    ; combine low two bits and store in carry bit
	AND #%00000011
	CMP #%00000001
	PLA
	; rotate carry into gamepad variable
	ROR
	DEX
	BNE loop
	STA gamepad
	RTS
.endproc
;*****************************************************************

;*****************************************************************
.proc init_title_screen
    ;player row and col on the startscreen
    LDA #18
    STA player_row
    LDA #13
    STA player_collumn

    LDA #2
    STA player_dir

    ;PLAY TITLE SCREEN MUSIC
    LDA #0
    JSR play_music

    RTS
.endproc

.proc title_screen_update
        ;Loading the title as an animation TODO
        


        JSR gamepad_poll
        ; UP/DOWN MOVEMENT OF SELECTION
        @UP_DOWN_MOVEMENT: 
            LDA gamepad     
            AND #PAD_D
            BEQ NOT_GAMEPAD_DOWN 

            LDA gamepad_prev            
            AND #PAD_D                  
            BNE NOT_GAMEPAD_DOWN
                LDA player_row
                CMP #20
                BEQ :+
                    INC player_row
                :

            NOT_GAMEPAD_DOWN: 
            LDA gamepad     
            AND #PAD_U
            BEQ NOT_GAMEPAD_UP

            LDA gamepad_prev            
            AND #PAD_U           
            BNE NOT_GAMEPAD_UP
                LDA player_row
                CMP #18
                BEQ :+
                    DEC player_row
                :
        ;---------------------

        ; SELECTION
        @SELECTION: 
            NOT_GAMEPAD_UP: 
            LDA gamepad     
            AND #PAD_SELECT
            BEQ NOT_GAMEPAD_SELECT

            ; select pressed


        CheckAndPlaySound:
            LDA sound_played   ; Check if sound has already been played
            BEQ PlaySoundOnce  ; If not, play the sound

            JMP Resume         ; continue if already played

        PlaySoundOnce:
            ; PLAY START SOUND
            LDA #FAMISTUDIO_SFX_CH1
            STA sfx_channel
            LDA #2
            JSR play_sound_effect

            ; Set the flag to indicate the sound was played
            LDA #$01
            STA sound_played

        Resume:
            LDA gamepad_prev            
            AND #PAD_SELECT  
            BNE NOT_GAMEPAD_SELECT
            LDA #0
            STA sound_played ;reset sound_played flag

                LDA player_row
                CMP #18
                BNE NOT_PLAY
                    JMP EXIT_SCREEN
                NOT_PLAY: 
                LDA player_row
                CMP #19
                BNE NOT_AUTO
                    LDA input_game_mode
                    EOR #%00010000
                    STA input_game_mode
                    JMP NOT_GAMEPAD_SELECT
                NOT_AUTO:
                LDA player_row
                CMP #20
                BNE NOT_HARD
                    LDA input_game_mode
                    EOR #%00001000
                    STA input_game_mode
                    JMP NOT_GAMEPAD_SELECT
                NOT_HARD:
        ;---------------------------
        NOT_GAMEPAD_SELECT: 

        ; reset direction since moving row changes it
        LDA #2
        STA player_dir

        ; Pressing start starts the game
        LDA gamepad
        AND #PAD_START

        BNE EXIT_SCREEN

        RTS

    EXIT_SCREEN:
        ;PLAY START SOUND
        LDA #FAMISTUDIO_SFX_CH1
        STA sfx_channel
        LDA #2
        JSR play_sound_effect

        ;------------------------
        ;STOP TITLE SCREEN MUSIC
        ;------------------------
        LDA #0
        JSR stop_music

        JSR tiny_delay_for_music

        LDA #GAMEMODE_GENERATING
        STA current_game_mode ; back to generating
        
        LDA #0                      
        STA has_started
        JSR reset_generation
        RTS
.endproc

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
