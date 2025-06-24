// We generate everything except jumps and implied instructions.

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

#if EXTENDED_65C02 {
    
    // Bit instructions
    #insert #run generate_bit_instructions("smb", .Set, .Zpg);
    #insert #run generate_bit_instructions("rmb", .Reset, .Zpg);
    #insert #run generate_bit_instructions("bbs", .Branch_On_Set, .Rel);
    #insert #run generate_bit_instructions("brs", .Branch_On_Reset, .Rel);

    Bit_Instruction_Type :: enum {
        Set;
        Reset;
        Branch_On_Set;
        Branch_On_Reset;
    }

    set_bit :: (bit: u8) #expand {
        `operand.* |= bit;
    }

    reset_bit :: (bit: u8) #expand {
        `operand.* &= ~bit;
    }
    
    branch_on_set_bit :: (bit: u8) #expand {

    }

    branch_on_reset_bit :: (bit: u8) #expand {

    }

    generate_bit_instructions :: (instruction_initials: string, type: Bit_Instruction_Type, variant: Instruction_Variant_Flags) -> string {
        sb: String_Builder;
        
        // Note: We are assuming that we only pass one variant.
        variant_name := get_enum_value_name_lower(variant);
        operand := get_operand_name(variant);
        
        proc_name := tprint("%_bit", get_enum_value_name_lower(type));

        for 0..7 {
            bit_name := tprint("BIT_%", it);
            append(*sb, tprint("%1%2_%3", instruction_initials, it, variant_name));
            append(*sb, " :: (using machine: *Machine_6502) {\n");
            append(*sb, tprint("    operand := *%;\n", operand));
            append(*sb, tprint("    %(%);\n", proc_name, bit_name));
            append(*sb, "}\n");
        }
        return builder_to_string(*sb);
    }

    bra :: (using machine: *Machine_6502) {
        pc = pc + 2 + memory[pc+1];
    }
}
else {

    bra :: null;
}

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
    Rel;
}

get_enum_value_name_lower :: (value: $T) -> string {
    info_enum := cast(*Type_Info_Enum)type_info(T);
    for info_enum.values {
        if it == cast(s64) value {
            return to_lower_copy(info_enum.names[it_index]);
        }
    }
    return "";
}

get_operand_name :: (variant: Instruction_Variant_Flags) -> string {
    if #complete variant == {
    case .Imm;
        return "memory[pc+1]";
    case .Zpg;
        return "memory[memory[pc+1]]";
    case .Zpg_X;
        return "memory[cast(u16)memory[pc+1] + cast(u16)x]";
    case .Zpg_Y;
        return "memory[cast(u16)memory[pc+1] + cast(u16)y]";
    case .Abs;
        return "memory[u16_le(*memory[pc+1])]";
    case .Abs_X;
        return "memory[u16_le(*memory[pc+1]) + x]";
    case .Abs_Y;
        return "memory[u16_le(*memory[pc+1]) + y]";
    case .X_Idx_Ind;
        return "memory[x_indexed_indirect()]";
    case .Ind_Y_Idx;
        return "memory[indirect_y_indexed()]";
    case .Acc;
        return "a";
    case .Rel; return "memory[pc + 2 + memory[pc+1]]"; // not used
    }
}

get_pc_increment :: (variant: Instruction_Variant_Flags) -> u8 {
    if variant == {
    case .Abs_X; #through;
    case .Abs_Y; #through;
    case .Abs; return 3;
    case .Acc; return 1;
    case; return 2;
    }    
}

generate_instructions :: (instruction_initials: string, variants: Instruction_Variant_Flags, proc_name: string, register_name := "") -> string {
    num_data : u8;
    args: string = ---;
    sb: String_Builder;
    generate :: (variant: Instruction_Variant_Flags) #expand {
        operand := get_operand_name(variant);
        pc_increment := get_pc_increment(variant);
        variant_name := get_enum_value_name_lower(variant);
        append(*sb, join(instruction_initials, "_", variant_name));
        append(*sb, " :: (using machine: *Machine_6502) {\n");
        append(*sb, tprint("    operand := *%;\n", operand));
        append(*sb, join("    ", proc_name, "("));
    
        append(*sb, args);
        
        append(*sb, ");\n");

        append(*sb, tprint("    pc += %;\n", pc_increment));
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
    
    // How can we factor this?
    if variants & .Imm {
        generate(.Imm);
    }
    if variants & .Zpg {
        generate(.Zpg);
    }
    if variants & .Zpg_X {
        generate(.Zpg_X);
    }
    if variants & .Zpg_Y {
        generate(.Zpg_Y);
    }
    if variants & .Abs {
        generate(.Abs);
    }
    if variants & .Abs_X {
        generate(.Abs_X);
    }
    if variants & .Abs_Y {
        generate(.Abs_Y);
    }

    if variants & .X_Idx_Ind {
        generate(.X_Idx_Ind);
    }

    if variants & .Ind_Y_Idx {
        generate(.Ind_Y_Idx);
    }

    if variants & .Acc {
        generate(.Acc);
    }

    return builder_to_string(*sb);
}

