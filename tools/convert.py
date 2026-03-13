#!/usr/bin/env python3
"""
Convert KARATEKA.EXE into a NASM source file.
- MZ header as db bytes
- Code section: instructions with labels, function markers, and string detection
- Data regions shown as db with ASCII preview
- Short jumps use labels with 'short' keyword
- Near jumps/calls use adjusted absolute addresses
- Call targets labeled as functions (sub_XXXXX)
"""
import subprocess
import re
import os
from function_names import FUNCTION_NAMES
from file_modules import CODE_MODULES

TOOLS_DIR = os.path.dirname(__file__)
EXE_PATH = os.path.join(TOOLS_DIR, '..', 'disk', 'KARATEKA.EXE')
DIS_PATH = os.path.join(TOOLS_DIR, '..', 'reference', 'karateka.dis')
SRC_DIR = os.path.join(TOOLS_DIR, '..', 'src')
ASM_PATH = os.path.join(SRC_DIR, 'karateka.asm')
HEADER_SIZE = 512

JCC_MAP = {
    'jo': 'jo', 'jno': 'jno', 'jc': 'jc', 'jnc': 'jnc',
    'jz': 'jz', 'jnz': 'jnz', 'jna': 'jna', 'ja': 'ja',
    'js': 'js', 'jns': 'jns', 'jpe': 'jpe', 'jpo': 'jpo',
    'jl': 'jl', 'jnl': 'jnl', 'jng': 'jng', 'jg': 'jg',
    'jmp': 'jmp', 'jcxz': 'jcxz',
}

# Everything after last code instruction (0x6C9D) is data.
# All 166 call targets are in 0x0000-0x6C9C.
DATA_START = 0x6C9D
DATA_REGIONS = [
    (0x06C9D, 0x06CB0, "lattice_c_runtime_tail"),  # End of C runtime code
    (0x06CB0, 0x06D22, "compiler_info"),      # Lattice C 2.1 identifier + padding
    (0x06D22, 0x06D7E, "error_strings"),      # Stack overflow, invalid IO, etc.
    (0x06D7E, 0x06E16, "unknown_data_1"),     # Unknown data
    (0x06E16, 0x06E88, "animation_commands"), # set_tune, set_bg, set_fig, etc.
    (0x06E88, 0x06FC2, "animation_tables"),   # bal00, ksi0, kmi0, etc.
    (0x06FC2, 0x06FD7, "index_filenames"),    # qazwsx46 b0.ind, .dat
    (0x06FD7, 0x0AE57, "game_data_1"),        # Game data (animation/graphics)
    (0x0AE57, 0x0AEBB, "game_strings"),       # "Karateka needs a graphics adapter..."
    (0x0AEBB, 0x12918, "game_data_2"),        # Large data block (graphics/animation)
    (0x12918, 0x12970, "file_strings"),        # castle.bcg, format strings, copyright
    (0x12970, 0x14200, "game_data_3"),        # More game data
    (0x14200, 0x14360, "file_tables"),        # allpal, cal07a, fuji.bcg, etc.
    (0x14360, 0x14855, "game_data_4"),        # Game data
    (0x14855, 0x14BE0, "story_text"),         # Intro/outro narrative text
    (0x14BE0, 0x14F69, "ui_data"),            # UI data and text
    (0x14F69, 0x15060, "device_names"),       # DOS device names (CON:, PRN:, etc.)
    (0x15060, 0x155B6, "crt_runtime_data"),   # C runtime data/BSS
]


def parse_ndisasm(dis_path):
    instructions = []
    with open(dis_path) as f:
        for line in f:
            m = re.match(r'^([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)\s+(.*)', line.strip())
            if m:
                offset = int(m.group(1), 16)
                raw_bytes = bytes.fromhex(m.group(2))
                instr = m.group(3).strip()
                instructions.append((offset, raw_bytes, instr))
    return instructions


def is_short_jump(raw_bytes):
    opcode = raw_bytes[0]
    return ((0x70 <= opcode <= 0x7F) or opcode == 0xEB or opcode == 0xE3) and len(raw_bytes) == 2


