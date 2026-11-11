Washing Machine FSM - Verilog RTL and Testbench
================================================

Files
-----
washing_machine.v      Synthesizable Moore FSM controller RTL
washing_machine_tb.v   Simulation testbench

FSM sequence
------------
IDLE -> FILL -> WASH -> DRAIN -> RINSE -> SPIN -> DONE

The controller advances when the corresponding input handshake is asserted:
- start       : IDLE/DONE to FILL
- water_full  : FILL to WASH
- wash_done   : WASH to DRAIN
- drain_done  : DRAIN to RINSE
- rinse_done  : RINSE to SPIN
- spin_done   : SPIN to DONE

ModelSim / QuestaSim commands
-----------------------------
vlib work
vlog washing_machine.v
vlog washing_machine_tb.v
vsim work.washing_machine_tb
add wave -position insertpoint sim:/washing_machine_tb/*
run -all

Expected final message
----------------------
TEST PASSED: Washing cycle completed!

Notes
-----
This is an educational RTL example. The cycle-stage completion inputs are
provided externally to keep the FSM example focused. A practical design
would add sensor conditioning, timeouts, door interlocks, fault handling,
and appropriate motor/pump safety logic.
