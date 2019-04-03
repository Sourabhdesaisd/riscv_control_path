module ex_mem_pipeline(
    input clk,
    input rst,
    input ex_forward_pipeline_flush,
    input pipeline_en,
    

    input [31:0] ex_result,
    input [31:0] ex_op2_selected,
    input ex_memory_write,
    input [2:0] ex_memory_load_type,
    input [1:0] ex_memory_store_type,
    input ex_mem_read,
    input ex_wb_reg_file,
    input [4:0] ex_wb_rd,

    output reg [31:0] mem_result,
    output reg [31:0] mem_op2_selected,
    output reg mem_memory_write,
    output reg [2:0] mem_memory_load_type,
    output reg [1:0] mem_memory_store_type,
    output reg mem_mem_read,
    output reg mem_wb_reg_file,
    output reg [4:0] mem_wb_rd
);

    always @(posedge clk ) begin
        if (rst) begin
            mem_result <= 32'h00000000;
            mem_op2_selected <= 32'h00000000;
            mem_memory_write <= 1'b0;
            mem_memory_load_type <= 3'b111;
            mem_memory_store_type <= 2'b11;
            mem_mem_read <= 1'b0;
            mem_wb_reg_file <= 1'b0;
            mem_wb_rd <= 5'b00000;
        end else if (ex_forward_pipeline_flush) begin
            mem_result <= 32'h00000000;
            mem_op2_selected <= 32'h00000000;
            mem_memory_write <= 1'b0;
            mem_memory_load_type <= 3'b111;
            mem_memory_store_type <= 2'b11;
            mem_mem_read <= 1'b0;
            mem_wb_reg_file <= 1'b0;
            mem_wb_rd <= 5'b00000;            
        end 
        else if (pipeline_en) begin
            mem_result <= ex_result;
            mem_op2_selected <= ex_op2_selected;
            mem_memory_write <= ex_memory_write;
            mem_memory_load_type <= ex_memory_load_type;
            mem_memory_store_type <= ex_memory_store_type;
            mem_mem_read <= ex_mem_read;
            mem_wb_reg_file <= ex_wb_reg_file;
            mem_wb_rd <= ex_wb_rd;
            end
    end

endmodule
