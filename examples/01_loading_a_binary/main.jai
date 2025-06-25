FONT_SIZE :: 32;

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
        return;
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

    default_font := Simp.load_font("fonts", "FiraSans-Regular.otf", FONT_SIZE);

    BITMAP_WIDTH :: 16;
    BITMAP_HEIGHT :: 16;

    bitmap: Simp.Bitmap;
    defer Simp.deinit(*bitmap);
    Simp.bitmap_alloc(*bitmap, BITMAP_WIDTH, BITMAP_HEIGHT, .RGBA8);

    old_bitmap := bitmap;
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
                if it.repeat || it.key_pressed  continue;
                if it.key_code == {
                case #char "S";
                    step(*machine);
                case #char "R";
                    reset(*machine);
                case #char "I";
                    interrupt(*machine);
                }
            }
        }

        Simp.clear_render_target(0.3, 0.3, 0.6, 1.0);

        if width > BITMAP_WIDTH && height > BITMAP_HEIGHT {
            quad_width, quad_height := width / BITMAP_WIDTH, height / BITMAP_HEIGHT;
            for i: 0..BITMAP_WIDTH-1 {
                for j: 0..BITMAP_HEIGHT-1 {
                    index := i + j * BITMAP_HEIGHT;
                    value := machine.memory[index];
                    color := Vector4.{value / 255.0, 1, 0, 1};

                    // Grey scale for now
                    bitmap.data[index*4] = value;
                    bitmap.data[index*4+1] = value;
                    bitmap.data[index*4+2] = value;
                    bitmap.data[index*4+3] = value;

                }
            }
        }

        // Draw the bitmap


        // Draw the information
        Simp.set_shader_for_text();
        Simp.draw_text(default_font, 5, FONT_SIZE * 3, "Press S to step, I to interrupt, R to reset.");

        format_pc :=  FormatInt.{value=machine.pc, base=16, minimum_digits=4};
        format_a  :=  FormatInt.{value=machine.a,  base=16, minimum_digits=2};
        format_x  :=  FormatInt.{value=machine.x,  base=16, minimum_digits=2};
        format_y  :=  FormatInt.{value=machine.y,  base=16, minimum_digits=2};
        
        Simp.draw_text(default_font, 5, FONT_SIZE, tprint("Program-counter: 0x%", format_pc));
        Simp.draw_text(default_font, 500, FONT_SIZE, tprint("Accumulator: 0x%  X: 0x% Y: 0x%", format_a, format_x, format_y));


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