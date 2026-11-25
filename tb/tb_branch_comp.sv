module tb_branch_comp;
    import rv32i_pkg::*;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [2:0] funct3;

    logic taken;

    branch_comp dut(.*);

    task automatic check(input logic [31:0] rs1_data_in, input logic [31:0] rs2_data_in,
                        input logic [2:0] funct3_in, input logic expected);

        rs1_data = rs1_data_in;
        rs2_data = rs2_data_in;
        funct3 = funct3_in;

        #1;
        if (taken !== expected)
            $fatal(1, "FAIL: rs1_data=%h rs2_data=%h funct3=%b -> taken=%b, expected %b",
                   rs1_data_in, rs2_data_in, funct3_in, taken, expected);

    endtask

    initial begin
        $dumpfile("build/branch_comp.fst");
        $dumpvars;

        // 1. Equal operands: the >= branches must be taken, the < branches not.
        //    Catches < vs <=, and "swap operands" instead of "invert".
        check(32'd5, 32'd5, F3_BEQ,  1'b1);
        check(32'd5, 32'd5, F3_BNE,  1'b0);
        check(32'd5, 32'd5, F3_BLT,  1'b0);
        check(32'd5, 32'd5, F3_BGE,  1'b1);
        check(32'd5, 32'd5, F3_BLTU, 1'b0);
        check(32'd5, 32'd5, F3_BGEU, 1'b1);

        // 2. Small positives, rs1 < rs2: signed and unsigned agree.
        check(32'd3, 32'd5, F3_BEQ,  1'b0);
        check(32'd3, 32'd5, F3_BNE,  1'b1);
        check(32'd3, 32'd5, F3_BLT,  1'b1);
        check(32'd3, 32'd5, F3_BGE,  1'b0);
        check(32'd3, 32'd5, F3_BLTU, 1'b1);
        check(32'd3, 32'd5, F3_BGEU, 1'b0);

        // 3. Small positives, rs1 > rs2: catches a comparison with operands reversed.
        check(32'd5, 32'd3, F3_BLT,  1'b0);
        check(32'd5, 32'd3, F3_BGE,  1'b1);
        check(32'd5, 32'd3, F3_BLTU, 1'b0);
        check(32'd5, 32'd3, F3_BGEU, 1'b1);

        // 4. Signed/unsigned disagree: bit 31 set on rs1.
        //    0x8000_0000 is -2^31 signed (less than 1) but 2^31 unsigned (greater).
        //    Catches a missing MSB flip (blt), or a flip applied to bltu too.
        check(32'h8000_0000, 32'd1, F3_BLT,  1'b1);
        check(32'h8000_0000, 32'd1, F3_BGE,  1'b0);
        check(32'h8000_0000, 32'd1, F3_BLTU, 1'b0);
        check(32'h8000_0000, 32'd1, F3_BGEU, 1'b1);

        // 5. -1 vs 0, both orders: -1 < 0 signed, but 0xFFFF_FFFF is max unsigned.
        check(32'hFFFF_FFFF, 32'd0, F3_BLT,  1'b1);
        check(32'hFFFF_FFFF, 32'd0, F3_BGE,  1'b0);
        check(32'hFFFF_FFFF, 32'd0, F3_BLTU, 1'b0);
        check(32'hFFFF_FFFF, 32'd0, F3_BGEU, 1'b1);
        check(32'd0, 32'hFFFF_FFFF, F3_BLT,  1'b0);
        check(32'd0, 32'hFFFF_FFFF, F3_BGE,  1'b1);
        check(32'd0, 32'hFFFF_FFFF, F3_BLTU, 1'b1);
        check(32'd0, 32'hFFFF_FFFF, F3_BGEU, 1'b0);

        // 6. Extremes: most negative vs most positive, both orders.
        check(32'h8000_0000, 32'h7FFF_FFFF, F3_BLT,  1'b1);
        check(32'h8000_0000, 32'h7FFF_FFFF, F3_BLTU, 1'b0);
        check(32'h7FFF_FFFF, 32'h8000_0000, F3_BLT,  1'b0);
        check(32'h7FFF_FFFF, 32'h8000_0000, F3_BLTU, 1'b1);

        // 7. Equality must look at all 32 bits: differ only in bit 31, then bit 0.
        check(32'h8000_0000, 32'd0, F3_BEQ, 1'b0);
        check(32'h8000_0000, 32'd0, F3_BNE, 1'b1);
        check(32'd1, 32'd0, F3_BEQ, 1'b0);
        check(32'd1, 32'd0, F3_BNE, 1'b1);

        // 8. funct3 010/011 are not branches: never taken. Operands chosen so
        //    that eq, lt_s and lt_u would each be true in one of the two pairs.
        check(32'd3, 32'd5, 3'b010, 1'b0);
        check(32'd3, 32'd5, 3'b011, 1'b0);
        check(32'd5, 32'd5, 3'b010, 1'b0);
        check(32'd5, 32'd5, 3'b011, 1'b0);

        $display("PASS");
        $finish;
    end

endmodule
