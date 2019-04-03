

module instruction_mem_B3 (
    //input clk,
//    input write_en,
   input [7:0] write_addr,
 //   input [7:0] write_data,
     
    output [7:0] read_data
);

reg [7:0] mem [0:255];

initial begin
    $readmemh("instruction_mem_B3.hex", mem);
end

/*always @(posedge clk) begin
    if (write_en)
        mem[write_addr] <= write_data;

    read_data <= mem[write_addr];
end*/

 assign   read_data = mem[write_addr];
 

endmodule

