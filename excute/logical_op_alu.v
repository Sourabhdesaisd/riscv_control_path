
module logical_op_alu (
    input  [31:0] op1,         // rs1 value
    input  [31:0] op2,         // rs2 or immediate (selected by ALUSrc)
    input  [6:0]  opcode,      // instruction[6:0]
    input  [2:0]  func3,       // instruction[14:12]
    output reg [31:0] result_alu
);

    // R-type opcode and I-type opcode
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    always @(*) begin
        case (func3)

            // XOR / XORI
            3'b100: begin
                if (opcode == OPCODE_R || opcode == OPCODE_I)
                    result_alu = op1 ^ op2;
                else
                    result_alu = 32'b0;
            end

            // OR / ORI
            3'b110: begin
                if (opcode == OPCODE_R || opcode == OPCODE_I)
                    result_alu = op1 | op2;
                else
                    result_alu = 32'b0;
            end

            // AND / ANDI
            3'b111: begin
                if (opcode == OPCODE_R || opcode == OPCODE_I)
                    result_alu = op1 & op2;
                else
                    result_alu = 32'b0;
            end

            default:
                result_alu = 32'b0;

        endcase
    end

endmodule


