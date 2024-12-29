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
