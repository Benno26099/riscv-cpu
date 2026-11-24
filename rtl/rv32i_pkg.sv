package rv32i_pkg;

    typedef enum logic [3:0] {
        ALU_ADD     = 4'b0000,
        ALU_SUB     = 4'b1000,
        ALU_SLL     = 4'b0001,
        ALU_SLT     = 4'b0010,
        ALU_SLTU    = 4'b0011,
        ALU_XOR     = 4'b0100,
        ALU_SRL     = 4'b0101,
        ALU_SRA     = 4'b1101,
        ALU_OR      = 4'b0110,
        ALU_AND     = 4'b0111
    } alu_op_t;

    typedef enum logic [1:0] {
        TYPE_ADD = 2'b00,
        TYPE_R   = 2'b01,
        TYPE_I   = 2'b10
    } alu_type_t;

    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100
    } imm_sel_t;

    typedef enum logic [1:0] {
        SEL_A_RS1   = 2'b00,
        SEL_A_PC    = 2'b01,
        SEL_A_ZERO  = 2'b10
    } sel_a_t;

    typedef enum logic {
        SEL_B_RS2   = 1'b0,
        SEL_B_IMM   = 1'b1
    } sel_b_t;

    typedef enum logic [1:0] {
        WB_ALU      = 2'b00,
        WB_LOAD     = 2'b01,
        WB_PC4      = 2'b10
    } wb_sel_t;

endpackage
