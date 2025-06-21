// TODO(yasin): Use a metaprogram to generate these.
// Example: #run generate_instructions("lda", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Idx_Y_Ind);
#insert #run generate_instructions("lda", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "load", "a");
#insert #run generate_instructions("ldx", .Imm | .Zpg | .Zpg_Y | .Abs | .Abs_X | .Abs_Y, "load", "x");
#insert #run generate_instructions("ldy", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y, "load", "y");

#scope_file
#import "String";
Instruction_Type :: enum {
    Load;
    Store;
    Logical;
    Logical_No_Change; // Compare, bit_test
}


// We generate everything except for the implied ones.
Instruction_Variant_Flags :: enum_flags {
    Imm;
    Zpg;
    Zpg_X;
    Zpg_Y;
    Abs;
    Abs_X;
    Abs_Y;
    X_Idx_Ind;
    Ind_Y_Idx;
}

generate_instructions :: (instruction_initials: string, variants: Instruction_Variant_Flags, proc_name: string, register_name : string, change_flags := true) -> string {
    operand: string;
    args: string;
    sb: String_Builder;
    generate :: (variant: Instruction_Variant_Flags) #expand {
        variant_name: string;
        info_enum := cast(*Type_Info_Enum)type_info(Instruction_Variant_Flags);
        for info_enum.values {
            if variant != xx it continue;
            variant_name = to_lower_copy(info_enum.names[it_index]);
        }
        append(*sb, join(instruction_initials, "_", variant_name));
        append(*sb, " :: (using machine: *Machine_6502, data: []u8) {\n");
        append(*sb, tprint("    operand := %;\n", operand));
        append(*sb, join("    ", proc_name, "("));
    
        append(*sb, args);
        if change_flags  append(*sb, ", *flags");
        
        append(*sb, ");\n");
        append(*sb, "}\n");
    }

    if proc_name == {
    case "bit_test";
        #through;
    case "compare";
        args = join(register_name, ", operand");
    case "store";
        args = join(register_name, ", *operand");
    case "xor";
        #through;
    case "and";
        #through;
    case "or";
        #through;
    case "load";
        args = join("*", register_name, ", operand");
    }
    
    if variants & .Imm {
        operand = "data[1]";
        generate(.Imm);
    }
    if variants & .Zpg {
        operand = "memory[data[1]]";
        generate(.Zpg);
    }
    if variants & .Zpg_X {
        operand = "memory[cast(u16)data[1] + cast(u16)x]";
        generate(.Zpg_X);
    }
    if variants & .Zpg_Y {
        operand = "memory[cast(u16)data[1] + cast(u16)y]";
        generate(.Zpg_Y);
    }
    if variants & .Abs {
        operand = "memory[little_endian(*data[1])]";
        generate(.Abs);
    }
    if variants & .Abs_X {
        operand = "memory[little_endian(*data[1]) + x]";
        generate(.Abs_X);
    }
    if variants & .Abs_Y {
        operand = "memory[little_endian(*data[1]) + y]";
        generate(.Abs_Y);
    }

    if variants & .X_Idx_Ind {
        operand = "memory[x_indexed_indirect()]";
        generate(.X_Idx_Ind);
    }

    if variants & .Ind_Y_Idx {
        operand = "memory[indirect_y_indexed()]";
        generate(.Ind_Y_Idx);
    }
    return builder_to_string(*sb);
}

#scope_module
nop :: inline (machine: *Machine_6502, data: []u8) {
    // You may want to use x86 nop instruction if you want to be fancy.
}

reset_flags :: inline (flags: *Status_Flags, to_reset: Status_Flags) {
    flags.* &= ~(to_reset);
}

little_endian :: inline (address: *u8) -> u16 {
    return (cast(*u16)address).*;
}

x_indexed_indirect :: () -> u16 #expand {
    base_address := cast(u16)`data[1] + cast(u16)`x;
    return little_endian(*`memory[base_address]);
}

indirect_y_indexed :: () -> u16 #expand {
    return little_endian(*`memory[`data[1]]) + `y;
}

load :: inline (register: *u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Zero | .Negative);

    // We hardcode the flags for now, in the future we may want to use
    // assembly to cast x86 flags to 6502. I guess that would be faster.
    if value == 0       flags.* |= .Zero;
    else if value > 127 flags.* |= .Negative;
    register.* = value;
}


