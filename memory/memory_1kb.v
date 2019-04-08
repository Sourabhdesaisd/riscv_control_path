/*module memory_1kb (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,

    input  wire [31:0] addr,          // byte address
    input  wire [31:0] write_data,
    input  wire [3:0]  byte_enable,
    output reg  [31:0] read_data
);

    reg [31:0] mem [0:255];           // 256 words = 1 KB

    wire [7:0] word_addr = addr[9:2]; // 4-byte aligned address

        integer i;
        
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000;
    end

    // -----------------------------------------------------
    // WRITE operation (byte enabled)
    // -----------------------------------------------------
    always @(posedge clk) begin
        if (mem_write) begin
            if (byte_enable[0]) mem[word_addr][7:0]   <= write_data[7:0];
            if (byte_enable[1]) mem[word_addr][15:8]  <= write_data[15:8];
            if (byte_enable[2]) mem[word_addr][23:16] <= write_data[23:16];
            if (byte_enable[3]) mem[word_addr][31:24] <= write_data[31:24];
        end
    end

    // -----------------------------------------------------
    // READ operation (combinational)
    // -----------------------------------------------------
    always @(*) begin
        read_data = mem_read ? mem[word_addr] : 32'b0;
    end

endmodule
 */
module memory_1kb (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,

    input  wire [31:0] addr,          // byte address
    input  wire [31:0] write_data,
    input  wire [3:0]  byte_enable,
    output reg  [31:0] read_data
);

    // 1024 bytes = 1 KB
    reg [7:0] mem [0:1023];

    integer i;

    // WRITE (byte-level)
    always @(posedge clk) begin
        if (mem_write) begin
            if (byte_enable[0]) mem[addr]     <= write_data[7:0];
            if (byte_enable[1]) mem[addr + 1] <= write_data[15:8];
            if (byte_enable[2]) mem[addr + 2] <= write_data[23:16];
            if (byte_enable[3]) mem[addr + 3] <= write_data[31:24];
        end
    end

    // READ (combinational)
    always @(*) begin
        if (mem_read) begin
            read_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
        end else begin
            read_data = 32'b0;
        end
    end

endmodule

