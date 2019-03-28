// tb_decode_controller.v
module tb_decode_controller;
    // RISC-V base opcodes (numeric)
    localparam OPCODE_RTYPE  = 7'b0110011; // 0x33
    localparam OPCODE_ITYPE  = 7'b0010011; // 0x13 (ALU immediate)
    localparam OPCODE_ILOAD  = 7'b0000011; // 0x03 (loads)
    localparam OPCODE_STYPE  = 7'b0100011; // 0x23 (stores)
    localparam OPCODE_BTYPE  = 7'b1100011; // 0x63 (branches)
    localparam OPCODE_JTYPE  = 7'b1101111; // 0x6f (JAL)
    localparam OPCODE_AUIPC  = 7'b0010111; // 0x17 (AUIPC)
    localparam OPCODE_IJALR  = 7'b1100111; // 0x67 (JALR)

    // func7 values
    localparam FUNC7_ADD = 7'b0000000;
    localparam FUNC7_SUB = 7'b0100000;

    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;

    wire ex_alu_src;
    wire mem_write;
    wire [2:0] mem_load_type;
    wire [1:0] mem_store_type;
    wire wb_load;
    wire wb_reg_file;
    wire invalid_inst;

    integer pass_count, fail_count;

    // instantiate DUT
    decode_controller dut (
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .ex_alu_src(ex_alu_src),
        .mem_write(mem_write),
        .mem_load_type(mem_load_type),
        .mem_store_type(mem_store_type),
        .wb_load(wb_load),
        .wb_reg_file(wb_reg_file),
        .invalid_inst(invalid_inst)
    );

    // checker task
    task CHECK;
        input condition;
        input [200*8:1] msg;
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


    initial begin
        

        pass_count = 0; fail_count = 0;

        // Test 1: R-type ADD -> should be wb_inst, not ex_alu_src from immediate, invalid_inst = 0
        opcode = OPCODE_RTYPE; func3 = 3'b000; func7 = FUNC7_ADD;
        #1;
        CHECK(wb_reg_file == 1'b1, "R-type (ADD) should writeback to regfile");
        CHECK(ex_alu_src == 1'b0, "R-type (ADD) should NOT set alu_src (immediate) by controller");
        CHECK(invalid_inst == 1'b0, "R-type should be valid");

        // Test 2: R-type SUB -> valid R-type (func7 SUB)
        opcode = OPCODE_RTYPE; func3 = 3'b000; func7 = FUNC7_SUB;
        #1;
        CHECK(wb_reg_file == 1'b1, "R-type (SUB) should writeback to regfile");
        CHECK(invalid_inst == 1'b0, "R-type SUB should be valid");

        // Test 3: I-type ALU immediate -> alu_src = 1, writeback
        opcode = OPCODE_ITYPE; func3 = 3'b000; func7 = 7'b0000000;
        #1;
        CHECK(ex_alu_src == 1'b1, "I-type ALU immediate should set ex_alu_src");
        CHECK(wb_reg_file == 1'b1, "I-type ALU immediate should writeback");

        // Test 4: Load -> wb_load=1, ex_alu_src=1, wb_reg_file=1
        opcode = OPCODE_ILOAD; func3 = 3'b010; func7 = 7'b0000000;
        #1;
        CHECK(wb_load == 1'b1, "Load opcode should assert wb_load");
        CHECK(ex_alu_src == 1'b1, "Load uses ALU immediate/address calc");
        CHECK(wb_reg_file == 1'b1, "Loads write back to regfile");

        // Test 5: Store (SB) func3=000 -> mem_write=1 and mem_store_type should be SB (encoded in your defines)
        opcode = OPCODE_STYPE; func3 = 3'b000; func7 = 7'b0000000;
        #1;
        CHECK(mem_write == 1'b1, "Store opcode should assert mem_write");
        CHECK(mem_store_type == `STORE_SB, "Store func3=000 -> STORE_SB");

        // Test 6: Store halfword
        opcode = OPCODE_STYPE; func3 = 3'b001; #1;
        CHECK(mem_store_type == `STORE_SH, "Store func3=001 -> STORE_SH");

        // Test 7: Store word
        opcode = OPCODE_STYPE; func3 = 3'b010; #1;
        CHECK(mem_store_type == `STORE_SW, "Store func3=010 -> STORE_SW");

        // Test 8: Branch (B-type) should not be ex_alu_src/wb_reg_file (controller decides)
        opcode = OPCODE_BTYPE; func3 = 3'b000; #1;
        CHECK(invalid_inst == 1'b0, "Branch should be a valid instruction type");

        // Test 9: JAL (J-type) -> writeback to rd
        opcode = OPCODE_JTYPE; func3 = 3'b000; #1;
        CHECK(wb_reg_file == 1'b1, "JAL should assert wb_reg_file");

        // Test 10: AUIPC -> alu_src true (since treated as U-type), wb_reg_file true
        opcode = OPCODE_AUIPC; #1;
        CHECK(ex_alu_src == 1'b1, "AUIPC should set ALU src");
        CHECK(wb_reg_file == 1'b1, "AUIPC should write back");

        // Test 11: JALR (IJALR) -> treated as jump (jalr_inst) -> writeback and alu_src
        opcode = OPCODE_IJALR; #1;
        CHECK(wb_reg_file == 1'b1, "JALR should write back");
        CHECK(ex_alu_src == 1'b1, "JALR should set ALU src");

        // Test 12: Unknown opcode -> invalid_inst = 1
        opcode = 7'b1111111; func3 = 3'b111; func7 = 7'b1111111; #1;
        CHECK(invalid_inst == 1'b1, "Unknown opcode should set invalid_inst");

        // Summary
        #5;
        $display("=== decode_controller TB SUMMARY ===");
        $display(" PASSED = %0d", pass_count);
        $display(" FAILED = %0d", fail_count);
        if (fail_count == 0) $display(" RESULT: PASS");
        else $display(" RESULT: FAIL");
        $display("====================================");
       #100  $finish;
    end
endmodule

