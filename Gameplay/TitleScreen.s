
;*****************************************************************
.proc title_screen_input_logic
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

        ; start btn
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

        ; reset the player movement delay and use it as an animation delay
        LDA #1
        STA player_movement_delay_ct

        LDA #GAMEMODE_GENERATING
        STA current_game_mode ; back to generating
        
        LDA #0                      
        STA has_started
        JSR reset_generation
    RTS
.endproc

; During the titlescreen we temporarily treat some values as sizes of different buffers and since nothing in memory is currently in use we use those locations as buffers
.proc init_title_screen
    LDA #0 
    STA MAZE_BUFFER
    STA MAZE_BUFFER + 1
    STA MAZE_BUFFER + 2

    ;initial player row and col on the startscreen
    LDA #18
    STA player_row
    LDA #13
    STA player_collumn

    LDA #2
    STA player_dir

    ;PLAY TITLE SCREEN MUSIC
    LDA #0
    JSR play_music
    
    ; label to allow collapsing this big block of code
    @TITLE_SCREEN_BUFFER_FILL: 
        ; fill buffers with initial values for the title
        ; ROW 1
        LDX #0 ;buffer
        LDA #1 ; row
            LDY #2; col
            JSR add_to_start_screen_buffer
            LDY #5; col
            JSR add_to_start_screen_buffer
            LDY #6; col
            JSR add_to_start_screen_buffer
            LDY #7; col
            JSR add_to_start_screen_buffer
            LDY #10; col
            JSR add_to_start_screen_buffer
            LDY #11; col
            JSR add_to_start_screen_buffer
            LDY #12; col
            JSR add_to_start_screen_buffer
            LDY #13; col
            JSR add_to_start_screen_buffer
            LDY #17; col
            JSR add_to_start_screen_buffer
            LDY #20; col
            JSR add_to_start_screen_buffer
            LDY #21; col
            JSR add_to_start_screen_buffer
            LDY #24; col
            JSR add_to_start_screen_buffer
            LDY #26; col
            JSR add_to_start_screen_buffer
        
        ; ROW 2
        LDA #2 ; row
        LDX #0
            LDY #2; col
            JSR add_to_start_screen_buffer
            LDY #3; col
            JSR add_to_start_screen_buffer
            LDY #4; col
            JSR add_to_start_screen_buffer
            LDY #5; col
            JSR add_to_start_screen_buffer
            LDY #6; col
            JSR add_to_start_screen_buffer
            LDY #7; col
            JSR add_to_start_screen_buffer
            LDY #8; col
            JSR add_to_start_screen_buffer
            LDY #9; col
            JSR add_to_start_screen_buffer
            LDY #10; col
            JSR add_to_start_screen_buffer
            LDY #11; col
            JSR add_to_start_screen_buffer
            LDY #12; col
            JSR add_to_start_screen_buffer
            LDY #13; col
            JSR add_to_start_screen_buffer
            LDY #14; col
            JSR add_to_start_screen_buffer
            LDY #17; col
            JSR add_to_start_screen_buffer
            LDY #18; col
            JSR add_to_start_screen_buffer    
            LDY #19; col
            JSR add_to_start_screen_buffer    
            LDY #20; col
            JSR add_to_start_screen_buffer    
            LDY #21; col
            JSR add_to_start_screen_buffer    
            LDY #22; col
            JSR add_to_start_screen_buffer    
            LDY #23; col
            JSR add_to_start_screen_buffer    
            LDY #24; col
            JSR add_to_start_screen_buffer    
            LDY #25; col
            JSR add_to_start_screen_buffer    
            LDY #26; col
            JSR add_to_start_screen_buffer    
            LDY #27; col
            JSR add_to_start_screen_buffer    
            LDY #28; col
            JSR add_to_start_screen_buffer    
            LDY #29; col
            JSR add_to_start_screen_buffer

        ;ROW 3
        LDA #3
        LDX #0  
            LDY #1; col
            JSR add_to_start_screen_buffer
            LDY #2; col
            JSR add_to_start_screen_buffer
        LDX #2 ; Buffer 3 == letters
            LDY #3
            JSR add_to_start_screen_buffer
            LDY #4
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #5
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #6
            JSR add_to_start_screen_buffer
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
            LDY #10
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #14
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #19
            JSR add_to_start_screen_buffer
            LDY #20
            JSR add_to_start_screen_buffer
            LDY #21
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #24
            JSR add_to_start_screen_buffer
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer
            LDY #27
            JSR add_to_start_screen_buffer
            LDY #28
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #29
            JSR add_to_start_screen_buffer

        ;ROW 4
        LDA #4
        LDX #0
            LDY #1
            JSR add_to_start_screen_buffer
            LDY #2
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #3
            JSR add_to_start_screen_buffer
            LDY #4
            JSR add_to_start_screen_buffer
            LDY #5
            JSR add_to_start_screen_buffer
            LDY #6
            JSR add_to_start_screen_buffer
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #10
            JSR add_to_start_screen_buffer
            LDY #11
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #12
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #13
            JSR add_to_start_screen_buffer
            LDY #14
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #16
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #17
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #19
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #20
            JSR add_to_start_screen_buffer
            LDY #21
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #24
            JSR add_to_start_screen_buffer
            LDY #25
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #26
            JSR add_to_start_screen_buffer
            LDY #27
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #28
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #29
            JSR add_to_start_screen_buffer
            LDY #30
            JSR add_to_start_screen_buffer

        ;ROW 5
        LDA #5
        LDX #0
            LDY #1
            JSR add_to_start_screen_buffer
            LDY #2
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #3
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #4
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #5
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #6
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #10
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #14
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #19
            JSR add_to_start_screen_buffer
            LDY #20
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #21
            JSR add_to_start_screen_buffer
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
            LDY #24
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #27
            JSR add_to_start_screen_buffer
            LDY #28
            JSR add_to_start_screen_buffer
            LDY #29
            JSR add_to_start_screen_buffer
            LDY #30
            JSR add_to_start_screen_buffer

        ;ROW 6
        LDA #6
        LDX #0
            LDY #1
            JSR add_to_start_screen_buffer
            LDY #2
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #3
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #4
            JSR add_to_start_screen_buffer
            LDY #5
            JSR add_to_start_screen_buffer
            LDY #6
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #10
            JSR add_to_start_screen_buffer
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
            LDY #14
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
            LDY #17
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #19
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #20
            JSR add_to_start_screen_buffer
            LDY #21
            JSR add_to_start_screen_buffer
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
            LDY #24
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #27
            JSR add_to_start_screen_buffer
            LDY #28
            JSR add_to_start_screen_buffer
            LDY #29
            JSR add_to_start_screen_buffer
            LDY #30
            JSR add_to_start_screen_buffer
        
        ;ROW 7
        LDA #7
        LDX #0
            LDY #1
            JSR add_to_start_screen_buffer
            LDY #2
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #3
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #4
            JSR add_to_start_screen_buffer
            LDY #5
            JSR add_to_start_screen_buffer
            LDY #6
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #10
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #14
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #19
            JSR add_to_start_screen_buffer
            LDY #20
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #21
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
            LDY #24
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #25
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #26
            JSR add_to_start_screen_buffer
            LDY #27
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #28
            JSR add_to_start_screen_buffer
        LDX #0
            LDY #29
            JSR add_to_start_screen_buffer

        ;Row 8
        LDA #8
        LDX #1
            LDY #2
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #3
            JSR add_to_start_screen_buffer
        LDX #0 ; Buffer at idx 0 is now full ! use idx 1
            LDY #4
            JSR add_to_start_screen_buffer
            LDY #5
            JSR add_to_start_screen_buffer
            LDY #6
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #7
            JSR add_to_start_screen_buffer
        LDX #1
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #10
            JSR add_to_start_screen_buffer
        LDX #1
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #14
            JSR add_to_start_screen_buffer
        LDX #1
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #19
            JSR add_to_start_screen_buffer
            LDY #20
            JSR add_to_start_screen_buffer
            LDY #21
            JSR add_to_start_screen_buffer
        LDX #1
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
        LDX #2
            LDY #24
            JSR add_to_start_screen_buffer
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer
            LDY #27
            JSR add_to_start_screen_buffer
            LDY #28
            JSR add_to_start_screen_buffer
        LDX #1
            LDY #29
            JSR add_to_start_screen_buffer

        ;Row 9
        LDA #9
        LDX #1
            LDY #2
            JSR add_to_start_screen_buffer
            LDY #3
            JSR add_to_start_screen_buffer
            LDY #4
            JSR add_to_start_screen_buffer
            LDY #7
            JSR add_to_start_screen_buffer
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
            LDY #10
            JSR add_to_start_screen_buffer
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
            LDY #14
            JSR add_to_start_screen_buffer
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #19
            JSR add_to_start_screen_buffer
            LDY #20
            JSR add_to_start_screen_buffer
            LDY #21
            JSR add_to_start_screen_buffer
            LDY #22
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
            LDY #24
            JSR add_to_start_screen_buffer
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer
            LDY #27
            JSR add_to_start_screen_buffer
            LDY #28
            JSR add_to_start_screen_buffer
            LDY #29
            JSR add_to_start_screen_buffer

        ;Row 10
        LDA #10
        LDX #1
            LDY #8
            JSR add_to_start_screen_buffer
            LDY #9
            JSR add_to_start_screen_buffer
            LDY #10
            JSR add_to_start_screen_buffer
            LDY #11
            JSR add_to_start_screen_buffer
            LDY #12
            JSR add_to_start_screen_buffer
            LDY #13
            JSR add_to_start_screen_buffer
            LDY #14
            JSR add_to_start_screen_buffer
            LDY #15
            JSR add_to_start_screen_buffer
            LDY #16
            JSR add_to_start_screen_buffer
            LDY #17
            JSR add_to_start_screen_buffer
            LDY #18
            JSR add_to_start_screen_buffer
            LDY #23
            JSR add_to_start_screen_buffer
            LDY #24
            JSR add_to_start_screen_buffer
            LDY #25
            JSR add_to_start_screen_buffer
            LDY #26
            JSR add_to_start_screen_buffer

    RTS
