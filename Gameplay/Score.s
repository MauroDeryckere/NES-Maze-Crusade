;*****************************************************************
; Score system
; high byte and low byte are manually capped to #99, not #$99
; low byte represents the tens and single digits, while high byte represents the hundreds and thousands
; max value of is the max 4 digit decimal number 9999
;*****************************************************************.
.segment "CODE"
; adds value in A to the total score
; assumes no more than 99 (added 00 makes this 9900) will be added to score at once 
; to add more just do it in multiple steps
.proc add_score
    CLC
    ADC score
    STA score
    CMP #99
    BCC @skip

    SEC
    SBC #100
    INC score + 1
    LDA score + 1
    CMP #99
    BCC @skip

    SEC
    SBC #100
    STA score + 1
    INC score + 2
    LDA score + 2
    CMP #99
    BCC @skip
    SEC
    SBC #100
    STA score + 2

    ; set update flag - score changed
    @skip: 
        LDA #1
        STA should_update_score
        RTS
.endproc

; subtracts whatever is loaded in A form the score
; assumes no more than 99 (added 00 makes this 9900) will be removed from the score at once 
; to remove more just do it in multiple steps
.proc sub_score
    STA temp
    SEC
    LDA score
    SBC temp
    STA score
    BCS @skip

    CLC 
    ADC #100
    STA score
    DEC score + 1
    BCS @skip

    CLC
    LDA score + 1
    ADC #100
    STA score + 1
    DEC score + 2 
    BCS @skip

    ; ensure score cant be less than 0
    LDA #0
    STA score + 2
    STA score + 1
    STA score 

    @skip: 
        LDA #1
        STA should_update_score
        RTS
.endproc
;*****************************************************************
