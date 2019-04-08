
module instruction_mem_B3 (
   input [7:0] write_addr,
   output [7:0] read_data
);

reg [7:0] mem [0:255];

initial begin
    $readmemh("instruction_mem_B3.hex", mem);
end

assign read_data = mem[write_addr];

endmodule


