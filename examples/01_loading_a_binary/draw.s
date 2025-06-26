; You can use vasm to compile this
; vasm6502_oldstyle draw.s -Fbin -dotdir -o draw.bin
    .org $8000
reset:
    ldx #$0 ; we use x to denote the memory
interrupt:
    ldy #$30 ; we use y to denote color value
loop:
    sty $0, x ; store the color value to the memory
    inx

    iny
    jmp loop

    .org $fffc
    .word reset
    .word interrupt