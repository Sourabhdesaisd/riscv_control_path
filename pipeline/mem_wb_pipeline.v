module mem_wb_pipeline(
    input clk,
    input rst,
    input mem_mem_read,
    input mem_wb_reg_file,
    input [31:0] mem_read_data,
    input [31:0] mem_calculated_result,
    input [4:0] mem_wb_rd,

    output reg mem_read,
    output reg wb_reg_file,
    output [31:0] wb_read_data,
    output reg [31:0] wb_calculated_result,
    output reg [4:0] wb_rd
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_read <= 1'b0;
            wb_reg_file <= 1'b0;
            wb_calculated_result <= 32'h00000000;
            wb_rd <= 5'b00000;
        end else begin
            mem_read <= mem_mem_read;
            wb_reg_file <= mem_wb_reg_file;
            wb_calculated_result <= mem_calculated_result;
            wb_rd <= mem_wb_rd;
        end
    end

    assign wb_read_data = mem_read_data;

endmodule
