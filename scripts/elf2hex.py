#!/usr/bin/env python3
"""
elf2hex.py — turn an RV32 ELF into $readmemh images for instruction and data memory.

    python3 scripts/elf2hex.py prog.elf -o outdir --imem BASE SIZE --dmem BASE SIZE

Writes outdir/imem.hex and outdir/dmem.hex: one 32-bit word per line, in hex, no '0x',
line N = word at address BASE + 4*N. Each file is padded with zeros to SIZE bytes, so
`$readmemh(file, mem)` fills the whole array and uninitialised memory reads 0 (not X).

Words are assembled little-endian (RISC-V is little-endian): the byte at the lowest
address ends up in bits [7:0] of the word.

The script reads the ELF program headers (PT_LOAD segments) directly — no pyelftools
dependency. Bytes past p_filesz (i.e. .bss) are left as zero.
"""
import argparse
import struct
import sys
from pathlib import Path

PT_LOAD = 1


def parse_int(s: str) -> int:
    return int(s, 0)


def load_segments(path: Path):
    data = path.read_bytes()
    if data[:4] != b"\x7fELF":
        sys.exit(f"{path}: not an ELF file")
    if data[4] != 1:
        sys.exit(f"{path}: not a 32-bit ELF (EI_CLASS={data[4]})")
    if data[5] != 1:
        sys.exit(f"{path}: not little-endian")
    (e_type, e_machine, _ver, e_entry, e_phoff, _shoff, _flags, _ehsize,
     e_phentsize, e_phnum) = struct.unpack_from("<HHIIIIIHHH", data, 16)
    if e_machine != 243:
        sys.exit(f"{path}: not RISC-V (e_machine={e_machine})")

    segs = []
    for i in range(e_phnum):
        (p_type, p_offset, _vaddr, p_paddr, p_filesz, p_memsz, _pflags,
         _align) = struct.unpack_from("<IIIIIIII", data, e_phoff + i * e_phentsize)
        if p_type == PT_LOAD and p_filesz > 0:
            segs.append((p_paddr, data[p_offset:p_offset + p_filesz]))
    return e_entry, segs


def write_hex(path: Path, image: bytearray):
    with path.open("w") as f:
        for i in range(0, len(image), 4):
            (word,) = struct.unpack_from("<I", image, i)
            f.write(f"{word:08x}\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("elf", type=Path)
    ap.add_argument("-o", "--outdir", type=Path, required=True)
    ap.add_argument("--imem", nargs=2, type=parse_int, metavar=("BASE", "SIZE"), required=True)
    ap.add_argument("--dmem", nargs=2, type=parse_int, metavar=("BASE", "SIZE"), required=True)
    args = ap.parse_args()

    regions = {
        "imem": (args.imem[0], args.imem[1], bytearray(args.imem[1])),
        "dmem": (args.dmem[0], args.dmem[1], bytearray(args.dmem[1])),
    }
    for name, (base, size, _) in regions.items():
        if base % 4 or size % 4:
            sys.exit(f"{name}: base and size must be word-aligned")

    entry, segs = load_segments(args.elf)
    if not (regions["imem"][0] <= entry < regions["imem"][0] + regions["imem"][1]):
        sys.exit(f"entry point 0x{entry:08x} is outside IMEM")

    for addr, blob in segs:
        for name, (base, size, img) in regions.items():
            if base <= addr and addr + len(blob) <= base + size:
                off = addr - base
                img[off:off + len(blob)] = blob
                break
        else:
            sys.exit(f"segment at 0x{addr:08x} (+{len(blob)} bytes) doesn't fit in IMEM or DMEM")

    args.outdir.mkdir(parents=True, exist_ok=True)
    for name, (_, _, img) in regions.items():
        write_hex(args.outdir / f"{name}.hex", img)
    used = {n: sum(len(b) for a, b in segs if r[0] <= a < r[0] + r[1])
            for n, r in regions.items()}
    print(f"elf2hex: entry 0x{entry:08x}; imem {used['imem']} B, dmem {used['dmem']} B "
          f"(initialised) -> {args.outdir}/{{imem,dmem}}.hex")


if __name__ == "__main__":
    main()
