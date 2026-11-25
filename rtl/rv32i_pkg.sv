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

    // Shared encoding constants: each importing module uses only a subset,
    // so Verilator's per-module UNUSEDPARAM warning is expected here.
    /* verilator lint_off UNUSEDPARAM */

    // OPCODES
    localparam  logic [6:0]
        OPCODE_LUI    = 7'b0110111,
        OPCODE_AUIPC  = 7'b0010111,
        OPCODE_JAL    = 7'b1101111,
        OPCODE_JALR   = 7'b1100111,
        OPCODE_BRANCH = 7'b1100011,
        OPCODE_LOAD   = 7'b0000011,
        OPCODE_STORE  = 7'b0100011,
        OPCODE_IMM    = 7'b0010011,
        OPCODE_ALU    = 7'b0110011,
        OPCODE_FENCE  = 7'b0001111,
        OPCODE_SYSTEM = 7'b1110011;

    // funct3 for BRANCH opcode
    localparam logic [2:0]
        F3_BEQ  = 3'b000,
        F3_BNE  = 3'b001,
        F3_BLT  = 3'b100,
        F3_BGE  = 3'b101,
        F3_BLTU = 3'b110,
        F3_BGEU = 3'b111;

    // funct3 for LOAD opcode
    localparam logic [2:0]
        F3_LB   = 3'b000,
        F3_LH   = 3'b001,
        F3_LW   = 3'b010,
        F3_LBU  = 3'b100,
        F3_LHU  = 3'b101;

    // funct3 for STORE opcode
    localparam logic [2:0]
        F3_SB   = 3'b000,
        F3_SH   = 3'b001,
        F3_SW   = 3'b010;

    /* verilator lint_on UNUSEDPARAM */

endpackage
