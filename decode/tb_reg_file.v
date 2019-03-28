// tb_register_file.v
module tb_register_file;
    reg clk;
    reg wr_en;
    reg [4:0] wr_addr;
    reg [31:0] wr_data;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;

    wire [31:0] op1;
    wire [31:0] op2;

    integer pass_count, fail_count;
    integer fh;

    // instance
    register_file uut (
        .clk(clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .op1(op1),
        .op2(op2)
    );

    initial clk = 0; always #5 clk = ~clk;
    initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end

    initial begin
        // create reg file hex
        fh = $fopen("reg_hex_file.hex","w");
         $fdisplay(fh, "00000000"); // x0
        $fdisplay(fh, "00000001"); // x1
        $fdisplay(fh, "00000002"); // x2
        $fdisplay(fh, "00000003"); // x3
        $fdisplay(fh, "00000004"); // x4
        $fdisplay(fh, "00000005"); // x5
        $fdisplay(fh, "00000006"); // x6
        $fdisplay(fh, "00000007"); // x7
        $fdisplay(fh, "00000008"); // x8
        $fdisplay(fh, "00000009"); // x9
        $fdisplay(fh, "0000000A"); // x10
        $fdisplay(fh, "0000000B"); // x11
        $fdisplay(fh, "0000000C"); // x12
        $fdisplay(fh, "0000000D"); // x13
        $fdisplay(fh, "0000000E"); // x14
        $fdisplay(fh, "0000000F"); // x15
        $fdisplay(fh, "00000010"); // x16
        $fdisplay(fh, "00000011"); // x17
        $fdisplay(fh, "00000012"); // x18
        $fdisplay(fh, "00000013"); // x19
        $fdisplay(fh, "00000014"); // x20
        $fdisplay(fh, "00000015"); // x21
        $fdisplay(fh, "00000016"); // x22
        $fdisplay(fh, "00000017"); // x23
        $fdisplay(fh, "00000018"); // x24
        $fdisplay(fh, "00000019"); // x25
        $fdisplay(fh, "0000001A"); // x26
        $fdisplay(fh, "0000001B"); // x27
        $fdisplay(fh, "0000001C"); // x28
        $fdisplay(fh, "0000001D"); // x29
        $fdisplay(fh, "0000001E"); // x30
        $fdisplay(fh, "0000001F"); // x31
        $fclose(fh);

        pass_count = 0; fail_count = 0;
                // wait for init
        #10;

        // check initial values readback (x1 = 1)
        rs1_addr = 5'd1; rs2_addr = 5'd2; wr_en = 0; #1;
        if (op1 === 32'h1 && op2 === 32'h2) begin
            $display("[PASS] initial reg file values");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] initial reg file values, op1=%h op2=%h", op1, op2);
            fail_count = fail_count + 1;
        end

        // Test write on posedge (write x5 = 0xDEAD)
        wr_en = 1; wr_addr = 5'd5; wr_data = 32'hDEAD_BEEF;
        #10; // allow posedge and write
        wr_en = 0;
        rs1_addr = 5'd5; #1;
        if (op1 === 32'hDEAD_BEEF) begin
            $display("[PASS] write then read back");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] write then read back op1=%h", op1);
            fail_count = fail_count + 1;
        end

        // Test forwarding: assert wr_en and read same reg in same cycle
        // set rs1 == wr_addr and wr_en=1 before posedge; the module forwards combinationally
        wr_en = 1; wr_addr = 5'd6; wr_data = 32'hCAFEBABE;
        rs1_addr = 5'd6; rs2_addr = 5'd0;
        #1; // small time to allow combinational assignment in model
        if (op1 === 32'hCAFEBABE) begin
            $display("[PASS] same-cycle forwarding");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] same-cycle forwarding op1=%h", op1);
            fail_count = fail_count + 1;
        end
        #10; wr_en = 0;

        // final summary
        #5;
        $display("=== register_file TB SUMMARY ===");
        $display(" PASSED = %0d", pass_count);
        $display(" FAILED = %0d", fail_count);
        if (fail_count == 0) $display(" RESULT: PASS");
        else $display(" RESULT: FAIL");
        $display("===============================");
       #100  $finish;
    end
endmodule

