# Karateka DOS Matching Disassembly

## Project Goal
Reconstruct a byte-identical build of `disk/KARATEKA.EXE` from assembly source files. Every change must pass `make` (which runs `nasm -f bin` then `cmp` against the original). The original EXE is never modified.

## Build
```
make          # build + verify (MATCH OK = success)
make clean    # remove build artifacts
```
Requires: `nasm`, `ndisasm` (both installed via homebrew).

## The Executable

- **File**: `disk/KARATEKA.EXE` (87,990 bytes)
- **Format**: MS-DOS MZ EXE, 16-bit real mode x86
- **Compiler**: Lattice C 2.1, IBM PC version by The Connelley Group
- **Game**: Karateka (1986) by Jordan Mechner, Broderbund Software

### MZ Header
- Header size: 512 bytes (32 paragraphs)
- Entry point: CS:IP = 0000:0002
- SS:SP = 155C:0080
- 4 relocations at code offsets 0x0004, 0x0009, 0x4819, 0x482D
- Max memory allocation: 0xFFFF paragraphs

### Memory Layout (code section offsets, after 512-byte header)
| Range | Size | Content |
|-------|------|---------|
| 0x0000-0x0254 | ~600B | C runtime startup, error handlers |
| 0x0255-0x05E4 | ~900B | Game init, main loop, scene mgmt |
| 0x05E5-0x063F | ~90B | Video mode, cursor |
| 0x0640-0x0B4D | ~1.2KB | Sprite rendering (draw_sprite, mirrored, right-edge clipping) |
| 0x0B4E-0x1276 | ~1.8KB | Graphics rendering (screen buffer, backgrounds, animation display) |
| 0x1277-0x166C | ~1KB | Animation script loading and bytecode compilation |
| 0x166D-0x1733 | ~200B | File open retry, Ctrl+Q quit, copy protection disk read |
| 0x1734-0x19A1 | ~620B | Animation script interpreter, timer/delay, music playback |
| 0x19A2-0x1AC1 | ~290B | Animation data loading (enemy offsets, player data, compaction) |
| 0x1AC2-0x205D | ~1.4KB | Combat init, state setup, enemy spawn, player input |
| 0x205E-0x22E0 | ~640B | Player animation select, memcpy, sprite frame copy |
| 0x22E1-0x2BDC | ~2.3KB | Scene update, enemy AI, animation processing |
| 0x2BDD-0x3A2C | ~3.6KB | Level setup, cutscenes, transitions |
| 0x3A2D-0x4148 | ~1.8KB | Screen effects, vsync, double buffer, UI |
| 0x4149-0x4618 | ~1.2KB | Keyboard/joystick input, video init, hit zone check |
| 0x4619-0x4FDC | ~2.5KB | Controls, interrupt handlers, file I/O (fopen/fclose/fread IOB), heap |
| 0x4FDD-0x5952 | ~2.4KB | File loading, resource management |
| 0x5953-0x5C11 | ~700B | C main() |
| 0x5C12-0x6C9C | ~4.2KB | C runtime (DOS wrappers, memory, strings) |
| 0x6C9D-0x155B5 | ~56KB | **Data section** (see below) |

### Data Section Regions
| Range | Name | Content |
|-------|------|---------|
| 0x6C9D-0x6CB0 | lattice_c_runtime_tail | End of C runtime |
| 0x6CB0-0x6D22 | compiler_info | "Lattice C 2.1" identifier |
| 0x6D22-0x6D7E | error_strings | "Invalid stack size", "STACK OVERFLOW", etc. |
| 0x6E16-0x6E88 | animation_commands | set_tune, set_bg, set_fig, chg_fig, do_scr, del_fig, set_wipe, set_nowipe, wait, init_sal, set_pos, inc_x, loop, end_animation |
| 0x6E88-0x6FC2 | animation_tables | bal00-bal03, ksi0-ksi4, kmi0-kmi4 (animation sequence names) |
| 0x6FC2-0x6FD7 | index_filenames | "qazwsx46 b0.ind", ".dat" |
| 0x6FD7-0xAE57 | game_data_1 | Animation/graphics data (~16KB) |
| 0xAE57-0xAEBB | game_strings | "Karateka needs a graphics adapter card to operate correctly.", filenames (allgal, fuji.bcg, title.bcg, cal00, cal01) |
| 0xAEBB-0x12918 | game_data_2 | Large graphics/animation data block (~31KB) |
| 0x12918-0x12970 | file_strings | "castle.bcg", format strings ("%d %d %d"), "KARATEKA COPYRIGHT 1986 BRODERBUND SOFTWARE" |
| 0x14200-0x14360 | file_tables | allpal, cal07a, fuji.bcg, cal04-06, allval, cal03, prngal, cal07 |
| 0x14855-0x14BE0 | story_text | Full intro/outro narrative (see below) |
| 0x14F69-0x15060 | device_names | DOS device names: CON:, PRN:, LST:, LPT:, AUX:, COM:, NUL: (uppercase and lowercase) |

