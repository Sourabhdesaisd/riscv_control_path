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


/*module execute_stage(
    input [31:0] pc,
    input [31:0] op1,
    input [31:0] op2,
    input pipeline_flush,
    input [31:0] immediate,
    input [6:0] func7,
    input [2:0] func3,
    input [6:0] opcode,
    input ex_alu_src,
    input predictedTaken,
    input invalid_inst,
    input ex_wb_reg_file,
  
    input [4:0] alu_rd,
    
    input [1:0] operand_a_forward_cntl,
    input [1:0] operand_b_forward_cntl,
    input [31:0] data_forward_mem,
    input [31:0] data_forward_wb,

    output  [31:0] result_alu,
    output  [31:0] op1_selected,
    output  [31:0] op2_selected,
    output  [31:0] pc_jump_addr,
    output  jump_en,
    output  update_btb,
    output  [31:0] calc_jump_addr,
    output  [4:0] wb_rd,
    output  wb_reg_file
);

    reg [31:0] op1_forwarded;
    reg [31:0] op2_forwarded;
    reg [31:0] op1_alu;
    reg [31:0] op2_alu;
   // wire [31:0] alu_result;

    wire [31:0] op1_valid;
    wire [31:0] op2_valid;

    wire zero_flag;   
    wire carry_flag;
    wire negative_flag;
    wire overflow_flag;


    // Mux for forwarding operand 1
    always @(*) begin
        case (operand_a_forward_cntl)
            `FORWARD_MEM: op1_forwarded = data_forward_mem;
            `FORWARD_WB:  op1_forwarded = data_forward_wb;
            default:      op1_forwarded = op1;
        endcase
    end

    // Mux for forwarding operand 2
    always @(*) begin
        case (operand_b_forward_cntl)
            `FORWARD_MEM: op2_forwarded = data_forward_mem;
            `FORWARD_WB:  op2_forwarded = data_forward_wb;
            default:      op2_forwarded = op2;
        endcase
    end

    // Pass op2 directly to pipeline stage in case it is used for Load instruction
    // Forwarded outputs are also used in the M unit to avoid data hazards
    //assign op2_selected = op2_forwarded;
   // assign op1_selected = op1_forwarded;
    
assign op1_selected = (operand_a_forward_cntl == `FORWARD_MEM) ? data_forward_mem :
                      (operand_a_forward_cntl == `FORWARD_WB)  ? data_forward_wb  :
                                                                op1;

assign op2_selected = (operand_b_forward_cntl == `FORWARD_MEM) ? data_forward_mem :
                      (operand_b_forward_cntl == `FORWARD_WB)  ? data_forward_wb  :
                                                                op2;
    
    always @(*) begin
        case (opcode)
            `OPCODE_IJALR: begin
                op1_alu = pc;
                op2_alu = 32'd4;
            end
            `OPCODE_JTYPE: begin
                op1_alu = pc;
                op2_alu = 32'd4;
            end
            `OPCODE_UTYPE: begin
                op1_alu = 32'h00000000;
                op2_alu = immediate;
            end
            `OPCODE_AUIPC: begin
                op1_alu = pc;
                op2_alu = immediate;
            end
            default: begin
                op1_alu = invalid_inst ? 0 : op1_forwarded;
                op2_alu = ex_alu_src ? immediate : op2_forwarded;
            end      
        endcase
    end
        
    assign op1_valid = pipeline_flush ? 0 : op1_alu;
    assign op2_valid = pipeline_flush ? 0 : op2_alu;

    // Instantiate the PC Jump Module
    pc_jump pc_jump_inst (
        .pc(pc),
        .immediate(immediate),
        .op1(op1_forwarded),
        .opcode(opcode),
        .func3(func3),
        .carry_flag(carry_flag),
        .negative_flag(negative_flag),
        .overflow_flag (overflow_flag),
        .zero_flag(zero_flag),
        .predictedTaken(predictedTaken),
        .update_pc(pc_jump_addr),
        .jump_addr(calc_jump_addr),
        .modify_pc(jump_en),
        .update_btb(update_btb)
    );


alu_top alu_top_inst (
    .op1(op1_alu),
    .op2(op2_alu),
    .imm(immediate),
    .opcode(opcode),
    .func3(func3),
    .func7(func7),

    .result_alu(result_alu),
    .zero_flag(zero_flag),
    .negative_flag(negative_flag),
    .carry_flag(carry_flag),
    .overflow_flag(overflow_flag)
);
      
  //assign alu_result= result_alu;
//assign wb_reg_file = ex_wb_reg_file; // temp dont use in pipeline
assign wb_rd       = alu_rd;
reg [31:0] operand_b;

always @(*) begin
    case(ex_opcode)
        `OPCODE_STYPE,
        `OPCODE_ILOAD: operand_b = ex_immediate;   // <- FIX
        default:       operand_b = ex_alu_src ? ex_immediate : ex_op2;
    endcase
end

   
endmodule*/


