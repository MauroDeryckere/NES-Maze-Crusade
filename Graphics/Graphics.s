;*****************************************************************
; Graphics utility functions
;*****************************************************************
.proc wait_frame
	INC nmi_ready
@loop:
	LDA nmi_ready
	BNE @loop
	RTS
.endproc

; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
.proc ppu_update
    LDA ppu_ctl0
	ORA #VBLANK_NMI
	STA ppu_ctl0
	STA PPU_CONTROL
	LDA ppu_ctl1
	ORA #OBJ_ON|BG_ON
	STA ppu_ctl1
	JSR wait_frame
	RTS
.endproc

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_VRAM_IO)
.proc ppu_off
    JSR wait_frame
	LDA ppu_ctl0
	AND #%01111111
	STA ppu_ctl0
	STA PPU_CONTROL
	LDA ppu_ctl1
	AND #%11100001
	STA ppu_ctl1
	STA PPU_MASK
	RTS
.endproc

.segment "CODE"
.proc reset
    SEI
    LDA #0
    STA PPU_CONTROL
    STA PPU_MASK
    sta APU_DM_CONTROL
    LDA #40
    STA JOYPAD2 

    CLD
    LDX #$FF
    TXS

    wait_vblank:
        BIT PPU_STATUS
        BPL wait_vblank

        LDA #0
        LDX #0

    clear_ram:
        STA $0000, x
        STA $0100, x
        STA $0200, x
        STA $0300, x
        STA $0400, x
        STA $0500, x
        STA $0600, x
        STA $0700, x
        INX
        BNE clear_ram

        LDA #255
        LDX #0

    clear_oam:
        STA oam, x
        INX
        INX
        INX
        INX
        BNE clear_oam

    wait_vblank2:
        BIT PPU_STATUS
        BPL wait_vblank2

        LDA #%10001000
        STA PPU_CONTROL

    JMP main
.endproc

.segment "CODE"
.proc clear_nametable_0
    vram_set_address (NAME_TABLE_0_ADDRESS + 3 * 32 + 0) ; dont clear HUD row
    LDA #0
    LDY #MAP_ROWS
    @rowloop:
        LDX #SCREEN_COLS
        @columnloop:
            STA PPU_VRAM_IO
            DEX
            BNE @columnloop
    DEY
    BNE @rowloop

    ; attributes
    ; LDX #64
    ; @loop:
    ;     STA PPU_VRAM_IO
    ;     DEX
    ;     BNE @loop
    RTS
.endproc

.proc clear_nametable_1
    vram_set_address (NAME_TABLE_1_ADDRESS + 3 * 32 + 0) ; dont clear HUD row

    LDA #0
    LDY #MAP_ROWS
    @rowloop:
        LDX #SCREEN_COLS
        @columnloop:
            STA PPU_VRAM_IO
            DEX
            BNE @columnloop
        DEY
        BNE @rowloop

    ; attributes
    ; LDX #64
    ; @loop:
    ;     STA PPU_VRAM_IO
    ;     DEX
    ;     BNE @loop
    RTS
.endproc
;*****************************************************************

;*****************************************************************
; Graphics 
;*****************************************************************
.segment "CODE"
; fills the nametables with all walls (again)
.proc display_map_all_walls
    JSR ppu_off
    ;since our wall tile is at idx 0, clearing the nametable is all that's required
    JSR clear_nametable_0
    JSR clear_nametable_1

    JSR ppu_update
    RTS
.endproc

;displays a clear map
.proc display_clear_map
    JSR ppu_off
    ; Set PPU address to nametable address
    vram_set_address (NAME_TABLE_0_ADDRESS + 3 * 32 + 0)

    LDA #BLACK_TILE ; clear tile
    LDY #MAP_ROWS
    @rowloop:
        LDX #SCREEN_COLS
        @columnloop:
            STA PPU_VRAM_IO ; Write tile to PPU data
            DEX
            BNE @columnloop
        DEY
        BNE @rowloop

    vram_clear_address

    vram_set_address (NAME_TABLE_1_ADDRESS + 3 * 32 + 0)

    LDA #BLACK_TILE ; clear tile
    LDY #MAP_ROWS
    @rowloop2:
        LDX #SCREEN_COLS
        @columnloop2:
            STA PPU_VRAM_IO ; Write tile to PPU data
            DEX
            BNE @columnloop2
        DEY
        BNE @rowloop2