## Architecture

### Call Graph
- All 166 functions live in 0x0000-0x6C9C (the code section)
- No call targets exist beyond 0x6C9C — everything after is data
- `main()` at 0x5953 is called from the C runtime startup at 0x01F5
- `main()` calls `game_init()` which orchestrates everything
- `game_main_loop()` at 0x03C7 has the most callees (24 functions)
- `wait_vsync()` at 0x3BAE is the most-called function (21 callers)

### Lattice C Conventions
- Function prologue: `push bp` / `mov bp,sp` (the mov uses alternate encoding 0x8B 0xEC)
- Function epilogue: `mov sp,bp` / `pop bp` / `ret` (mov uses 0x8B 0xE5)
- Stack overflow check at function entry: `cmp sp,[0x17]` / `ja .ok` / `jmp 0x420` (stack overflow handler)
- Parameters passed on stack, accessed via `[bp+0x4]`, `[bp+0x6]`, etc.
- Return values in AX
- DOS error code stored at `[0x80]` by all DOS wrapper functions

### Key Functions (172 named)
See `tools/function_names.py` for the complete mapping. Highlights:
- **game_init** (0x0255): Master initialization — checks graphics card, installs handlers, loads game disk, enters main loop
- **game_main_loop** (0x03C7): Plays intro sequence, then enters gameplay loop (24 callees)
- **poll_keyboard** (0x4149): Keyboard input — handles Ctrl+Q (quit), Ctrl+R (restart), Ctrl+S (sound mode cycle), arrow key mapping
- **init_combat_level** (0x1AC2): Initializes a combat encounter — loads animation data, scripts, sets up state
- **init_combat_state** (0x1B27): Sets player/enemy positions, camera bounds, health for a new encounter
- **read_player_input** (0x1D07): Reads keyboard/joystick, translates to combat move via key_to_move → combat_resolve_move
- **scene_update** (0x22E1): Per-frame update — processes player and enemy animation frames, camera follow, sprite buffers
- **enemy_ai_decide** (0x2605): Enemy AI decision function — returns animation index based on distance, health, combat phase
- **player_anim_select** (0x205E): Player animation state machine — selects next animation based on combat state
- **level_setup** (0x2BDD): Combat encounter management — hit detection, health regen, enemy spawn/despawn
- **cutscene_play** (0x31AA): Level transition state machine — gate openings, boss introductions, endgame
- **wait_vsync** (0x3BAE): Sound/sync dispatcher — 21 callers, handles music playback and frame timing
- **draw_sprite** (0x0640): Renders sprite to offscreen buffer with sub-pixel alignment and CGA bit rotation
- **load_anim_script** (0x1277): Loads animation script file, compiles text commands to bytecode
- **run_anim_script** (0x1734): Bytecode interpreter for animation scripts (14 opcodes)
- **fopen_iob** (0x483C): Lattice C fopen — scans IOB array for free slot, opens file
- All DOS wrappers: dos_open_file, dos_read_file, dos_close_file, dos_write_file, dos_seek_file, dos_delete_file, dos_ioctl, dos_rename_file

### Video
- Uses CGA mode 4 (320x200, 4 colors)
- Double-buffered rendering (init_screen_buffers, swap_screen_buffers)
- INT 10h for mode setting and cursor control
- Screen effects: wipe, fade, scroll left/right, dissolve

### Sound
- PC speaker via direct port I/O (toggle_speaker, play_speaker_data)
- Music playback embedded in wait_vsync — 15 music data pointers, two-channel tone generator with vibrato
- Music sequences triggered via play_music_sequence (saves/restores scene state, plays animation+music, returns)

### Input
- INT 21h/06h for non-blocking keyboard check (check_ctrl_q)
- INT 21h/07h for blocking keyboard read (wait_for_key)
- Joystick support via check_joystick (0x44D3) — maps directions+buttons to key codes
- Ctrl+Q = quit, Ctrl+S = cycle sound mode (0/1/2), Ctrl+R = restart game
- Debug keys: Ctrl+X/Y/E/B toggle axis swaps and button swaps, Ctrl+N clears all
- Arrow keys mapped to '4'/'6', joystick combos to combat key codes ('w','x','s','q','z','a')