#scope_module
// Utility
BIT_7 :: 0b1000_0000;
BIT_6 :: 0b0100_0000;
BIT_5 :: 0b0010_0000;
BIT_4 :: 0b0001_0000;
BIT_3 :: 0b0000_1000;
BIT_2 :: 0b0000_0100;
BIT_1 :: 0b0000_0010;
BIT_0 :: 1;

reset_flags :: inline (flags: *Status_Flags, to_reset: Status_Flags) {
    flags.* &= ~(to_reset);
}

basic_flags :: inline (flags: *Status_Flags, value: u8) {
    if value == 0          flags.* |= .Zero;
    else if value & BIT_7  flags.* |= .Negative;
}

u16_le :: inline (address: *u8) -> u16 {
    return (cast(*u16)address).*;
}

x_indexed_indirect :: () -> u16 #expand {
    base_address := cast(u16)`memory[`pc+1] + cast(u16)`x;
    return u16_le(*`memory[base_address]);
}
indirect_y_indexed :: () -> u16 #expand {
    return u16_le(*`memory[`memory[`pc+1]]) + `y;
}

push_stack :: (value: u8) #expand {
    `memory[0x100 & `sp] = value;
    `sp -= 1;
}

push_stack :: (value: u16) #expand {
    `memory[0x100 & `sp]   = cast(u8)(value >> 8);
    `memory[0x100 & (`sp-1)] = cast(u8)(value & 0xFF);

    `sp -= 2;
}

pull_stack :: () -> u8 #expand {
    `sp +=1;
    return `memory[0x100 & `sp];;
}

// @Consistency
// There is a bug where the compiler cannot inference the type with some overloaded procedures,
// so this is named differently.
pull_stack_2 :: () -> u16 #expand {
    value : u16 = ---;

    value = `memory[0x100 & `sp+1]; // low
    value &= cast(u16)(`memory[0x100 & `sp+2]) << 8; // high
    
    `sp +=2;
    return value;
}

// Actual instruction macros

load :: (register: *u8) #expand {
    reset_flags(*`flags, .Zero | .Negative);

    // We hardcode the flags for now, in the future we may want to use
    // assembly to cast x86 flags to 6502. I guess that would be faster.
    if `operand.* == 0       `flags |= .Zero;
    else if `operand.* & BIT_7 `flags |= .Negative;
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
    `pc += 1;
}

tax :: inline (using machine: *Machine_6502) {
    transfer(*a, *x);
}

tay :: inline (using machine: *Machine_6502) {
    transfer(*a, *y);
}

txa :: inline (using machine: *Machine_6502) {
    transfer(*x, *a);
}

tya :: inline (using machine: *Machine_6502) {
    transfer(*y, *a);
}

tsx :: inline (using machine: *Machine_6502) {
    transfer(*sp, *x);
}

txs :: inline (using machine: *Machine_6502) {
    // Doesn't have an effect on the flags.
    x = sp;
    pc += 1;
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
    if result == 0         `flags |= .Zero;
    if `operand.* & BIT_7  `flags |= .Negative;
    if `operand.* & BIT_6  `flags |= .Overflow;
}

do_carry_add :: inline (register: *u8, num: u8, carry: u8, flags: *Status_Flags) {
    result := register.* + num + carry;

    reset_flags(flags, .Negative | .Overflow | .Zero | .Carry);
    basic_flags(flags, result);

    if result & BIT_7 != register.* & BIT_7  flags.* |= .Carry;

    if (register.* & BIT_7 == num & BIT_7) && (result & BIT_7 != register.* & BIT_7) 
        flags.* |= .Overflow;
    register.* = result;
}

adc :: (register: *u8) #expand {
    carry : u8 = ifx `flags & .Carry then cast(u8)1 else cast(u8)0;
    do_carry_add(register, `operand.*, carry, *`flags);
}

sbc :: (register: *u8) #expand {
    carry : u8 = 0;
    if `flags & .Carry  carry -= 1;
    new_operand := ~`operand.* + 1; // Two's complement.
    do_carry_add(register, new_operand, carry, *`flags);
}

// --- Set/Clear Flags ---
clc :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Carry);
    pc += 1;
}

sec :: inline (using machine: *Machine_6502) {
    flags |= .Carry;
    pc += 1;
}

clv :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Overflow);
    pc += 1;
}

cld :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Decimal);
    pc += 1;
}

sed :: inline (using machine: *Machine_6502) {
    flags |= .Decimal;
    pc += 1;
}

cli :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Interrupt_Disable);
    pc += 1;
}

sei :: inline (using machine: *Machine_6502) {
    flags |= .Interrupt_Disable;
    pc += 1;
}

// --- Inc/Dec ---
inc :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* += 1;
    basic_flags(*`flags, `operand.*);
}

inx :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Negative | .Zero);
    x += 1;
    basic_flags(*flags, x);
    pc += 1;
}

iny :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Negative | .Zero);
    y += 1;
    basic_flags(*flags, y);
    pc += 1;
}

dec :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* -= 1;
    basic_flags(*`flags, `operand.*);
}

dex :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Negative | .Zero);
    x -= 1;
    basic_flags(*flags, x);
    pc += 1;
}
dey :: inline (using machine: *Machine_6502) {
    reset_flags(*flags, .Negative | .Zero);
    y -= 1;
    basic_flags(*flags, y);
    pc += 1;
}

// --- Shifts and Rotations ---
lsr :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* >> 1;

    basic_flags(*`flags, result);
    if value.* & BIT_0  `flags |= .Carry;

    value.* = result;
}

asl :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* << 1;

    basic_flags(*`flags, result);
    if value.* & BIT_7  `flags |= .Carry;

    value.* = result;
}

ror :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* >>> 1;
    
    basic_flags(*`flags, result);
    if value.* & BIT_0  `flags |= .Carry;

    value.* = result;
}

rol :: (value: *u8) #expand {
    reset_flags(*`flags, .Carry | .Zero | .Negative);
    result := value.* <<< 1;

    basic_flags(*`flags, result);
    if value.* & BIT_7  `flags |= .Carry;

    value.* = result;
}

// --- Jumps ---
jmp_abs :: inline (using machine: *Machine_6502) {
    pc = u16_le(*memory[pc+1]);
}

jmp_ind :: inline (using machine: *Machine_6502) {
    pc = u16_le(*memory[u16_le(*memory[pc+1])]);
}

jsr_abs :: inline (using machine: *Machine_6502) {
    push_stack(pc + 3); // return address, pc + 2 on the chip for various reasons but we put the actual address here. 
    pc = u16_le(*memory[pc+1]);
}

rts :: inline (using machine: *Machine_6502) {
    pc = pull_stack_2();
}

// --- Stack operations ---
pha :: inline (using machine: *Machine_6502) {
    push_stack(a);
    pc += 1;
}

pla :: inline (using machine: *Machine_6502) {
    a = pull_stack();
    pc += 1;
}

php :: inline (using machine: *Machine_6502) {
    push_stack(xx flags);
    pc += 1;
}

plp :: inline (using machine: *Machine_6502) {
    flags = xx pull_stack();
    pc += 1;
}

// --- System ---
brk :: inline (using machine: *Machine_6502) {
    pc += 2; // brk acts as a two byte instruction
    interrupt(machine);
}

rti :: inline (using machine: *Machine_6502) {
    flags = xx pull_stack();
    pc = pull_stack_2();
}

nop :: inline (using machine: *Machine_6502) {
    // x86 nop
    // #bytes 0x90;
    pc += 1;
}

// --- Branches ---
branch_on :: (flag: Status_Flags, on := true) #expand {
    rel_address := `memory[`pc+1];
    `pc += 2;
    if (`flags & flag != 0) == on {
        if rel_address & BIT_7
            `pc -= ~rel_address + 1; // Two's complement
        else
            `pc += rel_address;
    }
}

beq :: inline (using machine: *Machine_6502) {
    branch_on(.Zero);
}

bne :: inline (using machine: *Machine_6502) {
    branch_on(.Zero, false);
}

bcs :: inline (using machine: *Machine_6502) {
    branch_on(.Carry);
}

bcc :: inline (using machine: *Machine_6502) {
    branch_on(.Carry, false);
}

bvs :: inline (using machine: *Machine_6502) {
    branch_on(.Overflow);
}

bvc :: inline (using machine: *Machine_6502) {
    branch_on(.Overflow, false);
}

bmi :: inline (using machine: *Machine_6502) {
    branch_on(.Negative);
}

bpl :: inline (using machine: *Machine_6502) {
    branch_on(.Negative, false);
}