/*
// ========= execute_stage.v =========
module execute_stage(
    input  [31:0] pc,
    input  [31:0] op1,
    input  [31:0] op2,
    input         pipeline_flush,
    input  [31:0] immediate,
    input  [6:0]  func7,
    input  [2:0]  func3,
    input  [6:0]  opcode,
    input         ex_alu_src,
    input         predictedTaken,
    input         invalid_inst,
    input         ex_wb_reg_file,

    input  [4:0]  alu_rd,

    input  [1:0]  operand_a_forward_cntl,
    input  [1:0]  operand_b_forward_cntl,
    input  [31:0] data_forward_mem,
    input  [31:0] data_forward_wb,

    output [31:0] result_alu,
    output [31:0] op1_selected,
    output [31:0] op2_selected,
    output [31:0] pc_jump_addr,
    output        jump_en,
    output        update_btb,
    output [31:0] calc_jump_addr,
    output [4:0]  wb_rd,
    output        wb_reg_file
);

    // ---------------------------------------------------
    // Forwarded operands from EX/MEM or MEM/WB
    // ---------------------------------------------------
    reg [31:0] op1_forwarded;
    reg [31:0] op2_forwarded;

    always @(*) begin
        case (operand_a_forward_cntl)
            `FORWARD_MEM: op1_forwarded = data_forward_mem;
            `FORWARD_WB:  op1_forwarded = data_forward_wb;
            default:      op1_forwarded = op1;
        endcase
    end

    always @(*) begin
        case (operand_b_forward_cntl)
            `FORWARD_MEM: op2_forwarded = data_forward_mem;
            `FORWARD_WB:  op2_forwarded = data_forward_wb;
            default:      op2_forwarded = op2;
        endcase
    end

    // These go forward to EX/MEM for store data, M-unit, etc.
    assign op1_selected = op1_forwarded;
    assign op2_selected = op2_forwarded;

    // ---------------------------------------------------
    // ALU operand selection  (*** main fix here ***)
    // ---------------------------------------------------
    reg [31:0] op1_alu;
    reg [31:0] op2_alu;

    always @(*) begin
        // defaults: normal ALU op on forwarded operands
        op1_alu =op1_forwarded;
        op2_alu = ex_alu_src ? immediate : op2_forwarded;

        case (opcode)
            // JAL / JALR compute PC+4 for link register
            `OPCODE_IJALR,
            `OPCODE_JTYPE: begin
                op1_alu = pc;
                op2_alu = 32'd4;
            end

            // LUI
            `OPCODE_UTYPE: begin
                op1_alu = 32'd0;
                op2_alu = immediate;
            end

            // AUIPC
            `OPCODE_AUIPC: begin
                op1_alu = pc;
                op2_alu = immediate;
            end

            // ***** LOAD / STORE ADDRESS = base (rs1) + imm *****
            `OPCODE_STYPE,
            `OPCODE_ILOAD: begin
                op1_alu = op1_forwarded;  // base register
                op2_alu = immediate;      // offset
            end

            default: begin
                // keep defaults above
  end
        endcase

        // If pipeline is being flushed, kill ALU inputs
        if (pipeline_flush) begin
            op1_alu = 32'd0;
            op2_alu = 32'd0;
        end
    end

    // ---------------------------------------------------
    // Branch / jump PC update (uses forwarded rs1)
    // ---------------------------------------------------
    wire zero_flag, carry_flag, negative_flag, overflow_flag;

    pc_jump pc_jump_inst (
        .pc            (pc),
        .immediate     (immediate),
        .op1           (op1_forwarded),   // branch compares on forwarded rs1
        .opcode        (opcode),
        .func3         (func3),
        .carry_flag    (carry_flag),
        .negative_flag (negative_flag),
        .overflow_flag (overflow_flag),
        .zero_flag     (zero_flag),
        .predictedTaken(predictedTaken),
        .update_pc     (pc_jump_addr),
        .jump_addr     (calc_jump_addr),
        .modify_pc     (jump_en),
        .update_btb    (update_btb)
    );

    // ---------------------------------------------------
    // Main ALU
    // ---------------------------------------------------
    alu_top alu_top_inst (
        .op1          (op1_alu),
        .op2          (op2_alu),
        .imm          (immediate),
        .opcode       (opcode),
        .func3        (func3),
        .func7        (func7),
        .result_alu   (result_alu),
        .carry_flag   (carry_flag),
        .zero_flag    (zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag)
    );

    // WB info just passes through
    assign wb_reg_file = ex_wb_reg_file;
    assign wb_rd       = alu_rd;

endmodule
*/