### File I/O
- Game resources loaded from disk: .bcg (backgrounds), animation data (bal, cal, gal, pal, val files)
- INT 13h for raw sector reads (copy protection or direct disk access)
- Index files: "qazwsx46 b0.ind" (obfuscated name), ".dat"
- Resources: allgal, allpal, allval, allbal, allcal, prngal, castle.bcg, fuji.bcg, title.bcg, cal00-cal07a

## Story Text (from binary)
The game's intro narrative, extracted from 0x14855:
> "high atop a craggy cliff, guarded by an army of fierce warriors, stands the fortress of the evil warlord akuma. deep in the darkest dungeon of the castle, akuma gloats over his lovely captive, the princess mariko."
>
> "you are one trained in the way of karate — a karateka. alone and unarmed, you must defeat akuma and rescue the beautiful mariko."
>
> "put fear and self-concern behind you. focus your will on your objective, accepting death as a possibility. this is the way of the karateka."

The outro:
> "and so this adventure ends. the evil akuma lies vanquished, the beautiful mariko safe in your arms. for the first time in memory, the village basks in the sunlight of peace. but beware — for the true karateka there is always a next time..."

Credits: "a game by jordan mechner" / "ibm version by the connelley group"

Note: `{` = period, `|` = comma, `}` = dash, `~` = hyphen in the game's custom character mapping.

## Disassembly Status

### Conversion Rate
- **87.9% of code instructions** are real NASM assembly
- **12.1%** remain as `db` with instruction comments (NASM encoding limitations)
- **100% of data** is properly formatted with ASCII preview and string detection

### Known NASM Encoding Limitations
These produce different byte sequences than the original Lattice C compiler:
1. **ALU reg,reg alternate encoding** (~982 instances): `xor ax,ax` = 0x33 0xC0 (original) vs 0x31 0xC0 (NASM). Both are valid x86, but NASM picks the opposite opcode form. Affects: mov, xor, add, cmp, and, or, sub between registers.
2. **Immediate size optimization** (~70 instances): `and di,0xFFFE` = 0x81 0xE7 0xFE 0xFF (original, 4 bytes) vs 0x83 0xE7 0xFE (NASM, 3 bytes with sign extension). NASM optimizes to the shorter form.
3. **Short jumps to non-instruction boundaries** (~134 instances): jumps that land in data regions or mid-instruction. Kept as raw bytes.

### Files
- `src/karateka.asm` — Master file with %include directives
- `src/*.asm` — 21 module files split by purpose
- `tools/convert.py` — Converter script (regenerates all src/ from binary + ndisasm)
- `tools/function_names.py` — 172 function name mappings
- `tools/file_modules.py` — Module split definitions
- `reference/karateka.dis` — ndisasm reference output (40,336 lines)
- `disk/KARATEKA.EXE` — Original binary (never modified)

### Running the Converter
```
PYTHONPATH=tools python3 tools/convert.py && make
```
This regenerates all `src/*.asm` files from the binary and verifies the build.

## What's Been Done
- **172 functions named and documented** with input/output parameters, algorithm descriptions
- **176 EQU variable definitions** in data.asm covering CRT runtime, game state, combat, animation, joystick, file I/O, heap
- **Animation script system fully documented** — 14 opcodes, bytecode compiler (parse_anim_command), interpreter (run_anim_script)
- **Combat system decoded** — player input chain (read_player_input → key_to_move → combat_resolve_move), enemy AI (enemy_ai_decide), hit detection (check_hit_zone), health regen timers
- **Sprite renderer documented** — three-function pipeline (draw_sprite, draw_sprite_mirrored, draw_sprite_rightedge) with CGA sub-pixel bit rotation
- **Lattice C runtime identified** — fopen_iob, fclose_iob, fread_iob, fgets_iob, heap_alloc, crt_malloc/free, 25 CRT functions documented
- **All code reformatted** with consistent tab indentation
- **Copy protection identified** — read_disk_sector uses INT 13h to read specific tracks and verify CRC error patterns

## What's Left To Do
1. Name the remaining ~20 unnamed code blocks (unlabeled sections within larger functions)
2. Document the remaining graphics.asm and effects.asm functions in detail
3. Decode the graphics data format (.bcg files, sprite encoding, RLE compression)
4. Map the animation data tables (0x6FD7-0xAE57, 0xAEBB-0x12918) — frame data, sequence definitions
5. Document the level layout tables — per-level position/boundary data at [si+0x2E6], [si+0x2DC], etc.
6. Understand the game's scene/encounter progression fully (scene_index values 1-7 per level)
