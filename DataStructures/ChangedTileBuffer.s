; Vblank buffer contains the row and column of the tile on the background
; Only tiles from the first 4 rows (0-3) and first 8 cols (0-7) can currently be set using this macro.
; Internal info:
; F: flag bit - not in use currently other than to check if it is an invalid or valid IDX in the buffer
; T: tile bit
; R: background row bit
; C: background col bit
; Row: FTTR RRRR
; Col: TTTC CCCC
;*****************************************************************
.macro add_to_changed_tiles_buffer Row, Col, TileID
    LDY #0
    .local loop
    loop:

        LDA changed_tiles_buffer, y
        CMP #$FF
        BEQ add_vals
        
        INY
        INY

        CPY #CHANGED_TILES_BUFFER_SIZE - 2
        BNE loop

    .local add_vals
    add_vals:
        LDA TileID

        ;convert tileID to row
        ;divide by 16 to get the row (16 tiles per row in sheet)
        ; (0011 1111) -> (0000 0011)
        ; LSR
        ; LSR
        ; LSR
        ; LSR
        
        ; ;shift to the correct location
        ; ; 0000 0011 -> 0110 0000
        ; ASL			
        ; ASL			
        ; ASL				
        ; ASL	
        ; ASL	

        ;but the optimised version allows us to just mask and shift once
        AND #%11111000
        ASL	

        ORA Row
        STA changed_tiles_buffer, y
        INY

        ;convert tileID to Column
        LDA TileID
        AND #%00000111
        ; shift to the correct location
        ; 0000 0111 -> 1110 0000
        ASL			
        ASL			
        ASL			
        ASL	
        ASL

        ORA Col
        STA changed_tiles_buffer, y
.endmacro
;*****************************************************************