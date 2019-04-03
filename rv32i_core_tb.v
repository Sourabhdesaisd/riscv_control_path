module rv32i_core_tb;

    reg clk;
    reg rst;

    // Instantiate the core
    rv32i_core dut (
        .clk(clk),
        .rst(rst)
    );
    
    initial begin

        $shm_open("wave.shm") ;
        $shm_probe("ACTMF") ;

    end

    // Clock generation: 10ns period
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize reset
        rst = 1;
        #20;       // Hold reset for 20ns
        rst = 0;

        // Run simulation for 500ns then finish
        #500;
        $finish;
    end
endmodule
