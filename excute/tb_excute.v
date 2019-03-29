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

// FUNC7 - M Unit
`define FUNC7_M_UNIT 7'b0000001

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



/*
module tb_execute_stage;

    // -------------------------------------------------------------------------
    // DUT interface signals (match execute_stage ports shown in screenshots)
    // -------------------------------------------------------------------------
    reg  [31:0] pc;
    reg  [31:0] op1;
    reg  [31:0] op2;
    reg         pipeline_flush;
    reg  [31:0] immediate;
    reg  [6:0]  func7;
    reg  [2:0]  func3;
    reg  [6:0]  opcode;
    reg         ex_alu_src;
    reg         predictedTaken;
    reg         invalid_inst;
    reg         ex_wb_reg_file;

    reg  [4:0]  alu_rd;

    reg  [1:0]  operand_a_forward_cntl;
    reg  [1:0]  operand_b_forward_cntl;
    reg  [31:0] data_forward_mem;
    reg  [31:0] data_forward_wb;

    wire [31:0] result_alu;
    wire [31:0] op1_selected;
    wire [31:0] op2_selected;
    wire [31:0] pc_jump_addr;
    wire        jump_en;
    wire        update_btb;
    wire [31:0] calc_jump_addr;
    wire [4:0]  wb_rd;
    wire        wb_reg_file;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    execute_stage dut (
        .pc(pc),
        .op1(op1),
        .op2(op2),
        .pipeline_flush(pipeline_flush),
        .immediate(immediate),
        .func7(func7),
        .func3(func3),
        .opcode(opcode),
        .ex_alu_src(ex_alu_src),
        .predictedTaken(predictedTaken),
        .invalid_inst(invalid_inst),
        .ex_wb_reg_file(ex_wb_reg_file),
        .alu_rd(alu_rd),
        .operand_a_forward_cntl(operand_a_forward_cntl),
        .operand_b_forward_cntl(operand_b_forward_cntl),
        .data_forward_mem(data_forward_mem),
        .data_forward_wb(data_forward_wb),

        .result_alu(result_alu),
        .op1_selected(op1_selected),
        .op2_selected(op2_selected),
        .pc_jump_addr(pc_jump_addr),
        .jump_en(jump_en),
        .update_btb(update_btb),
        .calc_jump_addr(calc_jump_addr),
        .wb_rd(wb_rd),
        .wb_reg_file(wb_reg_file)
    );

    // -------------------------------------------------------------------------
    // Test bookkeeping
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task CHECK;
        input condition;
        input [256:1] msg;
        begin
            if (condition) begin
                $display("[PASS] %s", msg);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s", msg);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Clock (kept for submodules if needed)
    // -------------------------------------------------------------------------
    reg clk;
    initial clk = 0;
    always #10 clk = ~clk;

    // -------------------------------------------------------------------------
    // Localparams (adjust if your RTL uses different encodings)
    // -------------------------------------------------------------------------
    localparam OPCODE_RTYPE = 7'b0110011; // R-type (may be used elsewhere)
    localparam OPCODE_ITYPE = 7'b0010011; // OP-IMM (ADDI)
    localparam OPCODE_JTYPE = 7'b1101111; // JAL (example)

    localparam FUNC7_ADD = 7'b0000000;
    localparam FUNC3_ADD = 3'b000;

    localparam FORWARD_NONE = 2'b00;
    localparam FORWARD_MEM  = 2'b01;
    localparam FORWARD_WB   = 2'b10;

    initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end


    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("dump_execute_stage.vcd");
        $dumpvars(0, tb_execute_stage);

        // initialize counters
        pass_count = 0;
        fail_count = 0;

        // init signals
        pc = 32'h00000000;
        op1 = 32'h00000011;
        op2 = 32'h00000022;
        pipeline_flush = 0;
        immediate = 32'h00000100;
        func7 = FUNC7_ADD;
        func3 = FUNC3_ADD;
        opcode = OPCODE_ITYPE; // default to I-type ALU (ADDI) which your ALU expects
        ex_alu_src = 0;
        predictedTaken = 0;
        invalid_inst = 0;
        ex_wb_reg_file = 0;
        alu_rd = 5'd3;

        operand_a_forward_cntl = FORWARD_NONE;
        operand_b_forward_cntl = FORWARD_NONE;
        data_forward_mem = 32'hAAAAAAAA;
        data_forward_wb  = 32'hBBBBBBBB;

        #20; // settle

        // ---------------------------
        // Test 1: default selection (no forwarding)
        // ---------------------------
        CHECK(op1_selected === op1, "op1_selected equals op1 when no forwarding (A)");
        CHECK(op2_selected === op2, "op2_selected equals op2 when no forwarding (B)");

        // Check wb signals are driven (not X)
        CHECK((wb_rd !== 5'bxxxxx), "wb_rd is driven (not X)");
        CHECK((wb_reg_file === 1'b0) || (wb_reg_file === 1'b1), "wb_reg_file is driven (0 or 1)");

        // ---------------------------
        // Test 2: forward operand A from MEM
        // ---------------------------
        operand_a_forward_cntl = FORWARD_MEM;
        data_forward_mem = 32'hDEAD0001;
        #40;
        CHECK(op1_selected === 32'hDEAD0001, "op1_selected forwarded from MEM (A)");

        // ---------------------------
        // Test 3: forward operand A from WB
        // ---------------------------
        operand_a_forward_cntl = FORWARD_WB;
        data_forward_wb = 32'hFEED0002;
        #20;
        CHECK(op1_selected === 32'hFEED0002, "op1_selected forwarded from WB (A)");

        // Reset A forward control
        operand_a_forward_cntl = FORWARD_NONE;
        #20;

        // ---------------------------
        // Test 4: forward operand B from MEM
        // ---------------------------
        operand_b_forward_cntl = FORWARD_MEM;
        data_forward_mem = 32'hCAFED00D;
        #20;
        CHECK(op2_selected === 32'hCAFED00D, "op2_selected forwarded from MEM (B)");

        // ---------------------------
        // Test 5: forward operand B from WB
        // ---------------------------
        operand_b_forward_cntl = FORWARD_WB;
        data_forward_wb = 32'h0BADF00D;
        #20;
        CHECK(op2_selected === 32'h0BADF00D, "op2_selected forwarded from WB (B)");

        // Reset B forward control
        operand_b_forward_cntl = FORWARD_NONE;
        #20;

        // ---------------------------
        // Test 6: ALU behavior (ADDI style) via result_alu
        // - We use OP-IMM (OPCODE_ITYPE) so ALU performs op1 + imm when ex_alu_src=1
        // - When ex_alu_src=0 the ALU should perform op1 + op2 (if your ALU implements that for the chosen opcode; for OP-IMM typically op2 is immediate, but many student designs accept opcode and ex_alu_src to choose)
        // We'll check two cases to be robust:
        //   1) op1 + op2 when ex_alu_src==0 (if ALU uses op2)
        //   2) op1 + immediate when ex_alu_src==1
        // If your RTL maps add differently, adjust opcodes above.
        // ---------------------------
        // Set deterministic operands
        op1 = 32'h00000010;
        op2 = 32'h00000004;
        immediate = 32'h00000020; // 32
        func3 = FUNC3_ADD;
        func7 = FUNC7_ADD;

        // Use OP-IMM for ALU (ADDI)
        opcode = OPCODE_ITYPE;
        ex_alu_src = 1'b0;
        #20;
        // If ALU uses op2 for this opcode we expect op1 + op2, otherwise we still test op1+op2 attempt
        CHECK(result_alu === (op1 + op2), "result_alu equals op1+op2 when ex_alu_src=0 (ALU uses op2)");

        // now select immediate into ALU (expected behavior for OP-IMM)
        ex_alu_src = 1'b1;
        #20;
        CHECK(result_alu === (op1 + immediate), "result_alu equals op1+immediate when ex_alu_src=1");

        // restore
        ex_alu_src = 1'b0;
        #10;
        CHECK(result_alu === (op1 + op2), "result_alu returns to op1+op2 when ex_alu_src=0 again");

        // ---------------------------
        // Test 7: jump signals produced (sanity)
        // ---------------------------
        opcode = OPCODE_JTYPE; // JAL (commonly)
        immediate = 32'h00000010;
        #20;
        CHECK((jump_en === 1'b0) || (jump_en === 1'b1), "jump_en is driven (0 or 1)");
        CHECK((pc_jump_addr !== 32'hXXXXXXXX), "pc_jump_addr is driven (not X)");
        CHECK((calc_jump_addr !== 32'hXXXXXXXX), "calc_jump_addr is driven (not X)");

        // ---------------------------
        // Final summary
        // ---------------------------
        #10;
        $display("=======================================");
        $display("EXECUTE_STAGE TB SUMMARY");
        $display(" PASSED = %0d", pass_count);
        $display(" FAILED = %0d", fail_count);
        if (fail_count == 0) $display(" OVERALL RESULT: PASS");
        else $display(" OVERALL RESULT: FAIL");
        $display("=======================================");
        #100 $finish;
    end

endmodule*/



module tb_execute_stage;
    reg  [31:0] pc;
    reg  [31:0] op1;
    reg  [31:0] op2;
    reg         pipeline_flush;
    reg  [31:0] immediate;
    reg  [6:0]  func7;
    reg  [2:0]  func3;
    reg  [6:0]  opcode;
    reg         ex_alu_src;
    reg         predictedTaken;
    reg         invalid_inst;
    reg         ex_wb_reg_file;
    reg  [4:0]  alu_rd;
    reg  [1:0]  operand_a_forward_cntl;
    reg  [1:0]  operand_b_forward_cntl;
    reg  [31:0] data_forward_mem;
    reg  [31:0] data_forward_wb;

    wire [31:0] result_alu;
    wire [31:0] op1_selected;
    wire [31:0] op2_selected;
    wire [31:0] pc_jump_addr;
    wire        jump_en;
    wire        update_btb;
    wire [31:0] calc_jump_addr;
    wire [4:0]  wb_rd;
    wire        wb_reg_file;

    // DUT (use fixed/updated RTL file name if you replaced it)
    execute_stage dut (
        .pc(pc),
        .op1(op1),
        .op2(op2),
        .pipeline_flush(pipeline_flush),
        .immediate(immediate),
        .func7(func7),
        .func3(func3),
        .opcode(opcode),
        .ex_alu_src(ex_alu_src),
        .predictedTaken(predictedTaken),
        .invalid_inst(invalid_inst),
        .ex_wb_reg_file(ex_wb_reg_file),
        .alu_rd(alu_rd),
        .operand_a_forward_cntl(operand_a_forward_cntl),
        .operand_b_forward_cntl(operand_b_forward_cntl),
        .data_forward_mem(data_forward_mem),
        .data_forward_wb(data_forward_wb),

        .result_alu(result_alu),
        .op1_selected(op1_selected),
        .op2_selected(op2_selected),
        .pc_jump_addr(pc_jump_addr),
        .jump_en(jump_en),
        .update_btb(update_btb),
        .calc_jump_addr(calc_jump_addr),
        .wb_rd(wb_rd),
        .wb_reg_file(wb_reg_file)
    );

    integer pass_count, fail_count;
    task CHECK;
        input condition;
        input [256:1] msg;
        begin
            if (condition) begin $display("[PASS] %s", msg); pass_count = pass_count + 1; end
            else begin $display("[FAIL] %s", msg); fail_count = fail_count + 1; end
        end
    endtask

    reg clk;
    initial clk = 0; always #5 clk = ~clk;
    initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end

    initial begin
        
        pass_count = 0; fail_count = 0;

        // defaults
        pc = 0;
        op1 = 32'h10; op2 = 32'h4;
        pipeline_flush = 0;
        immediate = 32'h20;
        func7 = `FUNC7_ADD;
        func3 = `ALU_ADD;//[2:0]; // not exactly func3 but reuse for simple add test
        opcode = `OPCODE_ITYPE; // test ADDI-style
        ex_alu_src = 0;
        predictedTaken = 0;
        invalid_inst = 0;
        ex_wb_reg_file = 1'b1;
        alu_rd = 5'd5;

        operand_a_forward_cntl = `FORWARD_ORG;
        operand_b_forward_cntl = `FORWARD_ORG;
        data_forward_mem = 32'hDEAD_AAAA;
        data_forward_wb  = 32'hBEEF_BBBB;

        #10;

        // no-forward tests
        CHECK(op1_selected === op1, "op1 selected equals op1 (no forwarding)");
        CHECK(op2_selected === op2, "op2 selected equals op2 (no forwarding)");

        // wb signals driven
        CHECK(wb_rd !== 5'bxxxxx, "wb_rd driven (not X)");
        CHECK(wb_reg_file === 1'b0 || wb_reg_file === 1'b1, "wb_reg_file driven (0 or 1)");

        // forward A from MEM
        operand_a_forward_cntl = `FORWARD_MEM; data_forward_mem = 32'h11112222; #10;
        CHECK(op1_selected === 32'h11112222, "op1 forwarded from MEM");

        // forward A from WB
        operand_a_forward_cntl = `FORWARD_WB; data_forward_wb = 32'h33334444; #10;
        CHECK(op1_selected === 32'h33334444, "op1 forwarded from WB");
        operand_a_forward_cntl = `FORWARD_ORG; #5;

        // forward B from MEM
        operand_b_forward_cntl = `FORWARD_MEM; data_forward_mem = 32'h55556666; #10;
        CHECK(op2_selected === 32'h55556666, "op2 forwarded from MEM");

        // forward B from WB
        operand_b_forward_cntl = `FORWARD_WB; data_forward_wb = 32'h77778888; #10;
        CHECK(op2_selected === 32'h77778888, "op2 forwarded from WB");
        operand_b_forward_cntl = `FORWARD_ORG; #5;

        // ---- ALU behavior (use I-TYPE opcode so ALU will use immediate when ex_alu_src=1) ----
        op1 = 32'h00000010;
        op2 = 32'h00000004;
        immediate = 32'h00000020;
        opcode = `OPCODE_ITYPE; // ADI/OP-IMM mapping used by many student designs
        func3 = 3'b000;
        func7 = `FUNC7_ADD;

        // expect op1 + op2 when ex_alu_src=0 (if ALU uses op2 as second operand)
        ex_alu_src = 1'b0;
        #10;
        CHECK(result_alu === (op1 + op2), "result_alu equals op1+op2 when ex_alu_src=0");

        // expect op1 + immediate when ex_alu_src=1
        ex_alu_src = 1'b1;
        #10;
        CHECK(result_alu === (op1 + immediate), "result_alu equals op1+immediate when ex_alu_src=1");

        // restore
        ex_alu_src = 1'b0;
        #10;
        CHECK(result_alu === (op1 + op2), "result_alu returns to op1+op2 when ex_alu_src=0");

        // jump sanity
        opcode = `OPCODE_JTYPE; immediate = 32'h10; #10;
        CHECK(jump_en === 1'b0 || jump_en === 1'b1, "jump_en driven");
        CHECK(pc_jump_addr !== 32'hXXXXXXXX, "pc_jump_addr driven");
        CHECK(calc_jump_addr !== 32'hXXXXXXXX, "calc_jump_addr driven");

        // summary
        #5;
        $display("===================================");
        $display(" TB SUMMARY: PASSED=%0d  FAILED=%0d", pass_count, fail_count);
        $display("===================================");
        #100 $finish;
    end

endmodule