def get_short_jump_target(raw_bytes, offset):
    rel8 = raw_bytes[1]
    if rel8 >= 0x80:
        rel8 -= 0x100
    return offset + 2 + rel8


def get_short_jump_mnemonic(instr):
    parts = instr.split()
    if parts:
        mnem = parts[0].lower()
        if mnem in JCC_MAP:
            return JCC_MAP[mnem]
    return None


def adjust_jump_target(instr):
    def replace_target(m):
        prefix = m.group(1)
        target = int(m.group(2), 16)
        new_target = target + HEADER_SIZE
        return f"{prefix}0x{new_target:x}"
    return re.sub(r'\b(j[a-z]+\s+|call\s+)(0x[0-9a-fA-F]+)\s*$', replace_target, instr)


def fix_instruction(instr, raw_bytes, offset, call_targets_set=None):
    instr = re.sub(r'\bint byte (0x[0-9a-fA-F]+)\b', r'int \1', instr)
    instr = re.sub(r'\bint byte (\d+)\b', r'int \1', instr)

    opcode = raw_bytes[0]

    if is_short_jump(raw_bytes):
        return None

    if opcode in (0xD0, 0xD1):
        instr = re.sub(r',0x0$', ',1', instr)

    # Near calls: replace with function name labels
    if opcode == 0xE8 and len(raw_bytes) == 3 and call_targets_set:
        m = re.search(r'call\s+(0x[0-9a-fA-F]+)', instr)
        if m:
            target = int(m.group(1), 16)
            if target in call_targets_set:
                instr = f'call {func_name(target)}'
                return instr  # skip adjust_jump_target

    # Near jumps: still use adjusted absolute addresses (labels would cause size optimization)
    if opcode in (0xE8, 0xE9) or (opcode == 0x0F and len(raw_bytes) >= 2 and 0x80 <= raw_bytes[1] <= 0x8F):
        instr = adjust_jump_target(instr)

    alt_alu_opcodes = {0x02, 0x03, 0x0A, 0x0B, 0x12, 0x13, 0x1A, 0x1B,
                       0x22, 0x23, 0x2A, 0x2B, 0x32, 0x33, 0x3A, 0x3B,
                       0x8A, 0x8B}
    if opcode in alt_alu_opcodes and len(raw_bytes) == 2:
        modrm = raw_bytes[1]
        if (modrm >> 6) & 3 == 3:
            return None

    if opcode == 0x81 and len(raw_bytes) == 4:
        imm16 = int.from_bytes(raw_bytes[2:4], 'little', signed=True)
        if -128 <= imm16 <= 127:
            return None

    return instr


def test_instruction(instr, expected_bytes, offset):
    output_pos = offset + HEADER_SIZE
    asm = f"[BITS 16]\n[ORG 0x{output_pos:04X}]\n{instr}\n"
    with open('/tmp/test_inst.asm', 'w') as f:
        f.write(asm)
    result = subprocess.run(['nasm', '-f', 'bin', '/tmp/test_inst.asm', '-o', '/tmp/test_inst.bin'],
                          capture_output=True, text=True)
    if result.returncode != 0:
        return False
    with open('/tmp/test_inst.bin', 'rb') as f:
        actual = f.read()
    return actual == expected_bytes


def format_db(raw_bytes, offset, comment=""):
    hex_bytes = ', '.join(f'0x{b:02X}' for b in raw_bytes)
    c = f"  ; {offset:05X}"
    if comment:
        c += f" {comment}"
    return f"db {hex_bytes}{c}"


def format_data_line(data_bytes, offset):
    """Format a data line with both hex and ASCII preview."""
    hex_bytes = ', '.join(f'0x{b:02X}' for b in data_bytes)
    ascii_preview = ''.join(chr(b) if 0x20 <= b <= 0x7E else '.' for b in data_bytes)
    return f'db {hex_bytes}  ; {offset:05X} |{ascii_preview}|'


