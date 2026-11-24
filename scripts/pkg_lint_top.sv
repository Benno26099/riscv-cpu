// Dummy top used only by `make lint` to lint rtl/rv32i_pkg.sv on its own
// (Verilator needs a top-level module; a package alone isn't one).
module pkg_lint_top;
  import rv32i_pkg::*;
endmodule
