# RV32I CPU — build / lint / test flow.
# Run from WSL, in the repo root:  make help
#
# Conventions this Makefile relies on:
#   - One module per file in rtl/, file name == module name (rtl/alu.sv -> module alu).
#     Verilator finds submodules by that name via -y rtl.
#   - rtl/rv32i_pkg.sv (if present) is always compiled first.
#   - Simulations run from the repo root, so paths inside a testbench ($dumpfile("build/x.fst"),
#     hex files) are relative to the repo root.
#   - Testbenches are tb/tb_<name>.sv containing module tb_<name>. They are SystemVerilog,
#     built with `verilator --binary` (no C++ harness needed). A failing test should call
#     $fatal so the simulation exits non-zero.

# ---------------------------------------------------------------------------
# Memory map — single source of truth. Passed to the linker (sw/link.ld) and to elf2hex.
# Must agree with the RTL (reset PC, memory depths) — change both together.
# ---------------------------------------------------------------------------
IMEM_BASE ?= 0x00000000
# IMEM: 16 KiB
IMEM_SIZE ?= 0x4000
DMEM_BASE ?= 0x00010000
# DMEM: 16 KiB (matches docs: 4096 words)
DMEM_SIZE ?= 0x4000

# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
VERILATOR ?= verilator
CROSS     ?= riscv-none-elf-
CC        := $(CROSS)gcc
OBJDUMP   := $(CROSS)objdump
PYTHON    ?= python3

RTL_DIR := rtl
TB_DIR  := tb
SW_DIR  := sw
BUILD   := build
# Verilator's generated C++ build (verilated.mk) refuses to run in a directory whose path
# contains spaces, and this repo lives under "Verilog Projects/RISC-V CPU". So the Verilator
# object dirs go outside the repo. Simulation still runs from the repo root.
OBJ_ROOT ?= $(HOME)/.cache/rv32i_cpu/obj