// --- Compares ---
compare :: inline (register: u8, value: u8, flags: *Status_Flags) #expand {
    reset_flags(flags, .Zero | .Negative | .Carry);
    if register >= value  flags.* |= .Carry;
    if register == value  flags.* |= .Zero;
    if register <  value  flags.* |= .Negative;
}
compare_variant :: inline (register: u8) #expand {
    reset_flags(`flags, .Zero | .Negative | .Carry);
    if register >= `operand  `flags.* |= .Carry;
    if register == `operand  `flags.* |= .Zero;
    if register <  `operand  `flags.* |= .Negative;
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
    compare(a, memory[x_indexed_indirect()], *flags);
}

cmp_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    compare(machine.a, memory[indirect_y_indexed()], *flags);
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
store :: inline (save_to: *u8, value: u8, flags: *Status_Flags) {
    // Store instructions do not change the flags
}
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
    memory[x_indexed_indirect()] = a;
}

sta_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    memory[indirect_y_indexed()] = a;
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

// --- Transfers ---
transfer :: inline (from: *u8, to: *u8, flags: *Status_Flags) {
    reset_flags(flags, .Negative | .Zero);
    num := from.*;
    if num == 0        flags.* |= .Zero;
    else if num > 127  flags.* |= .Negative;
    to.* = num;
}

tax :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*a, *x, *flags);
}

tay :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*a, *y, *flags);
}

txa :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*x, *a, *flags);
}

tya :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*y, *a, *flags);
}

tsx :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*sp, *x, *flags);
}

txs :: inline (using machine: *Machine_6502, data: []u8) {
    // Doesn't have an effect on the flags.
    x = sp;
}

// -- Logical --
and :: inline (register: *u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Negative | .Zero);
    if value == 0        flags.* |= .Zero;
    else if value > 127  flags.* |= .Negative;
    register.* &= value;
}

or :: inline (register: *u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Negative | .Zero);
    if value == 0        flags.* |= .Zero;
    else if value > 127  flags.* |= .Negative;
    register.* |= value;
}

xor :: inline (register: *u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Negative | .Zero);
    if value == 0        flags.* |= .Zero;
    else if value > 127  flags.* |= .Negative;
    register.* ^= value;
}
bit_test :: inline (register: u8, value: u8, flags: *Status_Flags) {
    reset_flags(flags, .Negative | .Zero | .Overflow);
    BIT_6 :: 0b0100_0000;

    if value == 0             flags.* |= .Zero;
    else if value > 127       flags.* |= .Negative;
    if value & BIT_6 == BIT_6 flags.* |= .Overflow;
}

and_imm :: inline (using machine: *Machine_6502, data: []u8) {
    and(*a, data[1], *flags);
}

and_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    and(*a, memory[data[1]], *flags);
}

and_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := cast(u16)data[1] + cast(u16)x;
    and(*a, memory[address], *flags);
}

and_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    and(*a, memory[address], *flags);
}

and_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    and(*a, memory[address + x], *flags);
}

and_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    and(*a, memory[address + y], *flags);
}

and_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    and(*a, memory[x_indexed_indirect()], *flags);
}

and_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    and(*a, memory[indirect_y_indexed()], *flags);
}

ora_imm :: inline (using machine: *Machine_6502, data: []u8) {
    or(*a, data[1], *flags);
}

ora_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    or(*a, memory[data[1]], *flags);
}

ora_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := cast(u16)data[1] + cast(u16)x;
    or(*a, memory[address], *flags);
}

ora_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    or(*a, memory[address], *flags);
}

ora_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    or(*a, memory[address + x], *flags);
}

ora_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    or(*a, memory[address + y], *flags);
}

ora_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    or(*a, memory[x_indexed_indirect()], *flags);
}

ora_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    or(*a, memory[indirect_y_indexed()], *flags);
}

eor_imm :: inline (using machine: *Machine_6502, data: []u8) {
    xor(*a, data[1], *flags);
}

eor_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    xor(*a, memory[data[1]], *flags);
}

eor_zpg_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := cast(u16)data[1] + cast(u16)x;
    xor(*a, memory[address], *flags);
}

eor_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    xor(*a, memory[address], *flags);
}

eor_abs_x :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    xor(*a, memory[address + x], *flags);
}

eor_abs_y :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    xor(*a, memory[address + y], *flags);
}

eor_x_idx_ind :: inline (using machine: *Machine_6502, data: []u8) {
    xor(*a, memory[x_indexed_indirect()], *flags);
}

eor_ind_y_idx :: inline (using machine: *Machine_6502, data: []u8) {
    xor(*a, memory[indirect_y_indexed()], *flags);
}

bit_zpg :: inline (using machine: *Machine_6502, data: []u8) {
    bit_test(a, memory[data[1]], *flags);
}

bit_abs :: inline (using machine: *Machine_6502, data: []u8) {
    address := little_endian(*data[1]);
    bit_test(a, memory[address], *flags);
}
