# Control Table — single-cycle RV32I

Datapath reference: `datapath_2026-11-24_v25.png`
Encoding reference: `rv32i_reference.md`

Use `x` for don't-care. Multi-bit selects are written by name; the binary values are listed in the
encoding tables below and will become `typedef enum`s in `rv32i_pkg.sv`.

## Signal encodings

### Datapath mux selects

| Signal  | Width | Value | Name   | Selects                          |
|---------|-------|-------|--------|----------------------------------|
| sel_a   | 2     | 00    | RS1    | rs1_data                         |
| sel_a   | 2     | 01    | PC     | PC (auipc)                       |
| sel_a   | 2     | 10    | ZERO   | constant 0 (lui)                 |
| sel_b   | 1     | 0     | RS2    | rs2_data                         |
| sel_b   | 1     | 1     | IMM    | imm                              |
| wb_sel  | 2     | 00    | ALU    | alu_res                          |
| wb_sel  | 2     | 01    | LOAD   | load extend output               |
| wb_sel  | 2     | 10    | PC4    | pc_plus4 (jal/jalr return addr)  |
| pc_sel  | 2     | 00    | —      | pc_plus4                         |
| pc_sel  | 2     | 01    | —      | branch_target (taken branch, jal)|
| pc_sel  | 2     | 10    | —      | {alu_res[31:1], 0} (jalr)        |

`pc_sel` is not a decoder output: `pc_sel[0] = (branch & taken) | jal`, `pc_sel[1] = jalr`.

### imm_sel (immediate format)

| Value | Name | Used by                               |
|-------|------|---------------------------------------|
| 000   | I    | I-type ALU, loads, jalr               |
| 001   | S    | stores                                |
| 010   | B    | branches                              |
| 011   | U    | lui, auipc                            |
| 100   | J    | jal                                   |

### alu_type (ALU-control category, from main decoder)

| Value | Name | Instructions                     | ALU control does                              |
|-------|------|----------------------------------|-----------------------------------------------|
| 00    | ADD  | loads, stores, jalr, lui, auipc  | always ADD; ignores funct3/funct7             |
| 01    | R    | R-type                           | `alu_op = {inst[30], funct3}`                 |
| 10    | I    | I-type ALU                       | `alu_op = {inst[30] & (funct3 == 101), funct3}` |

### alu_op (4 bits, 10 operations)

| alu_op | Name | Operation                    | Used by             |
|--------|------|------------------------------|---------------------|
| 0000   | ADD  | A + B                        | add, addi, ADD type |
| 1000   | SUB  | A − B                        | sub                 |
| 0001   | SLL  | A << B[4:0]                  | sll, slli           |
| 0010   | SLT  | (A < B) signed ? 1 : 0       | slt, slti           |
| 0011   | SLTU | (A < B) unsigned ? 1 : 0     | sltu, sltiu         |
| 0100   | XOR  | A ^ B                        | xor, xori           |
| 0101   | SRL  | A >> B[4:0] (logical)        | srl, srli           |
| 1101   | SRA  | A >>> B[4:0] (arithmetic)    | sra, srai           |
| 0110   | OR   | A \| B                       | or, ori             |
| 0111   | AND  | A & B                        | and, andi           |

**Why this encoding:** `alu_op` is exactly `{inst[30], funct3}` for every R-type instruction, so
ALU control is almost pure wiring:
- **R:** pass `{inst[30], funct3}` straight through.
- **I:** same, but force bit 3 to 0 unless funct3 = `101` (shift right). That one AND gate is the
  "inst[30] is an immediate bit, except for srai" rule — and it's why there is no `subi`.
- **ADD:** constant `0000`.

## Control signals

