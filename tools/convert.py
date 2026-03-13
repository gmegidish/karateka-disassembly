#!/usr/bin/env python3
"""
Convert KARATEKA.EXE into a NASM source file.
- MZ header as db bytes
- Code section: each instruction tested against NASM to verify encoding match
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

def parse_ndisasm(dis_path):
    """Parse ndisasm output into list of (offset, raw_bytes, instruction)"""
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

def adjust_jump_target(instr):
    """Add HEADER_SIZE offset to absolute jump/call targets for flat binary layout.
    In the flat binary, code section starts at offset HEADER_SIZE, so all absolute
    targets from ndisasm need to be shifted by HEADER_SIZE."""
    # Match jmp/call/jcc with absolute hex targets like "jmp 0x207" or "jnz 0x1c"
    def replace_target(m):
        prefix = m.group(1)
        target = int(m.group(2), 16)
        new_target = target + HEADER_SIZE
        return f"{prefix}0x{new_target:x}"

    # Near jumps/calls: jmp 0xNNN, call 0xNNN, jz 0xNNN, etc.
    # But NOT: jmp [bx], call [0x1234], jmp word [si], etc. (indirect)
    # Also NOT: jmp far, int, etc.
    result = re.sub(r'\b(j[a-z]+\s+|call\s+)(0x[0-9a-fA-F]+)\s*$', replace_target, instr)
    return result

def fix_instruction(instr, raw_bytes, offset):
    """Try to fix known NASM encoding differences."""
    # Fix 1: ndisasm shows "int byte 0x21" but nasm wants "int 0x21"
    instr = re.sub(r'\bint byte (0x[0-9a-fA-F]+)\b', r'int \1', instr)
    instr = re.sub(r'\bint byte (\d+)\b', r'int \1', instr)

    # Fix 2: Short conditional jumps - ndisasm doesn't say "short" but nasm needs it
    # for 2-byte Jcc instructions (opcodes 0x70-0x7F, 0xEB, 0xE3)
    opcode = raw_bytes[0]
    short_jcc = (0x70 <= opcode <= 0x7F) or opcode == 0xEB or opcode == 0xE3
    if short_jcc and len(raw_bytes) == 2:
        # These are short jumps. ndisasm shows absolute target, we need relative.
        # Use db for now since labels aren't set up yet
        return None  # signal to keep as db

    # Fix 3: "shr reg,0x0" should be "shr reg,1" (D1 opcode = shift by 1)
    if opcode == 0xD1 or opcode == 0xD0:
        instr = re.sub(r',0x0$', ',1', instr)

    # Fix 6: Adjust absolute jump/call targets for flat binary layout
    # Near jumps (E9) and near calls (E8) use relative encoding, so NASM needs
    # targets adjusted by HEADER_SIZE since code starts at that offset in the output
    if opcode in (0xE8, 0xE9) or (opcode == 0x0F and len(raw_bytes) >= 2 and 0x80 <= raw_bytes[1] <= 0x8F):
        instr = adjust_jump_target(instr)

    # Fix 4: NASM picks opposite ALU encoding for reg,reg ops
    # These opcodes use the "r, r/m" form (higher opcode) but NASM emits "r/m, r" (lower)
    # 0x02/0x03 vs 0x00/0x01 (ADD), 0x0A/0x0B vs 0x08/0x09 (OR),
    # 0x12/0x13 vs 0x10/0x11 (ADC), 0x1A/0x1B vs 0x18/0x19 (SBB),
    # 0x22/0x23 vs 0x20/0x21 (AND), 0x2A/0x2B vs 0x28/0x29 (SUB),
    # 0x32/0x33 vs 0x30/0x31 (XOR), 0x3A/0x3B vs 0x38/0x39 (CMP),
    # 0x8A/0x8B vs 0x88/0x89 (MOV)
    alt_alu_opcodes = {0x02, 0x03, 0x0A, 0x0B, 0x12, 0x13, 0x1A, 0x1B,
                       0x22, 0x23, 0x2A, 0x2B, 0x32, 0x33, 0x3A, 0x3B,
                       0x8A, 0x8B}
    if opcode in alt_alu_opcodes and len(raw_bytes) == 2:
        modrm = raw_bytes[1]
        mod = (modrm >> 6) & 3
        if mod == 3:  # reg,reg - NASM will pick the other encoding
            return None  # keep as db

    # Fix 5: Immediate size - 81 vs 83 (sign-extended byte immediate)
    # e.g., "and di, 0xFFFE" -> 81 E7 FE FF, but NASM optimizes to 83 E7 FE
    if opcode == 0x81 and len(raw_bytes) == 4:
        imm16 = int.from_bytes(raw_bytes[2:4], 'little', signed=True)
        if -128 <= imm16 <= 127:
            # NASM will optimize this, keep as db
            return None

    return instr

def test_instruction(instr, expected_bytes, offset):
    """Test if nasm produces the exact same bytes.
    Uses output_pos = offset + HEADER_SIZE to match the flat binary layout."""
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
    """Format bytes as db line with offset comment."""
    hex_bytes = ', '.join(f'0x{b:02X}' for b in raw_bytes)
    c = f"  ; {offset:05X}"
    if comment:
        c += f" {comment}"
    return f"db {hex_bytes}{c}"

def main():
    with open(EXE_PATH, 'rb') as f:
        exe_data = f.read()

    instructions = parse_ndisasm(DIS_PATH)

    lines = []
    lines.append('; Karateka (1986) - DOS matching disassembly')
    lines.append('; Build: nasm -f bin src/karateka.asm -o build/NEW.EXE')
    lines.append(';')
    lines.append('; MZ Header: bytes 0x0000-0x01FF (512 bytes)')
    lines.append('; Code/Data: bytes 0x0200-end (87478 bytes)')
    lines.append('')

    # MZ Header as db
    lines.append('; === MZ HEADER ===')
    for i in range(0, HEADER_SIZE, 16):
        chunk = exe_data[i:i+16]
        hex_bytes = ', '.join(f'0x{b:02X}' for b in chunk)
        lines.append(f'db {hex_bytes}  ; {i:05X}')
    lines.append('')

    # Code section
    lines.append('; === CODE/DATA SECTION ===')
    lines.append('; Entry point: CS:IP = 0000:0002 (offset 0x0002 in code section)')
    lines.append('')

    match_count = 0
    db_count = 0
    code_data = exe_data[HEADER_SIZE:]
    code_size = len(code_data)

    # Track position to detect gaps in ndisasm output
    expected_offset = 0

    for offset, raw_bytes, instr in instructions:
        # Fill any gap bytes that ndisasm skipped
        if offset > expected_offset:
            gap = code_data[expected_offset:offset]
            hex_bytes = ', '.join(f'0x{b:02X}' for b in gap)
            lines.append(f'db {hex_bytes}  ; {expected_offset:05X} (gap: {len(gap)} bytes)')
            db_count += 1

        expected_offset = offset + len(raw_bytes)
        fixed = fix_instruction(instr, raw_bytes, offset)

        if fixed is not None:
            # Test the instruction
            if test_instruction(fixed, raw_bytes, offset):
                lines.append(f'{fixed}  ; {offset:05X}')
                match_count += 1
                continue

        # Keep as db with instruction comment
        lines.append(format_db(raw_bytes, offset, instr))
        db_count += 1

    # Append any trailing bytes that ndisasm didn't cover
    if expected_offset < code_size:
        remaining = code_data[expected_offset:]
        lines.append(f'; trailing bytes not covered by ndisasm ({len(remaining)} bytes)')
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

if __name__ == '__main__':
    main()
