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

module id_ex_pipeline(
    input clk,
    input rst,
    input pipeline_flush,
    input pipeline_en,

    input id_invalid_inst,
    input [31:0] id_instruction,
    input [31:0] id_pc,
    input [31:0] id_op1,
    input [31:0] id_op2,
    input [31:0] id_immediate,
    input [6:0]  id_opcode,
    input id_alu_src,
    input [6:0]  id_func7,
    input [2:0]  id_func3,
    input id_mem_write,
    input [2:0] id_mem_load_type,
    input [1:0] id_mem_store_type,
    input id_mem_read,
    input id_wb_reg_file,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] id_wb_rd,
    input id_pred_taken,

    output reg ex_forward_pipeline_flush,
 //   output reg ex_invalid_inst,
   // output reg [31:0] ex_instruction,
    output reg [31:0] ex_pc,
    output reg [31:0] ex_op1,
    output reg [31:0] ex_op2,
    output reg [31:0] ex_immediate,
    output reg [6:0] ex_opcode,
    output reg ex_alu_src,
    output reg [6:0] ex_func7,
    output reg [2:0] ex_func3,
    output reg ex_mem_write,
    output reg [2:0] ex_mem_load_type,
    output reg [1:0] ex_mem_store_type,
    output reg ex_mem_read,
    output reg ex_wb_reg_file,
    output reg [4:0] ex_rs1,
    output reg [4:0] ex_rs2,
    output reg [4:0] ex_wb_rd,
    output reg ex_pred_taken
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
  //          ex_invalid_inst <= 1'b0;
    //        ex_instruction <= 32'h00000000;
            ex_pc <= 32'h00000000;
            ex_op1 <= 32'h00000000;
            ex_op2 <= 32'h00000000;
            ex_immediate <= 32'h00000000;
            ex_opcode <= 7'b0000000;
            ex_alu_src <= 1'b0;
            ex_func7 <= 7'b0000000;
            ex_func3 <= 3'b000;
            ex_mem_write <= 1'b0;
            ex_mem_load_type <= 3'b111;
            ex_mem_store_type <= 2'b00;
            ex_mem_read <= 1'b0;
            ex_wb_reg_file <= 1'b0;
            ex_wb_rd <= 5'b00000;
            ex_rs1 <= 5'b00000;
            ex_rs2 <= 5'b00000;
            ex_pred_taken <= 1'b0;
            ex_forward_pipeline_flush <= 1'b0;
        end else if (pipeline_flush) begin
          //  ex_invalid_inst <= id_invalid_inst;
          //  ex_instruction <= id_instruction;
            ex_pc <= ex_pc;
            ex_op1 <= id_op1;
            ex_op2 <= id_op2;
            ex_immediate <= 32'h00000000;
            ex_opcode <= `OPCODE_ITYPE;
            ex_alu_src <= 1'b1;
            ex_func7 <= 7'b0000000;
            ex_func3 <= 3'b000;
            ex_mem_write <= 1'b0;
            ex_mem_load_type <= 3'b111;
            ex_mem_store_type <= 2'b00;
            ex_mem_read <= 1'b0;
            ex_wb_reg_file <= 1'b0;
            ex_wb_rd <= id_wb_rd;
            ex_rs1 <= id_rs1;
            ex_rs2 <= id_rs2;
            ex_pred_taken <= 1'b0;
            ex_forward_pipeline_flush <= pipeline_flush;
        end else if (pipeline_en) begin
           // ex_invalid_inst <= id_invalid_inst;
         //   ex_instruction <= id_instruction;
            ex_pc <= id_pc;
            ex_op1 <= id_op1;
            ex_op2 <= id_op2;
            ex_immediate <= id_immediate;
            ex_opcode <= id_opcode;
            ex_alu_src <= id_alu_src;
            ex_func7 <= id_func7;
            ex_func3 <= id_func3;
            ex_mem_write <= id_mem_write;
            ex_mem_load_type <= id_mem_load_type;
            ex_mem_store_type <= id_mem_store_type;
            ex_mem_read <= id_mem_read;
            ex_wb_reg_file <= id_wb_reg_file;
            ex_wb_rd <= id_wb_rd;
            ex_rs1 <= id_rs1;
            ex_rs2 <= id_rs2;
            ex_pred_taken <= id_pred_taken;
            ex_forward_pipeline_flush <= 1'b0;
        end
    end

endmodule
