module mem_stage(
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

endmodule
