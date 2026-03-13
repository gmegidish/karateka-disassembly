#!/usr/bin/env python3
"""
Convert KARATEKA.EXE into a NASM source file.
- MZ header as db bytes
- Code section: each instruction tested against NASM to verify encoding match
- Short jumps use labels with 'short' keyword
- Near jumps/calls use adjusted absolute addresses (not labels, to prevent NASM optimization)
- Mismatches kept as db with instruction comment
"""
import subprocess
import re
import sys
import os

EXE_PATH = os.path.join(os.path.dirname(__file__), '..', 'disk', 'KARATEKA.EXE')
DIS_PATH = os.path.join(os.path.dirname(__file__), '..', 'reference', 'karateka.dis')
ASM_PATH = os.path.join(os.path.dirname(__file__), '..', 'src', 'karateka.asm')
HEADER_SIZE = 512

JCC_MAP = {
    'jo': 'jo', 'jno': 'jno', 'jc': 'jc', 'jnc': 'jnc',
    'jz': 'jz', 'jnz': 'jnz', 'jna': 'jna', 'ja': 'ja',
    'js': 'js', 'jns': 'jns', 'jpe': 'jpe', 'jpo': 'jpo',
    'jl': 'jl', 'jnl': 'jnl', 'jng': 'jng', 'jg': 'jg',
    'jmp': 'jmp', 'jcxz': 'jcxz',
}

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
    """Add HEADER_SIZE offset to absolute jump/call targets for flat binary layout."""
    def replace_target(m):
        prefix = m.group(1)
        target = int(m.group(2), 16)
        new_target = target + HEADER_SIZE
        return f"{prefix}0x{new_target:x}"
    return re.sub(r'\b(j[a-z]+\s+|call\s+)(0x[0-9a-fA-F]+)\s*$', replace_target, instr)

def fix_instruction(instr, raw_bytes, offset):
    """Try to fix known NASM encoding differences. Returns None to keep as db."""
    instr = re.sub(r'\bint byte (0x[0-9a-fA-F]+)\b', r'int \1', instr)
    instr = re.sub(r'\bint byte (\d+)\b', r'int \1', instr)

    opcode = raw_bytes[0]

    if is_short_jump(raw_bytes):
        return None  # handled by label system

    # Shift by 1 fix
    if opcode in (0xD0, 0xD1):
        instr = re.sub(r',0x0$', ',1', instr)

    # Adjust near jump/call targets for flat binary layout
    if opcode in (0xE8, 0xE9) or (opcode == 0x0F and len(raw_bytes) >= 2 and 0x80 <= raw_bytes[1] <= 0x8F):
        instr = adjust_jump_target(instr)

    # ALU reg,reg alternate encoding
    alt_alu_opcodes = {0x02, 0x03, 0x0A, 0x0B, 0x12, 0x13, 0x1A, 0x1B,
                       0x22, 0x23, 0x2A, 0x2B, 0x32, 0x33, 0x3A, 0x3B,
                       0x8A, 0x8B}
    if opcode in alt_alu_opcodes and len(raw_bytes) == 2:
        modrm = raw_bytes[1]
        if (modrm >> 6) & 3 == 3:
            return None

    # Immediate size optimization (81 vs 83)
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

def label_name(offset):
    return f"loc_{offset:05X}"

def main():
    with open(EXE_PATH, 'rb') as f:
        exe_data = f.read()

    instructions = parse_ndisasm(DIS_PATH)
    code_data = exe_data[HEADER_SIZE:]
    code_size = len(code_data)

    # Build set of valid instruction offsets
    instruction_offsets = set()
    for offset, raw_bytes, instr in instructions:
        instruction_offsets.add(offset)

    # Collect short jump targets that land on valid instruction boundaries
    label_offsets = set()
    for offset, raw_bytes, instr in instructions:
        if is_short_jump(raw_bytes):
            target = get_short_jump_target(raw_bytes, offset)
            if target in instruction_offsets:
                label_offsets.add(target)

    # Generate output
    lines = []
    lines.append('; Karateka (1986) - DOS matching disassembly')
    lines.append('; Build: nasm -f bin src/karateka.asm -o build/NEW.EXE')
    lines.append(';')
    lines.append('; MZ Header: bytes 0x0000-0x01FF (512 bytes)')
    lines.append('; Code/Data: bytes 0x0200-end (87478 bytes)')
    lines.append('')

    # MZ Header
    lines.append('; === MZ HEADER ===')
    for i in range(0, HEADER_SIZE, 16):
        chunk = exe_data[i:i+16]
        hex_bytes = ', '.join(f'0x{b:02X}' for b in chunk)
        lines.append(f'db {hex_bytes}  ; {i:05X}')
    lines.append('')

    lines.append('; === CODE/DATA SECTION ===')
    lines.append('; Entry point: CS:IP = 0000:0002 (offset 0x0002 in code section)')
    lines.append('')

    match_count = 0
    db_count = 0
    expected_offset = 0

    for offset, raw_bytes, instr in instructions:
        # Fill gaps
        if offset > expected_offset:
            gap = code_data[expected_offset:offset]
            hex_bytes = ', '.join(f'0x{b:02X}' for b in gap)
            lines.append(f'db {hex_bytes}  ; {expected_offset:05X} (gap: {len(gap)} bytes)')
            db_count += 1

        expected_offset = offset + len(raw_bytes)

        # Emit label
        if offset in label_offsets:
            lines.append(f'{label_name(offset)}:')

        # Handle short jumps with labels
        if is_short_jump(raw_bytes):
            target = get_short_jump_target(raw_bytes, offset)
            mnem = get_short_jump_mnemonic(instr)
            if mnem and target in label_offsets:
                lines.append(f'{mnem} short {label_name(target)}  ; {offset:05X} {instr}')
                match_count += 1
                continue
            # Target not on instruction boundary or unknown mnemonic - keep as db
            lines.append(format_db(raw_bytes, offset, instr))
            db_count += 1
            continue

        fixed = fix_instruction(instr, raw_bytes, offset)

        if fixed is not None:
            if test_instruction(fixed, raw_bytes, offset):
                lines.append(f'{fixed}  ; {offset:05X}')
                match_count += 1
                continue

        lines.append(format_db(raw_bytes, offset, instr))
        db_count += 1

    # Trailing bytes
    if expected_offset < code_size:
        remaining = code_data[expected_offset:]
        lines.append(f'; trailing bytes ({len(remaining)} bytes)')
        for i in range(0, len(remaining), 16):
            chunk = remaining[i:i+16]
            hex_bytes = ', '.join(f'0x{b:02X}' for b in chunk)
            file_off = HEADER_SIZE + expected_offset + i
            lines.append(f'db {hex_bytes}  ; {file_off:05X}')

    lines.append('')

    with open(ASM_PATH, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    total = match_count + db_count
    pct = match_count / total * 100 if total else 0
    print(f"Converted: {match_count}/{total} instructions ({pct:.1f}%)")
    print(f"Remaining as db: {db_count}")
    print(f"Labels: {len(label_offsets)}")

if __name__ == '__main__':
    main()
