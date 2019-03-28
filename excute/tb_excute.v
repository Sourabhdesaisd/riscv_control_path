
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

endmodule
 
