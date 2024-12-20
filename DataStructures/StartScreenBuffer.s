.segment "CODE"
; Row in A
; Col in Y
; Which buffer in X
; Buffer 0-2
; X is not affected! 
; A is restored! 

.proc add_to_start_screen_buffer
    STY temp
    STA a_val ; only necessary because we want a restored

    ; buffer 1
    CPX #0
    BNE :+
    LDY maze_buffer
    STA START_SCREEN_BUFFER_1, Y
    INY
    LDA temp
    STA START_SCREEN_BUFFER_1, Y

    INC maze_buffer
    INC maze_buffer

    LDA a_val
    RTS

    : ; buffer 2
    CPX #1
    BNE :+
    LDY maze_buffer + 1
    STA START_SCREEN_BUFFER_2, Y
    INY
    LDA temp
    STA START_SCREEN_BUFFER_2, Y
    
    INC maze_buffer + 1
    INC maze_buffer + 1

    LDA a_val
    RTS

    : ; buffer 3
    LDY maze_buffer + 2
    STA START_SCREEN_BUFFER_3, Y
    INY
    LDA temp
    STA START_SCREEN_BUFFER_3, Y
    
    INC maze_buffer + 2
    INC maze_buffer + 2
    
    LDA a_val
    RTS
.endproc

; Offset in A
; Offset 0-127
; Which buffer in X
; Buffer 0-2
; X is not affected! 

; return: row in y_val, col in x_val
.proc get_start_screen_buffer
    ASL
    TAY

    ; buffer 1
    CPX #0
    BNE :+
    LDA START_SCREEN_BUFFER_1, Y
    STA y_val
    INY
    LDA START_SCREEN_BUFFER_1, Y
    STA x_val
    RTS

    : ; buffer 2
    CPX #1
    BNE :+
    LDA START_SCREEN_BUFFER_2, Y
    STA y_val
    INY
    LDA START_SCREEN_BUFFER_2, Y
    STA x_val
    RTS

    : ; buffer 3
    LDA START_SCREEN_BUFFER_3, Y
    STA y_val
    INY
    LDA START_SCREEN_BUFFER_3, Y
    STA x_val
    RTS
.endproc

; Which buffer in X
; Buffer 0-2
; Offset in Y
; Offset 0-127
.proc remove_from_start_screen_buffer
    TYA
    ASL

    ; buffer 1
    CPX #0
    BNE :+
    TAX ; X is now our offset
    INX

    LDY maze_buffer
    DEY

    LDA START_SCREEN_BUFFER_1, Y
    STA START_SCREEN_BUFFER_1, X
    DEY
    DEX
    LDA START_SCREEN_BUFFER_1, Y
    STA START_SCREEN_BUFFER_1, X

    DEC maze_buffer
    DEC maze_buffer
    RTS
    ; buffer 2
    :
    CPX #1
    BNE :+
    TAX
    INX

    LDY maze_buffer + 1
    DEY

    LDA START_SCREEN_BUFFER_2, Y
    STA START_SCREEN_BUFFER_2, X
    DEY
    DEX
    LDA START_SCREEN_BUFFER_2, Y
    STA START_SCREEN_BUFFER_2, X

    DEC maze_buffer + 1
    DEC maze_buffer + 1
    RTS
    ; buffer 3
    :
    TAX
    INX

    LDY maze_buffer + 2
    DEY

    LDA START_SCREEN_BUFFER_3, Y
    STA START_SCREEN_BUFFER_3, X
    DEY
    DEX
    LDA START_SCREEN_BUFFER_3, Y
    STA START_SCREEN_BUFFER_3, X

    DEC maze_buffer + 2
    DEC maze_buffer + 2
    RTS
.endproc

; returns offset in b_val, row in y_val en col in x_val
; Which buffer in X
; Buffer 0-2
.proc get_random_start_screen_buffer_tile
    ;random number for offset
    JSR random_number_generator

    CPX #0
    BNE @N
        ;clamp the offset
        LDA maze_buffer
        LSR
        STA temp
        modulo random_seed, temp
        LDX #0
        JMP @END
    @N:
    CPX #1
    BNE @NN
        LDA maze_buffer + 1
        LSR
        STA temp
        ;clamp the offset
        modulo random_seed, temp
        LDX #1
        JMP @END
    @NN:
        LDA maze_buffer + 2
        LSR
        STA temp
        ;clamp the offset
        modulo random_seed, temp
        LDX #2

    @END: 
        STA b_val
        JSR get_start_screen_buffer 
        RTS
.endproc
