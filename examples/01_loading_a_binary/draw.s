; You can use vasm to compile this
; vasm6502_oldstyle draw.s -Fbin -dotdir -o draw.bin

    .org $8000
    lda #$ff
    sta $01
loop:
    lda #$55
    sta $0f

    lda #$aa
    jmp loop

    .org $fffc
    .word $8000 ; Reset vector
    .word $8000 ; Interrupt vector, same for now