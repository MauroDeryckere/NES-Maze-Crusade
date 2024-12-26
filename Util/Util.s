;*****************************************************************
; Simple Random number generation
;*****************************************************************
.segment "CODE"
.proc random_number_generator
    @RNG:
        LDA random_seed  ; Load the current seed
        BNE :+
            INC random_seed ; ensure its non zero
        :

        set_Carry_to_highest_bit_A ;to make sure the rotation happens properly (makes odd numbers possible)
        ROL             ; Shift left
        BCC @NoXor       ; Branch if no carry
        EOR #$B4        ; XOR with a feedback value (tweak as needed)

    @NoXor:
        STA random_seed  ; Store the new seed
        RTS             ; Return

.endproc
;*****************************************************************