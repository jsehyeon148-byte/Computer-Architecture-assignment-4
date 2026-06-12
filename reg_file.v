//==============================================================================
// Register File
//==============================================================================
// Description:
// A set of 32 general-purpose 32-bit registers.
// Register $0 is hardwired to zero.
// Includes dual read ports and a single synchronous write port.
//==============================================================================
`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        we3,        // Write Enable
    input  wire [4:0]  wa3,        // Write Address
    input  wire [31:0] wd3,        // Write Data
    input  wire [4:0]  ra1,        // Read Address 1
    input  wire [4:0]  ra2,        // Read Address 2
    output wire [31:0] rd1,        // Read Data 1
    output wire [31:0] rd2         // Read Data 2
);
    reg [31:0] rf [31:0];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            rf[i] = 32'b0;
    end

    // Synchronous Write
    always @(posedge clk) begin
        if (we3 && (wa3 != 5'd0))
            rf[wa3] <= wd3;
    end
    
    // Constant/Default behavior for $0
    assign rd1 = (ra1 == 5'd0) ? 32'd0 : rf[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : rf[ra2];

endmodule