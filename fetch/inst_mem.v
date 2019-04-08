module inst_mem (
    input [31:0] pc,
    input [7:0] write_addr,
    output  [31:0] instruction
);

wire [7:0] mem_B0_out;
wire [7:0] mem_B1_out;
wire [7:0] mem_B2_out;
wire [7:0] mem_B3_out;

// Byte memories (256 entries each)
instruction_mem_B0 mem0 (
    .write_addr(write_addr),
    .read_data(mem_B0_out)
);

instruction_mem_B1 mem1 (
    .write_addr(write_addr),
    .read_data(mem_B1_out)
);

instruction_mem_B2 mem2 (
    .write_addr(write_addr),
    .read_data(mem_B2_out)
);

instruction_mem_B3 mem3 (
    .write_addr(write_addr),
    .read_data(mem_B3_out)
);

// Registered output stage was removed in original (combinational output OK for IF stage)
assign instruction = {mem_B3_out, mem_B2_out, mem_B1_out, mem_B0_out};

endmodule











/*module inst_mem (
  //  input clk,
   // input rst,
    input [31:0] pc,
 //   input read_en,
 //   input write_en,
//    input flush,
    input [7:0] write_addr,
//    input [31:0] write_data,
    output  [31:0] instruction
);

wire [7:0] mem_B0_out;
wire [7:0] mem_B1_out;
wire [7:0] mem_B2_out;
wire [7:0] mem_B3_out;

// Byte write enable into split memories when write_en = 1
instruction_mem_B0 mem0 (
   // .clk(clk),
   // .write_en(write_en),
    .write_addr(write_addr),
   // .write_data(write_data[7:0]),
    .read_data(mem_B0_out)
);

instruction_mem_B1 mem1 (
   // .clk(clk),
  //  .write_en(write_en),
    .write_addr(write_addr),
 //   .write_data(write_data[15:8]),
    .read_data(mem_B1_out)
);

instruction_mem_B2 mem2 (
   // .clk(clk),
   // .write_en(write_en),
    .write_addr(write_addr),
   // .write_data(write_data[23:16]),
    .read_data(mem_B2_out)
);

instruction_mem_B3 mem3 (
  //  .clk(clk),
   // .write_en(write_en),
    .write_addr(write_addr),
   // .write_data(write_data[31:24]),
    .read_data(mem_B3_out)
);

// Registered output stage (pipeline-safe)
// always @(posedge clk) begin
    if (rst)
        instruction = 32'h00000000;
    else if (flush)
        instruction = 32'h00000000;
    else if (read_en)
      instruction = {mem_B3_out, mem_B2_out, mem_B1_out, mem_B0_out};
end 
  assign   instruction = {mem_B3_out, mem_B2_out, mem_B1_out, mem_B0_out};


endmodule */







/*

module inst_mem(
   // input clk,
   // input rst,
    input [31:0] pc,
    input read_en,
 //   input write_en,
  //  input flush,
//    input [7:0] write_addr,
 //   input [31:0] write_data,
    output  [31:0] instruction
);
   // reg [31:0] instruction;

    // Memory array to hold instructions
    reg [31:0] mem [0:255]; // 1KB memory

    // Initialize memory using file
    initial begin
        $readmemh("instructions.hex", mem);
    end

    // Add this for synthesis to block RAM
    always @(posedge clk) begin
        if (write_en) 
            mem[write_addr] <= write_data;
    end


    always @(posedge clk) begin
        if (rst) begin
            instruction <= 32'h00000000; // Reset instruction to NOP
        end else if (flush) begin
            instruction <= 32'h00000000; // Flush instruction to NOP
        end else if (read_en) begin
            instruction <= mem[pc[11:2]]; // Fetch instruction based on PC
        end
    end 
    assign instruction = mem[pc[11:2]]; 
endmodule  */












