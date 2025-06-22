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
    num_data : u8;
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
        append(*sb, " :: (using state: *State_6502) {\n");
        append(*sb, tprint("    operand := *%;\n", operand));
        append(*sb, join("    ", proc_name, "("));
    
        append(*sb, args);
        
        append(*sb, ");\n");

        if num_data != 0  {
            append(*sb, tprint("pc += %;\n", num_data));
        }

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
        operand = "memory[pc+1]";
        num_data = 1;
        generate(.Imm);
    }
    if variants & .Zpg {
        operand = "memory[memory[pc+1]]";
        num_data = 1;
        generate(.Zpg);
    }
    if variants & .Zpg_X {
        operand = "memory[cast(u16)memory[pc+1] + cast(u16)x]";
        num_data = 1;
        generate(.Zpg_X);
    }
    if variants & .Zpg_Y {
        operand = "memory[cast(u16)memory[pc+1] + cast(u16)y]";
        num_data = 1;
        generate(.Zpg_Y);
    }
    if variants & .Abs {
        operand = "memory[u16_le(*memory[pc+1])]";
        num_data = 2;
        generate(.Abs);
    }
    if variants & .Abs_X {
        operand = "memory[u16_le(*memory[pc+1]) + x]";
        num_data = 2;
        generate(.Abs_X);
    }
    if variants & .Abs_Y {
        operand = "memory[u16_le(*memory[pc+1]) + y]";
        num_data = 2;
        generate(.Abs_Y);
    }

    if variants & .X_Idx_Ind {
        operand = "memory[x_indexed_indirect()]";
        num_data = 1;
        generate(.X_Idx_Ind);
    }

    if variants & .Ind_Y_Idx {
        operand = "memory[indirect_y_indexed()]";
        num_data = 1;
        generate(.Ind_Y_Idx);
    }

    if variants & .Acc {
        operand = "a";
        generate(.Acc);
    }

    return builder_to_string(*sb);
}

#scope_module
// Utility
BIT_7 :: 0b1000_0000;
BIT_6 :: 0b0100_0000;
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

tax :: inline (using state: *State_6502) {
    transfer(*a, *x);
}

tay :: inline (using state: *State_6502) {
    transfer(*a, *y);
}

txa :: inline (using state: *State_6502) {
    transfer(*x, *a);
}

tya :: inline (using state: *State_6502) {
    transfer(*y, *a);
}

tsx :: inline (using state: *State_6502) {
    transfer(*sp, *x);
}

txs :: inline (using state: *State_6502) {
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
    if result == 0         `flags |= .Zero;
    if `operand.* > 127    `flags |= .Negative;
    if `operand.* & BIT_6  `flags |= .Overflow;
}

do_carry_add:: (register: *u8, num: u8, flags: *Status_Flags) #expand {
    carry := ifx flags.* & .Carry == .Carry then cast(u8)1 else cast(u8)0;
    result := register.* + num + carry;

    reset_flags(flags, .Negative | .Overflow | .Zero | .Carry);
    basic_flags(flags, result);

    if result < register.*  flags.* |= .Carry;

    // Ugh...
    if (register.* & BIT_7 == num & BIT_7) && (result & BIT_7 != register.* & BIT_7) 
        flags.* |= .Overflow;

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
clc :: inline (using state: *State_6502) {
    reset_flags(*flags, .Carry);
}

sec :: inline (using state: *State_6502) {
    flags |= .Carry;
}

clv :: inline (using state: *State_6502) {
    reset_flags(*flags, .Overflow);
}

cld :: inline (using state: *State_6502) {
    reset_flags(*flags, .Decimal);
}

sed :: inline (using state: *State_6502) {
    flags |= .Decimal;
}

cli :: inline (using state: *State_6502) {
    reset_flags(*flags, .Interrupt_Disable);
}

sei :: inline (using state: *State_6502) {
    flags |= .Interrupt_Disable;
}

// --- Inc/Dec ---
inc :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* += 1;
    basic_flags(*`flags, `operand.*);
}

inx :: inline (using state: *State_6502) {
    reset_flags(*flags, .Negative | .Zero);
    x += 1;
    basic_flags(*flags, x);
}

iny :: inline (using state: *State_6502) {
    reset_flags(*flags, .Negative | .Zero);
    y += 1;
    basic_flags(*flags, y);
}

dec :: () #expand {
    reset_flags(*`flags, .Negative | .Zero);
    `operand.* -= 1;
    basic_flags(*`flags, `operand.*);
}

dex :: inline (using state: *State_6502) {
    reset_flags(*flags, .Negative | .Zero);
    x -= 1;
    basic_flags(*flags, x);
}
dey :: inline (using state: *State_6502) {
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
jmp_abs :: inline (using state: *State_6502) {
    pc = u16_le(*memory[pc+1]);
}

jmp_ind :: inline (using state: *State_6502) {
    pc = u16_le(*memory[u16_le(*memory[pc+1])]);
}

jsr_abs :: inline (using state: *State_6502) {
    push_stack(pc + 3); // return address, pc + 2 on the chip for various reasons but we put the actual address here. 
    pc = u16_le(*memory[pc+1]);
}

rts :: inline (using state: *State_6502) {
    pc = pull_stack_2();
}

// --- Stack operations ---
pha :: inline (using state: *State_6502) {
    push_stack(a);
}

pla :: inline (using state: *State_6502) {
    a = pull_stack();
}

php :: inline (using state: *State_6502) {
    push_stack(xx flags);
}

plp :: inline (using state: *State_6502) {
    flags = xx pull_stack();
}

// --- System ---
brk :: inline (using state: *State_6502) {
    push_stack(pc);
    push_stack(xx flags);
    pc = 0xFFFE; // IRQ interrupt vector
    flags |= .Break;
}

rti :: inline (using state: *State_6502) {
    flags = xx pull_stack();
    pc = pull_stack_2();
}

nop :: inline (state: *State_6502) {
    // x86 nop
    // #bytes 0x90;
}

// --- Branches ---
branch_on :: (flag: Status_Flags, on := true) #expand {
    rel_address := `memory[`pc+1];
    if (`flags & flag != 0) == on {
        if rel_address & BIT_7
            `pc -= rel_address - 255 - 1; // Two's complement, we can't just put -256 because it exceeds 8 bytes
        else
            `pc += rel_address;
    }
}

beq :: inline (using state: *State_6502) {
    branch_on(.Zero);
}

bne :: inline (using state: *State_6502) {
    branch_on(.Zero, false);
}

bcs :: inline (using state: *State_6502) {
    branch_on(.Carry);
}

bcc :: inline (using state: *State_6502) {
    branch_on(.Carry, false);
}

bvs :: inline (using state: *State_6502) {
    branch_on(.Overflow);
}

bvc :: inline (using state: *State_6502) {
    branch_on(.Overflow, false);
}

bmi :: inline (using state: *State_6502) {
    branch_on(.Negative);
}

bpl :: inline (using state: *State_6502) {
    branch_on(.Negative, false);
}