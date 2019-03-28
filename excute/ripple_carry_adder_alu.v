module ripple_carry_adder_alu (
    input  [31:0] op1,
    input  [31:0] op2,
    input         sub,               // 0 = ADD, 1 = SUB
    output [31:0] result_alu,
    output        carry_flag,
    output        zero_flag,
    output        negative_flag,
    output        overflow_flag
);

    // -------------------------
    // For SUB ? perform: op1 + (~op2) + 1
    // -------------------------
    wire [31:0] op2_in  = sub ? ~op2 : op2;
    wire        cin_in  = sub ? 1'b1 : 1'b0;

    reg [31:0] s;
    reg [32:0] c; // c[0] to c[32]
    integer i;

    always @(*) begin
        c[0] = cin_in;

        for (i = 0; i < 32; i = i + 1) begin
            // SUM
            s[i] = op1[i] ^ op2_in[i] ^ c[i];

            // CARRY
            c[i+1] = (op1[i] & op2_in[i]) |
                     (op1[i] & c[i])      |
                     (op2_in[i] & c[i]);
        end
    end

    assign result_alu = s;

    assign carry_flag    = c[32];
    assign zero_flag     = (result_alu == 32'd0);
    assign negative_flag = result_alu[31];

    // Signed overflow detection
    assign overflow_flag = (op1[31] == op2_in[31]) &&
                           (result_alu[31] != op1[31]);

endmodule

