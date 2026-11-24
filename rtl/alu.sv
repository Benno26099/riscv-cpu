module alu
    import rv32i_pkg::*;
(
    input logic [31:0]    a,
    input logic [31:0]    b,
    input alu_op_t        alu_op,
    output logic [31:0]   alu_res
);

    always_comb begin

        case (alu_op)
            ALU_ADD:
                alu_res = a + b;
            ALU_SUB:
                alu_res = a - b;
            ALU_SLL:
                alu_res = a << b[4:0];
            ALU_SLT:
                if ($signed(a) < $signed(b))
                    alu_res = 32'b1;
                else
                    alu_res = 32'b0;
            ALU_SLTU:
                if (a < b)
                    alu_res = 32'b1;
                else
                    alu_res = 32'b0;
            ALU_XOR:
                alu_res = a ^ b;
            ALU_SRL:
                alu_res = a >> b[4:0];
            ALU_SRA:
                alu_res = $signed(a) >>> b[4:0];
            ALU_OR:
                alu_res = a | b;
            ALU_AND:
                alu_res = a & b;
            default: alu_res = 32'b0;
        endcase
    end

endmodule
