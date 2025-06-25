#module_parameters(EXTENDED_65C02 := false);

MEMORY_SIZE_6502 :: 64 * 1024;

Machine_6502 :: struct {
    memory: []u8;
    a, x, y, sp: u8;
    pc: u16;
    flags: Status_Flags;
#if EXTENDED_65C02 {
    wait_for_interrupt: bool;
    stop_until_reset: bool;
}
}

Status_Flags :: enum_flags u8 #specified {
    Carry :: 0x1;
    Zero :: 0x2;
    Interrupt_Disable :: 0x4;
    Decimal :: 0x8; // Most 6502 variants ignore this, we do too (for now).
    Break :: 0x10;
    Unused ::  0x20; // Always 1
    Overflow :: 0x40;
    Negative :: 0x80;
}

init :: (using machine: *Machine_6502) {
    memory.data = alloc(MEMORY_SIZE_6502); // We know that this is aligned, so we don't bother with NewArray
    memory.count = MEMORY_SIZE_6502;
}

deinit :: (using machine: *Machine_6502) {
    free(memory.data);
    memory.count = 0;
}

step :: (using machine: *Machine_6502) {
    #if EXTENDED_65C02 {
        if wait_for_interrupt || stop_until_reset  return;
    }
    instruction_proc := INSTRUCTION_TABLE[memory[pc]];

    if instruction_proc == null {
        log_error("(6502) Instruction 0x% is not available.\n", FormatInt.{value=memory[pc], base=16, minimum_digits=2});
        pc += 1;
        return;
    }

    instruction_proc(machine);
}

reset :: (using machine: *Machine_6502) {
    #if EXTENDED_65C02 {
        stop_until_reset = false;
    }
    flags = .Unused | .Interrupt_Disable;
    pc = u16_le(*memory[0xFFFC]);
    if pc == 0 {
        log_error("(6502) No start address at reset vector (0xFFFC, 0xFFFD) has been found.\n");
    }
    sp = 0xFF;
    // We do not push the program-counter, maybe we should.
}

interrupt :: (using machine: *Machine_6502, hardware := false) {
    #if EXTENDED_65C02 {
        if hardware  wait_for_interrupt = false;
    }
    push_stack(pc);
    push_stack(xx flags);
    pc = u16_le(*memory[0xFFFE]); // Interrupt vector

    flags |= .Interrupt_Disable;
    if !hardware  flags |= .Break;
}

#scope_module
#import "Basic"; // for alloc
#load "instructions.jai";

Instruction_Proc :: #type (machine: *Machine_6502);

// https://www.masswerk.at/6502/6502_instruction_set.html
INSTRUCTION_TABLE :: Instruction_Proc.[
//  0x0,     0x1,           0x2,         0x3,  0x4,       0x5,       0x6,       0x7,      0x8, 0x9,       0xA,     0xB,  0xC,           0xD,       0xE,       0xF
    brk,     ora_x_idx_ind, null,        null, tsb_zpg,   ora_zpg,   asl_zpg,   rmb0_zpg, php, ora_imm,   asl_acc, null, tsb_abs,       ora_abs,   asl_abs,   bbr0, // 0x0
    bpl,     ora_ind_y_idx, ora_zpg_ind, null, trb_zpg,   ora_zpg_x, asl_zpg_x, rmb1_zpg, clc, ora_abs_y, inc_acc, null, trb_abs,       ora_abs_x, asl_abs_x, bbr1, // 0x1
    jsr_abs, and_x_idx_ind, null,        null, bit_zpg,   and_zpg,   rol_zpg,   rmb2_zpg, plp, and_imm,   rol_acc, null, bit_abs,       and_abs,   rol_abs,   bbr2, // 0x2
    bmi,     and_ind_y_idx, and_zpg_ind, null, bit_zpg_x, and_zpg_x, rol_zpg_x, rmb3_zpg, sec, and_abs_y, dec_acc, null, bit_abs_x,     and_abs_x, rol_abs_x, bbr3, // 0x3
    rti,     eor_x_idx_ind, null,        null, null,      eor_zpg,   lsr_zpg,   rmb4_zpg, pha, eor_imm,   lsr_acc, null, jmp_abs,       eor_abs,   lsr_abs,   bbr4, // 0x4
    bvc,     eor_ind_y_idx, eor_zpg_ind, null, null,      eor_zpg_x, lsr_zpg_x, rmb5_zpg, cli, eor_abs_y, phy,     null, null,          eor_abs_x, lsr_abs_x, bbr5, // 0x5
    rts,     adc_x_idx_ind, null,        null, stz_zpg,   adc_zpg,   ror_zpg,   rmb6_zpg, pla, adc_imm,   ror_acc, null, jmp_ind,       adc_abs,   ror_abs,   bbr6, // 0x6
    bvs,     adc_ind_y_idx, adc_zpg_ind, null, stz_zpg_x, adc_zpg_x, ror_zpg_x, rmb7_zpg, sei, adc_abs_y, ply,     null, jmp_abs_x_ind, adc_abs_x, ror_abs_x, bbr7, // 0x7
    bra,     sta_x_idx_ind, null,        null, sty_zpg,   sta_zpg,   stx_zpg,   smb0_zpg, dey, bit_imm,   txa,     null, sty_abs,       sta_abs,   stx_abs,   bbs0, // 0x8
    bcc,     sta_ind_y_idx, sta_zpg_ind, null, sty_zpg_x, sta_zpg_x, stx_zpg_y, smb1_zpg, tya, sta_abs_y, txs,     null, stz_abs,       sta_abs_x, stz_abs_x, bbs1, // 0x9
    ldy_imm, lda_x_idx_ind, ldx_imm,     null, ldy_zpg,   lda_zpg,   ldx_zpg,   smb2_zpg, tay, lda_imm,   tax,     null, ldy_abs,       lda_abs,   ldx_abs,   bbs2, // 0xA
    bcs,     lda_ind_y_idx, lda_zpg_ind, null, ldy_zpg_x, lda_zpg_x, ldx_zpg_y, smb3_zpg, clv, lda_abs_y, tsx,     null, ldy_abs_x,     lda_abs_x, ldx_abs_y, bbs3, // 0xB
    cpy_imm, cmp_x_idx_ind, null,        null, cpy_zpg,   cmp_zpg,   dec_zpg,   smb4_zpg, iny, cmp_imm,   dex,     wai,  cpy_abs,       cmp_abs,   dec_abs,   bbs4, // 0xC
    bne,     cmp_ind_y_idx, cmp_zpg_ind, null, null,      cmp_zpg_x, dec_zpg_x, smb5_zpg, cld, cmp_abs_y, phx,     stp,  null,          cmp_abs_x, dec_abs_x, bbs5, // 0xD
    cpx_imm, sbc_x_idx_ind, null,        null, cpx_zpg,   sbc_zpg,   inc_zpg,   smb6_zpg, inx, sbc_imm,   nop,     null, cpx_abs,       sbc_abs,   inc_abs,   bbs6, // 0xE
    beq,     sbc_ind_y_idx, sbc_zpg_ind, null, null,      sbc_zpg_x, inc_zpg_x, smb7_zpg, sed, sbc_abs_y, plx,     null, null,          sbc_abs_x, inc_abs_x, bbs7, // 0xF
];
get_instruction_opcode :: (proc: Instruction_Proc) -> u8 {
    for INSTRUCTION_TABLE {
        if proc == it  return it_index;
    }
}