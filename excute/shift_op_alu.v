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

module shift_op_alu (
    input  [31:0] op1,         // rs1
    input  [31:0] op2,         // rs2 or immediate (already selected outside)
    input  [6:0]  opcode,      // instruction[6:0]
    input  [2:0]  func3,       // instruction[14:12]
    input  [6:0]  func7,       // instruction[31:25] for R-type
    input  [31:0] imm,         // full immediate (for imm[11:5] check)
    output reg [31:0] result_alu
);

       reg [4:0] shamt;

    always @(*) begin

        // shamt selection
        if (opcode == ``OPCODE_RTYPE)
            shamt = op2[4:0];
        else if (opcode == `OPCODE_ITYPE)
            shamt = imm[4:0];
        else
            shamt = 5'd0;

        case (func3)

            // =====================================================
            // SLL / SLLI
            // =====================================================
            3'b001: begin
                if (opcode == ``OPCODE_RTYPE && func7 == 7'b0000000)
                    result_alu = op1 << shamt;

                else if (opcode == `OPCODE_ITYPE && imm[11:5] == 7'b0000000)
                    result_alu = op1 << shamt;

                else
                    result_alu = 32'b0;
            end

            // =====================================================
            // SRL / SRLI / SRA / SRAI
            // =====================================================
            3'b101: begin

                // SRL (logical)
                if (opcode == ``OPCODE_RTYPE && func7 == 7'b0000000)
                    result_alu = op1 >> shamt;

                else if (opcode == `OPCODE_ITYPE && imm[11:5] == 7'b0000000)
                    result_alu = op1 >> shamt;

                // SRA (arithmetic)
                else if (opcode == `OPCODE_RTYPE && func7 == 7'b0100000)
                    result_alu = $signed(op1) >>> shamt;

                // SRAI (arithmetic immediate)
                // imm[11:5] MUST be 0100000
                else if (opcode == `OPCODE_ITYPE && imm[11:5] == 7'b0100000)
                    result_alu = $signed(op1) >>> shamt;

                else
                    result_alu = 32'b0;
            end

            default: result_alu = 32'b0;

        endcase
    end

endmodule

