/* module fetch_stage(
    input clk,
    input rst,
    input pc_en,
    input flush,
    input [31:0] pc_jump_addr,
    input jump_en,
    input [31:0] btb_target_pc,
    input btb_pc_valid,
    input btb_pc_predictTaken,
    output [31:0] instruction,
    output [31:0] pc
);
    
    wire [31:0] next_pc;

    // Instantiate the PC module
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_en(pc_en),
        .pc(pc)
    );

    // Instantiate the PC update module
    pc_update pc_update_inst (
        .pc(pc),
        .pc_jump_addr(pc_jump_addr),
        .btb_target_pc(btb_target_pc),
        .btb_pc_valid(btb_pc_valid),
        .btb_pc_predictTaken(btb_pc_predictTaken),
        .jump_en(jump_en),
        .next_pc(next_pc)
    );

    // Instantiate the instruction memory module
    inst_mem instruction_mem_inst (
        //.clk(clk),
       // .rst(rst),
        .pc(pc),
     //   .read_en(pc_en),
       // .write_en(1'b0),
       // .flush(flush),
          .write_addr(pc[11:2]),
       // .write_data(32'h00000000),
        .instruction(instruction)
    );

endmodule */

module fetch_stage(
    input clk,
    input rst,
    input pc_en,
    input flush,
    input [31:0] pc_jump_addr,
    input jump_en,
    input [31:0] btb_target_pc,
    input btb_pc_valid,
    input btb_pc_predictTaken,
    input  [31:0] next_pc,
    output [31:0] instruction,
    output [31:0] pc,
    output [31:0] corrected_pc

);
wire [31:0] corrected_pc;

assign corrected_pc = (jump_en) ? pc_jump_addr : next_pc;

pc pc_inst(
    .clk(clk),
    .rst(rst),
    .next_pc(corrected_pc),
    .pc_en(pc_en),
    .pc(pc)
);
   
    
    wire [31:0] next_pc;

   /* // Instantiate the PC module
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_en(pc_en),
        .pc(pc)
    );
*/
    // Instantiate the PC update module
    pc_update pc_update_inst (
        .pc(pc),
        .pc_jump_addr(pc_jump_addr),
        .btb_target_pc(btb_target_pc),
        .btb_pc_valid(btb_pc_valid),
        .btb_pc_predictTaken(btb_pc_predictTaken),
        .jump_en(jump_en),
        .next_pc(next_pc)
    );

    // ********* FIXED: pass correct index bits to instruction memory *********
    // instruction memories (each bank has 256 entries): use pc[9:2] (8 bits)
    inst_mem instruction_mem_inst (
        .pc(pc),
        .write_addr(pc[9:2]),
        .instruction(instruction)
    );

endmodule



