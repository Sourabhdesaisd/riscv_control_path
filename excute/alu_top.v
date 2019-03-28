
module alu_top (
    input  [31:0] op1,
    input  [31:0] op2,       // rs2 or imm (selected outside)
    input  [31:0] imm,       // immediate
    input  [6:0]  opcode,
    input  [2:0]  func3,
    input  [6:0]  func7,

    output reg [31:0] result_alu,

    // flags from adder only
    output carry_flag,
    output zero_flag,
    output negative_flag,
    output overflow_flag
);

    //----------------------------------------------------------
    // Detect SUB instruction
    // ---------------------------------------------------------
    // SUB = R-type, func3=000, func7=0100000
    wire is_sub = (opcode == 7'b0110011) &&
                  (func3  == 3'b000) &&
                  (func7  == 7'b0100000);

    //----------------------------------------------------------
    // Submodule outputs
    //----------------------------------------------------------
    wire [31:0] add_res;
    wire [31:0] shift_res;
    wire [31:0] logic_res;
    wire [31:0] comp_res;

    //----------------------------------------------------------
    // ADDER
    //----------------------------------------------------------
    ripple_carry_adder_alu ADD_UNIT (
        .op1(op1),
        .op2(op2),
        .sub(is_sub),          // select ADD or SUB
        .result_alu(add_res),
        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag)
    );

    //----------------------------------------------------------
    // SHIFTER
    //----------------------------------------------------------
    shift_op_alu SHIFT_UNIT (
        .op1(op1),
        .op2(op2),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .imm(imm),
        .result_alu(shift_res)
    );

    //----------------------------------------------------------
    // LOGICAL UNIT
    //----------------------------------------------------------
    logical_op_alu LOGIC_UNIT (
        .op1(op1),
        .op2(op2),
        .opcode(opcode),
        .func3(func3),
        .result_alu(logic_res)
    );

    //----------------------------------------------------------
    // COMPARATOR UNIT
    //----------------------------------------------------------
    comparator_alu COMP_UNIT (
        .op1(op1),
        .op2(op2),
        .opcode(opcode),
        .func3(func3),
        .result_alu(comp_res)
    );

    //----------------------------------------------------------
    // ALU RESULT SELECTOR (OUTPUT MUX)
    //----------------------------------------------------------
    always @(*) begin
        case (func3)

            // ADD / SUB / ADDI
            3'b000: result_alu = add_res;

            // SLL / SLLI
            3'b001: result_alu = shift_res;

            // SLT / SLTI
            3'b010: result_alu = comp_res;

            // SLTU / SLTIU
            3'b011: result_alu = comp_res;

            // XOR / XORI
            3'b100: result_alu = logic_res;

            // SRL / SRLI / SRA / SRAI
            3'b101: result_alu = shift_res;

            // OR / ORI
            3'b110: result_alu = logic_res;

            // AND / ANDI
            3'b111: result_alu = logic_res;

            default: result_alu = 32'd0;

        endcase
    end

endmodule

