MEMORY_SIZE_6502 :: 64 * 1024;
Machine_6502 :: struct {
    memory: []u8;
}

init :: (using machine: *Machine_6502) {
    memory.data = alloc(MEMORY_SIZE_6502);
    memory.count = MEMORY_SIZE_6502;
}
deinit :: (using machine: *Machine_6502) {
    free(memory.data);
    memory.count = 0;
}

#scope_module
#import "Basic"; // for alloc