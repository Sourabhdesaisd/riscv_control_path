module tb_alu_top;

    reg  [31:0] op1;
    reg  [31:0] op2;
    reg  [31:0] imm;
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    reg  [6:0]  func7;

    wire [31:0] result_alu;
    wire carry_flag, zero_flag, negative_flag, overflow_flag;

    alu_top DUT (
        .op1(op1),
        .op2(op2),
        .imm(imm),
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .result_alu(result_alu),
        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .overflow_flag(overflow_flag)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end


    initial begin
        $display("\n============================");
        $display("      ALU TESTCASES START");
        $display("============================\n");

        //--------------------------------------------------------
        // ADD
        //--------------------------------------------------------
        op1=10; op2=20;
        opcode=7'b0110011; func3=3'b000; func7=7'b0000000;
        imm=0;
        #1 $display("ADD   : Expected = 30        , Result = %0d", result_alu);

        //--------------------------------------------------------
        // SUB
        //--------------------------------------------------------
        func7=7'b0100000;
	#1 $display("SUB   : Expected = -10       , Result = %0d", $signed(result_alu));
       
        //--------------------------------------------------------
        // ADDI
        //--------------------------------------------------------
        opcode=7'b0010011; func3=3'b000;
        op1=50; imm=25; op2=imm;
        func7=7'b0000000;
        #1 $display("ADDI  : Expected = 75        , Result = %0d", result_alu);

        //--------------------------------------------------------
        // AND / ANDI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b111;
        op1=32'hFF00FF00; op2=32'h0F0F0F0F;
        #1 $display("AND   : Expected = 0F000F00  , Result = %h", result_alu);

        opcode=7'b0010011;
        op1=32'hAAAA5555; imm=32'h0000FFFF; op2=imm;
        #1 $display("ANDI  : Expected = 00005555  , Result = %h", result_alu);

        //--------------------------------------------------------
        // OR / ORI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b110;
        op1=32'h12345678; op2=32'hFFFF0000;
        #1 $display("OR    : Expected = FFFF5678  , Result = %h", result_alu);

        opcode=7'b0010011;
        imm=32'h0000FF00; op2=imm;
        #1 $display("ORI   : Expected = 1234FF78  , Result = %h", result_alu);

        //--------------------------------------------------------
        // XOR / XORI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b100;
        op1=32'hAAAAAAAA; op2=32'h55555555;
        #1 $display("XOR   : Expected = FFFFFFFF  , Result = %h", result_alu);

        opcode=7'b0010011;
        imm=32'h0000FFFF; op2=imm;
        #1 $display("XORI  : Expected = AAAA5555  , Result = %h", result_alu);

        //--------------------------------------------------------
        // SLL / SLLI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b001; func7=7'b0000000;
        op1=32'h00000011; op2=2;
        #1 $display("SLL   : Expected = 00000044  , Result = %h", result_alu);

        opcode=7'b0010011;
        imm=2; op2=imm;
        #1 $display("SLLI  : Expected = 00000044  , Result = %h", result_alu);

        //--------------------------------------------------------
        // SRL / SRLI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b101; func7=7'b0000000;
        op1=32'h80000000; op2=4;
        #1 $display("SRL   : Expected = 08000000  , Result = %h", result_alu);

        opcode=7'b0010011;
        imm=4; op2=imm;
        #1 $display("SRLI  : Expected = 08000000  , Result = %h", result_alu);

        //--------------------------------------------------------
        // SRA / SRAI
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b101; func7=7'b0100000;
        op1=-32'd32; op2=3;
        #1 $display("SRA   : Expected = FFFFFC    , Result = %h", result_alu);

        opcode=7'b0010011;
        imm = {7'b0100000, 5'd3};   // correct SRAI encoding
        op2 = imm;
        #1 $display("SRAI  : Expected = FFFFFFFC  , Result = %h", result_alu);

        //--------------------------------------------------------
        // SLT / SLTI (signed)
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b010;
        op1=-5; op2=10;
        #1 $display("SLT   : Expected = 1         , Result = %0d", result_alu);

        opcode=7'b0010011; imm=10; op2=imm;
        #1 $display("SLTI  : Expected = 1         , Result = %0d", result_alu);

        //--------------------------------------------------------
        // SLTU / SLTIU (unsigned)
        //--------------------------------------------------------
        opcode=7'b0110011; func3=3'b011;
        op1=32'hFFFFFF00; op2=32'h00000100;
        #1 $display("SLTU  : Expected = 0         , Result = %0d", result_alu);

        opcode=7'b0010011; imm=32'h00000100; op2=imm;
        #1 $display("SLTIU : Expected = 0         , Result = %0d", result_alu);

        //--------------------------------------------------------
        $display("\n============================");
        $display("    ALL TESTCASES COMPLETE");
        $display("============================\n");

        $finish;
    end

endmodule

