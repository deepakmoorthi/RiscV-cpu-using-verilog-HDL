BASIC 2-STAGE RISC-V PROCESSOR (Verilog)

Files
-----
1. riscv_2stage.v       - Processor design
2. tb_riscv_2stage.v    - Simulation testbench

Architecture
------------
Stage 1: Instruction Fetch (IF)
  - Uses the program counter to fetch an instruction.
  - Increments PC by 4.
  - Stores the instruction in the IF/ID pipeline register.

Stage 2: Decode, Execute, Memory Access and Write Back
  - Decodes the instruction.
  - Reads the register file.
  - Performs the ALU operation.
  - Reads/writes data memory for LW/SW.
  - Writes results back to the register file.
  - Resolves BEQ and flushes the next fetched instruction when taken.

Supported instructions
----------------------
ADD, SUB, AND, OR, ADDI, LW, SW, BEQ

Important teaching limitations
------------------------------
- This is a small educational subset, not a complete RISC-V implementation.
- Instructions are 32-bit and use standard RV32I encodings for the supported subset.
- Instruction memory and data memory are separate.
- x0 is hardwired to zero.
- There is no data hazard detection or forwarding unit.
- Insert NOPs or otherwise separate dependent instructions when extending the
  example. The supplied test program uses independent/appropriately separated
  operations for this simple pipeline.
- Branches are resolved in Stage 2; a taken branch flushes the fetched instruction.

Run using Icarus Verilog
------------------------
iverilog -g2012 -o riscv_sim riscv_2stage.v tb_riscv_2stage.v
vvp riscv_sim

Expected result
---------------
The testbench should print TEST PASSED and show:
x1=5, x2=7, x3=12, x4=7, x5=12, x6=0, x7=11, MEM[0]=12.

For waveform output, add this to the testbench initial block:
  $dumpfile("riscv.vcd");
  $dumpvars(0, tb_riscv_2stage);
Then open riscv.vcd in GTKWave.
