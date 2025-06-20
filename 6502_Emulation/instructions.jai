nop :: inline (machine: *Machine_6502, data: []u8) {
    // You may want to use x86 nop instruction if you want to be fancy.
}

reset_flags :: inline (flags: *Status_Flags, to_reset: Status_Flags) {
    flags.* &= ~(to_reset);
}

// Loads
load_imm :: inline (register: *u8, flags: *Status_Flags, data: []u8) {
    reset_flags(flags, .Zero | .Negative);
    
    // We hardcode the flags for now, in the future we may want to use 
    // assembly to cast x86 flags to 6502. I guess that should be faster.
    if data[1] == 0       flags.* |= .Zero;
    else if data[1] > 127 flags.* |= .Negative;
    register.* = data[1];
}

lda_imm :: inline (machine: *Machine_6502, data: []u8) {
    // Clear the related flags.
    load_imm(*machine.a, *machine.flags, data);
}

ldx_imm :: inline (machine: *Machine_6502, data: []u8) {
    load_imm(*machine.x, *machine.flags, data);
}

ldy_imm :: inline (machine: *Machine_6502, data: []u8) {
    load_imm(*machine.y, *machine.flags, data);
}


// Compares
compare_imm :: inline (register: u8, flags: *Status_Flags, data: []u8) {
    reset_flags(*flags, .Zero | .Negative | .Carry);
    if register >= data[1]  flags.* |= .Carry;
    if register == data[1]  flags.* |= .Zero;
    if register <  data[1]  flags.* |= .Negative;
}

cmp_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare_imm(machine.a, *machine.flags, data);
}

cpx_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare_imm(machine.x, *machine.flags, data);
}

cpy_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare_imm(machine.y, *machine.flags, data);
}

