//`include "../defines.vh"
`define STORE_SB  2'b00
`define STORE_SH  2'b01
`define STORE_SW  2'b10
`define STORE_DEF 2'b11

// Load Types
`define LOAD_LB  3'b000
`define LOAD_HD  3'b001
`define LOAD_LW  3'b010
`define LOAD_LBU 3'b011
`define LOAD_LHU 3'b100
`define LOAD_DEF 3'b111

`define OPCODE_RTYPE 7'b0110011
`define OPCODE_ITYPE 7'b0010011
`define OPCODE_ILOAD 7'b0000011
`define OPCODE_IJALR 7'b1100111
`define OPCODE_BTYPE 7'b1100011
`define OPCODE_STYPE 7'b0100011
`define OPCODE_JTYPE 7'b1101111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_UTYPE 7'b0110111

`define FUNC7_ADD 7'b0000000
`define FUNC7_SUB 7'b0100000

module decode_controller (
    input [6:0] opcode,
    input [2:0] func3,
    input [6:0] func7,
    output ex_alu_src,
    output mem_write,
    output reg [2:0] mem_load_type,
    output reg [1:0] mem_store_type,
    output wb_load,
    output wb_reg_file,
    output invalid_inst
);
    wire r_type_inst;
    wire i_type_inst;
    wire wb_inst;
    wire u_type_inst;
    wire b_type_inst;
    wire j_type_inst;
    wire aupic_inst;
    wire jalr_inst;

    assign wb_inst = (opcode == `OPCODE_RTYPE);
    assign r_type_inst = (wb_inst && (func7 == `FUNC7_ADD || func7 == `FUNC7_SUB));
    assign i_type_inst = (opcode == `OPCODE_ITYPE);
    assign mem_write = (opcode == `OPCODE_STYPE);
    assign wb_load = (opcode == `OPCODE_ILOAD);
    assign u_type_inst = (opcode == `OPCODE_UTYPE);
    assign b_type_inst = (opcode == `OPCODE_BTYPE);
    assign j_type_inst = (opcode == `OPCODE_JTYPE);
    assign aupic_inst = ( opcode == `OPCODE_AUIPC);
    assign jalr_inst = (opcode == `OPCODE_IJALR);

    assign ex_alu_src  = i_type_inst || wb_load || mem_write ||
                          u_type_inst ||aupic_inst || jalr_inst;

    assign wb_reg_file  = wb_inst || i_type_inst || wb_load ||
                          u_type_inst ||aupic_inst || jalr_inst || j_type_inst;
                         
    assign invalid_inst = !(r_type_inst || ex_alu_src ||
                            b_type_inst || j_type_inst);

    always @(*) begin
        mem_store_type = `STORE_DEF; // Disable writing
        if (mem_write) begin
            case (func3)
                3'b000: mem_store_type = `STORE_SB;
                3'b001: mem_store_type = `STORE_SH;
                3'b010: mem_store_type = `STORE_SW;
                default:mem_store_type = `STORE_DEF; // Disable writing
            endcase
        end
    end

    always @(*) begin
        mem_load_type = `LOAD_DEF; // Load full value
        if (wb_load) begin
            case (func3)
                3'b000: mem_load_type = `LOAD_LB;
                3'b001: mem_load_type = `LOAD_HD;
                3'b010: mem_load_type = `LOAD_LW;
                3'b100: mem_load_type = `LOAD_LBU;
                3'b101: mem_load_type = `LOAD_LHU;
                default:mem_load_type = `LOAD_DEF; // Load full value
            endcase
        end
    end

endmodule
