nop :: inline (machine: *Machine_6502, data: []u8) {
    // You may want to use x86 nop instruction if you want to be fancy.
}

reset_flags :: inline (flags: *Status_Flags, to_reset: Status_Flags) {
    flags.* &= ~(to_reset);
}

little_endian :: inline (address: *u8) -> u16 {
    return (cast(*u16)address).*;
}

// --- Loads ---
load :: inline (register: *u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Zero | .Negative);
    
    // We hardcode the flags for now, in the future we may want to use 
    // assembly to cast x86 flags to 6502. I guess that should be faster.
    if value == 0       flags.* |= .Zero;
    else if value > 127 flags.* |= .Negative;
    register.* = value;
}

lda_imm :: inline (machine: *Machine_6502, data: []u8) {
    // Clear the related flags.
    load(*machine.a, data[1], *machine.flags);
}

ldx_imm :: inline (machine: *Machine_6502, data: []u8) {
    load(*machine.x, data[1], *machine.flags);
}

ldy_imm :: inline (machine: *Machine_6502, data: []u8) {
    load(*machine.y, data[1], *machine.flags);
}


// --- Compares ---
compare :: inline (register: u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Zero | .Negative | .Carry);
    if register >= value  flags.* |= .Carry;
    if register == value  flags.* |= .Zero;
    if register <  value  flags.* |= .Negative;
}

cmp_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare(machine.a, data[1], *machine.flags);
}

cpx_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare(machine.x, data[1], *machine.flags);
}

cpy_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare(machine.y, data[1], *machine.flags);
}

// --- Stores ---
sta_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1]] = a;
}

sta_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1] + x] = a;
}

sta_abs :: inline (using machine: *Machine_6502, data: []u8) {
    memory[little_endian(*data[1])] = a;
}

sta_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    index := little_endian(*data[1]);
    memory[index + x] = a;
}

sta_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    index := little_endian(*data[1]);
    memory[index + y] = a;
}

sta_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    load_index := cast(u16)data[1] + cast(u16)x;
    store_index := little_endian(*memory[load_index]);
    memory[store_index] = a;
}

sta_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    store_index := little_endian(*memory[data[1]]) + y;
    memory[store_index] = a;
}

