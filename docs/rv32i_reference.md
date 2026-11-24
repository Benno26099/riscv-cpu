# RV32I Quick Reference

Summary of the RISC-V Unprivileged ISA, RV32I base integer chapter. The spec is the
authority — if anything here disagrees with it, the spec wins.

Bit numbering: bit 31 is the MSB of the instruction word, bit 0 the LSB.

---

## 1. Basics

| Item              | Value                                                              |
|-------------------|--------------------------------------------------------------------|
| Registers         | `x0`–`x31`, 32 bits each, plus `pc`                                |
| `x0`              | Hardwired to zero. Reads return 0; writes are discarded            |
| Instruction size  | 32 bits, must be 4-byte aligned (no C extension)                   |
| Endianness        | Little-endian (byte at lowest address = least significant byte)    |
| Opcode bits [1:0] | Always `11` for 32-bit instructions                                |
| Sign bit          | Every immediate's sign bit is **instruction bit 31**, in all formats |
| Overflow          | Ignored. Arithmetic wraps; no flags, no traps                      |
| NOP               | `addi x0, x0, 0` = `0x00000013`                                    |

---

## 2. Instruction formats

Register fields sit in the **same bit positions in every format** that has them.

| Format | [31:25]        | [24:20]        | [19:15]     | [14:12]     | [11:7]         | [6:0]  |
|--------|----------------|----------------|-------------|-------------|----------------|--------|
| R      | funct7         | rs2            | rs1         | funct3      | rd             | opcode |
| I      | imm[11:5]      | imm[4:0]       | rs1         | funct3      | rd             | opcode |
| S      | imm[11:5]      | rs2            | rs1         | funct3      | imm[4:0]       | opcode |
| B      | imm[12\|10:5]  | rs2            | rs1         | funct3      | imm[4:1\|11]   | opcode |
| U      | imm[31:25]     | imm[24:20]     | imm[19:15]  | imm[14:12]  | rd             | opcode |
| J      | imm[20\|10:5]  | imm[4:1\|11]   | imm[19:15]  | imm[14:12]  | rd             | opcode |

Field widths: opcode 7, rd/rs1/rs2 5, funct3 3, funct7 7.

---

## 3. Immediates (spec: "Immediate Encoding Variants")

Which **instruction bit** supplies each bit of the 32-bit immediate. `inst[31]` repeated
= sign extension.

| Format | imm[31:20]      | imm[19:12]      | imm[11]    | imm[10:5]    | imm[4:1]     | imm[0]    |
|--------|-----------------|-----------------|------------|--------------|--------------|-----------|
| I      | inst[31]        | inst[31]        | inst[31]   | inst[30:25]  | inst[24:21]  | inst[20]  |
| S      | inst[31]        | inst[31]        | inst[31]   | inst[30:25]  | inst[11:8]   | inst[7]   |
| B      | inst[31]        | inst[31]        | inst[7]    | inst[30:25]  | inst[11:8]   | 0         |
| U      | inst[31:20]     | inst[19:12]     | 0          | 0            | 0            | 0         |
| J      | inst[31]        | inst[19:12]     | inst[20]   | inst[30:25]  | inst[24:21]  | 0         |

Ranges: I/S ±2 KiB (−2048…2047), B ±4 KiB, J ±1 MiB, U = upper 20 bits.
B and J immediates are always even (bit 0 = 0), so they encode multiples of 2 bytes.

---

## 4. Major opcodes

| Name     | opcode [6:0] | Hex  | Format | Instructions                                  |
|----------|--------------|------|--------|-----------------------------------------------|
| LUI      | `0110111`    | 0x37 | U      | lui                                           |
| AUIPC    | `0010111`    | 0x17 | U      | auipc                                         |
| JAL      | `1101111`    | 0x6F | J      | jal                                           |
| JALR     | `1100111`    | 0x67 | I      | jalr                                          |
| BRANCH   | `1100011`    | 0x63 | B      | beq bne blt bge bltu bgeu                     |
| LOAD     | `0000011`    | 0x03 | I      | lb lh lw lbu lhu                              |
| STORE    | `0100011`    | 0x23 | S      | sb sh sw                                      |
| OP-IMM   | `0010011`    | 0x13 | I      | addi slti sltiu xori ori andi slli srli srai  |
| OP       | `0110011`    | 0x33 | R      | add sub sll slt sltu xor srl sra or and       |
| MISC-MEM | `0001111`    | 0x0F | I      | fence                                         |
| SYSTEM   | `1110011`    | 0x73 | I      | ecall ebreak                                  |

Any other opcode is illegal in RV32I.

---

## 5. Full encoding table

`—` = field not present in that format.

### OP (R-type, opcode `0110011`)

| Instr | funct7    | funct3 | Operation                          |
|-------|-----------|--------|------------------------------------|
| add   | `0000000` | `000`  | rd = rs1 + rs2                     |
| sub   | `0100000` | `000`  | rd = rs1 − rs2                     |
| sll   | `0000000` | `001`  | rd = rs1 << rs2[4:0]               |
| slt   | `0000000` | `010`  | rd = (rs1 < rs2) signed ? 1 : 0    |
| sltu  | `0000000` | `011`  | rd = (rs1 < rs2) unsigned ? 1 : 0  |
| xor   | `0000000` | `100`  | rd = rs1 ^ rs2                     |
| srl   | `0000000` | `101`  | rd = rs1 >> rs2[4:0] (logical)     |
| sra   | `0100000` | `101`  | rd = rs1 >> rs2[4:0] (arithmetic)  |
| or    | `0000000` | `110`  | rd = rs1 \| rs2                    |
| and   | `0000000` | `111`  | rd = rs1 & rs2                     |

