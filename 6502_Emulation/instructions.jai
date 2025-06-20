// We generate everything except for the implied ones.

// Loads
#insert #run generate_instructions("lda", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "load", "a");
#insert #run generate_instructions("ldx", .Imm | .Zpg | .Zpg_Y | .Abs | .Abs_X | .Abs_Y, "load", "x");
#insert #run generate_instructions("ldy", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y, "load", "y");

// Compares
#insert #run generate_instructions("cmp", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "compare", "a");
#insert #run generate_instructions("cpx", .Imm | .Zpg | .Abs, "compare", "x");
#insert #run generate_instructions("cpy", .Imm | .Zpg | .Abs, "compare", "y");

// Stores
#insert #run generate_instructions("sta", .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "store", "a");
#insert #run generate_instructions("stx", .Zpg | .Zpg_Y | .Abs, "store", "x");
#insert #run generate_instructions("sty", .Zpg | .Zpg_X | .Abs, "store", "y");

// Logical
#insert #run generate_instructions("and", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "and", "a");
#insert #run generate_instructions("ora", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "or", "a");
#insert #run generate_instructions("eor", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "xor", "a");
#insert #run generate_instructions("bit", .Zpg | .Abs, "bit_test", "a");

// Add, sub
#insert #run generate_instructions("adc", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "adc", "a");
#insert #run generate_instructions("sbc", .Imm | .Zpg | .Zpg_X | .Abs | .Abs_X | .Abs_Y | .X_Idx_Ind | .Ind_Y_Idx, "sbc", "a");
#insert #run generate_instructions("inc", .Zpg | .Zpg_X | .Abs | .Abs_X, "inc");
#insert #run generate_instructions("dec", .Zpg | .Zpg_X | .Abs | .Abs_X, "dec");

// Shifts, rotations
#insert #run generate_instructions("lsr", .Acc | .Zpg  | .Zpg_X | .Abs | .Abs_X, "lsr");
#insert #run generate_instructions("asl", .Acc | .Zpg  | .Zpg_X | .Abs | .Abs_X, "asl");
#insert #run generate_instructions("rol", .Acc | .Zpg  | .Zpg_X | .Abs | .Abs_X, "rol");
#insert #run generate_instructions("ror", .Acc | .Zpg  | .Zpg_X | .Abs | .Abs_X, "ror");

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
    Acc;
}

