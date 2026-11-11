`timescale 1ns/1ps

// Beginner-friendly 32-bit RISC-V subset, 5 pipeline stages:
//   IF -> ID -> EX -> MEM -> WB
// Supported: ADD, SUB, AND, OR, ADDI, LW, SW, BEQ
// Separate instruction and data memories.
// Includes simple forwarding + load-use hazard stall.

module riscv_5stage (
    input wire clk,
    input wire reset
);

    // ------------------------------------------------------------------
    // Architectural state
    // ------------------------------------------------------------------
    reg [31:0] pc;
    reg [31:0] instruction_mem [0:63];
    reg [31:0] data_mem        [0:63];
    reg [31:0] registers       [0:31];

    // ==================================================================
    // IF/ID pipeline register
    // ==================================================================
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;

    // ==================================================================
    // ID/EX pipeline register
    // ==================================================================
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_val;
    reg [31:0] id_ex_rs2_val;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;
    reg [2:0]  id_ex_funct3;
    reg [6:0]  id_ex_funct7;
    reg [6:0]  id_ex_opcode;
    // control signals
    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_alu_src;   // 0 = rs2, 1 = imm
    reg        id_ex_branch;
    reg [1:0]  id_ex_alu_op;    // 00=ADD, 01=SUB, 10=AND, 11=OR

    // ==================================================================
    // EX/MEM pipeline register
    // ==================================================================
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_rs2_val;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_branch_taken;
    reg [31:0] ex_mem_branch_target;

    // ==================================================================
    // MEM/WB pipeline register
    // ==================================================================
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_data;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg; // 0 = ALU, 1 = memory

    // ==================================================================
    // IF stage
    // ==================================================================
    wire [31:0] if_instr = instruction_mem[pc[7:2]];

    // ==================================================================
    // ID stage
    // ==================================================================
    wire [6:0] id_opcode = if_id_instr[6:0];
    wire [4:0] id_rd     = if_id_instr[11:7];
    wire [2:0] id_funct3 = if_id_instr[14:12];
    wire [4:0] id_rs1    = if_id_instr[19:15];
    wire [4:0] id_rs2    = if_id_instr[24:20];
    wire [6:0] id_funct7 = if_id_instr[31:25];

    wire [31:0] id_rs1_val = (id_rs1 == 0) ? 32'd0 : registers[id_rs1];
    wire [31:0] id_rs2_val = (id_rs2 == 0) ? 32'd0 : registers[id_rs2];

    wire [31:0] id_imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    wire [31:0] id_imm_s = {{20{if_id_instr[31]}},
                             if_id_instr[31:25], if_id_instr[11:7]};
    wire [31:0] id_imm_b = {{19{if_id_instr[31]}}, if_id_instr[31],
                             if_id_instr[7], if_id_instr[30:25],
                             if_id_instr[11:8], 1'b0};

    reg [31:0] id_imm;
    reg        id_reg_write;
    reg        id_mem_read;
    reg        id_mem_write;
    reg        id_alu_src;
    reg        id_branch;
    reg [1:0]  id_alu_op;

    always @(*) begin
        id_imm       = 32'd0;
        id_reg_write = 1'b0;
        id_mem_read  = 1'b0;
        id_mem_write = 1'b0;
        id_alu_src   = 1'b0;
        id_branch    = 1'b0;
        id_alu_op    = 2'b00;

        case (id_opcode)
            7'b0110011: begin // R-type
                id_reg_write = 1'b1;
                id_alu_src   = 1'b0;
                case (id_funct3)
                    3'b000: id_alu_op = (id_funct7 == 7'b0100000) ? 2'b01 : 2'b00;
                    3'b111: id_alu_op = 2'b10;
                    3'b110: id_alu_op = 2'b11;
                    default: id_reg_write = 1'b0;
                endcase
            end
            7'b0010011: begin // ADDI
                if (id_funct3 == 3'b000) begin
                    id_reg_write = 1'b1;
                    id_alu_src   = 1'b1;
                    id_alu_op    = 2'b00;
                    id_imm       = id_imm_i;
                end
            end
            7'b0000011: begin // LW
                if (id_funct3 == 3'b010) begin
                    id_reg_write = 1'b1;
                    id_mem_read  = 1'b1;
                    id_alu_src   = 1'b1;
                    id_alu_op    = 2'b00;
                    id_imm       = id_imm_i;
                end
            end
            7'b0100011: begin // SW
                if (id_funct3 == 3'b010) begin
                    id_mem_write = 1'b1;
                    id_alu_src   = 1'b1;
                    id_alu_op    = 2'b00;
                    id_imm       = id_imm_s;
                end
            end
            7'b1100011: begin // BEQ
                if (id_funct3 == 3'b000) begin
                    id_branch  = 1'b1;
                    id_alu_op  = 2'b01; // SUB for comparison
                    id_imm     = id_imm_b;
                end
            end
            default: ;
        endcase
    end

    // ==================================================================
    // EX stage
    // ==================================================================
    // Forwarding muxes
    reg [31:0] ex_fwd_a;
    reg [31:0] ex_fwd_b;

    // If the EX/MEM stage is writing a register that EX needs, forward.
    // Priority: EX/MEM (more recent) over MEM/WB.
    always @(*) begin
        ex_fwd_a = id_ex_rs1_val;
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
            ex_fwd_a = ex_mem_alu_result;
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1))
            ex_fwd_a = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

        ex_fwd_b = id_ex_rs2_val;
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))
            ex_fwd_b = ex_mem_alu_result;
        else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2))
            ex_fwd_b = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;
    end

    wire [31:0] ex_alu_in_b = id_ex_alu_src ? id_ex_imm : ex_fwd_b;

    reg [31:0] ex_alu_result;
    always @(*) begin
        case (id_ex_alu_op)
            2'b00: ex_alu_result = ex_fwd_a + ex_alu_in_b;   // ADD
            2'b01: ex_alu_result = ex_fwd_a - ex_alu_in_b;   // SUB
            2'b10: ex_alu_result = ex_fwd_a & ex_alu_in_b;   // AND
            2'b11: ex_alu_result = ex_fwd_a | ex_alu_in_b;   // OR
        endcase
    end

    wire ex_branch_taken  = id_ex_branch && (ex_alu_result == 32'd0);
    wire [31:0] ex_branch_target = id_ex_pc + id_ex_imm;

    // ==================================================================
    // Hazard detection: only a load-use hazard requires a stall.
    // (If EX is a LW and ID wants that same register.)
    // ==================================================================
    wire load_use_hazard =
        id_ex_mem_read &&
        ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2)) &&
        (id_ex_rd != 0);

    // ==================================================================
    // Sequential pipeline logic
    // ==================================================================
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc               <= 32'd0;
            if_id_pc         <= 32'd0;
            if_id_instr      <= 32'h00000013; // NOP
            id_ex_pc         <= 32'd0;
            id_ex_rs1_val    <= 32'd0;
            id_ex_rs2_val    <= 32'd0;
            id_ex_imm        <= 32'd0;
            id_ex_rs1        <= 5'd0;
            id_ex_rs2        <= 5'd0;
            id_ex_rd         <= 5'd0;
            id_ex_funct3     <= 3'd0;
            id_ex_funct7     <= 7'd0;
            id_ex_opcode     <= 7'd0;
            id_ex_reg_write  <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_alu_src    <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_alu_op     <= 2'b00;
            ex_mem_alu_result    <= 32'd0;
            ex_mem_rs2_val       <= 32'd0;
            ex_mem_rd            <= 5'd0;
            ex_mem_reg_write     <= 1'b0;
            ex_mem_mem_read      <= 1'b0;
            ex_mem_mem_write     <= 1'b0;
            ex_mem_branch_taken  <= 1'b0;
            ex_mem_branch_target <= 32'd0;
            mem_wb_alu_result    <= 32'd0;
            mem_wb_mem_data      <= 32'd0;
            mem_wb_rd            <= 5'd0;
            mem_wb_reg_write     <= 1'b0;
            mem_wb_mem_to_reg    <= 1'b0;
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else begin
            // ----------------------------------------------------------
            // WB stage (combinational writeback, clocked here)
            // ----------------------------------------------------------
            if (mem_wb_reg_write && mem_wb_rd != 0)
                registers[mem_wb_rd] <=
                    mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;
            registers[0] <= 32'd0;

            // ----------------------------------------------------------
            // MEM stage -> MEM/WB register
            // ----------------------------------------------------------
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_data   <= data_mem[ex_mem_alu_result[7:2]];
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_read;

            // Store to memory
            if (ex_mem_mem_write)
                data_mem[ex_mem_alu_result[7:2]] <= ex_mem_rs2_val;

            // ----------------------------------------------------------
            // EX stage -> EX/MEM register
            // ----------------------------------------------------------
            ex_mem_alu_result    <= ex_alu_result;
            ex_mem_rs2_val       <= ex_fwd_b;
            ex_mem_rd            <= id_ex_rd;
            ex_mem_reg_write     <= id_ex_reg_write;
            ex_mem_mem_read      <= id_ex_mem_read;
            ex_mem_mem_write     <= id_ex_mem_write;
            ex_mem_branch_taken  <= ex_branch_taken;
            ex_mem_branch_target <= ex_branch_target;

            // ----------------------------------------------------------
            // ID stage -> ID/EX register
            // If stalling, insert a bubble in ID/EX.
            // ----------------------------------------------------------
            if (load_use_hazard) begin
                id_ex_pc         <= 32'd0;
                id_ex_rs1_val    <= 32'd0;
                id_ex_rs2_val    <= 32'd0;
                id_ex_imm        <= 32'd0;
                id_ex_rs1        <= 5'd0;
                id_ex_rs2        <= 5'd0;
                id_ex_rd         <= 5'd0;
                id_ex_funct3     <= 3'd0;
                id_ex_funct7     <= 7'd0;
                id_ex_opcode     <= 7'd0;
                id_ex_reg_write  <= 1'b0;
                id_ex_mem_read   <= 1'b0;
                id_ex_mem_write  <= 1'b0;
                id_ex_alu_src    <= 1'b0;
                id_ex_branch     <= 1'b0;
                id_ex_alu_op     <= 2'b00;
            end else begin
                id_ex_pc         <= if_id_pc;
                id_ex_rs1_val    <= id_rs1_val;
                id_ex_rs2_val    <= id_rs2_val;
                id_ex_imm        <= id_imm;
                id_ex_rs1        <= id_rs1;
                id_ex_rs2        <= id_rs2;
                id_ex_rd         <= id_rd;
                id_ex_funct3     <= id_funct3;
                id_ex_funct7     <= id_funct7;
                id_ex_opcode     <= id_opcode;
                id_ex_reg_write  <= id_reg_write;
                id_ex_mem_read   <= id_mem_read;
                id_ex_mem_write  <= id_mem_write;
                id_ex_alu_src    <= id_alu_src;
                id_ex_branch     <= id_branch;
                id_ex_alu_op     <= id_alu_op;
            end

            // ----------------------------------------------------------
            // IF stage -> IF/ID register and PC update
            // Branch taken in EX -> flush IF/ID and redirect PC.
            // ----------------------------------------------------------
            if (ex_branch_taken) begin
                pc              <= ex_branch_target;
                if_id_pc        <= ex_branch_target;
                if_id_instr     <= 32'h00000013; // NOP (flush)
            end else if (load_use_hazard) begin
                // Hold PC and IF/ID so the same instruction is re-fetched
                pc              <= pc;
                if_id_pc        <= if_id_pc;
                if_id_instr     <= if_id_instr;
            end else begin
                if_id_pc        <= pc;
                if_id_instr     <= if_instr;
                pc              <= pc + 32'd4;
            end
        end
    end

endmodule