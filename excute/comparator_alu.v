module comparator_alu (
    input  [31:0] op1,        // rs1
    input  [31:0] op2,        // rs2 or immediate (selected outside)
    input  [6:0]  opcode,     // instruction[6:0]
    input  [2:0]  func3,      // instruction[14:12]
    output reg [31:0] result_alu
);

    // Opcodes
    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;

    always @(*) begin
        case (func3)

            // -------------------------------------------------
            // SLT, SLTI  (signed)
            // func3 = 010
            // -------------------------------------------------
            3'b010: begin
                if (opcode == OPCODE_R)      // SLT
                    result_alu = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0;

                else if (opcode == OPCODE_I) // SLTI
                    result_alu = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0;

                else
                    result_alu = 32'd0;
            end

            // -------------------------------------------------
            // SLTU, SLTIU  (unsigned)
            // func3 = 011
            // -------------------------------------------------
            3'b011: begin
                if (opcode == OPCODE_R)      // SLTU
                    result_alu = (op1 < op2) ? 32'd1 : 32'd0;

                else if (opcode == OPCODE_I) // SLTIU
                    result_alu = (op1 < op2) ? 32'd1 : 32'd0;

                else
                    result_alu = 32'd0;
            end

            default:
                result_alu = 32'd0;

        endcase
    end

endmodule

