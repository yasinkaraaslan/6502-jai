main :: () {
    machine: Machine_6502;
    init(*machine);
    defer deinit(*machine);
    args := get_command_line_arguments();
    if args.count < 2 {
        print("Please provide a binary file representing a 6502 memory layout to emulate.");
        return;
    }
    content: string;
    for args {
        if it_index == 0  continue;
        read, ok := read_entire_file(it);
        if !ok  continue;
        content = read;
    }

    if !content {
        print("We haven't been able to read any file you provided.");
    }
    if content.count < MEMORY_SIZE_6502 {
        print("Size of the file is less than the memory of 6502, copying the file to the upper portion of the memory (to make sure reset and interrupt vectors get set).");
        memcpy(machine.memory.data + (MEMORY_SIZE_6502 - content.count), content.data, content.count);
    }
    else {
        if content.count > MEMORY_SIZE_6502  print("Size of the file is more than the memory of 6502, copying the file's lower portion to the memory.");
        memcpy(machine.memory.data, content.data, MEMORY_SIZE_6502);
    }
    free(content);
    reset(*machine);
    width := 1280;
    height := 720;
    window := create_window(1280, 720, "6502 Emulation!");

    Simp.set_render_target(window);
    Simp.set_shader_for_color();
    default_font := Simp.load_font("fonts", "LiberationMono-Regular.ttf", 32);

    quit := false;
    while !quit {
        reset_temporary_storage();
        update_window_events();
        for get_window_resizes() {
            Simp.update_window(window);
            width = it.width;
            height = it.height;
        }

        for events_this_frame {
            if it.type == .QUIT quit = true;
            if it.type == .KEYBOARD {
                if it.key_code == #char "S" {
                    step(*machine);
                }
            }
        }

        Simp.clear_render_target(0.3, 0.3, 0.6, 1.0);
        quad_width, quad_height := width / 255, height / 255;

        if width > 255 && height > 255 {
            for i: 0..255 {
                for j: 0..255 {
                    value := machine.memory[i + j * 255];
                    color := Vector4.{(value >> 8) / 255.0, (value & 0xFF) / 255.0, 0, 1};
                    // Change the bitmap
                }
            }
        }

        // Draw the bitmap


        Simp.set_shader_for_text();
        Simp.draw_text(default_font, 5, 32, "Press S to step.");
        Simp.swap_buffers(window, true);
    }

}
#import "Math";
#import "Window_Creation";
#import "File";
#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import,dir "../../6502_Emulation";