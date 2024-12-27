.segment "CODE"
.proc display_hp_bar
    LDA #NAME_TABLE_0_ADDRESS_HIGH
    STA PPU_VRAM_ADDRESS2
    LDA #NAME_TABLE_0_ADDRESS_LOW
    STA PPU_VRAM_ADDRESS2

    LDA #HP_BAR_FILLED_LEFT
    STA PPU_VRAM_IO
    LDA #HP_BAR_FILLED_LEFT + 1
    STA PPU_VRAM_IO
    LDA #HP_BAR_LEFT+2
    STA PPU_VRAM_IO
    LDA #HP_BAR_LEFT+2
    STA PPU_VRAM_IO
    LDA #HP_BAR_LEFT+2
    STA PPU_VRAM_IO
    LDA #HP_BAR_LEFT+3
    STA PPU_VRAM_IO

    RTS
.endproc

.proc init_hp_bar
    ;TODO
    RTS
.endproc

.proc add_hp_bar_to_changed_tiles
      ; TODO
    RTS
.endproc