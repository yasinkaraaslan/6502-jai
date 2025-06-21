// This is a very simple 6502 emulation module that executes the given instruction by using a lookup table of procedures.
// It doesn't count cycles or anything, but you can modify it to do so.

MEMORY_SIZE_6502 :: 64 * 1024;
Machine_6502 :: struct {
    memory: []u8;
    a, x, y, sp: u8;
    pc: u16;
    flags: Status_Flags;
}

Status_Flags :: enum_flags u8 #specified {
    Carry :: 0x1;
    Zero :: 0x2;
    Interrupt_Disable :: 0x4;
    Decimal :: 0x8; // Most 6502 variants ignore this.
    B :: 0x10;
    Unused ::  0x20; // Always 1
    Overflow :: 0x40;
    Negative :: 0x80;
}

init :: (using machine: *Machine_6502) {
    memory.data = alloc(MEMORY_SIZE_6502);
    memory.count = MEMORY_SIZE_6502;
    flags = .Unused;
}
deinit :: (using machine: *Machine_6502) {
    free(memory.data);
    memory.count = 0;
}

// We look for the first byte and decide which instruction we should execute based on the table.
// We hope that the user knows what they are doing and has provided enough bytes for the specified
// instruction.
execute_instruction :: (machine: *Machine_6502, data: []u8) {
    instruction_proc := INSTRUCTION_TABLE[data[0]];
    assert(instruction_proc != null, "Instruction 0x% is not available.", FormatInt.{value=data[0], base=16, minimum_digits=2});

    instruction_proc(machine, data);
}

#scope_module
#import "Basic"; // for alloc
#load "instructions.jai";

Instruction_Proc :: #type (machine: *Machine_6502, data: []u8);

// Column specifies the high byte while row specifies the low byte.
// https://www.masswerk.at/6502/6502_instruction_set.html
INSTRUCTION_TABLE :: Instruction_Proc.[
//  0x0,     0x1,           0x2,     0x3,  0x4,       0x5,       0x6,       0x7,  0x8,       0x9,       0xA,  0xB,  0xC,     0xD,       0xE,     0xF
    null,    ora_x_idx_ind, null,    null, null,      ora_zpg,   null,      null, null,      ora_imm,   null, null, null,    ora_abs,   null,      null, // 0x0
    null,    ora_ind_y_idx, null,    null, null,      ora_zpg_x, null,      null, null,      ora_abs_y, null, null, null,    ora_abs_x, null,      null, // 0x1
    null,    and_x_idx_ind, null,    null, bit_zpg,   and_zpg,   null,      null, null,      and_imm,   null, null, bit_abs, and_abs,   null,      null, // 0x2
    null,    and_ind_y_idx, null,    null, null,      and_zpg_x, null,      null, null,      and_abs_y, null, null, null,    and_abs_x, null,      null, // 0x3
    null,    eor_x_idx_ind, null,    null, null,      eor_zpg,   null,      null, null,      eor_imm,   null, null, null,    eor_abs,   null,      null, // 0x4
    null,    eor_ind_y_idx, null,    null, null,      eor_zpg_x, null,      null, null,      eor_abs_y, null, null, null,    eor_abs_x, null,      null, // 0x5
    null,    adc_x_idx_ind, null,    null, adc_zpg,   null,      null,      null, null,      adc_imm,   null, null, null,    adc_abs,   null,      null, // 0x6
    null,    adc_ind_y_idx, null,    null, adc_zpg_x, null,      null,      null, null,      adc_abs_y, null, null, null,    adc_abs_x, null,      null, // 0x7
    null,    sta_x_idx_ind, null,    null, sty_zpg,   sta_zpg,   stx_zpg,   null, null,      null,      txa,  null, sty_abs, sta_abs,   stx_abs,   null, // 0x8
    null,    sta_ind_y_idx, null,    null, sty_zpg_x, sta_zpg_x, stx_zpg_y, null, tya,       sta_abs_y, txs,  null, null,    sta_abs_x, null,      null, // 0x9
    ldy_imm, lda_x_idx_ind, ldx_imm, null, ldy_zpg,   lda_zpg,   ldx_zpg,   null, tay,       lda_imm,   tax,  null, null,    lda_abs,   ldx_abs,   null, // 0xA
    null,    lda_ind_y_idx, null,    null, ldy_zpg_x, lda_zpg_x, ldx_zpg_y, null, null,      lda_abs_y, tsx,  null, null,    lda_abs_x, ldx_abs_y, null, // 0xB
    cpy_imm, cmp_x_idx_ind, null,    null, cpy_zpg,   cmp_zpg,   null,      null, cmp_imm,   null,      null, null, cpy_abs, cmp_abs,   null,      null, // 0xC
    null,    cmp_ind_y_idx, null,    null, null,      cmp_zpg_x, null,      null, cmp_abs_y, null,      null, null, null,    cmp_abs_x, null,      null, // 0xD
    cpx_imm, null,          null,    null, cpx_zpg,   null,      null,      null, null,      null,      nop,  null, cpx_abs, null,      null,      null, // 0xE
    null,    null,          null,    null, null,      null,      null,      null, null,      null,      null, null, null,    null,      null,      null, // 0xF
];
