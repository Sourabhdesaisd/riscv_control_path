module  data_mem(
    input  wire        clk,
    input  wire        mem_read,        // 1 = load
    input  wire        mem_write,       // 1 = store

    input  wire [31:0] addr,            // byte address from ALU
    input  wire [31:0] write_data,      // store input data (rs2)
    input  wire [2:0]  load_type,       // 000=LB,001=LH,010=LW,011=LBU,100=LHU
    input  wire [1:0]  store_type,      // 00=SB, 01=SH, 10=SW

    output wire [31:0] read_data        // load output (rd)
);

    // -----------------------------------------------------
    // Local wires between datapaths and memory
    // -----------------------------------------------------
    wire [31:0] mem_write_data;
    wire [3:0]  byte_enable;
    wire [31:0] mem_read_data;

    // -----------------------------------------------------
    // STORE DATAPATH
    // -----------------------------------------------------
    store u_store (
        .store_type     (store_type),
        .write_data     (write_data),
        .addr           (addr),
        .mem_write_data (mem_write_data),
        .byte_enable    (byte_enable)
    );

    // -----------------------------------------------------
    // MEMORY BLOCK (1 KB = 1024 bytes = 256 words)
    // -----------------------------------------------------
    memory_1kb u_mem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (mem_write_data),
        .byte_enable(byte_enable),
        .read_data  (mem_read_data)
    );

    // -----------------------------------------------------
    // LOAD DATAPATH
    // -----------------------------------------------------
    load u_load (
        .load_type   (load_type),
        .mem_data_in (mem_read_data),
        .addr        (addr),
        .read_data   (read_data)
    );

endmodule