| Instr  | Type | opcode  | funct3 | funct7 / imm[11:5] | reg_we | sel_a | sel_b | imm_sel | alu_type | alu_op | wb_sel | mem_we | branch | jal | jalr | halt |
|--------|------|---------|--------|--------------------|--------|-------|-------|---------|----------|--------|--------|--------|--------|-----|------|------|
| add    | R    | 0110011 |   000  | 0000000            | 1      | RS1   | RS2   | x       | R        | ADD    | ALU    | 0      | 0      | 0   | 0    | 0    |
| sub    | R    | 0110011 |   000  | 0100000            | 1      | RS1   | RS2   | x       | R        | SUB    | ALU    | 0      | 0      | 0   | 0    | 0    |
| sll    | R    | 0110011 |   001  | 0000000            | 1      | RS1   | RS2   | x       | R        | SLL    | ALU    | 0      | 0      | 0   | 0    | 0    |
| slt    | R    | 0110011 |   010  | 0000000            | 1      | RS1   | RS2   | x       | R        | SLT    | ALU    | 0      | 0      | 0   | 0    | 0    |
| sltu   | R    | 0110011 |   011  | 0000000            | 1      | RS1   | RS2   | x       | R        | SLTU   | ALU    | 0      | 0      | 0   | 0    | 0    |
| xor    | R    | 0110011 |   100  | 0000000            | 1      | RS1   | RS2   | x       | R        | XOR    | ALU    | 0      | 0      | 0   | 0    | 0    |
| srl    | R    | 0110011 |   101  | 0000000            | 1      | RS1   | RS2   | x       | R        | SRL    | ALU    | 0      | 0      | 0   | 0    | 0    |
| sra    | R    | 0110011 |   101  | 0100000            | 1      | RS1   | RS2   | x       | R        | SRA    | ALU    | 0      | 0      | 0   | 0    | 0    |
| or     | R    | 0110011 |   110  | 0000000            | 1      | RS1   | RS2   | x       | R        | OR     | ALU    | 0      | 0      | 0   | 0    | 0    |
| and    | R    | 0110011 |   111  | 0000000            | 1      | RS1   | RS2   | x       | R        | AND    | ALU    | 0      | 0      | 0   | 0    | 0    |
| addi   | I    | 0010011 |   000  | imm (x)            | 1      | RS1   | IMM   | I       | I        | ADD    | ALU    | 0      | 0      | 0   | 0    | 0    |
| slti   | I    | 0010011 |   010  | imm (x)            | 1      | RS1   | IMM   | I       | I        | SLT    | ALU    | 0      | 0      | 0   | 0    | 0    |
| sltiu  | I    | 0010011 |   011  | imm (x)            | 1      | RS1   | IMM   | I       | I        | SLTU   | ALU    | 0      | 0      | 0   | 0    | 0    |
| xori   | I    | 0010011 |   100  | imm (x)            | 1      | RS1   | IMM   | I       | I        | XOR    | ALU    | 0      | 0      | 0   | 0    | 0    |
| ori    | I    | 0010011 |   110  | imm (x)            | 1      | RS1   | IMM   | I       | I        | OR     | ALU    | 0      | 0      | 0   | 0    | 0    |
| andi   | I    | 0010011 |   111  | imm (x)            | 1      | RS1   | IMM   | I       | I        | AND    | ALU    | 0      | 0      | 0   | 0    | 0    |
| slli   | I    | 0010011 |   001  | 0000000            | 1      | RS1   | IMM   | I       | I        | SLL    | ALU    | 0      | 0      | 0   | 0    | 0    |
| srli   | I    | 0010011 |   101  | 0000000            | 1      | RS1   | IMM   | I       | I        | SRL    | ALU    | 0      | 0      | 0   | 0    | 0    |
| srai   | I    | 0010011 |   101  | 0100000            | 1      | RS1   | IMM   | I       | I        | SRA    | ALU    | 0      | 0      | 0   | 0    | 0    |
| beq    | B    | 1100011 |   000  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| bne    | B    | 1100011 |   001  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| blt    | B    | 1100011 |   100  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| bge    | B    | 1100011 |   101  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| bltu   | B    | 1100011 |   110  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| bgeu   | B    | 1100011 |   111  | imm (x)            | 0      | x     | x     | B       | x        | x      | x      | 0      | 1      | 0   | 0    | 0    |
| lb     | I    | 0000011 |   000  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | LOAD   | 0      | 0      | 0   | 0    | 0    |
| lh     | I    | 0000011 |   001  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | LOAD   | 0      | 0      | 0   | 0    | 0    |
| lw     | I    | 0000011 |   010  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | LOAD   | 0      | 0      | 0   | 0    | 0    |
| lbu    | I    | 0000011 |   100  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | LOAD   | 0      | 0      | 0   | 0    | 0    |
| lhu    | I    | 0000011 |   101  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | LOAD   | 0      | 0      | 0   | 0    | 0    |
| sb     | S    | 0100011 |   000  | imm (x)            | 0      | RS1   | IMM   | S       | ADD      | ADD    | x      | 1      | 0      | 0   | 0    | 0    |
| sh     | S    | 0100011 |   001  | imm (x)            | 0      | RS1   | IMM   | S       | ADD      | ADD    | x      | 1      | 0      | 0   | 0    | 0    |
| sw     | S    | 0100011 |   010  | imm (x)            | 0      | RS1   | IMM   | S       | ADD      | ADD    | x      | 1      | 0      | 0   | 0    | 0    |
| lui    | U    | 0110111 |   x    | imm (x)            | 1      | ZERO  | IMM   | U       | ADD      | ADD    | ALU    | 0      | 0      | 0   | 0    | 0    |
| auipc  | U    | 0010111 |   x    | imm (x)            | 1      | PC    | IMM   | U       | ADD      | ADD    | ALU    | 0      | 0      | 0   | 0    | 0    |
| jal    | J    | 1101111 |   x    | imm (x)            | 1      | x     | x     | J       | x        | x      | PC4    | 0      | 0      | 1   | 0    | 0    |
| jalr   | I    | 1100111 |   000  | imm (x)            | 1      | RS1   | IMM   | I       | ADD      | ADD    | PC4    | 0      | 0      | 0   | 1    | 0    |
| fence  | I    | 0001111 |   000  | x                  | 0      | x     | x     | x       | x        | x      | x      | 0      | 0      | 0   | 0    | 0    |
| ecall  | I    | 1110011 |   000  | 0000000            | 0      | x     | x     | x       | x        | x      | x      | 0      | 0      | 0   | 0    | 1    |
| ebreak | I    | 1110011 |   000  | 0000000            | 0      | x     | x     | x       | x        | x      | x      | 0      | 0      | 0   | 0    | 1    |
| *other*| —    | any     |   x    | x                  | 0      | x     | x     | x       | x        | x      | x      | 0      | 0      | 0   | 0    | 0    |