def label_name(offset):
    return f"loc_{offset:05X}"


def func_name(offset):
    if offset in FUNCTION_NAMES:
        return FUNCTION_NAMES[offset]
    return f"sub_{offset:05X}"


def is_in_data_region(offset):
    for start, end, name in DATA_REGIONS:
        if start <= offset < end:
            return True
    return False


def get_data_region_name(offset):
    for start, end, name in DATA_REGIONS:
        if start <= offset < end:
            return name
    return None


def find_strings(code_data):
    """Find null-terminated ASCII strings in data."""
    strings = {}
    current = b''
    start = -1
    for i, b in enumerate(code_data):
        if 0x20 <= b <= 0x7E:
            if not current:
                start = i
            current += bytes([b])
        else:
            if len(current) >= 4 and b == 0x00 and any(c.isalpha() for c in current.decode('ascii')):
                strings[start] = current.decode('ascii')
            current = b''
            start = -1
    return strings


def main():
    with open(EXE_PATH, 'rb') as f:
        exe_data = f.read()

    instructions = parse_ndisasm(DIS_PATH)
    code_data = exe_data[HEADER_SIZE:]
    code_size = len(code_data)

    # Find strings
    strings = find_strings(code_data)

    # Build instruction offset set
    instruction_offsets = set()
    for offset, raw_bytes, instr in instructions:
        instruction_offsets.add(offset)

    # Collect short jump targets on instruction boundaries
    label_offsets = set()
    for offset, raw_bytes, instr in instructions:
        if is_short_jump(raw_bytes):
            target = get_short_jump_target(raw_bytes, offset)
            if target in instruction_offsets:
                label_offsets.add(target)

    # Collect call targets for function labels
    call_targets = set()
    for offset, raw_bytes, instr in instructions:
        opcode = raw_bytes[0]
        if opcode == 0xE8 and len(raw_bytes) == 3:
            m = re.search(r'(0x[0-9a-fA-F]+)', instr)
            if m:
                target = int(m.group(1), 16)
                call_targets.add(target)

    # === Generate output split into module files ===

    def get_module(offset):
        """Return the module filename for a given code offset."""
        for mod_start, mod_end, filename, desc in CODE_MODULES:
            if mod_start <= offset < mod_end:
                return filename
        return None

    # Dictionary of lines per module file
    module_lines = {}
    for _, _, filename, desc in CODE_MODULES:
        module_lines[filename] = [f'; {desc}', '']

    # Also prepare header and data
    header_lines = []
    header_lines.append('; MZ Header (512 bytes)')
    header_lines.append('')
    for i in range(0, HEADER_SIZE, 16):
        chunk = exe_data[i:i+16]
        hex_bytes = ', '.join(f'0x{b:02X}' for b in chunk)
        header_lines.append(f'db {hex_bytes}  ; {i:05X}')
    header_lines.append('')

    data_lines = []
    data_lines.append('; Data section')
    data_lines.append('; Everything after 0x6C9D is data (no call targets beyond this point)')
    data_lines.append('')

    match_count = 0
    db_count = 0
    expected_offset = 0
    current_module = None

    def emit(line, offset=None):
        """Emit a line to the correct module file."""
        nonlocal current_module
        if offset is not None:
            mod = get_module(offset)
            if mod:
                current_module = mod
        if current_module and current_module in module_lines:
            module_lines[current_module].append(line)
        else:
            # Shouldn't happen for code section
            pass

    # Emit code section (before DATA_START)
    for offset, raw_bytes, instr in instructions:
        if offset >= DATA_START:
            break

        # Fill gaps
        if offset > expected_offset:
            gap = code_data[expected_offset:offset]
            hex_bytes = ', '.join(f'0x{b:02X}' for b in gap)
            emit(f'db {hex_bytes}  ; {expected_offset:05X} (gap: {len(gap)} bytes)', expected_offset)
            db_count += 1

        expected_offset = offset + len(raw_bytes)

        # Check if we're entering a new module
        mod = get_module(offset)
        if mod and mod != current_module:
            current_module = mod

        # Emit function label
        if offset in call_targets:
            emit('', offset)
            emit(f'; ---- function {func_name(offset)} ----', offset)
            emit(f'{func_name(offset)}:', offset)

        # Emit jump target label
        if offset in label_offsets:
            emit(f'{label_name(offset)}:', offset)

        # Handle short jumps with labels
        if is_short_jump(raw_bytes):
            target = get_short_jump_target(raw_bytes, offset)
            mnem = get_short_jump_mnemonic(instr)
            if mnem and target in label_offsets:
                emit(f'{mnem} short {label_name(target)}  ; {offset:05X} {instr}', offset)
                match_count += 1
                continue
            emit(format_db(raw_bytes, offset, instr), offset)
            db_count += 1
            continue

        fixed = fix_instruction(instr, raw_bytes, offset, call_targets)

        if fixed is not None:
            is_label_call = fixed.startswith('call ') and not fixed.startswith('call 0x')
            if is_label_call or test_instruction(fixed, raw_bytes, offset):
                emit(f'{fixed}  ; {offset:05X}', offset)
                match_count += 1
                continue

        emit(format_db(raw_bytes, offset, instr), offset)
        db_count += 1

    # Emit data regions directly from binary
    for region_start, region_end, region_name in DATA_REGIONS:
        data_lines.append(f'; --- {region_name} (0x{region_start:05X}-0x{region_end:05X}) ---')

        region_data = code_data[region_start:region_end]
        i = 0
        while i < len(region_data):
            abs_off = region_start + i

            if abs_off in strings:
                s = strings[abs_off]
                str_len = len(s) + 1
                escaped = s.replace("'", "',0x27,'")
                data_lines.append(f"db '{escaped}', 0  ; {abs_off:05X} \"{s}\"")
                i += str_len
                db_count += 1
                continue

            end = min(i + 16, len(region_data))
            chunk = region_data[i:end]
            data_lines.append(format_data_line(chunk, abs_off))
            i += len(chunk)
            db_count += 1

        data_lines.append('')

    # Write module files
    for _, _, filename, _ in CODE_MODULES:
        filepath = os.path.join(SRC_DIR, filename)
        with open(filepath, 'w') as f:
            f.write('\n'.join(module_lines[filename]) + '\n')

    # Write header.asm
    with open(os.path.join(SRC_DIR, 'header.asm'), 'w') as f:
        f.write('\n'.join(header_lines) + '\n')

    # Write data.asm
    with open(os.path.join(SRC_DIR, 'data.asm'), 'w') as f:
        f.write('\n'.join(data_lines) + '\n')

    # Write master karateka.asm with %include directives
    master = []
    master.append('; Karateka (1986) - DOS matching disassembly')
    master.append('; Compiled with Lattice C 2.1, IBM version by The Connelley Group')
    master.append('; Build: nasm -f bin src/karateka.asm -o build/NEW.EXE')
    master.append(';')
    master.append('; Memory layout:')
    master.append(';   0x0000-0x01FF  MZ Header (512 bytes)')
    master.append(';   0x0200-0x06CFF Code section (~27KB)')
    master.append(';   0x06D00-0x155B6 Data section (~56KB)')
    master.append('')
    master.append('%include "header.asm"')
    master.append('')
    for _, _, filename, desc in CODE_MODULES:
        master.append(f'%include "{filename}"  ; {desc}')
    master.append('')
    master.append('%include "data.asm"')
    master.append('')

    with open(ASM_PATH, 'w') as f:
        f.write('\n'.join(master) + '\n')

    total = match_count + db_count
    pct = match_count / total * 100 if total else 0
    print(f"Converted: {match_count}/{total} instructions ({pct:.1f}%)")
    print(f"Remaining as db: {db_count}")
    print(f"Labels: {len(label_offsets)}")
    print(f"Functions: {len(call_targets)}")
    print(f"Strings found: {len(strings)}")


if __name__ == '__main__':
    main()