.endproc


; one step of updating the title
.proc step_title_update
    BUFFER_3: 
        LDA MAZE_BUFFER + 2
        CMP #0
        BNE :+
            JMP BUFFER_1
        :
        LDX #2
        JSR get_random_start_screen_buffer_tile
        add_to_changed_tiles_buffer y_val, x_val, #FRONTIER_WALL_TILE

        LDX #2
        LDY b_val 
        JSR remove_from_start_screen_buffer    

        LDA MAZE_BUFFER + 2
        CMP #0
        BNE :+
            JMP BUFFER_1
        :
        LDX #2
        JSR get_random_start_screen_buffer_tile
        add_to_changed_tiles_buffer y_val, x_val, #FRONTIER_WALL_TILE
            LDA y_val
            JSR enqueue
            LDA x_val 
            JSR enqueue
        LDX #2
        LDY b_val 
        JSR remove_from_start_screen_buffer   

        RTS

    BUFFER_1: 
        LDA MAZE_BUFFER
        CMP #0
        BNE :+
            JMP BUFFER_2
        :
        LDX #0
        JSR get_random_start_screen_buffer_tile
            LDA y_val
            JSR enqueue
            LDA x_val 
            JSR enqueue
        add_to_changed_tiles_buffer y_val, x_val, #PATH_TILE_1

        LDX #0
        LDY b_val 
        JSR remove_from_start_screen_buffer

        LDA MAZE_BUFFER
        CMP #0
        BNE :+
            JMP BUFFER_2
        :
        LDX #0
        JSR get_random_start_screen_buffer_tile
        add_to_changed_tiles_buffer y_val, x_val, #PATH_TILE_1

        LDX #0
        LDY b_val 
        JSR remove_from_start_screen_buffer

    BUFFER_2: 
        LDA MAZE_BUFFER + 1
        CMP #0
        BNE :+
            RTS
        :
        LDX #1
        JSR get_random_start_screen_buffer_tile
        add_to_changed_tiles_buffer y_val, x_val, #PATH_TILE_1

        LDX #1
        LDY b_val 
        JSR remove_from_start_screen_buffer   

    RTS
.endproc