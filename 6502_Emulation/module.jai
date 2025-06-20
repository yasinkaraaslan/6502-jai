MEMORY_SIZE_6502 :: 64 * 1024;
Machine_6502 :: struct {
    memory: []u8;
    a, x, y, sp: u8;
    pc: u16;
    flags: u8;
}

init :: (using machine: *Machine_6502) {
    memory.data = alloc(MEMORY_SIZE_6502);
    memory.count = MEMORY_SIZE_6502;
}
deinit :: (using machine: *Machine_6502) {
    free(memory.data);
    memory.count = 0;
}

// We look for the first byte and decide which instruction we should execute based on the table.
// We hope that the user knows what they are doing and has provided enough bytes for the specified
// instruction.
execute_instruction :: (machine: *Machine_6502, instruction_data: []u8) {
    instruction_proc := INSTRUCTION_TABLE[instruction_data[0]];
    assert(instruction_proc != null, "Instruction is not implemented.");

    instruction_proc(machine, instruction_data);
}

#scope_module
#import "Basic"; // for alloc

Instruction_Proc :: #type (machine: *Machine_6502, instruction_data: []u8);

// Column specifies the high byte while row specifies the low byte.
INSTRUCTION_TABLE :: Instruction_Proc.[
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
];