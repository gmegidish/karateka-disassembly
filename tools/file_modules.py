"""
Module definitions for splitting karateka.asm into multiple files.
Each module is (start_offset, end_offset, filename, description).
Boundaries chosen at natural function group transitions.
"""

CODE_MODULES = [
    # (start, end, filename, description)
    (0x00000, 0x00255, "startup.asm",      "C runtime startup, entry point, error handlers"),
    (0x00255, 0x005E5, "game.asm",         "Game init, main loop, scene management, actor init"),
    (0x005E5, 0x00640, "video.asm",        "Video mode, cursor, shutdown"),
    (0x00640, 0x00B4E, "actors.asm",       "Actor/character initialization and management"),
    (0x00B4E, 0x01277, "graphics.asm",     "Screen drawing, sprites, backgrounds, animation display"),
    (0x01277, 0x0166D, "resources.asm",    "Figure/animation data loading and setup"),
    (0x0166D, 0x01734, "disk.asm",         "Disk I/O, CGA palette, Ctrl+Q check, sector reading"),
    (0x01734, 0x019A2, "timer.asm",        "Screen setup, timer/delay functions"),
    (0x019A2, 0x01AC2, "sound.asm",        "Sound system: init, play, stop, music callback"),
    (0x01AC2, 0x0205E, "combat.asm",       "Combat system: update, hit detection, damage, AI"),
    (0x0205E, 0x022E1, "math.asm",         "Math helpers: multiply, divide, modulo"),
    (0x022E1, 0x02BDD, "scene.asm",        "Scene update, animation processing, random numbers"),
    (0x02BDD, 0x03A2D, "levels.asm",       "Level setup, cutscenes, scene transitions"),
    (0x03A2D, 0x04149, "effects.asm",      "Screen effects, vsync, buffers, UI, health bar, dialog"),
    (0x04149, 0x04619, "input.asm",        "Keyboard polling, joystick, video mode init"),
    (0x04619, 0x04FDD, "system.asm",       "Controls, interrupt handlers, collision, disk prompts"),
    (0x04FDD, 0x05953, "fileio.asm",       "File loading, resource management, parsing"),
    (0x05953, 0x05C12, "main.asm",         "C main(), resource loading entry"),
    (0x05C12, 0x06C9D, "crt.asm",          "C runtime: DOS wrappers, memory, strings, I/O"),
]

DATA_MODULES = [
    # These are emitted from DATA_REGIONS in convert.py
    # They go into data.asm
]
