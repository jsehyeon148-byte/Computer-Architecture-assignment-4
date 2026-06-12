//==============================================================================
// Data Memory with MMIO (Memory-Mapped I/O)
//==============================================================================
// Description:
// Standard RAM for data storage, plus memory-mapped registers for I/O.
// 
// Address Map:
// - 0x000 - 0x08F: Internal RAM (256 words, though only 0-63 used here)
// - 0x090        : Switches (Read-Only)
// - 0x098        : PWM Duty Cycle (Write-Only)
//==============================================================================
`timescale 1ns / 1ps

module data_memory (
    input  wire        clk,
    input  wire        rst_n,           // Added for PWM reset
    input  wire        mem_write_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    
    // External IO
    input  wire [7:0]  switches,    
    output wire [7:0]  leds_out,
    
    output reg  [31:0] read_data
);
    // 1. Internal RAM (Synchronous Write, Asynchronous Read)
    reg [31:0] ram [0:63]; // 64 words for simplicity (reduce simulation memory)
    wire [31:0] ram_out;
    assign ram_out = ram[addr[7:2]]; // Word-aligned address

    // 2. MMIO Registers
    reg [7:0] leds; // Address 0x94

    // Synchronous Writes
    always @(posedge clk) begin
        if (mem_write_en) begin
            case (addr)
                32'h00000094: leds <= write_data[7:0]; 
                default:      ram[addr[7:2]] <= write_data;
            endcase
            
            // Console Logging for Debug
            if (addr == 32'h00000094)
                $display("MMIO WRITE: LEDs Updated to %b (0x%h)", write_data[7:0], write_data[7:0]);
        end
    end

    // Asynchronous/Combinational Reads
    always @(*) begin
        case (addr)
            32'h00000090: read_data = {24'b0, switches};
            32'h00000094: read_data = {24'b0, leds};
            default:      read_data = ram_out;
        endcase
    end

    assign leds_out = leds;

    // Initialization
    initial begin
        leds = 8'h00;
    end

endmodule