### OP-IMM (I-type, opcode `0010011`)

| Instr | imm[11:5] (inst[31:25]) | funct3 | Operation                               |
|-------|-------------------------|--------|-----------------------------------------|
| addi  | imm                     | `000`  | rd = rs1 + imm                          |
| slti  | imm                     | `010`  | rd = (rs1 < imm) signed ? 1 : 0         |
| sltiu | imm                     | `011`  | rd = (rs1 < imm) unsigned ? 1 : 0       |
| xori  | imm                     | `100`  | rd = rs1 ^ imm                          |
| ori   | imm                     | `110`  | rd = rs1 \| imm                         |
| andi  | imm                     | `111`  | rd = rs1 & imm                          |
| slli  | `0000000`               | `001`  | rd = rs1 << shamt                       |
| srli  | `0000000`               | `101`  | rd = rs1 >> shamt (logical)             |
| srai  | `0100000`               | `101`  | rd = rs1 >> shamt (arithmetic)          |

- Shifts: `shamt = inst[24:20]` (5 bits). Upper bits must match the funct7-style pattern shown.
- `sltiu`: imm is **sign-extended first**, then compared unsigned (so `sltiu rd, rs1, 1` sets rd = 1 iff rs1 == 0).

### LOAD (I-type, opcode `0000011`) — address = rs1 + imm

| Instr | funct3 | Result written to rd                     |
|-------|--------|------------------------------------------|
| lb    | `000`  | byte, **sign**-extended to 32 bits       |
| lh    | `001`  | halfword, **sign**-extended              |
| lw    | `010`  | word                                     |
| lbu   | `100`  | byte, **zero**-extended                  |
| lhu   | `101`  | halfword, **zero**-extended              |

### STORE (S-type, opcode `0100011`) — address = rs1 + imm, data = rs2

| Instr | funct3 | Writes                                   |
|-------|--------|------------------------------------------|
| sb    | `000`  | rs2[7:0] to 1 byte                       |
| sh    | `001`  | rs2[15:0] to 2 bytes                     |
| sw    | `010`  | rs2[31:0] to 4 bytes                     |

### BRANCH (B-type, opcode `1100011`) — if taken, pc = pc + imm

| Instr | funct3 | Taken when                 |
|-------|--------|----------------------------|
| beq   | `000`  | rs1 == rs2                 |
| bne   | `001`  | rs1 != rs2                 |
| blt   | `100`  | rs1 < rs2 (signed)         |
| bge   | `101`  | rs1 >= rs2 (signed)        |
| bltu  | `110`  | rs1 < rs2 (unsigned)       |
| bgeu  | `111`  | rs1 >= rs2 (unsigned)      |

### Jumps and upper-immediates

| Instr | opcode    | funct3 | Operation                                          |
|-------|-----------|--------|----------------------------------------------------|
| jal   | `1101111` | —      | rd = pc + 4; pc = pc + imm                         |
| jalr  | `1100111` | `000`  | rd = pc + 4; pc = (rs1 + imm) & ~1                 |
| lui   | `0110111` | —      | rd = imm (upper 20 bits, low 12 bits zero)         |
| auipc | `0010111` | —      | rd = pc + imm (upper 20 bits, low 12 bits zero)    |

- `jalr` clears bit 0 of the computed target.
- Jump/branch targets not 4-byte aligned raise an instruction-address-misaligned exception.

### MISC-MEM and SYSTEM

| Instr  | opcode    | funct3 | inst[31:20]    | Notes                                          |
|--------|-----------|--------|----------------|------------------------------------------------|
| fence  | `0001111` | `000`  | fm/pred/succ   | Memory ordering; can be a NOP in a simple in-order core |
| ecall  | `1110011` | `000`  | `000000000000` | Environment call (trap)                        |
| ebreak | `1110011` | `000`  | `000000000001` | Breakpoint (trap)                              |

For ecall/ebreak, rs1 and rd fields are 0.

---

## 6. Useful pseudo-instructions (what the assembler emits)

| Pseudo           | Expands to                      |
|------------------|---------------------------------|
| `nop`            | `addi x0, x0, 0`                |
| `li rd, imm`     | `addi` (small) or `lui` + `addi` |
| `mv rd, rs`      | `addi rd, rs, 0`                |
| `not rd, rs`     | `xori rd, rs, -1`               |
| `neg rd, rs`     | `sub rd, x0, rs`                |
| `j off`          | `jal x0, off`                   |
| `ret`            | `jalr x0, 0(x1)`                |
| `beqz rs, off`   | `beq rs, x0, off`               |

ABI names: `x1` = ra, `x2` = sp, `x10`–`x17` = a0–a7. The disassembler prints ABI names.

---

## 7. Handy checks

- Assemble and inspect: `riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -c t.S && riscv-none-elf-objdump -d t.o`
- Spec PDF: RISC-V Unprivileged ISA, chapter "RV32I Base Integer Instruction Set".
