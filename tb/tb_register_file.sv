module tb_register_file;

    logic clk = 1'b0;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic reg_we;
    logic [4:0] rd;
    logic [31:0] wb_data;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    register_file dut(.*);

    always #5 clk = ~clk;

    task automatic write(input logic [4:0] rd_in, input logic [31:0] data_in);
        rd      = rd_in;
        wb_data = data_in;
        reg_we  = 1'b1;
        @(posedge clk);
        #1;
        reg_we  = 1'b0;
    endtask

    task automatic check_read(input logic [4:0] rs1_in, input logic [4:0] rs2_in,
                              input logic [31:0] exp1, input logic [31:0] exp2);
        rs1 = rs1_in;
        rs2 = rs2_in;
        #1;
        if (rs1_data !== exp1)
            $fatal(1, "FAIL: rs1=x%0d -> %h, expected %h", rs1_in, rs1_data, exp1);
        if (rs2_data !== exp2)
            $fatal(1, "FAIL: rs2=x%0d -> %h, expected %h", rs2_in, rs2_data, exp2);
    endtask

    initial begin
        $dumpfile("build/register_file.fst");
        $dumpvars;

        reg_we = 1'b0;

        // Test 1+2: basic write/read, both ports, both orderings
        write(5'd5, 32'h1234_5678);
        write(5'd6, 32'hCAFE_F00D);
        check_read(5'd5, 5'd6, 32'h1234_5678, 32'hCAFE_F00D);
        check_read(5'd6, 5'd5, 32'hCAFE_F00D, 32'h1234_5678);

        // Test 3: reg_we = 0 blocks a write
        reg_we  = 1'b0;
        rd      = 5'd5;
        wb_data = 32'hBAD0_BAD0;    // must NOT end up in x5
        @(posedge clk);
        #1;
        check_read(5'd5, 5'd6, 32'h1234_5678, 32'hCAFE_F00D);

        // Test 4: writes to x0 are ignored; x0 always reads 0 on both ports
        write(5'd0, 32'hDEAD_BEEF);
        check_read(5'd0, 5'd0, 32'h0, 32'h0);

        // Test 5: reads are combinational - outputs follow the addresses with no clock edge
        check_read(5'd5, 5'd6, 32'h1234_5678, 32'hCAFE_F00D);
        check_read(5'd6, 5'd5, 32'hCAFE_F00D, 32'h1234_5678);

        // Test 6: the write lands on the clock edge, not before
        write(5'd7, 32'h7777_0000);                                 // known starting value
        reg_we  = 1'b1;
        rd      = 5'd7;
        wb_data = 32'hBABE_BABE;
        check_read(5'd7, 5'd7, 32'h7777_0000, 32'h7777_0000);       // set up, no edge yet: old value
        @(posedge clk);
        #1;
        reg_we  = 1'b0;
        check_read(5'd7, 5'd7, 32'hBABE_BABE, 32'hBABE_BABE);       // after the edge: new value

        // Test 7: address boundaries (lowest writable and highest register)
        write(5'd1,  32'hAAAA_0001);
        write(5'd31, 32'hBBBB_0031);
        check_read(5'd1, 5'd31, 32'hAAAA_0001, 32'hBBBB_0031);
        check_read(5'd31, 5'd1, 32'hBBBB_0031, 32'hAAAA_0001);

        // Earlier registers untouched by later writes
        check_read(5'd5, 5'd6, 32'h1234_5678, 32'hCAFE_F00D);

        $display("PASS");
        $finish;
    end

endmodule
