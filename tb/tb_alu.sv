module tb_alu;
    import rv32i_pkg::*;

    logic [31:0]    a;
    logic [31:0]    b;
    alu_op_t        alu_op;
    logic [31:0]    alu_res;

    alu dut (.*);

    task automatic check(input logic [31:0] a_in, input logic [31:0] b_in,
                         input alu_op_t alu_op_in, input logic [31:0] expected);

        a = a_in;
        b = b_in;
        alu_op = alu_op_in;

        #1;
        if (alu_res !== expected)
            $fatal(1, "FAIL: %s a=%h b=%h alu_op=%h -> alu_res=%h, expected %h",
                   alu_op_in.name(), a_in, b_in, alu_op_in, alu_res, expected);

    endtask

    initial begin
        $dumpfile("build/alu.fst");
        $dumpvars;
        check(32'd5, 32'd7, ALU_ADD, 32'd12);
        check(32'hFFFF_FFFF, 32'd1, ALU_ADD, 32'd0);
        check(32'd0, 32'd1, ALU_SUB, 32'hFFFF_FFFF);
        check(32'hFFFF_FFFF, 32'd1, ALU_SLT, 32'd1);
        check(32'hFFFF_FFFF, 32'd1, ALU_SLTU, 32'd0);
        check(32'd0, 32'd16, ALU_SLT, 32'd1);
        check(32'd3, 32'd3, ALU_SLT, 32'd0);
        check(32'h8000_0000, 32'd4, ALU_SRL, 32'h0800_0000);
        check(32'h8000_0000, 32'd4, ALU_SRA, 32'hF800_0000);
        check(32'h0000_0001, 32'h21, ALU_SLL, 32'h0000_0002);
        check(32'h8000_0000, 32'h21, ALU_SRL, 32'h4000_0000);
        check(32'h8000_0000, 32'd31, ALU_SRA, 32'hFFFF_FFFF);
        check(32'hF0F0_F0F0, 32'hFF00_FF00, ALU_XOR, 32'h0FF0_0FF0);
        check(32'hF0F0_F0F0, 32'hFF00_FF00, ALU_OR, 32'hFFF0_FFF0);
        check(32'hF0F0_F0F0, 32'hFF00_FF00, ALU_AND, 32'hF000_F000);
        check(32'h1234_5678, 32'h1, alu_op_t'(4'b1111), 32'b0);

        $display("PASS");
        $finish;
    end

endmodule
