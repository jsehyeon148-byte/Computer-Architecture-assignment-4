//==============================================================================
// MIPS Processor Testbench (Class 11 - Basic MMIO)
//==============================================================================
// Description:
// Top-level testbench for verifying Memory-Mapped I/O.
// Monitors:
// - SWITCHES Input (0x90)
// - LED Output (0x94)
//==============================================================================
`timescale 1ns / 1ps

module mips_tb;
    reg         clk;
    reg         rst_n;
    
    // IO Ports
    reg  [7:0]  switches;
    wire [7:0]  leds;
    
    // Debug Monitoring
    wire [31:0] pc_out;
    wire [31:0] alu_result;
    
    // Unit Under Test (UUT)
    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .leds(leds),
        .pc_out(pc_out),
        .alu_result(alu_result)
    );
    
    // Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Trace Generation
    initial begin
        $dumpfile("mips.vcd");
        $dumpvars(0, mips_tb);
    end
    
    // Simulation Control
    initial begin
        // Reset Logic
        rst_n = 0;
        switches = 8'h00;
        #15;
        rst_n = 1;
        
        $display("===========================================");
        $display("   MIPS Class 11: Basic MMIO Simulation    ");
        $display("===========================================");
        
        // Stimulus 1: Switches = 0xAA (10101010)
        #100;
        switches = 8'h00; 
        $display("TEST: Switch Input Set to 0xAA");
        
        // Wait for program to loop and update LEDs
        #1000;
        
        // Stimulus 2: Switches = 0x55 (01010101)
        switches = 8'h00;
        $display("TEST: Switch Input Set to 0x55");
        
        #1000;
        
        $display("===========================================");
        $display("   Simulation Complete                   ");
        $display("===========================================");
        $finish;
    end

endmodule