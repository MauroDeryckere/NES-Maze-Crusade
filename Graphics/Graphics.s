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

    vram_clear_address

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
                    LDA #TOPDOWN_WALL_TILE ; todo select appropriate tile
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
                    LDA #TOPDOWN_WALL_TILE ; todo select appropriate tile
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
    JSR write_consecutive_tiles

    ; Write play button
    vram_set_address (NAME_TABLE_0_ADDRESS + 18 * 32 + 11)
    assign_16i paddr, play_text
    JSR write_consecutive_tiles

    ; Write auto button
    vram_set_address (NAME_TABLE_0_ADDRESS + 19 * 32 + 11)
    assign_16i paddr, auto_text
    JSR write_consecutive_tiles

    ; Write hard button
    vram_set_address (NAME_TABLE_0_ADDRESS + 20 * 32 + 11)
    assign_16i paddr, hard_text
    JSR write_consecutive_tiles

    ; Write bottom border
    vram_set_address (NAME_TABLE_0_ADDRESS + 21 * 32 + 11)
    assign_16i paddr, bottom_border
    JSR write_consecutive_tiles
	RTS
.endproc

.segment "CODE"
.proc write_consecutive_tiles
    LDY #0
    @loop:
        LDA (paddr),y ; get the byte at the current source address
        BEQ @exit ; exit when we encounter a zero in the text
        STA PPU_VRAM_IO ; write the byte to video memory
        INY
        JMP @loop
    @exit:
	RTS
.endproc

top_border:
    .byte $72, $71, $71, $71, $71, $71, $71, $71, $71, $75, 0
play_text:
    .byte $70, $10, $10, $5F, $5B, $50, $68, $10, $10, $74, 0 ; PLAY
auto_text: 
    .byte $70, $10, $10, $50, $64, $63, $5E, $10, $10, $74, 0 ; AUTO
hard_text:
    .byte $70, $10, $10, $57, $50, $61, $53, $10, $10, $74, 0 ; HARD
bottom_border:
    .byte $73, $76, $76, $76, $76, $76, $76, $76, $76, $77, 0
;*****************************************************************
