/*
 * Linker script for the RV32I core (Harvard: separate instruction and data memories).
 *
 * IMEM_BASE/IMEM_SIZE/DMEM_BASE/DMEM_SIZE are passed in by the Makefile with --defsym,
 * so the memory map lives in exactly one place.
 *
 * Why the layout looks like this:
 *   - The core fetches only from IMEM and loads/stores only to DMEM. A load can never
 *     read IMEM, so EVERYTHING a program reads as data (.rodata — string literals,
 *     const tables, switch jump tables — as well as .data) must live in DMEM.
 *   - Initialised data is not copied at startup (there is no ROM copy of it the core
 *     could read). Instead elf2hex produces dmem.hex and the testbench preloads DMEM.
 *     Consequence on the FPGA: pressing reset does NOT restore .data — reprogram instead.
 *   - The DMEM in the datapath decodes only alu_res[13:2], so DMEM_BASE's upper bits are
 *     ignored by the hardware today; they matter once a memory map (UART) exists.
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = IMEM_BASE, LENGTH = IMEM_SIZE
    DMEM (rw)  : ORIGIN = DMEM_BASE, LENGTH = DMEM_SIZE
}

SECTIONS
{
    /* .text.init holds _start: KEEP + first => the program begins at IMEM_BASE,
       which must equal the core's reset PC. */
    .text : {
        KEEP(*(.text.init))
        *(.text .text.*)
        . = ALIGN(4);
    } > IMEM

    .rodata : {
        . = ALIGN(4);
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
    } > DMEM

    .data : {
        . = ALIGN(4);
        *(.data .data.*)
    } > DMEM

    /* gp points 0x800 past the start of the small-data area so a signed 12-bit offset
       from gp reaches 4 KiB of globals in a single instruction (linker "relaxation"). */
    .sdata : {
        . = ALIGN(4);
        __global_pointer$ = . + 0x800;
        *(.sdata .sdata.*)
        . = ALIGN(4);
    } > DMEM

    .bss (NOLOAD) : {
        . = ALIGN(4);
        __bss_start = .;
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > DMEM

    /* Stack grows down from the top of DMEM (the ABI wants sp 16-byte aligned). */
    __stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

    /DISCARD/ : { *(.comment) *(.note .note.*) *(.eh_frame .eh_frame_hdr) }
}
