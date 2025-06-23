put_bytes :: (using machine: *Machine_6502, address: u16, bytes: ..u8) {
    for bytes {
        machine.memory[address + it_index] = it;
    }
}

main :: () {
    machine: Machine_6502;
    init(*machine);
    defer deinit(*machine);

    // 0xFFFC is where memory location for the first instruction is provided.
    // Let's start from 0x8000. Note that 6502 is little endian.
    put_bytes(*machine, 0xFFFC,  0x00, 0x80);

    // 0xFFFE is where IRQ vector (address of the interrupt handler) lives in. Let's put 0x8005.
    put_bytes(*machine, 0xFFFE,  0x05, 0x80);

    // Nop instruction
    put_bytes(*machine, 0x8000,  0xEA);

    // brk interrupt
    put_bytes(*machine, 0x8001,  0x00);

    // Load 69 to the accumulator
    put_bytes(*machine, 0x8005,  0xA9, 69);

    // Compare the accumulator to 105;
    put_bytes(*machine, 0x8007,  0xC9, 105);

    reset(*machine);


    step(*machine);
    print("Program-counter after step 1: 0x%\n", FormatInt.{value=machine.pc, base=16});

    step(*machine);
    print("Program-counter after step 2 (interrupt):  0x%\n", FormatInt.{value = machine.pc, base=16});

    step(*machine);
    print("Program-counter, accumulator after step 3 (load): 0x%, %\n", FormatInt.{value = machine.pc, base=16}, machine.a);

    step(*machine);
    print("Program-counter, flags after step 4 (compare): 0x%, %\n", FormatInt.{value = machine.pc, base=16}, machine.flags);

}

#import "Basic";
#import,dir "../../6502_Emulation"; // You would put 6502_Emulation to your local modules folder in a real project.