;    vram_clear_address

    JSR ppu_update
    RTS
.endproc

; loads nametable 0 in one go
.proc display_map_nametable_0
    JSR ppu_off

    vram_set_address (NAME_TABLE_0_ADDRESS) 
    assign_16i paddr, MAZE_BUFFER    ;load map into ppu

    ; store the "border" first
    LDY #32
    LDA #HUD_BG_TILE
    @toprow_loop: 
        STA PPU_VRAM_IO
        DEY
        BNE @toprow_loop

    LDY #0
    @rowloop:
        INY
        INY
        INY
        INY
        @byteloop:
            LDA #%10000000
            STA temp
            LDX #8
            @bitloop:
                LDA (paddr), Y
                AND temp
                CMP #0
                BEQ :+
                    LDA #PATH_TILE_1
                    STA PPU_VRAM_IO
                    JMP :++
                :
                    LDA #WALL_TILE
                    STA PPU_VRAM_IO
                :
                LSR temp
                DEX
                BNE @bitloop
            INY
            TYA
            AND #%00000100
            BNE @byteloop

        CPY #MAZE_BUFFER_SIZE
        BNE @rowloop

        JSR ppu_update

        RTS
.endproc 

; loads the second half of the map in nametable 2 to allow scrolling
.proc display_map_nametable_1
    JSR ppu_off

    vram_set_address (NAME_TABLE_1_ADDRESS) 
    assign_16i paddr, MAZE_BUFFER    ;load map into ppu

    ; store the "border" first
    LDY #32
    LDA #HUD_BG_TILE
    @toprow_loop: 
        STA PPU_VRAM_IO
        DEY
        BNE @toprow_loop

    LDY #0
    @rowloop:
        INY
        INY
        INY
        INY
        @byteloop:
            LDA #%10000000
            STA temp
            LDX #8
            @bitloop:
                LDA (paddr), Y
                AND temp
                CMP #0
                BEQ :+
                    LDA #PATH_TILE_1
                    STA PPU_VRAM_IO
                    JMP :++
                :
                    LDA #WALL_TILE
                    STA PPU_VRAM_IO
                :
                LSR temp
                DEX
                BNE @bitloop
            INY
            TYA
            AND #%00000100
            BNE @byteloop

        CPY #MAZE_BUFFER_SIZE
        BNE @rowloop

        JSR ppu_update

        RTS
.endproc 

;handles the background tiles during vblank using the buffers set in zero page
.proc draw_background
    ;update the map tiles
    LDY #0
     @maploop: 
        ;row
        LDA changed_tiles_buffer, Y
        CMP #$FF ;end of buffer check
        BEQ @done 
        STA PPU_VRAM_ADDRESS2
        
        ;col
        INY
        LDA changed_tiles_buffer, Y
        STA PPU_VRAM_ADDRESS2

        ;tile
        INY
        LDA changed_tiles_buffer, Y
        STA PPU_VRAM_IO
      
        INY
        CPY #CHANGED_TILES_BUFFER_SIZE
        BNE @maploop    
    @done: 
        JSR clear_changed_tiles_buffer
    RTS

.endproc

