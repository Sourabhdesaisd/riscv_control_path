module tb_pc_jump;

    reg  [31:0] pc, immediate, op1;
    reg  [6:0]  opcode;
    reg  [2:0]  func3;
    reg         carry_flag, zero_flag, negative_flag, overflow_flag;
    reg         predictedTaken;

    wire [31:0] update_pc, jump_addr;
    wire        modify_pc, update_btb;

    // Expected results for checking
    reg  [31:0] expected_pc;
    reg         expected_modify;

    integer pass_count = 0;
    integer fail_count = 0;


    // ---------------- DUT ----------------
    pc_jump dut (
        .pc(pc), .immediate(immediate), .op1(op1),
        .opcode(opcode), .func3(func3),
        .carry_flag(carry_flag), .zero_flag(zero_flag),
        .negative_flag(negative_flag), .overflow_flag(overflow_flag),
        .predictedTaken(predictedTaken),
        .update_pc(update_pc), .jump_addr(jump_addr),
        .modify_pc(modify_pc), .update_btb(update_btb)
    );


    // ---------------- Result Printer + Checker ----------------
    task check;
        input [127:0] testname;
    begin
        #1;
        $display("\n[Test] %0s", testname);
        $display(" PC=%h  IMM=%h  jump_addr=%h  update_pc=%h", pc, immediate, jump_addr, update_pc);
        $display(" Flags: C=%b Z=%b N=%b O=%b | Pred=%b  modify_pc=%b",
                    carry_flag, zero_flag, negative_flag, overflow_flag, predictedTaken, modify_pc);

        if (update_pc === expected_pc && modify_pc === expected_modify) begin
            $display(" ---> RESULT: PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display(" ---> RESULT: FAIL (Expected PC=%h modify=%b)\n", expected_pc, expected_modify);
            fail_count = fail_count + 1;
        end
    end
    endtask

         initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end

    // ---------------- Stimulus ----------------
    initial begin
        
        // Default values
        pc = 32'h1000;
        immediate = 32'h10;
        op1 = 32'h2000;
        predictedTaken = 0;
        carry_flag = 0; zero_flag = 0;
        negative_flag = 0; overflow_flag = 0;


        // 1) BEQ Taken
        opcode = 7'b1100011; func3=3'b000; zero_flag=1;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("BEQ TAKEN");

        // 2) BEQ Not Taken
        zero_flag=0;
        expected_modify = 0; expected_pc = pc + 32'h4;
        #5 check("BEQ NOT TAKEN");

        // 3) BLT signed
        func3=3'b100; negative_flag=1; overflow_flag=0;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("BLT");

        // 4) BGE signed
        func3=3'b101; negative_flag=0; overflow_flag=0;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("BGE");

        // 5) BLTU (unsigned)
        func3=3'b110; carry_flag=1;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("BLTU");

        // 6) BGEU (unsigned)
        func3=3'b111; carry_flag=0;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("BGEU");

        // 7) JAL
        opcode=7'b1101111;
        expected_modify = 1; expected_pc = pc + immediate;
        #5 check("JAL");

        // 8) JALR
        opcode=7'b1100111; op1=32'h3003;
        expected_modify = 1; expected_pc = (op1 + immediate) & 32'hFFFF_FFFE;
        #5 check("JALR");

        // Final Summary
        $display("=====================================");
        $display(" TEST SUMMARY:");
        $display(" PASSED: %0d", pass_count);
        $display(" FAILED: %0d", fail_count);
        $display("=====================================");

        #100 $finish;
    end

endmodule
 
