/*
 * smoke.S — toolchain smoke test (checks the build flow, not the CPU).
 * Assembly tests define their own _start in .text.init so it lands at IMEM_BASE.
 */
    .section .text.init, "ax"
    .globl _start
_start:
    addi    x1, x0, 5
    addi    x2, x0, 7
    add     x3, x1, x2          # x3 = 12
    addi    x10, x0, 0          # a0 = 0
    ebreak
