module imm_gen
    import rv32i_pkg::*;
    (
        input logic [31:7] inst,
        input imm_sel_t imm_sel,
        output logic [31:0] imm_data
    );

    always_comb begin

        case (imm_sel)
            IMM_I:
                imm_data = {{21{inst[31]}}, inst[30:25], inst[24:21], inst[20]};
            IMM_S:
                imm_data = {{21{inst[31]}}, inst[30:25], inst[11:8], inst[7]};
            IMM_B:
                imm_data = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            IMM_U:
                imm_data = {inst[31:20], inst[19:12], 12'b0};
            IMM_J:
                imm_data = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
            default: imm_data = 32'b0;
        endcase
    end
endmodule