Notes on the new rows:
- **Two different jump targets.** `jal` uses the branch-target adder (PC + J-imm) and leaves the ALU
  idle (`alu_type = x`). `jalr` uses the ALU (rs1 + I-imm, category ADD); bit 0 is cleared on the
  wire into the PC mux. Both write `pc_plus4` to rd (`wb_sel = PC4`).
- **lui vs auipc** differ only in `sel_a`: ZERO gives `0 + imm` = imm; PC gives `PC + imm`.
- **fence** is a no-op: single in-order core, one memory, so every access already happens in
  program order. All write enables are 0; next PC is PC + 4.
- **ecall vs ebreak** differ only in inst[20] (imm = 0 vs 1). Both raise `halt` here — see the
  end-of-test convention in `CLAUDE.md`. `halt` is a new decoder output that goes to the
  testbench (top-level port), not into the datapath.
- **Unknown opcodes (`other`)** must decode with every write/jump/halt signal at 0. That makes an
  illegal instruction behave as a NOP instead of corrupting registers or memory. In RTL this is the
  `default:` branch of the decoder's `case` — set safe defaults *before* the `case` so nothing can
  be left unassigned (which would also infer latches).

## Trace 1: `add x3, x1, x2` then `addi x3, x3, -5`

Assume x1 = 7, x2 = 10 beforehand. Hex encodings confirmed with `riscv-none-elf-objdump`.

| Signal            | add x3, x1, x2       | addi x3, x3, -5           |
|-------------------|----------------------|---------------------------|
| instruction (hex) | 0x002081B3           | 0xFFB18193                |
| rs1 / rs2 / rd    | x1 / x2 / x3         | x3 / (x27) / x3           |
| rs1_data          | 7                    | 17                        |
| rs2_data          | 10                   | value of x27 (unused)     |
| imm               | 0x00000002 (unused)  | 0xFFFFFFFB (−5)           |
| sel_b             | RS2                  | IMM                       |
| ALU input B       | 10                   | 0xFFFFFFFB                |
| alu_type          | R                    | I                         |
| inst[30], funct3  | 0, 000               | 1, 000                    |
| alu_op            | 0000 (ADD)           | 0000 (ADD) — bit 3 forced 0 |
| ALU result        | 17 (0x00000011)      | 12 (0x0000000C)           |
| wb_sel            | ALU                  | ALU                       |
| reg_we            | 1                    | 1                         |
| x3 after          | 17                   | 12                        |