;*****************************************************************
; startscreen
;*****************************************************************
.proc draw_title_settings
    LDA input_game_mode
    AND #GAME_MODE_MASK
    BNE AUTO_FALSE
        vram_set_address (NAME_TABLE_0_ADDRESS + 19 * 32 + 19)
        LDA #$6A
        STA PPU_VRAM_IO
        JMP HARD_CHECK
    AUTO_FALSE:
        vram_set_address (NAME_TABLE_0_ADDRESS + 19 * 32 + 19)
        LDA #$6B
        STA PPU_VRAM_IO
    HARD_CHECK:
    LDA input_game_mode
    AND #HARD_MODE_MASK
    BNE HARD_FALSE
        vram_set_address (NAME_TABLE_0_ADDRESS + 20 * 32 + 19)
        LDA #$6A
        STA PPU_VRAM_IO
        JMP EXIT
    HARD_FALSE:
        vram_set_address (NAME_TABLE_0_ADDRESS + 20 * 32 + 19)
        LDA #$6B
        STA PPU_VRAM_IO
    EXIT:
    RTS
.endproc

.segment "CODE"
.proc display_Start_screen
    ; Write top border
    vram_set_address (NAME_TABLE_0_ADDRESS + 17 * 32 + 11)
    assign_16i paddr, top_border
    jsr write_text

    ; Write play button
    vram_set_address (NAME_TABLE_0_ADDRESS + 18 * 32 + 11)
    assign_16i paddr, play_text
    jsr write_text

    ; Write auto button
    vram_set_address (NAME_TABLE_0_ADDRESS + 19 * 32 + 11)
    assign_16i paddr, auto_text
    jsr write_text

    ; Write hard button
    vram_set_address (NAME_TABLE_0_ADDRESS + 20 * 32 + 11)
    assign_16i paddr, hard_text
    jsr write_text

    ; Write bottom border
    vram_set_address (NAME_TABLE_0_ADDRESS + 21 * 32 + 11)
    assign_16i paddr, bottom_border
    jsr write_text
	RTS
.endproc

.segment "CODE"
.proc write_text
    ldy #0
    @loop:
        lda (paddr),y ; get the byte at the current source address
        beq exit ; exit when we encounter a zero in the text
        SEC
        SBC #$11
        sta PPU_VRAM_IO ; write the byte to video memory
        iny
        jmp @loop
    exit:
	rts
.endproc

; .proc draw_title
;     ; LDA temp_player_collumn
    
;     ; CMP #1
;     ; BEQ @p0
;     ; CMP #2
;     ; BEQ @p1
;     ; CMP #3
;     ; BNE :+
;     ;     JMP @p2
;     ; :
;     ; CMP #4
;     ; BNE :+
;     ;     JMP @p3
;     ; :
;     ; CMP #5
;     ; BNE :+
;     ;     JMP @p4
;     ; :

;     ; RTS

;     @p0:
;         vram_set_address (NAME_TABLE_0_ADDRESS + 1 * 32 + 1)
;         assign_16i paddr, titlebox_line_1
;         JSR write_text
;         vram_set_address (NAME_TABLE_0_ADDRESS + 2 * 32 + 1)
;         assign_16i paddr, titlebox_line_2
;         JSR write_text

;     ;RTS
;     @p1: 
;         vram_set_address (NAME_TABLE_0_ADDRESS + 3 * 32 + 1)
;         assign_16i paddr, title_line_1
; 	    JSR write_text 
;         vram_set_address (NAME_TABLE_0_ADDRESS + 4 * 32 + 1)
;         assign_16i paddr, title_line_2
;         JSR write_text 
;     ;RTS
;     @p2: 
;         vram_set_address (NAME_TABLE_0_ADDRESS + 5 * 32 + 1)
;         assign_16i paddr, title_line_3
;         JSR write_text
;         vram_set_address (NAME_TABLE_0_ADDRESS + 6 * 32 + 1)
;         assign_16i paddr, title_line_4
;         JSR write_text
;     ;RTS
;     @p3: 
;         vram_set_address (NAME_TABLE_0_ADDRESS + 7 * 32 + 1)
;         assign_16i paddr, title_line_5
;         JSR write_text
;         vram_set_address (NAME_TABLE_0_ADDRESS + 8 * 32 + 1)
;         assign_16i paddr, title_line_6
;         JSR write_text
;     ;RTS
;     @p4: 
;         vram_set_address (NAME_TABLE_0_ADDRESS + 9 * 32 + 1)
;         assign_16i paddr, titlebox_line_3
;         JSR write_text
;         vram_set_address (NAME_TABLE_0_ADDRESS + 10 * 32 + 1)
;         assign_16i paddr, titlebox_line_4
;         JSR write_text

