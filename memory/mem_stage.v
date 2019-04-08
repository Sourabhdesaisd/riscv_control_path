
`define LOAD_LB   3'b000
`define LOAD_LH   3'b001
`define LOAD_LW   3'b010
`define LOAD_LBU  3'b011
`define LOAD_LHU  3'b100

`define STORE_SB  2'b00
`define STORE_SH  2'b01
`define STORE_SW  2'b10




/*module mem_stage(
    input clk,
    input rst,
    input [31:0] result_alu,
    input [31:0] op2_data,
    input mem_write,
    input mem_read,
    input [1:0] store_type,
    input [2:0] load_type,
    output wire [31:0] read_data,
    output wire [31:0] calculated_result
);

    // Instantiate the Data Memory
    data_mem data_mem_inst (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .store_type(store_type),
        .load_type(load_type),
        .addr(result_alu),
        .write_data(op2_data),
        .read_data(read_data)
    );   

    assign calculated_result = result_alu;

endmodule*/



// ===================== mem_stage.v =====================

module mem_stage (
    input  wire        clk,
    input  wire        rst,

    // from EX/MEM pipeline
    input  wire [31:0] result_alu,        // address from EX
    input  wire [31:0] op2_data,          // store data (rs2 from EX/MEM)
    input  wire        mem_write,         // 1 = store
    input  wire        mem_read,          // 1 = load
    input  wire [1:0]  store_type,        // SB/SH/SW
    input  wire [2:0]  load_type,         // LB/LH/LW/LBU/LHU

    // to MEM/WB pipeline
    output wire [31:0] read_data,         // data loaded from memory
    output wire [31:0] calculated_result  // normally just ALU result
);

    // For ADDI / R-type etc we still need plain ALU result
    assign calculated_result = result_alu;

    // -------------- real data memory ----------------
    data_mem data_mem_inst (
        .clk        (clk),
        .mem_read   (mem_read),       // <-- from EX/MEM
        .mem_write  (mem_write),      // <-- from EX/MEM  (VERY IMPORTANT)
        .addr       (result_alu),
        .write_data (op2_data),
        .load_type  (load_type),
        .store_type (store_type),
        .read_data  (read_data)
    );

endmodule


/*
module mem_stage(
    input clk,
    input rst,

    input [31:0] result_alu,
    input [31:0] op2_data,
    
    input mem_write,
    input mem_read,
    input [1:0] store_type,
    input [2:0] load_type,

    output reg [31:0] read_data,
    output [31:0] calculated_result
);

    reg [31:0] mem [0:255];
    wire [31:0] addr = result_alu;

    wire [1:0] byte_offset = addr[1:0];


integer i;
initial begin
    for (i = 0; i < 256; i = i + 1)
        mem[i] = 32'h00000000;
end
    
    
    // STORE
    always @(posedge clk) begin
        if (mem_write) begin
            case(store_type)
                2'b00: begin // SB
                    case(byte_offset)
                        2'b00: mem[addr[31:2]][7:0]   <= op2_data[7:0];
                        2'b01: mem[addr[31:2]][15:8]  <= op2_data[7:0];
                        2'b10: mem[addr[31:2]][23:16] <= op2_data[7:0];
                        2'b11: mem[addr[31:2]][31:24] <= op2_data[7:0];
                    endcase
                end

                2'b01: begin // SH
                    case(addr[1])
                        1'b0: mem[addr[31:2]][15:0]  <= op2_data[15:0];
                        1'b1: mem[addr[31:2]][31:16] <= op2_data[15:0];
                    endcase
                end

                2'b10: mem[addr[31:2]] <= op2_data; // SW
            endcase
        end
    end

    // LOAD
    always @(*) begin

        if (mem_read) begin
            case(load_type)
                `LOAD_LB: begin
                    case(byte_offset)
                        2'b00: read_data = {{24{mem[addr[31:2]][7]}},  mem[addr[31:2]][7:0]};
                        2'b01: read_data = {{24{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:8]};
                        2'b10: read_data = {{24{mem[addr[31:2]][23]}}, mem[addr[31:2]][23:16]};
                        2'b11: read_data = {{24{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:24]};
                    endcase
                end

                `LOAD_LBU: begin
                    case(byte_offset)
                        2'b00: read_data = {24'b0, mem[addr[31:2]][7:0]};
                        2'b01: read_data = {24'b0, mem[addr[31:2]][15:8]};
                        2'b10: read_data = {24'b0, mem[addr[31:2]][23:16]};
                        2'b11: read_data = {24'b0, mem[addr[31:2]][31:24]};
                    endcase
                end

                `LOAD_LH: begin
                    case(addr[1])
                        1'b0: read_data = {{16{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:0]};
                        1'b1: read_data = {{16{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:16]};
                    endcase
                end

                `LOAD_LHU: begin
                    case(addr[1])
                        1'b0: read_data = {16'b0, mem[addr[31:2]][15:0]};
                        1'b1: read_data = {16'b0, mem[addr[31:2]][31:16]};
                    endcase
                end

                `LOAD_LW: read_data = mem[addr[31:2]];
                default:  read_data = 32'b0;
            endcase
        end else read_data = 32'b0;
    end

 assign calculated_result = result_alu;

    // -------------- real data memory ----------------
    data_mem data_mem_inst (
        .clk        (clk),
        .mem_read   (mem_read),       // <-- from EX/MEM
        .mem_write  (mem_write),      // <-- from EX/MEM  (VERY IMPORTANT)
        .addr       (result_alu),
        .write_data (op2_data),
        .load_type  (load_type),
        .store_type (store_type)
   //     .read_data  (read_data)
    );

endmodule */





/*module mem_stage (
    input clk,
    input mem_write,
    input mem_read,
    input [1:0] store_type,
    input [2:0] load_type,
    input [31:0] addr,
    input [31:0] write_data,
    output reg [31:0] read_data
);

    reg [7:0] mem [0:255];   // byte addressable memory

    // Extract bytes from the addressed location
    wire [7:0]  b0 = mem[addr];
    wire [7:0]  b1 = mem[addr + 1];
    wire [7:0]  b2 = mem[addr + 2];
    wire [7:0]  b3 = mem[addr + 3];

    // -------------------- STORE LOGIC --------------------
    always @(posedge clk) begin
        if (mem_write) begin
            case(store_type)

                2'b00: begin                             // SB
                    mem[addr] <= write_data[7:0];
                end

                2'b01: begin                             // SH
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                end

                2'b10: begin                             // SW
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end

            endcase
        end
    end

    // -------------------- LOAD LOGIC --------------------
    always @(*) begin
        if (mem_read) begin
            case(load_type)

                3'b000: read_data = {{24{b0[7]}}, b0};          // LB

                3'b011: read_data = {24'b0, b0};                // LBU

                3'b001: read_data = {{16{b1[7]}}, b1, b0};      // LH

                3'b101: read_data = {16'b0, b1, b0};            // LHU

                3'b010: read_data = {b3, b2, b1, b0};           // LW

                default: read_data = 32'h00000000;
            endcase
        end else begin
            read_data = 32'h00000000;
        end
    end
data_mem data_mem_inst (
        .clk        (clk),
        .mem_read   (mem_read),       // <-- from EX/MEM
        .mem_write  (mem_write),      // <-- from EX/MEM  (VERY IMPORTANT)
        .addr       (result_alu),
        .write_data (op2_data),
        .load_type  (load_type),
        .store_type (store_type)
   //     .read_data  (read_data)
    );

endmodule*/

