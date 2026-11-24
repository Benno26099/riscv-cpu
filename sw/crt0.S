/*
 * crt0.S — C runtime startup for the RV32I core. Linked in front of every .c program.
 * (Assembly test programs in sw/tests/ do NOT use this; they define their own _start.)
 *
 * What a C program assumes before main() runs, and who provides it here:
 *   1. gp holds __global_pointer$     -> set below (linker uses gp-relative accesses)
 *   2. sp points at valid stack       -> set below, top of DMEM (from link.ld)
 *   3. .bss is all zeros              -> zeroed below
 *   4. .data holds its initial values -> NOT done here: the testbench preloads DMEM
 *                                        from dmem.hex (see link.ld for why)
 *
 * After main returns, its return value is in a0 (x10). We then execute ebreak, which the
 * core decodes as `halt`; the testbench can inspect x10 to decide PASS/FAIL.
 */

    .section .text.init, "ax"
    .globl _start
_start:
    /* gp must be loaded WITHOUT relaxation: with relaxation on, the linker would try to
       rewrite `la gp, ...` as gp-relative — i.e. relative to the register being set. */
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop

    la      sp, __stack_top

    /* Zero .bss one word at a time (link.ld 4-byte-aligns both ends). */
    la      t0, __bss_start
    la      t1, __bss_end
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:
    call    main

    /* a0 = main's return value. Halt. */
    ebreak

    /* Should never get here (halt stops the testbench). Spin, in case it doesn't. */
3:  j       3b
