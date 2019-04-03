// OPCODES
`define OPCODE_RTYPE 7'b0110011
`define OPCODE_ITYPE 7'b0010011
`define OPCODE_ILOAD 7'b0000011
`define OPCODE_IJALR 7'b1100111
`define OPCODE_BTYPE 7'b1100011
`define OPCODE_STYPE 7'b0100011
`define OPCODE_JTYPE 7'b1101111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_UTYPE 7'b0110111

// FUNC7 - ADD
`define FUNC7_ADD 7'b0000000
`define FUNC7_SUB 7'b0100000

// ALU Codes
`define ALU_ADD  4'b0000
`define ALU_SUB  4'b0001
`define ALU_AND  4'b0010
`define ALU_OR   4'b0011
`define ALU_XOR  4'b0100
`define ALU_SLL  4'b0101
`define ALU_SRL  4'b0110
`define ALU_SRA  4'b0111
`define ALU_SLT  4'b1000
`define ALU_SLTU 4'b1001

// B Type Codes
`define BTYPE_BEQ  3'b000
`define BTYPE_BNE  3'b001
`define BTYPE_BLT  3'b100
`define BTYPE_BGE  3'b101
`define BTYPE_BLTU 3'b110
`define BTYPE_BGEU 3'b111

// Forwarding Unit
`define FORWARD_ORG 2'b00
`define FORWARD_MEM 2'b01
`define FORWARD_WB  2'b10

// Store Types
`define STORE_SB  2'b00
`define STORE_SH  2'b01
`define STORE_SW  2'b10
`define STORE_DEF 2'b11

// Load Types
`define LOAD_LB  3'b000
`define LOAD_HD  3'b001
`define LOAD_LW  3'b010
`define LOAD_LBU 3'b011
`define LOAD_LHU 3'b100
`define LOAD_DEF 3'b111

// Constants
`define ZERO_32BIT  32'h00000000
`define ZERO_12BIT  12'h000

// BTB State
`define STRONG_NOT_TAKEN 2'b00
`define WEAK_NOT_TAKEN   2'b01
`define STRONG_TAKEN     2'b10
`define WEAK_TAKEN       2'b11
module hazard_unit(
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [6:0] opcode,
    input [4:0] ex_rd,
    input ex_load_inst,
    input jump_branch_taken,
    input invalid_inst,

    output reg if_id_pipeline_flush,
    output reg if_id_pipeline_en,
    output reg id_ex_pipeline_flush,
    output reg id_ex_pipeline_en,
    output reg pc_en,
    output reg load_stall
);

    wire id_rs1_used;
    wire id_rs2_used;

    wire rs1_hazard;
    wire rs2_hazard;
    wire load_hazard;

    // For load we need to check if rs1 or rs2 is actually used in the instruction
    assign id_rs2_used  = (opcode == `OPCODE_RTYPE ||
                         opcode == `OPCODE_STYPE ||
                         opcode == `OPCODE_BTYPE);

    assign id_rs1_used  = (opcode == `OPCODE_ITYPE ||
                         opcode == `OPCODE_ILOAD ||
                         opcode == `OPCODE_IJALR) || id_rs2_used;

    assign rs1_hazard = id_rs1_used && (id_rs1 == ex_rd);
    assign rs2_hazard = id_rs2_used && (id_rs2 == ex_rd);
    assign load_hazard = ex_load_inst && (ex_rd != 5'b0) && (rs1_hazard || rs2_hazard);
     
    // At one time only 1 of `ex_load_inst` or `jump_branch_taken` will be true
    always @(*) begin
        //  Default values to avoid latch
        if_id_pipeline_flush = 1'b0;
        if_id_pipeline_en = 1'b1;
        id_ex_pipeline_flush = 1'b0;
        id_ex_pipeline_en = 1'b1;
        pc_en = 1'b1;
        load_stall = 1'b0;

        // Jump/Branch taken flush - 2 Stall
        if (jump_branch_taken) begin
            if_id_pipeline_flush = 1'b1;
            if_id_pipeline_en = 1'b0;
            id_ex_pipeline_flush = 1'b1;

        // Load flush - 1 Stall
        end else if (load_hazard) begin
            if_id_pipeline_en = 1'b0;
            id_ex_pipeline_flush = 1'b1;
            pc_en = 1'b0;
            load_stall = 1'b1;
        end

               else if (invalid_inst) begin
            id_ex_pipeline_flush = 1'b1;
        end

    end

endmodule
