module tb_imm_gen;

    import rv32i_pkg::*;

    logic [31:7] inst;
    imm_sel_t imm_sel;

    logic [31:0] imm_data;

    imm_gen dut (.*);

    task automatic check(input logic [31:0] inst_in, input imm_sel_t imm_sel_in, input logic [31:0] expected);
        inst = inst_in[31:7];
        imm_sel = imm_sel_in;

        #1;
        if (imm_data !== expected)
            $fatal(1, "FAIL: %s inst=%h imm_sel=%h -> imm_data=%h, expected %h",
                   imm_sel_in.name(), inst_in, imm_sel_in, imm_data, expected);
    endtask

    initial begin
        $dumpfile("build/imm_gen.fst");
        $dumpvars;

        // I-type
        check(32'h00500093, IMM_I, 32'h0000_0005);   // addi x1, x0, 5
        check(32'hfff00093, IMM_I, 32'hFFFF_FFFF);   // addi x1, x0, -1
        check(32'h7ff00093, IMM_I, 32'h0000_07FF);   // addi x1, x0, 2047
        check(32'h80000093, IMM_I, 32'hFFFF_F800);   // addi x1, x0, -2048

        // S-type
        check(32'h0021aa23, IMM_S, 32'h0000_0014);   // sw x2, 20(x3)
        check(32'hfe21ae23, IMM_S, 32'hFFFF_FFFC);   // sw x2, -4(x3)
        check(32'h8021a023, IMM_S, 32'hFFFF_F800);   // sw x2, -2048(x3)

        // B-type
        check(32'h00000463, IMM_B, 32'h0000_0008);   // beq x0, x0, .+8
        check(32'hfe000ce3, IMM_B, 32'hFFFF_FFF8);   // beq x0, x0, .-8
        check(32'h000000e3, IMM_B, 32'h0000_0800);   // beq x0, x0, .+2048
        check(32'h7e000fe3, IMM_B, 32'h0000_0FFE);   // beq x0, x0, .+4094
        check(32'h80000063, IMM_B, 32'hFFFF_F000);   // beq x0, x0, .-4096

        // U-type
        check(32'h123450b7, IMM_U, 32'h1234_5000);   // lui x1, 0x12345
        check(32'hfffff0b7, IMM_U, 32'hFFFF_F000);   // lui x1, 0xFFFFF

        // J-type
        check(32'h0080006f, IMM_J, 32'h0000_0008);   // jal x0, .+8
        check(32'hff9ff06f, IMM_J, 32'hFFFF_FFF8);   // jal x0, .-8
        check(32'h0010006f, IMM_J, 32'h0000_0800);   // jal x0, .+2048
        check(32'h0008006f, IMM_J, 32'h0008_0000);   // jal x0, .+0x80000
        check(32'h8000006f, IMM_J, 32'hFFF0_0000);   // jal x0, .-0x100000

        // Unused imm_sel code -> RTL default
        check(32'hfff00093, imm_sel_t'(3'b111), 32'h0000_0000);

        $display("PASS");
        $finish;
    end

endmodule
