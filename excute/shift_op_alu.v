
module shift_op_alu (
    input  [31:0] op1,         // rs1
    input  [31:0] op2,         // rs2 or immediate (already selected outside)
    input  [6:0]  opcode,      // instruction[6:0]
    input  [2:0]  func3,       // instruction[14:12]
    input  [6:0]  func7,       // instruction[31:25] for R-type
    input  [31:0] imm,         // full immediate (for imm[11:5] check)
    output reg [31:0] result_alu
);

    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    reg [4:0] shamt;

    always @(*) begin

        // shamt selection
        if (opcode == OPCODE_R)
            shamt = op2[4:0];
        else if (opcode == OPCODE_I)
            shamt = imm[4:0];
        else
            shamt = 5'd0;

        case (func3)

            // =====================================================
            // SLL / SLLI
            // =====================================================
            3'b001: begin
                if (opcode == OPCODE_R && func7 == 7'b0000000)
                    result_alu = op1 << shamt;

                else if (opcode == OPCODE_I && imm[11:5] == 7'b0000000)
                    result_alu = op1 << shamt;

                else
                    result_alu = 32'b0;
            end

            // =====================================================
            // SRL / SRLI / SRA / SRAI
            // =====================================================
            3'b101: begin

                // SRL (logical)
                if (opcode == OPCODE_R && func7 == 7'b0000000)
                    result_alu = op1 >> shamt;

                else if (opcode == OPCODE_I && imm[11:5] == 7'b0000000)
                    result_alu = op1 >> shamt;

                // SRA (arithmetic)
                else if (opcode == OPCODE_R && func7 == 7'b0100000)
                    result_alu = $signed(op1) >>> shamt;

                // SRAI (arithmetic immediate)
                // imm[11:5] MUST be 0100000
                else if (opcode == OPCODE_I && imm[11:5] == 7'b0100000)
                    result_alu = $signed(op1) >>> shamt;

                else
                    result_alu = 32'b0;
            end

            default: result_alu = 32'b0;

        endcase
    end

endmodule

