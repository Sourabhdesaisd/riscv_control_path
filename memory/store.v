module store (
    input  wire [1:0]   store_type,     // 00=SB, 01=SH, 10=SW
    input  wire [31:0]  write_data,     // data to be stored (renamed from rs2_data)
    input  wire [31:0]  addr,           // effective address from ALU
    output reg  [31:0]  mem_write_data, // data aligned for memory
    output reg  [3:0]   byte_enable     // active byte lanes
);

    always @(*) begin
        // Default values
        mem_write_data = 32'b0;
        byte_enable    = 4'b0000;

        case (store_type)
            // ---------------- SB ----------------
            2'b00: begin
                case (addr[1:0])
                    2'b00: begin mem_write_data = {24'b0, write_data[7:0]};  byte_enable = 4'b0001; end
                    2'b01: begin mem_write_data = {16'b0, write_data[7:0], 8'b0}; byte_enable = 4'b0010; end
                    2'b10: begin mem_write_data = {8'b0,  write_data[7:0], 16'b0}; byte_enable = 4'b0100; end
                    2'b11: begin mem_write_data = {write_data[7:0], 24'b0};      byte_enable = 4'b1000; end
                endcase
            end

            // ---------------- SH ----------------
            2'b01: begin
                case (addr[1])
                    1'b0: begin mem_write_data = {16'b0, write_data[15:0]}; byte_enable = 4'b0011; end
                    1'b1: begin mem_write_data = {write_data[15:0], 16'b0}; byte_enable = 4'b1100; end
                endcase
            end

            // ---------------- SW ----------------
            2'b10: begin
                mem_write_data = write_data;
                byte_enable    = 4'b1111;
            end

            default: begin
                // Safe default: no write
                mem_write_data = 32'b0;
                byte_enable    = 4'b0000;
            end
        endcase
    end

endmodule
 
