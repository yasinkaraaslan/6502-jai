// We generate everything except for the implied ones.
#insert #run generate_instructions("lda", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "load", "a");
#insert #run generate_instructions("ldx", .Imm | .Zpg | .Zpg_Y | .Abs | .Abs_X | .Abs_Y, "load", "x");
#insert #run generate_instructions("ldy", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y, "load", "y");

#insert #run generate_instructions("cmp", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "compare", "a");
#insert #run generate_instructions("cpx", .Imm | .Zpg | .Abs, "compare", "x");
#insert #run generate_instructions("cpy", .Imm | .Zpg | .Abs, "compare", "y");

#insert #run generate_instructions("sta", .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "store", "a");
#insert #run generate_instructions("stx", .Zpg | .Zpg_Y | .Abs, "store", "x");
#insert #run generate_instructions("sty", .Zpg | .Zpg_X | .Abs, "store", "y");

#insert #run generate_instructions("and", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "and", "a");
#insert #run generate_instructions("ora", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "or", "a");
#insert #run generate_instructions("eor", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "xor", "a");
#insert #run generate_instructions("bit", .Zpg | .Abs, "bit_test", "a");

#scope_file
#import "String";
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

generate_instructions :: (instruction_initials: string, variants: Instruction_Variant_Flags, proc_name: string, register_name : string) -> string {
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
        append(*sb, tprint("    operand := *%;\n", operand));
        append(*sb, join("    ", proc_name, "("));
    
        append(*sb, args);
        
        append(*sb, ");\n");
        append(*sb, "}\n");
    }

    if proc_name == {
    case "bit_test";
        #through;
    case "compare";
        #through;
    case "store";
        args = register_name;
    case "xor";
        #through;
    case "and";
        #through;
    case "or";
        #through;
    case "load";
        args = join("*", register_name);
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

load :: inline (register: *u8) #expand {
    reset_flags(*`flags, .Zero | .Negative);

    // We hardcode the flags for now, in the future we may want to use
    // assembly to cast x86 flags to 6502. I guess that would be faster.
    if `operand.* == 0       `flags |= .Zero;
    else if `operand.* > 127 `flags |= .Negative;
    register.* = `operand.*;
}

compare :: inline (register: u8) #expand {
    reset_flags(*`flags, .Zero | .Negative | .Carry);
    if register >= `operand.*  `flags |= .Carry;
    if register == `operand.*  `flags |= .Zero;
    if register <  `operand.*  `flags |= .Negative;
}

store :: inline (value: u8) #expand {
    `operand.* = value;
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
and :: inline (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    if `operand.* == 0        `flags |= .Zero;
    else if `operand.* > 127  `flags |= .Negative;
    register.* &= `operand.*;
}

or :: inline (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    if `operand.* == 0        `flags |= .Zero;
    else if `operand.* > 127  `flags |= .Negative;
    register.* |= `operand.*;
}

xor :: inline (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    if `operand.* == 0        `flags |= .Zero;
    else if `operand.* > 127  `flags |= .Negative;
    register.* ^= `operand.*;
}

bit_test :: inline (register: u8) #expand {
    reset_flags(*`flags, .Negative | .Zero | .Overflow);
    BIT_6 :: 0b0100_0000;
    result := register & `operand.*;
    if result == 0                 `flags |= .Zero;
    if `operand.* > 127            `flags |= .Negative;
    if `operand.* & BIT_6 == BIT_6 `flags |= .Overflow;
}