Notes:
- The hardware doesn't know which fields are "real". For `add`, the imm gen still produces a
  value from the instruction bits — the mux just ignores it. For `addi`, inst[24:20] = 27, so the
  register file still reads x27 on port 2; `sel_b` throws it away. Every block always computes something.
- `addi x3, x3, -5` has inst[30] = 1 (it's an immediate bit). If ALU control used it, the result
  would be SUB: 17 − (−5) = 22. The I-type rule forces it to 0 because funct3 ≠ 101.
- 0xFFFFFFFB + 17 wraps to 12: the same adder handles a negative immediate for free.

## Trace 2: branches, all at PC = 0x100

`beq x1, x2, 8` = `0x00208463`, `add x3, x1, x2` = `0x002081B3` (confirmed with objdump).

| Signal            | beq, x1 = x2 = 5     | beq, x1 = 5, x2 = 6  | add, x1 = x2 = 5          |
|-------------------|----------------------|----------------------|---------------------------|
| instruction (hex) | 0x00208463           | 0x00208463           | 0x002081B3                |
| rs1 / rs2 / rd    | x1 / x2 / (x8)       | x1 / x2 / (x8)       | x1 / x2 / x3              |
| rs1_data          | 5                    | 5                    | 5                         |
| rs2_data          | 5                    | 6                    | 5                         |
| imm_sel           | B                    | B                    | x                         |
| imm               | 8                    | 8                    | (unused)                  |
| pc_plus4          | 0x104                | 0x104                | 0x104                     |
| branch_target     | 0x108                | 0x108                | 0x100 + imm (unused)      |
| funct3            | 000 (eq)             | 000 (eq)             | 000 (comparator sees "eq")|
| taken             | 1                    | 0                    | **1**                     |
| branch / jal / jalr | 1 / 0 / 0          | 1 / 0 / 0            | 0 / 0 / 0                 |
| pc_sel            | 01                   | 00                   | **00**                    |
| pc_next           | 0x108                | 0x104                | 0x104                     |
| sel_a / sel_b     | x / x                | x / x                | RS1 / RS2                 |
| ALU result        | garbage (ignored)    | garbage (ignored)    | 10                        |
| wb_sel            | x                    | x                    | ALU                       |
| reg_we / mem_we   | 0 / 0                | 0 / 0                | 1 / 0                     |
| register written  | none                 | none                 | x3 = 10                   |

Notes:
- **`reg_we = 0` is what makes the ALU's garbage harmless.** For `beq`, inst[11:7] = `01000`, so the
  register file's write address is x8. If `reg_we` were 1, x8 would be overwritten with whatever the
  ALU produced. A branch's only effect is on `pc_next`.
- **The add column is why the AND gate exists.** funct3 = 000 makes the comparator test equality, and
  5 == 5, so `taken = 1`. Only `branch = 0` keeps `pc_sel` at 00.
- **`mem_we = 0`** for branches for the same reason: `alu_res` and `rs2_data` reach the LSU every
  cycle, so without it a branch would write garbage to memory.

## Design questions (answered)

- **How wide is `alu_op`?** 10 distinct operations → 4 bits.
- **Which bits pick `alu_op`?** funct3 and inst[30], qualified by `alu_type`. R-type trusts inst[30]
  always; I-type only when funct3 = 101 (shift right).
- **Why no `subi`?** `addi` with a negative immediate already subtracts, so inst[30] could stay an
  immediate bit for I-type arithmetic.
- **`srli` vs `srai`?** inst[30] (imm[10]). The shift amount only needs imm[4:0], so the upper
  immediate bits are free to act as funct7.
- **`wb_sel` for R/I rows?** ALU — data memory output is ignored, and `mem_we = 0` keeps memory untouched.