generate_instructions :: (instruction_initials: string, variants: Instruction_Variant_Flags, proc_name: string, register_name := "") -> string {
    operand: string;
    args: string = ---;
    sb: String_Builder;
    generate :: (variant: Instruction_Variant_Flags) #expand {
        variant_name: string;
        info_enum := cast(*Type_Info_Enum)type_info(Instruction_Variant_Flags);
        for info_enum.values {
            if variant == xx it {
                variant_name = to_lower_copy(info_enum.names[it_index]);
                break;
            }
        }
        append(*sb, join(instruction_initials, "_", variant_name));
        append(*sb, " :: (using machine: *Machine_6502, data: []u8) {\n");
        append(*sb, tprint("    operand := *%;\n", operand));
        append(*sb, join("    ", proc_name, "("));
    
        append(*sb, args);
        
        append(*sb, ");\n");
        append(*sb, "}\n");
    }

    // We could've used just *register_name for everything and it would've been a lot simpler, but whatever.
    if proc_name == {
    case "dec"; #through;
    case "inc";
        args = "";

    case "bit_test"; #through;
    case "compare";  #through;
    case "store";
        args = register_name;

    case "ror"; #through;
    case "rol"; #through;
    case "asl"; #through;
    case "lsr";
        args = "operand";
    case;
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

    if variants & .Acc {
        operand = "a";
        generate(.Acc);
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

basic_flags :: inline (flags: *Status_Flags, value: u8) {
    if value == 0                   flags.* |= .Zero;
    else if value & BIT_7 == BIT_7  flags.* |= .Negative;
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

load :: (register: *u8) #expand {
    reset_flags(*`flags, .Zero | .Negative);

    // We hardcode the flags for now, in the future we may want to use
    // assembly to cast x86 flags to 6502. I guess that would be faster.
    if `operand.* == 0       `flags |= .Zero;
    else if `operand.* > 127 `flags |= .Negative;
    register.* = `operand.*;
}

compare :: (register: u8) #expand {
    reset_flags(*`flags, .Zero | .Negative | .Carry);
    if register >= `operand.*  `flags |= .Carry;
    if register == `operand.*  `flags |= .Zero;
    if register <  `operand.*  `flags |= .Negative;
}

store :: (value: u8) #expand {
    `operand.* = value;
}

// --- Transfers ---
transfer :: (from: *u8, to: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    num := from.*;
    basic_flags(*`flags, num);
    to.* = num;
}

tax :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*a, *x);
}

tay :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*a, *y);
}

txa :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*x, *a);
}

tya :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*y, *a);
}

tsx :: inline (using machine: *Machine_6502, data: []u8) {
    transfer(*sp, *x);
}

txs :: inline (using machine: *Machine_6502, data: []u8) {
    // Doesn't have an effect on the flags.
    x = sp;
}

// -- Logical --
and :: (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    basic_flags(*`flags, `operand.*);
    register.* &= `operand.*;
}

or :: (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    basic_flags(*`flags, `operand.*);
    register.* |= `operand.*;
}

xor :: (register: *u8) #expand {
    reset_flags(*`flags, .Negative | .Zero);
    basic_flags(*`flags, `operand.*);
    register.* ^= `operand.*;
}

bit_test :: (register: u8) #expand {
    reset_flags(*`flags, .Negative | .Zero | .Overflow);
    result := register & `operand.*;
    if result == 0                 `flags |= .Zero;
    if `operand.* > 127            `flags |= .Negative;
    if `operand.* & BIT_6 == BIT_6 `flags |= .Overflow;
}

do_carry_add:: (register: *u8, num: u8, flags: *Status_Flags) #expand {
    carry := ifx flags.* & .Carry == .Carry then cast(u8)1 else cast(u8)0;
    result := register.* + num + carry;

    reset_flags(flags, .Negative | .Overflow | .Zero | .Carry);
    basic_flags(flags, result);

    if result < register.*  flags.* |= .Carry;

    // Ugh...
    if (register.* & BIT_7 == num & BIT_7) && (result & BIT_7 != register.* & BIT_7) flags.* |= .Overflow;

    register.* = result;
}

adc :: (register: *u8) #expand {
    do_carry_add(register, `operand.*, *`flags);
}

sbc :: (register: *u8) #expand {
    new_operand := ~`operand.*; // We invert the bits so we can pass it as carry add
    do_carry_add(register, new_operand, *`flags);
}

// --- Set/Clear Flags ---
clc :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Carry);
}

sec :: inline (using machine: *Machine_6502, data: []u8) {
    flags |= .Carry;
}

clv :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Overflow);
}

cld :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Decimal);
}
sed :: inline (using machine: *Machine_6502, data: []u8) {
    flags |= .Decimal;
}

// --- Inc/Dec ---
inc :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* += 1;
    basic_flags(*`flags, `operand.*);
}

inx :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Negative | .Zero);
    x += 1;
    basic_flags(*flags, x);
}

iny :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Negative | .Zero);
    y += 1;
    basic_flags(*flags, y);
}

dec :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* -= 1;
    basic_flags(*`flags, `operand.*);
}

dex :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Negative | .Zero);
    x -= 1;
    basic_flags(*flags, x);
}
dey :: inline (using machine: *Machine_6502, data: []u8) {
    reset_flags(*flags, .Negative | .Zero);
    y -= 1;
    basic_flags(*flags, y);
}

// --- Shifts and Rotations ---
lsr :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* >> 1;

    basic_flags(*`flags, result);
    if value.* & BIT_0 == BIT_0   `flags |= .Carry;

    value.* = result;
}

asl :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* << 1;

    basic_flags(*`flags, result);
    if value.* & BIT_7 == BIT_7   `flags |= .Carry;

    value.* = result;
}

ror :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* >>> 1;
    
    basic_flags(*`flags, result);
    if value.* & BIT_0 == BIT_0   `flags |= .Carry;

    value.* = result;
}

rol :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* <<< 1;

    basic_flags(*`flags, result);
    if value.* & BIT_7 == BIT_7   `flags |= .Carry;

    value.* = result;
}

BIT_7 :: 0b1000_0000;
BIT_6 :: 0b0100_0000;
BIT_0 :: 1;