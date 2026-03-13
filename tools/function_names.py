"""
Function name mapping for Karateka disassembly.
Based on analysis of DOS/BIOS interrupts, call graph, and behavior.
"""

FUNCTION_NAMES = {
    # === C Runtime (Lattice C 2.1) ===
    0x0023C: "crt_exit",              # INT 21h/4Ch - exit with return code
    0x05953: "main",                  # C main() - called from startup at 0x1F5
    0x05C12: "crt_realloc_down",      # INT 21h/4Ah - resize memory block (shrink)
    0x05C57: "crt_realloc_up",        # INT 21h/4Ah - resize memory block (grow)
    0x05C9B: "dos_create_file",       # INT 21h/3Ch - create file
    0x05CB5: "dos_open_file",         # INT 21h/3Dh - open file
    0x05CCF: "dos_close_file",        # INT 21h/3Eh - close file
    0x05CE6: "dos_read_file",         # INT 21h/3Fh - read file
    0x05D05: "dos_write_file",        # INT 21h/40h - write file
    0x05D24: "dos_seek_file",         # INT 21h/42h - seek file
    0x05D48: "dos_delete_file",       # INT 21h/41h - delete file (also 43h get/set attr)
    0x05D7E: "dos_ioctl",             # INT 21h/44h - IOCTL
    0x05D8D: "dos_rename_file",       # INT 21h/56h - rename file
    0x05DAB: "crt_init_io",           # C runtime I/O initialization
    0x06725: "dos_read_line",         # INT 21h/0Ah - buffered input
    0x06AF4: "crt_str_util",          # String utility
    0x06B84: "dos_int21",             # Generic INT 21h wrapper
    0x06BF5: "crt_long_multiply",     # 32-bit multiply helper

    # === Video / Display ===
    0x005E5: "game_shutdown",         # Calls cleanup, sets video mode, clears state
    0x00608: "set_video_mode",        # INT 10h/00h - set video mode (param: mode)
    0x00614: "set_cursor_pos",        # INT 10h/02h - set cursor position (col, row)
    0x04273: "video_set_mode_4",      # INT 10h/00h - set CGA mode 4 (320x200 4-color)
    0x04352: "check_graphics_card",   # INT 11h + INT 10h/0Fh - check for graphics adapter
    0x04373: "video_init",            # INT 10h/00h + INT 21h/0Eh - init video + select disk

    # === Keyboard / Input ===
    0x016A3: "check_ctrl_q",          # INT 21h/06h - check for Ctrl+Q (quit)
    0x04149: "poll_keyboard",         # Main keyboard polling - checks Ctrl+Q, special keys
    0x041FC: "wait_for_key",          # INT 21h/07h - blocking keyboard read
    0x04233: "flush_keyboard",        # Flush keyboard buffer
    0x04241: "consume_key",           # Read and discard a keystroke
    0x044D3: "check_joystick",        # Check joystick input

    # === Timer ===
    0x018BF: "delay_ticks",           # INT 1Ah - delay for N timer ticks
    0x018D5: "delay_with_input",      # Delay with keyboard check (interruptible)
    0x018EF: "timer_mark",            # INT 1Ah - save current timer value
    0x018F8: "timer_wait_3ticks",     # INT 1Ah - wait for 3 ticks since last mark

    # === Disk / File Operations ===
    0x016C1: "read_disk_sector",      # INT 13h - raw disk sector read
    0x01718: "load_game_disk",        # Load from game disk, check if present
    0x0169C: "disk_setup",            # Disk I/O setup
    0x04B7F: "show_insert_disk",      # "make sure your karateka disk is in drive a"
    0x04FDD: "load_file",             # High-level file load (calls dos_read_file)
    0x055F9: "load_resource",         # Load game resource file
    0x056DE: "load_resource_2",       # Another resource loader
    0x05B9C: "load_resource_3",       # Another resource loader

    # === Interrupt Vector Management ===
    0x0482B: "install_handlers",      # INT 21h/25h - install interrupt handlers
    0x04883: "save_int_vectors",      # Save original interrupt vectors
    0x0483C: "restore_int_vectors",   # Restore original interrupt vectors

    # === Graphics Rendering ===
    0x00B4E: "clear_screen",          # Called 14x - screen clear/fill
    0x00B5E: "draw_screen",           # Called 8x - main screen draw
    0x00C52: "draw_sprite",           # Sprite drawing routine
    0x00D68: "update_display",        # Called 14x - display update/vsync
    0x00D89: "draw_background",       # Background rendering
    0x00DD0: "scroll_screen",         # Screen scrolling
    0x00DEF: "draw_figure",           # Figure/character drawing
    0x00EE8: "erase_figure",          # Erase figure from screen
    0x00EEE: "animate_figure",        # Animate a figure (calls draw + delay)
    0x00F27: "animate_step",          # Single animation step
    0x00F52: "load_palette",          # Load color palette
    0x00FBB: "load_background",       # Load background image file
    0x01027: "load_animation",        # Load animation data file
    0x0166D: "set_cga_palette",       # Set CGA palette colors
    0x01277: "init_figure",           # Initialize figure/sprite data
    0x012EB: "setup_figure_data",     # Setup figure animation data
    0x01734: "setup_screen",          # Screen setup/configuration

    # === Sound ===
    0x019A2: "play_sound",            # Sound effect playback
    0x019AE: "init_sound",            # Initialize sound system
    0x019EE: "stop_sound",            # Stop current sound
    0x0190B: "set_music_callback",    # Set up music interrupt callback

    # === Game Logic ===
    0x00255: "game_init",             # Main game initialization - calls everything
    0x003C7: "game_main_loop",        # Main game loop (24 callees!)
    0x00569: "game_scene",            # Scene management
    0x005AD: "load_scene",            # Load a new scene
    0x00629: "calc_screen_offset",    # Calculate screen memory offset
    0x00640: "init_actor",            # Initialize actor/character data
    0x0083C: "process_animation",     # Process animation sequence
    0x0094C: "run_cutscene",          # Cutscene/scripted sequence (entry point, not called)

    # === Combat System ===
    0x01AC2: "combat_update",         # Combat state update (called 9x)
    0x01B27: "combat_check_hit",      # Check for hit/collision
    0x01C58: "combat_apply_damage",   # Apply damage to actor
    0x01D07: "combat_ai",             # Enemy AI decision making

    # === Scene / Level Management ===
    0x022E1: "scene_update",          # Scene state update
    0x02BDD: "level_setup",           # Level/stage setup
    0x0301C: "scene_transition",      # Scene transition effect
    0x031AA: "cutscene_play",         # Play cutscene sequence (16 callees)
    0x03162: "cutscene_step",         # Single cutscene step

    # === Animation System ===
    0x029E9: "anim_frame_update",     # Animation frame update
    0x02A0F: "anim_interpolate",      # Animation interpolation
    0x02A49: "anim_process",          # Process animation command
    0x02B94: "anim_command",          # Execute animation command
    0x02F2D: "anim_set_bg",           # Set background for animation
    0x02F98: "anim_set_figure",       # Set figure for animation

    # === Screen Effects ===
    0x03A2D: "effect_wipe",           # Screen wipe effect
    0x03A8A: "effect_fade",           # Fade effect
    0x03AD0: "effect_scroll_left",    # Scroll left effect
    0x03B19: "effect_scroll_right",   # Scroll right effect
    0x03B5C: "effect_dissolve",       # Dissolve effect
    0x03BAE: "wait_vsync",            # Wait for vertical sync (called 21x!)
    0x03DB9: "screen_copy",           # Screen buffer copy
    0x03DD5: "screen_copy_region",    # Copy screen region
    0x03E16: "init_screen_buffers",   # Initialize screen double-buffer
    0x03E7C: "swap_screen_buffers",   # Swap front/back buffers
    0x03F3F: "draw_health_bar",       # Draw health/status bar
    0x03F56: "draw_ui_element",       # Draw UI element
    0x03F71: "show_dialog",           # Show dialog/text box
    0x03FB7: "draw_scene_element",    # Draw scene-specific element
    0x03FDA: "draw_gate",             # Draw gate/door
    0x03FFD: "check_disk_prompt",     # Check disk and show prompt if needed
    0x040A1: "update_score",          # Update score display

    # === Physics / Movement ===
    0x04441: "update_position",       # Update actor position
    0x043AA: "apply_gravity",         # Apply gravity to actor
    0x04619: "init_controls",         # Initialize control scheme
    0x04A37: "collision_check",       # Collision detection
    0x04B0A: "bounds_check",          # Bounds checking

    # === File / Resource Management ===
    0x04883: "save_vectors",          # Save interrupt vectors
    0x04C99: "resource_manager",      # Resource management (entry point)
    0x04DB9: "file_manager",          # File management wrapper
    0x04D77: "build_filename",        # Construct filename from parts
    0x05501: "parse_resource_data",   # Parse resource file data
    0x05356: "callback_handler",      # Callback/function pointer handler
    0x05907: "init_file_system",      # Initialize file system
    0x0589A: "print_error",           # Print error message and exit
    0x05DE3: "read_data_block",       # Read a block of data from file
    0x066DF: "format_string",         # String formatting (printf-like)
    0x06810: "string_copy",           # String copy utility

    # === Math ===
    0x0205E: "math_multiply",         # Multiplication helper
    0x022A4: "math_divide",           # Division helper
    0x022BC: "math_modulo",           # Modulo helper
    0x02605: "math_random",           # Random number generator
}
