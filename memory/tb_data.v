
module tb_data_mem;
    reg clk;
    reg rst;
    reg mem_write;
    reg [1:0] store_type;
    reg [2:0] load_type;
    reg [11:0] addr;
    reg [31:0] write_data;
    wire [31:0] read_data;

    // instantiate the DUT
    data_mem dut (
        .clk(clk),
        .rst(rst),
        .mem_write(mem_write),
        .store_type(store_type),
        .load_type(load_type),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period
    initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
    end



    // helper tasks
    task write_word(input [11:0] a, input [31:0] data);
    begin
        @(negedge clk);
        mem_write   <= 1;
        store_type  <= 2'b10; // SW
        addr        <= a;
        write_data  <= data;
        @(negedge clk);
        mem_write <= 0;
    end
    endtask

    task write_half(input [11:0] a, input [15:0] data);
    begin
        @(negedge clk);
        mem_write   <= 1;
        store_type  <= 2'b01; // SH
        addr        <= a;
        write_data  <= {16'h0000, data};   // FIXED (must be in [15:0])
        @(negedge clk);
        mem_write <= 0;
    end
    endtask

    task write_byte(input [11:0] a, input [7:0] data);
    begin
        @(negedge clk);
        mem_write   <= 1;
        store_type  <= 2'b00; // SB
        addr        <= a;
        write_data  <= {24'h0, data};
        @(negedge clk);
        mem_write <= 0;
    end
    endtask

    task read_and_check(
        input [11:0] a,
        input [2:0] ltype,
        input [31:0] expected,
        input [80*1:1] msg
    );
    begin
        @(negedge clk);
        load_type <= ltype;
        addr      <= a;
        @(posedge clk);
        #1;
        if (read_data !== expected)
            $display("FAIL: %s addr=0x%0h got=0x%08h expected=0x%08h",
                      msg, a, read_data, expected);
        else
            $display("PASS: %s addr=0x%0h got=0x%08h",
                      msg, a, read_data);
    end
    endtask

    initial begin
        rst = 1;
        mem_write = 0;
        store_type = 0;
        load_type = 0;
        addr = 0;
        write_data = 0;
        #20;
        rst = 0;
        #10;

        write_word(12'h000, 32'h11223344);
        read_and_check(12'h000, 3'b010, 32'h11223344, "LW read");

        write_word(12'h001, 32'hDEADBEEF);
        write_byte(12'h001, 8'hAA);
        read_and_check(12'h001, 3'b000, 32'hFFFFFFAA, "LB signed");
        read_and_check(12'h001, 3'b011, 32'h000000AA, "LBU unsigned");

        write_word(12'h003, 32'h0);
        write_half(12'h003, 16'h1234);
        read_and_check(12'h003, 3'b001, 32'h00001234, "LH lower");
        read_and_check(12'h003, 3'b100, 32'h00001234, "LHU lower");

        write_word(12'h004, 32'h0);

        @(negedge clk);
        mem_write  <= 1;
        store_type <= 2'b01;  // SH
        addr       <= 12'h004 + 2;   // byte_offset = 2 ? upper half
        write_data <= {16'h0000, 16'hABCD};  // FIXED
        @(negedge clk);
        mem_write <= 0;

        read_and_check(12'h004 + 2, 3'b001, 32'hFFFFABCD, "LH upper signed");
        read_and_check(12'h004 + 2, 3'b100, 32'h0000ABCD, "LHU upper zero");

        write_word(12'h010, 32'hAABBCCDD);
        write_byte(12'h010 + 1, 8'h77);
        read_and_check(12'h010, 3'b010, 32'hAA77CCDD, "Byte update");

        $display("ALL tests in tb_data_mem_fixed completed.");
        #20;
        $finish;
    end

endmodule


