; Simple Pseudo Random number generation
; takes the current random seed and adjusts it based on the current frame
; if this adjustment happens to be 0 its incremented to ensure we never end up with a random seed of 0 (may cause issues in same cases)
.segment "CODE"
.proc random_number_generator
    @RNG:
        LDA random_seed
        EOR frame_counter ; XOR with a feedback value

        BNE :+
        ; If the random seed is 0 -> increase to 1
            INC random_seed ; ensure its non zero
        :
        STA random_seed  ; Store the new seed
    RTS 
.endproc

; fast routine to divide the value in A by 10, result placed in X as decimal tens
; remainder (decimal ones) placed in A
.proc dec99_to_bytes
    LDX #0
    CMP #50
    BCC @try_20
    SBC #50
    LDX #5
    BNE @try_20

    @div_20: 
        INX
        INX 
        SBC #20

    @try_20:    
        CMP #20
        BCS @div_20

    @try_10: 
        CMP #10
        BCC @done 
        SBC #10
        INX

    @done: 

    RTS
.endproc
