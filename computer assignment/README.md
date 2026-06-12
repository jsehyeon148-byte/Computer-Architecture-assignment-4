# Class 11: Memory-Mapped I/O

> **Week 11 | Hanyang University ERICA Campus | Department of Robotics**  
> **Computer Architecture Course**

---

## 📚 Learning Objectives

After completing this class, you will be able to:

1. **Understand the MMIO concept**: Access external devices using memory addresses
2. **Implement input device reading**: Read switch states
3. **Implement output device control**: Control LED display
4. **Design address decoding logic**: Distinguish between normal memory and I/O devices

---

## 🧠 Key Concepts

### What is Memory-Mapped I/O?

In MMIO architecture, peripherals (switches, LEDs, sensors) are mapped to specific memory addresses. The CPU can interact with hardware using regular `lw` and `sw` instructions:

```
           ┌────────────────────────────────────────┐
           │            Address Space               │
           │   ┌──────────────────────┐             │
  0x0000   │   │    Data Memory       │  Normal RAM │
           │   │    (256 words)       │             │
  0x03FC   │   └──────────────────────┘             │
           │              ...                       │
  0x0090   │   ┌──────────────────────┐             │
           │   │  Switches (read-only)│  I/O        │
  0x0094   │   ├──────────────────────┤             │
           │   │  LEDs (write-only)   │  I/O        │
           │   └──────────────────────┘             │
           └────────────────────────────────────────┘
```

### MMIO vs Port I/O

| Feature | MMIO | Port I/O |
|---------|------|----------|
| Access Method | `lw`, `sw` | Special instructions (IN, OUT) |
| Address Space | Shared memory address | Separate I/O address |
| CPU Complexity | Simple | Requires extra instructions |
| Representative Architecture | MIPS, ARM | x86 |

---

## 📊 Address Mapping Table

| Address | Device | Type | Description |
|---------|--------|------|-------------|
| 0x0000 - 0x03FC | Data Memory | R/W | 256 words normal memory |
| 0x0090 | Switches | **Read-only** | 8-bit switch input |
| 0x0094 | LEDs | **Write-only** | 8-bit LED output |

### Software Access Example

```assembly
# Read switch state
lw   $t0, 0x90($zero)     # $t0 = current value of switches

# Turn on LEDs
addi $t1, $zero, 0xFF     # All on
sw   $t1, 0x94($zero)     # Write to LED register
```

---

## 💻 Code Walkthrough

### `data_memory.v` - Data Memory with MMIO

```verilog
module data_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mem_write_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    
    // I/O Ports
    input  wire [7:0]  switches,    // External input signal
    output reg  [7:0]  leds,        // External output register
    
    output reg  [31:0] read_data
);
    // Normal data memory (256 × 32-bit)
    reg [31:0] RAM [255:0];

    // MMIO address constants
    localparam ADDR_SWITCHES = 32'h0090;
    localparam ADDR_LEDS     = 32'h0094;

    // Read logic (combinational)
    always @(*) begin
        case (addr)
            ADDR_SWITCHES: read_data = {24'b0, switches};  // Read-only
            ADDR_LEDS:     read_data = {24'b0, leds};      // Read back
            default:       read_data = RAM[addr[9:2]];     // Normal memory
        endcase
    end

    // Write logic (sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            leds <= 8'b0;
        end else if (mem_write_en) begin
            case (addr)
                ADDR_LEDS: leds <= write_data[7:0];       // Write to LED
                default:   RAM[addr[9:2]] <= write_data;  // Normal memory
            endcase
        end
    end
endmodule
```

### Top Module I/O Ports

```verilog
module mips (
    input  wire        clk,
    input  wire        rst_n,
    
    // I/O Ports (Memory-Mapped)
    input  wire [7:0]  switches,    // Address 0x90
    output wire [7:0]  leds,        // Address 0x94
    
    // Debug Outputs
    output wire [31:0] pc_out,
    output wire [31:0] alu_result
);
```

---

## 🎯 Design Highlights

### 1. Address Decoding

The key is the `case (addr)` block, which implements address decoding:
- Special addresses → I/O operations
- Other addresses → Normal memory access

### 2. Read-only vs Write-only

- **Switches**: Only read via `lw`, `sw` operation has no effect
- **LEDs**: Only write via `sw`, `lw` can read back current state

### 3. Synchronous vs Asynchronous

- **Read**: Combinational logic (immediately available)
- **Write**: Sequential logic (clock edge triggered)

---

## 🧪 Lab Exercise

### Step 1: Test program (`memfile.dat`)

```
# Infinite loop of switch-controlled LED
8C080090   // 0x00: lw   $t0, 0x90($zero)  → Read switches
AC080094   // 0x04: sw   $t0, 0x94($zero)  → Write to LED
08000000   // 0x08: j    0x00              → Infinite loop
00000000   // 0x0C: nop
```

### Step 2: Testbench Stimulus

```verilog
initial begin
    rst_n = 0;
    switches = 8'h00;
    #10;
    rst_n = 1;
    
    // Test different switch values
    #100 switches = 8'hAA;  // 0b10101010
    #100 switches = 8'h55;  // 0b01010101
    #100 switches = 8'hFF;  // All on
    
    #100 $finish;
end

// Monitor LED output
always @(leds) begin
    $display("Time=%0t: LEDs = %b", $time, leds);
end
```

### Step 3: Run simulation
```bash
cd class_11
make
```

### Step 4: Observe waveform
- Verify `switches` signal correctly comes from Testbench
- Verify `leds` output follows `switches` changes
- Observe how CPU continuously reads and writes in the loop

---

## 📊 Timing Analysis

```
                  Testbench Setting                CPU Execution
                        ↓                          ↓
         ┌─────────────────────────────────────────────────────┐
    0ns  │ switches = 0x00                                     │
   10ns  │ rst_n = 1          ← CPU starts running             │
   ...   │                      lw → sw → j → lw → sw → j ... │
  100ns  │ switches = 0xAA    ← Next lw reads new value        │
  110ns  │                      sw writes LED = 0xAA           │
         └─────────────────────────────────────────────────────┘
```

**Key point**: The CPU reads **the instantaneous value** of `switches` when executing `lw`. Subsequent changes will be read in the next `lw`.

---

## 🔍 Think Deeper

### Question 1: Polling vs Interrupts

Our program uses "polling" to constantly check switch state. What are the advantages of using interrupts?

### Question 2: Debouncing

Real physical switches produce "bounce". How to solve this in hardware or software?

### Question 3: Adding More Peripherals

If you want to add a 7-segment display (address 0x98), how would you modify the code?

---

## 🏆 Application Preview

The MMIO mechanism implemented in this class is the foundation for controlling any peripheral. In the next class, we will use the same mechanism to control a **PWM controller** and drive a motor!

```
        Class 11              Class 12
   ┌─────────────────┐   ┌─────────────────┐
   │   Switches      │   │   PWM Duty      │
   │   LEDs          │   │   Motor Speed   │
   │  (Basic I/O)    │   │(Advanced App)   │
   └─────────────────┘   └─────────────────┘
```

---

## ✅ Checkpoint

Before moving to the next class, make sure you can answer:

- [ ] What is the main difference between MMIO and Port I/O?
- [ ] How to read the value at address 0x90 using MIPS assembly?
- [ ] Why is I/O write sequential logic while read is combinational?

---

**Previous**: [Class 10 - Jump Instructions](../class_10/README.md)  
**Next**: [Class 12 - PWM Motor Control](../class_12/README.md)
