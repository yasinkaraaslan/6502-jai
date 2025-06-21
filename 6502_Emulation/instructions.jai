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
    load(*machine.a, data[1], *machine.flags);
}

lda_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    load(*a, memory[data[1]], *machine.flags);
}

lda_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := cast(u16)data[1] + cast(u16)x;
    load(*a, memory[address], *machine.flags);
}

lda_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*a, memory[address], *machine.flags);
}

lda_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*a, memory[address + x], *machine.flags);
}

lda_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*a, memory[address + y], *machine.flags);
}

lda_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := cast(u16)data[1] + cast(u16)x;
    address := little_endian(*memory[base_address]);
    load(*a, memory[address], *machine.flags);
}

lda_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := little_endian(*memory[data[1]]);
    load(*a, memory[base_address + y], *machine.flags);
}

ldx_imm :: inline (machine: *Machine_6502, data: []u8) {
    load(*machine.x, data[1], *machine.flags);
}

ldx_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    load(*x, memory[data[1]], *machine.flags);
}

ldx_zpg_y :: inline (using machine: *Machine_6502, data: []u8) {
    load(*x, memory[data[1] + y], *machine.flags);
}

ldx_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*x, memory[address], *machine.flags);
}

ldx_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*x, memory[address + y], *machine.flags);
}

ldy_imm :: inline (machine: *Machine_6502, data: []u8) {
    load(*machine.y, data[1], *machine.flags);
}

ldy_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    load(*y, memory[data[1]], *machine.flags);
}

ldy_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    load(*y, memory[data[1] + x], *machine.flags);
}

ldy_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*y, memory[address], *machine.flags);
}

ldy_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    load(*y, memory[address + x], *machine.flags);
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
cmp_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    compare(a, memory[data[1]], *flags);
}

cmp_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := cast(u16)data[1] + cast(u16)x;
    compare(a, memory[address], *flags);
}

cmp_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    compare(a, memory[address], *flags);
}

cmp_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := little_endian(*data[1]);
    compare(a, memory[base_address + x], *flags);
}

cmp_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := little_endian(*data[1]);
    compare(a, memory[base_address + y], *flags);
}

cmp_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := cast(u16)data[1] + cast(u16)x;
    address := little_endian(*memory[base_address]);
    compare(a, memory[address], *flags);
}

cmp_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    base_address := little_endian(*memory[data[1]]);
    compare(machine.a, memory[base_address + y], *flags);
}

cpx_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare(machine.x, data[1], *machine.flags);
}

cpx_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    compare(x, memory[data[1]], *flags);
}

cpx_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    compare(x, memory[address], *flags);
}

cpy_imm :: inline (machine: *Machine_6502, data: []u8) {
    compare(machine.y, data[1], *machine.flags);
}

cpy_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    compare(y, memory[data[1]], *flags);
}

cpy_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    compare(y, memory[address], *flags);
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
    address := little_endian(*data[1]);
    memory[address + x] = a;
}

sta_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    memory[address + y] = a;
}

sta_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    load_address := cast(u16)data[1] + cast(u16)x;
    store_address := little_endian(*memory[load_address]);
    memory[store_address] = a;
}

sta_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*memory[data[1]]) + y;
    memory[address] = a;
}

stx_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1]] = x;
}

stx_zpg_y :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1] + y] = x;
}

stx_abs :: inline (using machine: *Machine_6502, data: []u8) {
    memory[little_endian(*data[1])] = x;
}

sty_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1]] = y;
}

sty_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    memory[data[1] + x] = y;
}

sty_abs :: inline (using machine: *Machine_6502, data: []u8) {
    memory[little_endian(*data[1])] = y;
}