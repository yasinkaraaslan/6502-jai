machine: Machine_6502;

FONT_SIZE :: 32;
default_font: *Simp.Dynamic_Font;

BITMAP_WIDTH :: 16;
BITMAP_HEIGHT :: 16;
bitmap: Simp.Bitmap;
texture: Simp.Texture;

window_width := 1280;
window_height := 720;

main :: () {
    init(*machine);
    defer deinit(*machine);
    args := get_command_line_arguments();
    loaded := false;

    if args.count < 2 {
        loaded = load_file("draw.bin");
    }
    else {
        for args {
            if it_index == 0  continue;
            ok := load_file(it);
            if ok  {
                loaded = true;
                break;
            } 
        }
    }
    
    if !loaded {
        print("We haven't been able to read any file provided.");
        return;
    }


    reset(*machine);
    window := create_window(window_width, window_height, "6502 Emulation!");

    Simp.set_render_target(window);
    Simp.set_shader_for_color();

    default_font = Simp.load_font("fonts", "FiraSans-Regular.otf", FONT_SIZE);


    defer Simp.deinit(*bitmap);
    Simp.bitmap_alloc(*bitmap, BITMAP_WIDTH, BITMAP_HEIGHT, .RGBA8);

    quit := false;
    while !quit {
        reset_temporary_storage();
        update_window_events();
        for get_window_resizes() {
            Simp.update_window(window);
            window_width = it.width;
            window_height = it.height;
            recompute_the_texture();
        }

        for events_this_frame {
            if it.type == .QUIT quit = true;
            if it.type == .KEYBOARD {
                if it.repeat || it.key_pressed  continue;
                if it.key_code == {
                case #char "L";
                    for 0..3
                        step(*machine);
                    recompute_the_texture();
                case #char "S";
                    step(*machine);
                    recompute_the_texture();
                case #char "R";
                    reset(*machine);
                case #char "I";
                    interrupt(*machine);
                }
            }
        }

        Simp.clear_render_target(0.3, 0.3, 0.6, 1.0);

        Simp.set_shader_for_images(*texture);
        Simp.immediate_quad(50,50,xx (window_width - 50),xx (window_height - 50), .{1,1,1,1});

        draw_machine_info();
        Simp.swap_buffers(window, true);
    }

}

recompute_the_texture :: () {
    highest := 0;

    if window_width > BITMAP_WIDTH && window_height > BITMAP_HEIGHT {
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
        Simp.texture_load_from_bitmap(*texture, *bitmap);
    }
}

load_file :: (file_name: string) -> bool {
    content, ok := read_entire_file(file_name); 
    defer free(content);

    if !ok || !content  return false;

    if content.count < MEMORY_SIZE_6502 {
        print("Size of the file is less than the memory of 6502, copying the file to the upper portion of the memory (to make sure reset and interrupt vectors get set).");
        memcpy(machine.memory.data + (MEMORY_SIZE_6502 - content.count), content.data, content.count);
    }
    else {
        if content.count > MEMORY_SIZE_6502  print("Size of the file is more than the memory of 6502, copying the file's lower portion to the memory.");
        memcpy(machine.memory.data, content.data, MEMORY_SIZE_6502);
    }
    return true;
}

draw_machine_info :: () {
    color     :=  Vector4.{0.80, 0.80, 0.80, 1};
    format_pc :=  FormatInt.{value=machine.pc, base=16, minimum_digits=4};
    format_a  :=  FormatInt.{value=machine.a,  base=16, minimum_digits=2};
    format_x  :=  FormatInt.{value=machine.x,  base=16, minimum_digits=2};
    format_y  :=  FormatInt.{value=machine.y,  base=16, minimum_digits=2};

    Simp.set_shader_for_text();
    Simp.draw_text(default_font, 5, FONT_SIZE * 2 + 5, "Press S to step, I to interrupt, R to reset, L to step one loop.", color);

    Simp.draw_text(default_font, 5, FONT_SIZE, tprint("Program-counter: 0x%", format_pc), color);
    
    a_width := Simp.prepare_text(default_font, tprint("Accumulator: 0x%", format_a));
    Simp.draw_prepared_text(default_font, window_width / 2 - 50, FONT_SIZE, color);

    y_width := Simp.prepare_text(default_font, tprint("Y: %", format_y));
    Simp.draw_prepared_text(default_font, window_width - 150, FONT_SIZE, color);

    x_width := Simp.prepare_text(default_font, tprint("X: %", format_x));
    Simp.draw_prepared_text(default_font, window_width - 250, FONT_SIZE, color);
}
#import "Math";
#import "Window_Creation";
#import "File";
#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import,dir "../../6502_Emulation";