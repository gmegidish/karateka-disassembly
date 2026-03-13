; Karateka (1986) - DOS matching disassembly
; Compiled with Lattice C 2.1, IBM version by The Connelley Group
; Build: nasm -f bin src/karateka.asm -o build/NEW.EXE
;
; Memory layout:
;   0x0000-0x01FF  MZ Header (512 bytes)
;   0x0200-0x06CFF Code section (~27KB)
;   0x06D00-0x155B6 Data section (~56KB)

%include "header.asm"

%include "startup.asm"  ; C runtime startup, entry point, error handlers
%include "game.asm"  ; Game init, main loop, scene management, actor init
%include "video.asm"  ; Video mode, cursor, shutdown
%include "actors.asm"  ; Actor/character initialization and management
%include "graphics.asm"  ; Screen drawing, sprites, backgrounds, animation display
%include "resources.asm"  ; Figure/animation data loading and setup
%include "disk.asm"  ; Disk I/O, CGA palette, Ctrl+Q check, sector reading
%include "timer.asm"  ; Screen setup, timer/delay functions
%include "sound.asm"  ; Sound system: init, play, stop, music callback
%include "combat.asm"  ; Combat system: update, hit detection, damage, AI
%include "math.asm"  ; Math helpers: multiply, divide, modulo
%include "scene.asm"  ; Scene update, animation processing, random numbers
%include "levels.asm"  ; Level setup, cutscenes, scene transitions
%include "effects.asm"  ; Screen effects, vsync, buffers, UI, health bar, dialog
%include "input.asm"  ; Keyboard polling, joystick, video mode init
%include "system.asm"  ; Controls, interrupt handlers, collision, disk prompts
%include "fileio.asm"  ; File loading, resource management, parsing
%include "main.asm"  ; C main(), resource loading entry
%include "crt.asm"  ; C runtime: DOS wrappers, memory, strings, I/O

%include "data.asm"

