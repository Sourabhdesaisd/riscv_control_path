module load (
    input  wire [2:0]   load_type,    // 000=LB, 001=LH, 010=LW, 011=LBU, 100=LHU
    input  wire [31:0]  mem_data_in,  // 32-bit data from memory
    input  wire [31:0]  addr,         // byte address from ALU
    output wire [31:0]  read_data     // final data to register file
);

    wire [31:0] MDR = mem_data_in;

    // -------------------------------
    // Byte selection (addr[1:0])
    // -------------------------------
    wire [7:0] selected_byte =
        (addr[1:0] == 2'b00) ? MDR[7:0]   :
        (addr[1:0] == 2'b01) ? MDR[15:8]  :
        (addr[1:0] == 2'b10) ? MDR[23:16] :
                               MDR[31:24];

    // -------------------------------
    // Halfword selection (addr[1])
    // -------------------------------
    wire [15:0] selected_half =
        (addr[1]) ? MDR[31:16] : MDR[15:0];

    // -------------------------------
    // Byte extension
    // -------------------------------
    wire [31:0] ext_byte =
        (load_type == 3'b000) ? {{24{selected_byte[7]}}, selected_byte} : // LB (sign extend)
        (load_type == 3'b011) ? {24'b0, selected_byte}                  : // LBU (zero extend)
                                32'b0;

    // -------------------------------
    // Halfword extension
    // -------------------------------
    wire [31:0] ext_half =
        (load_type == 3'b001) ? {{16{selected_half[15]}}, selected_half} : // LH (sign extend)
        (load_type == 3'b100) ? {16'b0, selected_half}                  : // LHU (zero extend)
                                32'b0;

    // -------------------------------
    // Final output based on load_type
    // -------------------------------
    assign read_data =
        (load_type == 3'b010) ? MDR :        // LW
        (load_type == 3'b000 || load_type == 3'b011) ? ext_byte :
        (load_type == 3'b001 || load_type == 3'b100) ? ext_half :
        32'b0;

endmodule