// =====================================================
// EXECUTE STAGE  (Corrected & Debugged Version)
// =====================================================

module execute_stage(
    input  [31:0] pc,
    input  [31:0] op1,
    input  [31:0] op2,
    input         pipeline_flush,
    input  [31:0] immediate,
    input  [6:0]  func7,
    input  [2:0]  func3,
    input  [6:0]  opcode,
    input         ex_alu_src,
    input         predictedTaken,
    input         invalid_inst,
    input         ex_wb_reg_file,

    input  [4:0]  alu_rd,

    input  [1:0]  operand_a_forward_cntl,
    input  [1:0]  operand_b_forward_cntl,
    input  [31:0] data_forward_mem,
    input  [31:0] data_forward_wb,

    output wire [31:0] result_alu,
    output wire [31:0] op1_selected,
    output wire [31:0] op2_selected,
    output wire [31:0] pc_jump_addr,
    output wire        jump_en,
    output wire        update_btb,
    output wire [31:0] calc_jump_addr,
    output wire [4:0]  wb_rd,
    output wire        wb_reg_file
);

    // ---------------------------------------------------------
    // Forwarding Muxes
    // ---------------------------------------------------------
    reg [31:0] op1_forwarded;
    reg [31:0] op2_forwarded;

    always @(*) begin
        case (operand_a_forward_cntl)
            2'b01: op1_forwarded = data_forward_mem;
            2'b10: op1_forwarded = data_forward_wb;
            default: op1_forwarded = op1;
        endcase
    end

    always @(*) begin
        case (operand_b_forward_cntl)
            2'b01: op2_forwarded = data_forward_mem;
            2'b10: op2_forwarded = data_forward_wb;
            default: op2_forwarded = op2;
        endcase
    end

    assign op1_selected = op1_forwarded;
    assign op2_selected = op2_forwarded;

    // ---------------------------------------------------------
    // ALU Operand Selection (BUG FIXED — removed invalid_inst)
    // ---------------------------------------------------------
    reg [31:0] op1_alu;
    reg [31:0] op2_alu;

    always @(*) begin
        case (opcode)

            // JALR
            7'b1100111: begin
                op1_alu = op1_forwarded; 
                op2_alu = immediate;
            end

            // JAL
            7'b1101111: begin
                op1_alu = pc;
                op2_alu = 32'd4;
            end

            // LUI (U-type)
            7'b0110111: begin
                op1_alu = 32'b0;
                op2_alu = immediate;
            end

            // AUIPC
            7'b0010111: begin
                op1_alu = pc;
                op2_alu = immediate;
            end

            default: begin
                // *************** FIXED ***************
                // Always use forwarded rs1
                op1_alu = op1_forwarded;

                // ex_alu_src selects immediate for ADDI, load, store, etc.
                op2_alu = (ex_alu_src) ? immediate : op2_forwarded;
            end
        endcase
    end

    wire [31:0] op1_valid = pipeline_flush ? 32'b0 : op1_alu;
    wire [31:0] op2_valid = pipeline_flush ? 32'b0 : op2_alu;

    // ---------------------------------------------------------
    // ALU Module
    // ---------------------------------------------------------
    wire zero_flag, negative_flag, carry_flag, overflow_flag;

    alu_top alu_top_inst (
        .op1(op1_valid),
        .op2(op2_valid),
        .imm(immediate),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),

        .result_alu(result_alu),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag)
    );

    // ---------------------------------------------------------
    // PC Jump Logic
    // ---------------------------------------------------------
    pc_jump pc_jump_inst (
        .pc(pc),
        .immediate(immediate),
        .op1(op1_forwarded),
        .opcode(opcode),
        .func3(func3),
        .carry_flag(carry_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag),
        .zero_flag(zero_flag),
        .predictedTaken(predictedTaken),

        .update_pc(pc_jump_addr),
        .jump_addr(calc_jump_addr),
        .modify_pc(jump_en),
        .update_btb(update_btb)
    );

    // ---------------------------------------------------------
    // WB Pipeline Signals
    // ---------------------------------------------------------
    assign wb_rd       = alu_rd;
    assign wb_reg_file = ex_wb_reg_file;

endmodule

