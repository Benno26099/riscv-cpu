    .section .text.init, "ax"
    .globl _start
_start:
        # ---- I-type ----
    addi  x1, x0, 5            # small positive
    addi  x1, x0, -1           # all ones: sign extension
    addi  x1, x0, 2047         # largest positive (bit 11 = 0)
    addi  x1, x0, -2048        # most negative (only the sign bit set)

    # ---- S-type ----
    sw    x2, 20(x3)           # low 5 bits non-zero: tests the inst[11:7] field
    sw    x2, -4(x3)           # negative
    sw    x2, -2048(x3)        # most negative

    # ---- B-type ----
    beq   x0, x0, .+8          # small positive
    beq   x0, x0, .-8          # negative
    beq   x0, x0, .+2048       # sets only imm[11]: the bit that lives in inst[7]
    beq   x0, x0, .+4094       # largest positive: every bit except the sign
    beq   x0, x0, .-4096       # most negative

    # ---- U-type ----
    lui   x1, 0x12345          # ordinary value
    lui   x1, 0xFFFFF          # top bit set: no sign extension, but bit 31 = 1

    # ---- J-type ----
    jal   x0, .+8              # small positive
    jal   x0, .-8              # negative
    jal   x0, .+2048           # sets only imm[11]: the bit that lives in inst[20]
    jal   x0, .+0x80000        # sets only imm[19]: top of the inst[19:12] field
    jal   x0, .-0x100000       # most negative