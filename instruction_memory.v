//==============================================================================
// Instruction Memory (IMEM)
//==============================================================================
// Description:
// Asynchronous read-only memory that stores the program instructions.
// Pre-loads code from "memfile.dat" at initialization.
//==============================================================================
`timescale 1ns / 1ps

module instruction_memory #(
    parameter WIDTH = 32,
    parameter DEPTH = 256
)(
    input  wire [31:0] addr,       // Byte address (PC)
    output wire [31:0] rd          // Instruction word
);
    reg [WIDTH-1:0] ram [0:DEPTH-1];
    
    initial begin
        $readmemh("memfile.dat", ram);  // Load machine code
    end
    
    // Memory is word-addressed; Byte address [31:2] drops the lowest 2 bits
    assign rd = ram[addr[31:2]]; 

endmodule