;         LDA #1
;         STA has_started
    
;     RTS

; .endproc

; #BLACK_TILE = deciml 16
top_border:
    .byte $83, $82, $82, $82, $82, $82, $82, $82, $82, $86, 0
play_text:
    .byte $81, 16, 16, "p", "l", "a", "y", 16, 16, $85, 0
auto_text:
    .byte $81, 16, 16, "a", "u", "t", "o", 16, $7A, $85, 0
hard_text:
    .byte $81, 16, 16, "h", "a", "r", "d", 16, $7A, $85, 0
bottom_border:
    .byte $84, $87, $87, $87, $87, $87, $87, $87, $87, $88, 0

; titlebox_line_1:
; .byte $11,$15,  $11, $11, $17, $17, $17,  $11,$11,    $17, $17, $15, $15, $11,    $11,$11,    $15, $11, $11, $15, $15,    $11,$11,    $15, $11, $15, $11, $11,  $11,$11, 0
; titlebox_line_2:
; .byte $11,$15,  $15, $15, $15, $17, $17,  $15,$15,    $15, $17, $17, $15, $15,    $11,$11,    $15, $15, $15, $15, $15,    $15,$15,    $15, $16, $16, $15, $15,  $15,$11, 0

; title_line_1: 
; .byte $15,$15,  $14, $14, $15, $14, $14,  $15,$15,    $15, $14, $14, $14, $15,    $11,$15,    $14, $14, $14, $14, $14,    $15,$15,    $14, $14, $14, $14, $14,  $15,$11, 0
; title_line_2: 
; .byte $17,$15,  $14, $14, $14, $14, $14,  $17,$17,    $14, $14, $15, $14, $14,    $11,$15,    $14, $15, $15, $14, $14,    $17,$17,    $14, $14, $15, $15, $14,  $15,$15, 0
; title_line_3: 
; .byte $17,$15,  $14, $15, $14, $15, $14,  $15,$17,    $14, $15, $15, $15, $14,    $17,$15,    $16, $15, $14, $14, $15,    $15,$17,    $16, $14, $14, $15, $17,  $15,$15, 0
; title_line_4: 
; .byte $15,$17,  $14, $15, $15, $15, $14,  $15,$15,    $14, $14, $14, $14, $14,    $16,$16,    $16, $14, $14, $15, $15,    $15,$15,    $15, $14, $14, $17, $17,  $17,$15, 0
; title_line_5: 
; .byte $15,$15,  $14, $15, $15, $15, $14,  $15,$15,    $14, $15, $15, $16, $14,    $16,$16,    $14, $14, $15, $15, $14,    $15,$15,    $15, $14, $15, $15, $14,  $15,$11, 0
; title_line_6: 
; .byte $11,$16,  $14, $16, $15, $15, $14,  $15,$15,    $14, $15, $15, $15, $14,    $15,$16,    $14, $14, $14, $14, $14,    $15,$15,    $14, $14, $14, $14, $14,  $15,$11, 0

; titlebox_line_3:
; .byte $11,$16,  $16, $16, $11, $11, $15,  $15,$15,    $15, $15, $15, $15, $15,    $15,$15,    $15, $15, $15, $15, $15,    $15,$15,    $15, $17, $17, $17, $17,  $17,$11, 0
; titlebox_line_4:
; .byte $11,$11,  $11, $11, $11, $11, $11,  $15,$15,    $15, $15, $15, $15, $15,    $15,$15,    $15, $15, $11, $11, $11,    $11,$15,    $15, $15, $17, $17, $11,  $11,$11, 0
;*****************************************************************
