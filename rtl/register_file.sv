module register_file
    import rv32i_pkg::*;
    (
        input logic clk,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input logic reg_we,
        input logic [4:0] rd,
        input logic [31:0] wb_data,

        output logic [31:0] rs1_data,
        output logic [31:0] rs2_data
    );

    logic [31:0] regs [32];

    always_comb begin
        if (rs1 == 0) begin
            rs1_data = 32'b0;
        end
        else begin
            rs1_data = regs[rs1];
        end
        if (rs2 == 0) begin
            rs2_data = 32'b0;
        end
        else begin
            rs2_data = regs[rs2];
        end
    end

    always_ff @(posedge clk) begin
        if (reg_we)
            regs[rd] <= wb_data;
    end

endmodule