PKG      := $(wildcard $(RTL_DIR)/rv32i_pkg.sv)
MODULES  := $(basename $(notdir $(filter-out $(RTL_DIR)/rv32i_pkg.sv,$(wildcard $(RTL_DIR)/*.sv))))
TBS      := $(patsubst tb_%,%,$(basename $(notdir $(wildcard $(TB_DIR)/tb_*.sv))))

# WAVES=1 enables FST tracing. The testbench still needs $dumpfile("...fst") / $dumpvars.
WAVES ?= 0
ifeq ($(WAVES),1)
  TRACE := --trace-fst --trace-structs
endif

# Testbench build: -Wall so RTL warnings are visible, but non-fatal (testbench code is
# allowed to be untidy). `make lint` is the strict gate for rtl/.
VSIM_FLAGS := --binary --timing -j 0 -Wall -Wno-fatal --assert $(TRACE) \
              -y $(RTL_DIR) -I$(RTL_DIR) -I$(TB_DIR)

# ---------------------------------------------------------------------------
# Software
# ---------------------------------------------------------------------------
ARCH    := -march=rv32i -mabi=ilp32
CFLAGS  := $(ARCH) -O2 -g -ffreestanding -fno-builtin -nostdlib \
           -fno-asynchronous-unwind-tables -fno-unwind-tables -Wall -Wextra
ASFLAGS := $(ARCH) -g
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -T $(SW_DIR)/link.ld \
           -Wl,--defsym=IMEM_BASE=$(IMEM_BASE) -Wl,--defsym=IMEM_SIZE=$(IMEM_SIZE) \
           -Wl,--defsym=DMEM_BASE=$(DMEM_BASE) -Wl,--defsym=DMEM_SIZE=$(DMEM_SIZE)
# rv32i has no mul/div: gcc calls __mulsi3 etc. from libgcc
LDLIBS  := -lgcc

# PROG=sw/tests/foo.S  or  PROG=sw/foo.c
# .S programs provide their own _start; .c programs are linked with sw/crt0.S.
PROG    ?=
NAME    := $(basename $(notdir $(PROG)))
SW_OUT  := $(BUILD)/sw/$(NAME)
ELF     := $(SW_OUT)/$(NAME).elf

ifeq ($(suffix $(PROG)),.c)
  SW_SRCS := $(SW_DIR)/crt0.S $(PROG)
else
  SW_SRCS := $(PROG)
endif

# Plusargs given to the top-level simulation: tb/tb_top.sv should read these with
# $value$plusargs and $readmemh them into instruction / data memory.
SIM_PLUSARGS := +IMEM=$(SW_OUT)/imem.hex +DMEM=$(SW_OUT)/dmem.hex

.PHONY: help lint test-all sw sim clean check-prog

help:
	@echo "make lint                 strict lint of every module in rtl/ (each as its own top)"
	@echo "make test-<name>          build + run tb/tb_<name>.sv     (e.g. make test-alu)"
	@echo "make test-all             run every tb/tb_*.sv, report pass/fail summary"
	@echo "make sw   PROG=<file>     compile a .S/.c program -> elf, dump, imem.hex, dmem.hex"
	@echo "make sim  PROG=<file>     sw + run tb/tb_top.sv with +IMEM=/+DMEM= plusargs"
	@echo "make clean"
	@echo "Options: WAVES=1 (FST tracing), PLUSARGS='+foo=1' (extra plusargs to sim)"
	@echo "Modules found: $(MODULES)"
	@echo "Testbenches found: $(TBS)"

# --- Lint: each module linted as its own top, so a module that's never instantiated
#     still gets checked, and errors point at one file at a time.
lint:
ifneq ($(PKG),)
	@echo "== lint rv32i_pkg"
	@$(VERILATOR) --lint-only -Wall $(PKG) scripts/pkg_lint_top.sv --top-module pkg_lint_top
endif
	@for m in $(MODULES); do \
	  echo "== lint $$m"; \
	  $(VERILATOR) --lint-only -Wall -y $(RTL_DIR) -I$(RTL_DIR) $(PKG) $(RTL_DIR)/$$m.sv \
	    --top-module $$m || exit 1; \
	done
	@echo "lint clean"

# --- Unit tests
test-%:
	@test -f $(TB_DIR)/tb_$*.sv || { echo "no such testbench: $(TB_DIR)/tb_$*.sv"; exit 1; }
	@mkdir -p $(BUILD) $(OBJ_ROOT)/obj_$*
	$(VERILATOR) $(VSIM_FLAGS) $(PKG) $(TB_DIR)/tb_$*.sv --top-module tb_$* \
	  -Mdir $(OBJ_ROOT)/obj_$* -o Vtb_$*
	$(OBJ_ROOT)/obj_$*/Vtb_$* $(PLUSARGS)

# tb_top is excluded: it needs a program loaded, so it runs via `make sim PROG=...`.
test-all:
	@fail=""; \
	for t in $(filter-out top,$(TBS)); do \
	  $(MAKE) --no-print-directory test-$$t > $(BUILD)/test-$$t.log 2>&1 \
	    && echo "PASS  $$t" || { echo "FAIL  $$t  (see $(BUILD)/test-$$t.log)"; fail="$$fail $$t"; }; \
	done; \
	test -z "$$fail"
test-all: | $(BUILD)

$(BUILD):
	@mkdir -p $@

# --- Software
check-prog:
	@test -n "$(PROG)" || { echo "set PROG=<path to .S or .c>"; exit 1; }
	@test -f "$(PROG)" || { echo "no such file: $(PROG)"; exit 1; }

sw: check-prog
	@mkdir -p $(SW_OUT)
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(SW_OUT)/$(NAME).map -o $(ELF) $(SW_SRCS) $(LDLIBS)
	$(OBJDUMP) -d -M no-aliases,numeric $(ELF) > $(SW_OUT)/$(NAME).dump
	$(PYTHON) scripts/elf2hex.py $(ELF) -o $(SW_OUT) \
	  --imem $(IMEM_BASE) $(IMEM_SIZE) --dmem $(DMEM_BASE) $(DMEM_SIZE)

# --- Full-core simulation (needs tb/tb_top.sv)
sim: sw
	@$(MAKE) --no-print-directory test-top PLUSARGS="$(SIM_PLUSARGS) $(PLUSARGS)"

clean:
	rm -rf $(BUILD) $(OBJ_ROOT)
