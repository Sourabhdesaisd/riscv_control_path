module writeback_stage(
    input mem_read,
    input [31:0] mem_read_data,
    input [31:0] result_alu,

    output [31:0] wb_result
);
    assign wb_result = mem_read ? mem_read_data : result_alu;

endmodule
