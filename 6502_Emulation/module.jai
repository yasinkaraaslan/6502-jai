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
    flags = .UNUSED;
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
    assert(instruction_proc != null, "Instruction is not available.");

    instruction_proc(machine, data);
}

#scope_module
#import "Basic"; // for alloc
#load "instructions.jai";

Instruction_Proc :: #type (machine: *Machine_6502, data: []u8);

// Column specifies the high byte while row specifies the low byte.
// https://www.masswerk.at/6502/6502_instruction_set.html
INSTRUCTION_TABLE :: Instruction_Proc.[
//  0x0,  0x1,  0x2,  0x3,  0x4,  0x5,  0x6,  0x7,  0x8,  0x9,     0xA,  0xB,  0xC,  0xD,  0xE,  0xF
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x0
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x1
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x2
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x3
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x4
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x5
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x6
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x7
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x8
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0x9
    ldy_imm, null, ldx_imm, null, null, null, null, null, null,    lda_imm, null, null, null, null, null, null, // 0xA
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0xB
    cpy_imm, null, null,    null, null, null, null, null, cmp_imm, null,    null, null, null, null, null, null, // 0xC
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0xD
    cpx_imm, null, null,    null, null, null, null, null, null,    null,    nop,  null, null, null, null, null, // 0xE
    null,    null, null,    null, null, null, null, null, null,    null,    null, null, null, null, null, null, // 0xF
];
