// tb_decode_stage.v

module tb_decode_stage;
    // Signals (module scope)
    reg clk;
    reg rst;
    reg id_flush;
    reg [31:0] instruction_in;
    reg reg_file_wr_en;
    reg [4:0] reg_file_wr_addr;
    reg [31:0] reg_file_wr_data;

    wire [31:0] op1;
    wire [31:0] op2;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [31:0] immediate; // connected to DUT output
    wire [6:0] opcode;
    wire alu_src;
    wire invalid_inst;
    wire [6:0] func7;
    wire [2:0] func3;
    wire mem_write;
    wire [2:0] mem_load_type;
    wire [1:0] mem_store_type;
    wire wb_load;
    wire wb_reg_file;

    // Test bookkeeping
    integer pass_count;
    integer fail_count;

    // temporary regs for checks
    reg [31:0] expected_imm;
    reg [31:0] tmp32;

    // Instantiate DUT
    decode_stage uut (
        .clk(clk),
        .rst(rst),
        .id_flush(id_flush),
        .instruction_in(instruction_in),
        .reg_file_wr_en(reg_file_wr_en),
        .reg_file_wr_addr(reg_file_wr_addr),
        .reg_file_wr_data(reg_file_wr_data),

        .op1(op1),
        .op2(op2),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .immediate(immediate),
        .opcode(opcode),
        .alu_src(alu_src),
        .invalid_inst(invalid_inst),
        .func7(func7),
        .func3(func3),
        .mem_write(mem_write),
        .mem_load_type(mem_load_type),
        .mem_store_type(mem_store_type),
        .wb_load(wb_load),
        .wb_reg_file(wb_reg_file)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Create reg_hex_file.hex for register_file initialization
    integer fh;
    initial begin
        fh = $fopen("reg_hex_file.hex","w");
        if (fh == 0) begin
            $display("ERROR: cannot create reg_hex_file.hex");
            $finish;
        end
        $fdisplay(fh, "00000000"); // x0
        $fdisplay(fh, "00000001"); // x1
        $fdisplay(fh, "00000002"); // x2
        $fdisplay(fh, "00000003"); // x3
        $fclose(fh);
    end

    // Helper constructors (pure Verilog)
    function [31:0] make_i;
        input [6:0] opc;
        input [4:0] rd_i;
        input [2:0] f3;
        input [4:0] rs1_i;
        input [11:0] imm12;
        begin
            make_i = {imm12, rs1_i, f3, rd_i, opc};
        end
    endfunction

    function [31:0] make_s;
        input [6:0] opc;
        input [4:0] rs2_i;
        input [4:0] rs1_i;
        input [2:0] f3;
        input [11:0] imm12;
        reg [6:0] imm11_5;
        reg [4:0] imm4_0;
        begin
            imm11_5 = imm12[11:5];
            imm4_0  = imm12[4:0];
            make_s = {imm11_5, rs2_i, rs1_i, f3, imm4_0, opc};
        end
    endfunction

    // PASS/FAIL printing task
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
    initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end

    // Main test sequence
    initial begin
        pass_count = 0;
        fail_count = 0;
        // init
        rst = 1;
        id_flush = 0;
        instruction_in = 32'h00000013; // NOP default
        reg_file_wr_en = 0;
        reg_file_wr_addr = 0;
        reg_file_wr_data = 0;

        #20;
        rst = 0;
        #10;

        // ---- Test 1: I-type immediate (ADDI) sign-extend check ----
        // build instruction: addi x5, x1, -1  (imm = 0xFFF)
        instruction_in = make_i(7'b0010011, 5'd5, 3'b000, 5'd1, 12'hFFF);
        #10;
        // compute expected immediate using the instruction variable (portable)
        expected_imm = {{20{instruction_in[31]}}, instruction_in[31:20]}; // I-type sign-extend
        CHECK(uut.immediate === expected_imm, "I-type immediate sign-extend (ADDI)");

        // ---- Test 2: S-type immediate (store) and mem_store_type ----
        instruction_in = make_s(7'b0100011, 5'd2, 5'd1, 3'b000, 12'h00A); // sb x2, offset(x1)
        #10;
        expected_imm = {{20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7]};
        CHECK(uut.immediate === expected_imm, "S-type immediate build (SB)");
        CHECK(mem_write === 1'b1, "mem_write asserted for S-type");

        // store half
        instruction_in = make_s(7'b0100011, 5'd2, 5'd1, 3'b001, 12'h004);
        #10;
        expected_imm = {{20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7]};
        CHECK(uut.immediate === expected_imm, "S-type immediate build (SH)");

        // ---- Test 3: id_flush forcing NOP ----
        instruction_in = 32'hDEADBEEF;
        id_flush = 1;
        #10;
        // For flush we expect the decode stage to see NOP instruction (0x00000013)
        // Build expected immediate for NOP using an instruction variable (do not index numeric literal)
        tmp32 = 32'h00000013;
        expected_imm = {{20{tmp32[31]}}, tmp32[31:20]};
        CHECK(uut.immediate === expected_imm, "id_flush forces NOP decode");
        id_flush = 0;

        // ---- Test 4: ILOAD types and mem_load_type ----
        // lb (func3 = 000)
        instruction_in = make_i(7'b0000011, 5'd7, 3'b000, 5'd2, 12'h004);
        #10;
        expected_imm = {{20{instruction_in[31]}}, instruction_in[31:20]};
        CHECK(wb_load === 1'b1, "wb_load true for ILOAD");
        CHECK(mem_load_type == `LOAD_LB, "mem_load_type LB for func3=000");

        // lbu (func3 = 100)
        instruction_in = make_i(7'b0000011, 5'd7, 3'b100, 5'd2, 12'h004);
        #10;
        CHECK(mem_load_type == `LOAD_LBU, "mem_load_type LBU for func3=100");

        // ---- Test 5: register file write and read (write then read) ----
        // write x5 = 0xDEADBEEF using reg_file_wr ports (simulate writeback)
        reg_file_wr_en = 1;
        reg_file_wr_addr = 5;
        reg_file_wr_data = 32'hDEADBEEF;
        #10; // posedge write
        reg_file_wr_en = 0;
        // now create instruction reading rs1 = 5
        instruction_in = make_i(7'b0010011, 5'd8, 3'b000, 5'd5, 12'h001); // addi x8, x5, 1
        #10;
        CHECK(op1 === 32'hDEADBEEF, "register file read after write (x5 == DEADBEEF)");

        // ---- Test 6: same-cycle forwarding (write and read in same cycle) ----
        // assert write and read before posedge to test forwarding logic
        reg_file_wr_en = 1;
        reg_file_wr_addr = 5'd9;
        reg_file_wr_data = 32'hCAFEBABE;
        // set instruction to read rs1 = 9
        instruction_in = make_i(7'b0010011, 5'd10, 3'b000, 5'd9, 12'h002);
        #1; // small delta to let combinational forwarding be visible
        CHECK(op1 === 32'hCAFEBABE, "same-cycle forwarding: read forwarded value for x9");
        #9; // finish cycle so write actually happens
        reg_file_wr_en = 0;

        // ---- Test 7: invalid opcode detection ----
        instruction_in = 32'hFFFFFFFF; // unlikely valid opcode
        #10;
        CHECK(invalid_inst === 1'b1, "invalid_inst asserted for unsupported opcode");

        // Final summary
        #10;
        $display("=======================================");
        $display("DECODE_STAGE TB SUMMARY");
        $display(" PASSED = %0d", pass_count);
        $display(" FAILED = %0d", fail_count);
        if (fail_count == 0) $display(" OVERALL RESULT: PASS");
        else $display(" OVERALL RESULT: FAIL");
        $display("=======================================");
        $finish;
    end

endmodule

