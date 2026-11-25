module branch_comp
    import rv32i_pkg::*;
    (
        input logic [31:0] rs1_data,
        input logic [31:0] rs2_data,
        input logic [2:0] funct3,

        output logic taken
    );

    logic eq;       // rs1 == rs2
    logic lt_s;     // rs1 <  rs2, signed
    logic lt_u;     // rs1 <  rs2, unsigned

    assign eq   = (rs1_data == rs2_data);
    assign lt_s = ({~rs1_data[31], rs1_data[30:0]} < {~rs2_data[31], rs2_data[30:0]});
    assign lt_u = (rs1_data < rs2_data);

    always_comb begin
        unique case (funct3)
            F3_BEQ:  taken = eq;
            F3_BNE:  taken = !eq;
            F3_BLT:  taken = lt_s;
            F3_BGE:  taken = !lt_s;
            F3_BLTU: taken = lt_u;
            F3_BGEU: taken = !lt_u;
            default: taken = 1'b0;
        endcase
    end

endmodule
