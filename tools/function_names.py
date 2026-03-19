"""
Function name mapping for Karateka disassembly.
Based on analysis of DOS/BIOS interrupts, call graph, and behavior.
"""

FUNCTION_NAMES = {
    # === C Runtime (Lattice C 2.1) ===
    0x0023C: "crt_exit",              # INT 21h/4Ch - exit with return code
    0x05953: "main",                  # C main() - called from startup at 0x1F5
    0x05B2E: "strncmp",              # C runtime strncmp()
    0x05B9C: "strcat",               # C runtime strcat()
    0x05BCE: "strncat",              # C runtime strncat() (dead code)
    0x05C12: "crt_realloc_down",     # INT 21h/4Ah - resize memory block (shrink)
    0x05C57: "crt_realloc_up",       # INT 21h/4Ah - resize memory block (grow)
    0x05C9B: "dos_create_file",      # INT 21h/3Ch - create file
    0x05CB5: "dos_open_file",        # INT 21h/3Dh - open file
    0x05CCF: "dos_close_file",       # INT 21h/3Eh - close file
    0x05CE6: "dos_read_file",        # INT 21h/3Fh - read file
    0x05D05: "dos_write_file",       # INT 21h/40h - write file
    0x05D24: "dos_seek_file",        # INT 21h/42h - seek file
    0x05D48: "dos_delete_file",      # INT 21h/41h - delete file (also 43h get/set attr)
    0x05D7E: "dos_ioctl",            # INT 21h/44h - IOCTL
    0x05D8D: "dos_rename_file",      # INT 21h/56h - rename file
    0x05DAB: "crt_init_io",          # C runtime I/O initialization
    0x05E33: "parse_number",         # scanf-style number parser (decimal/octal/hex/long)
    0x06342: "crt_file_read_byte",   # FILE buffer refill / getc implementation
    0x0644E: "crt_file_write_byte",  # FILE buffer write / putc implementation
    0x06655: "crt_alloc_file_buffer", # Allocate dynamic I/O buffer for FILE struct
    0x066B9: "strlen",               # C runtime strlen()
    0x066DF: "format_string",        # String formatting (printf-like)
    0x06725: "dos_read_line",        # INT 21h/0Ah - buffered input
    0x06731: "heap_init_free_list",  # Initialize heap free-list head node
    0x06779: "heap_expand",          # Grow heap by N blocks of 0x400 bytes
    0x0682D: "crt_malloc",           # Free-list malloc implementation
    0x06810: "string_copy",          # String copy utility
    0x06954: "crt_free_small",       # 16-bit free wrapper (zero-extends, calls crt_free)
    0x06974: "crt_free",             # Free-list free with block coalescing
    0x06AF4: "crt_strcmp",            # C runtime strcmp() - compare two null-terminated strings
    0x06B3A: "crt_cmp_long",         # Signed 32-bit comparison (AX:BX vs CX:DX)
    0x06B57: "crt_mul_long",         # Unsigned 32-bit multiply (AX:BX * CX:DX)
    0x06B84: "dos_int21",            # Generic INT 21h wrapper
    0x06B96: "crt_file_reset_buffer", # Free FILE buffer, reset to inline mode
    0x06BF5: "crt_long_multiply",    # 32-bit multiply helper

    # === Video / Display ===
    0x005E5: "game_shutdown",        # Calls cleanup, sets video mode, clears state
    0x00608: "set_video_mode",       # INT 10h/00h - set video mode (param: mode)
    0x00614: "set_cursor_pos",       # INT 10h/02h - set cursor position (col, row)
    0x04257: "noop_stub",            # Empty function (single ret)
    0x0425E: "detect_hercules_vsync", # Probe port 0x3BA for Hercules vsync transition
    0x042D1: "init_hercules_mode",   # Initialize Hercules graphics mode
    0x0433E: "program_crtc_registers", # Program 6845 CRTC registers from table
    0x04396: "clear_video_buffer",   # Clear 32KB video segment to zero
    0x04273: "video_set_mode_4",     # INT 10h/00h - set CGA mode 4 (320x200 4-color)
    0x04352: "check_graphics_card",  # INT 11h + INT 10h/0Fh - check for graphics adapter
    0x04373: "video_init",           # INT 10h/00h + INT 21h/0Eh - init video + select disk

    # === Keyboard / Input ===
    0x016A3: "check_ctrl_q",         # INT 21h/06h - check for Ctrl+Q (quit)
    0x04149: "poll_keyboard",        # Main keyboard polling - checks Ctrl+Q, special keys
    0x041FC: "wait_for_key",         # INT 21h/07h - blocking keyboard read
    0x04233: "flush_keyboard",       # Flush keyboard buffer
    0x04241: "consume_key",          # Read and discard a keystroke
    0x044D3: "check_joystick",       # Check joystick input

    # === Joystick ===
    0x046FC: "calibrate_joystick_axis", # Compute dead-zone thresholds for one axis
    0x0470D: "read_joystick_buttons", # Read fire buttons from port 0x201
    0x04756: "read_joystick",        # Read both axes and buttons, update state
    0x047EE: "read_joystick_axis",   # Time RC discharge for one joystick axis
    0x04806: "time_joystick_pulse",  # Fire one-shot and count axis bit discharge

    # === Timer ===
    0x018BF: "delay_ticks",          # INT 1Ah - busy-wait for AX timer ticks (~55ms each)
    0x018D5: "delay_with_input",     # Interruptible delay: AX/2 iterations of 2-tick waits, breaks on keypress
    0x018EF: "timer_mark",           # INT 1Ah - record current tick for frame pacing
    0x018F8: "timer_wait_3ticks",    # INT 1Ah - wait until 3 ticks since timer_mark (~165ms, ~6 FPS)

    # === Disk / File Operations ===
    0x016C2: "read_disk_sector",     # INT 13h - copy protection disk verification
    0x01718: "load_game_disk",       # Verify game disk signature is present
    0x0169C: "reset_to_game_start",  # Non-local goto (longjmp) back to game_init
    0x04B7F: "show_insert_disk",     # "make sure your karateka disk is in drive a"
    0x04FDD: "load_file",            # High-level file load (calls dos_read_file)
    0x052D8: "write_file_data",      # Write buffer to file with optional LF->CRLF translation
    0x055F9: "close_file_slot",      # Close DOS file handle and clear file slot
    0x05659: "delete_resource_file", # Delete file (only in real-disk mode)
    0x056DE: "strcpy",               # C runtime strcpy() - copy null-terminated string
    0x05741: "scanf_format_parser",  # Lattice C internal scanf format-string walker

    # === Interrupt Vector / Error Handling ===
    0x04810: "critical_error_handler", # INT 24h handler: saves regs, calls check_disk_prompt, retries
    0x0482B: "install_handlers",     # INT 21h/25h - install critical error handler (INT 24h)
    0x0483C: "fopen_iob",             # Scan IOB array for free slot, open file, return IOB pointer or 0

    # === Memory Management ===
    0x04BCE: "heap_alloc",           # Allocate paragraph-aligned block from heap
    0x04C73: "heap_alloc_16",        # Thin wrapper: 16-bit size heap_alloc, returns 0xFFFF on failure

    # === Graphics Rendering ===
    0x00B4E: "clear_screen",         # Clear offscreen buffer at DS:0x337
    0x00B5E: "advance_anim_frame",   # Reads animation frame data from two streams, handles RLE repeat markers
    0x00BC9: "render_figures",       # Draw all active figures from figure slot list to screen
    0x00C52: "prepare_screen_buffer", # Prepare offscreen buffer + background, dispatch by render_mode/scene_state
    0x00D68: "update_display",       # Copy offscreen buffer (DS:0x337) to CGA VRAM (B800:0) via scanline LUT
    0x00D89: "draw_background",      # Copy background region directly to CGA VRAM
    0x00DD0: "scroll_screen",        # Clear scroll region of offscreen buffer
    0x00DEF: "blit_buffer_to_vram",  # Transfer offscreen buffer to CGA VRAM pixel-column by pixel-column (4 bit-plane passes with visible sweep)
    0x00EE8: "blit_column_delay",    # Busy-wait delay (1000 cycles) between bit-plane passes in blit
    0x00EEE: "animate_figure",       # Animate a figure (calls draw + delay)
    0x00F27: "animate_step",         # Single animation step
    0x00F52: "load_palette",         # Load color palette
    0x00FBB: "load_background",      # Load background image file
    0x01027: "load_animation",       # Load animation data file
    0x0166D: "open_file_retry",      # Open file via open_file_slot, retry on failure
    0x01277: "load_anim_script",     # Load animation script file from disk and compile to bytecode
    0x012EB: "parse_anim_command",   # Parse one text animation command line into bytecode

    # === Animation Script System ===
    0x01734: "run_anim_script",      # Animation script interpreter - reads bytecode commands from 0xBD04, dispatches via jump table at 0xBCE8
    0x017FB: "anim_cmd_do_scr",      # Animation command: render current frame (calls render_figures), waits for key in single_step_mode
    0x0186C: "anim_cmd_init_sal",    # Animation command: reset figure list and rendering state (init scene animation list)
    0x01976: "build_anim_offsets_alt", # Build animation frame offset table for secondary data (base 0xC428, table 0xC3D4)
    0x0197E: "build_anim_offsets",   # Build animation frame offset table - scans 42 frames (0x11-byte records or 2-byte skip markers, 0xFF terminated)

    # === Sound ===
    0x019A2: "build_enemy_anim_offsets", # Build frame offset lookup table for enemy animations
    0x019AE: "load_player_anim_data", # Load player animation script data and build offset tables
    0x019EE: "compact_anim_data",    # Compact/reorganize animation bytecode data and rebuild lookup tables
    0x0190B: "play_music_sequence",  # Save scene state, play animation+music sequence, restore state, redirect return address

    # === Game Logic ===
    0x00255: "game_init",            # Main game initialization - calls everything
    0x003C7: "game_main_loop",       # Main game loop (24 callees!)
    0x00569: "game_scene",           # Scene management
    0x005AD: "load_scene",           # Load a new scene
    0x00629: "rand_range",            # Random integer in [0, max_value]
    0x00640: "draw_sprite",           # Render sprite to offscreen buffer (normal case)
    0x0083C: "draw_sprite_mirrored", # Render sprite entering from left (X < camera)
    0x0094C: "draw_sprite_rightedge", # Render sprite clipped at right edge (X + width > 320)

    # === Combat System ===
    0x01AC2: "init_combat_level",     # Initialize new combat encounter/level
    0x01B27: "init_combat_state",    # Initialize all combat state variables for encounter
    0x01C58: "spawn_enemy",          # Spawn/position enemy for new encounter
    0x01D07: "read_player_input",    # Read keyboard/joystick input, translate to combat move
    0x01D8A: "get_pending_key",      # Read pending keystroke, drain repeats in joystick mode
    0x01DD5: "key_to_move",          # Translate key code to combat move index (1-11)
    0x01F4E: "combat_resolve_move",  # Validate move against current pose, remap to animation ID
    0x02941: "combat_pick_far_attack", # Select far-attack animation based on distance

    # === Scene / Level Management ===
    0x022E1: "scene_update",         # Scene state update
    0x02BDD: "level_setup",          # Level/stage setup
    0x0301C: "scene_transition",     # Scene transition effect
    0x0316F: "blit_column_data",     # Copy 7 words from SI to CGA column at DI (stride 80)
    0x0317F: "blit_transition_col_left", # Blit left-side wipe column from buffer 0xd654
    0x03196: "blit_transition_col_right", # Blit right-side wipe column from buffer 0xd662
    0x031AA: "cutscene_play",        # Play cutscene sequence (16 callees)
    0x03162: "clear_gate_column",    # Clear 7-row column in transition buffer (gate animation)

    # === Animation System ===
    0x029E9: "anim_frame_update",    # Animation frame update
    0x02A0F: "anim_interpolate",     # Animation interpolation
    0x02A49: "anim_process",         # Process animation command
    0x02B94: "anim_command",         # Execute animation command
    0x02F2D: "anim_set_bg",          # Set background for animation
    0x02F98: "anim_set_figure",      # Set figure for animation

    # === Screen Effects ===
    0x03A2D: "effect_wipe",          # Screen wipe effect
    0x03A8A: "effect_fade",          # Fade effect
    0x03AD0: "effect_scroll_left",   # Scroll left effect
    0x03B19: "effect_scroll_right",  # Scroll right effect
    0x03B5C: "effect_dissolve",      # Dissolve effect
    0x03BAE: "wait_vsync",           # Wait for vertical sync (called 21x!)
    0x03DB9: "busy_wait_delay",      # Nested busy-wait delay loop
    0x03DD5: "toggle_speaker",       # Toggle PC speaker gate (port 0x61 bit 1)
    0x03DDE: "play_speaker_data",    # Play 256 bytes of 1-bit audio from speaker_pcm_buf
    0x03E16: "init_screen_buffers",  # Swap double-buffer pointers, clear figure slot flags
    0x03E7C: "render_glyphs",        # Render null-terminated glyph string to offscreen buffer
    0x03F29: "shift_glyph_pixels",   # Sub-pixel shift: shift DX:AX right by [0xdbb1]*2 bits
    0x03F3F: "show_scroll_text",     # Show scrolling text (story narration)
    0x03F56: "draw_ui_element",      # Draw UI element
    0x03F71: "show_dialog",          # Show multi-line dialog, wait for keypress
    0x03FB7: "draw_scene_element",   # Draw scene-specific element
    0x03FDA: "draw_gate",            # Draw gate/door
    0x03FFD: "check_disk_prompt",    # Check disk and show prompt if needed
    0x040A1: "update_score",         # Checksum verification / anti-tamper
    0x04028: "scroll_text_up",       # Scroll text up on CGA VRAM one scanline at a time
    0x040D5: "rand_next",            # LCG pseudo-random number generator
    0x04111: "set_rand_seed",        # Set random seed (dead code)
    0x04123: "rand_seed_io",         # Get/set random seed at [0xdf40]

    # === Physics / Movement ===
    0x04441: "add_figure_to_scene",  # Add figure entry to scene animation list buffer
    0x043AA: "check_hit_zone",       # Check if combat move hits based on move type and distance
    0x04619: "init_controls",        # Initialize control scheme
    0x04A37: "fclose_iob",           # Flush and close an IOB file entry
    0x04A91: "fgets_iob",            # Read line from stdin IOB until newline or EOF
    0x04B0A: "fread_iob",            # Read N bytes from IOB stream into buffer, return bytes read

    # === File / Resource Management ===
    0x04883: "init_iob_entry",       # Initialize IOB entry for file reading, open file and set up buffer
    0x04C99: "reset_heap",           # Reset heap pointers and free-list, optionally shrink DOS memory
    0x04DB9: "open_file_slot",       # Find free file table slot, set up flags for file operation
    0x04FB8: "open_file_rw",         # Thin wrapper: open_file_slot with read+write+create flags
    0x04D77: "get_file_slot",        # Validate file slot index, return pointer to 42-byte file table entry
    0x05501: "seek_and_read",        # Seek to offset in file, read data block
    # 0x05356 is a call site within write_file_data, not a separate function
    0x05907: "init_file_system",     # Initialize file system
    0x0589A: "print_error",          # Print error message and exit
    0x05DE3: "dos_putchar",          # INT 21h/02h - write character to stdout

    # === Math ===
    0x0205E: "player_anim_select",   # Select next animation ID for player character
    0x022A4: "memcpy_block",         # Copy block of bytes from source to destination
    0x022BC: "copy_sprite_frame",    # Copy sprite frame data with X offset adjustment
    0x02605: "enemy_ai_decide",      # Enemy AI decision function
}
