`include "riscv_isa_defines.v"

module proc (
    input  wire        clk,
    input  wire        res,

    // Instruction Memory
    input  wire [31:0] instr_read,
    output wire [31:0] instr_adr,
    output wire        instr_req,
    input  wire        instr_valid,

    // Data Memory
    input  wire [31:0] data_read,
    output wire [31:0] data_write,
    output wire [31:0] data_adr,
    output wire        data_req,
    input  wire        data_valid,
    output wire        data_write_enable,
    output wire [3:0]  data_be,

    // Interrupts
    input  wire        irq,
    input  wire [4:0]  irq_id,
    output wire        irq_ack,
    output wire [4:0]  irq_ack_id
);

    // Feste Zuweisungen
    assign data_be    = 4'b1111; // 32-Bit Wortzugriff für LW/SW
    assign irq_ack    = 1'b0;
    assign irq_ack_id = 5'd0;

    // Instruction Register
    wire [31:0] ir_out;
    wire        ir_enable;  

    REG_DRE_32 instruction_register (
        .D(instr_read),
        .RES(res),
        .ENABLE(ir_enable),
        .CLK(clk),
        .Q(ir_out)
    );

    wire [6:0] opcode = ir_out[6:0];
    wire [4:0] rd     = ir_out[11:7];
    wire [2:0] funct3 = ir_out[14:12];
    wire [4:0] rs1    = ir_out[19:15];
    wire [4:0] rs2    = ir_out[24:20];
    wire [6:0] funct7 = ir_out[31:25];

    // Erweiterter Immediate Generator
    wire [31:0] imm_ext;
    assign imm_ext =
        (opcode == `OPCODE_LUI || opcode == `OPCODE_AUIPC) ? {ir_out[31:12], 12'b0} :
        (opcode == `OPCODE_JAL) ? {{12{ir_out[31]}}, ir_out[19:12], ir_out[20], ir_out[30:21], 1'b0} :
        (opcode == `OPCODE_BRANCH) ? {{20{ir_out[31]}}, ir_out[7], ir_out[30:25], ir_out[11:8], 1'b0} :
        (opcode == `OPCODE_STORE) ? {{20{ir_out[31]}}, ir_out[31:25], ir_out[11:7]} :
        {{20{ir_out[31]}}, ir_out[31:20]}; // Fallback: I-Type (LOAD, JALR, ALU_I)

    // PC Logik und Verzweigungen
    wire [31:0] pc_out;
    wire        pc_enable;   
    wire        branch;      
    wire        jump;
    wire        jump_reg;
    wire        cmp;         

    assign instr_adr = pc_out;

    wire [31:0] pc_plus_4     = pc_out + 4;
    wire [31:0] branch_target = pc_out + imm_ext;
    
    // Springen wenn Bedingung erfüllt ODER wenn unbedingter Sprung (JAL/JALR)
    wire        branch_taken  = (branch & cmp) | jump;
    wire        pc_mode       = ~branch_taken;   // 1: +4, 0: Target laden

    // NEU: Sprungziel-MUX (PC-relativ vs. Register-relativ für JALR)
    wire [31:0] pc_next_target;
    wire [31:0] alu_q; // Deklaration vorverlegt
    
    MUX_2x1_32 pc_target_mux (
        .I0(branch_target), // Normaler Sprung (B-Type, JAL)
        .I1({alu_q[31:1], 1'b0}),         // Aus ALU berechnete absolute Adresse (JALR)
        .S(jump_reg),
        .Y(pc_next_target)
    );

    pc my_pc (
        .D(pc_next_target),
        .MODE(pc_mode),
        .ENABLE(pc_enable),
        .RES(res),
        .CLK(clk),
        .PC_OUT(pc_out)
    );

    // Regset
    wire        reg_write;   
    wire [31:0] write_data;
    wire [31:0] read_data_1;
    wire [31:0] read_data_2;

    regset my_regset (
        .CLK(clk),
        .RES(res),
        .write_enable(reg_write),
        .A_Q0(rs1),
        .A_Q1(rs2),
        .A_D(rd),
        .D(write_data),
        .Q0(read_data_1),
        .Q1(read_data_2)
    );
    
    // Memory Interface (Data) - Verschaltung
    assign data_adr   = alu_q;
    assign data_write = read_data_2; // rs2 enthält die Daten für STORE

    // Multiplexer vor der ALU
    wire        alu_src_a;   
    wire        alu_src_b;   
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    MUX_2x1_32 mux_a (
        .I0(read_data_1),    // rs1
        .I1(pc_out),         // PC
        .S(alu_src_a),
        .Y(alu_in_a)
    );

    MUX_2x1_32 mux_b (
        .I0(read_data_2),    // rs2
        .I1(imm_ext),        // Direktwert
        .S(alu_src_b),
        .Y(alu_in_b)
    );

    // ALU
    wire [5:0]  alu_op;      
    alu my_alu (
        .S(alu_op),
        .A(alu_in_a),
        .B(alu_in_b),
        .CMP(cmp),
        .Q(alu_q)
    );

    // NEU: Erweiterter Write-Back-MUX (4-zu-1 Kaskade)
    wire [1:0]  wb_select;    // Auf 2 Bit erweitert
    wire [31:0] wb_mux_0_y;
    wire [31:0] wb_mux_1_y;

    MUX_2x1_32 wb_mux_0 (
        .I0(alu_q),          // 00: ALU-Ergebnis
        .I1(imm_ext),        // 01: LUI
        .S(wb_select[0]),
        .Y(wb_mux_0_y)
    );

    MUX_2x1_32 wb_mux_1 (
        .I0(data_read),      // 10: Datenspeicher (LW)
        .I1(pc_plus_4),      // 11: Rücksprungadresse (JAL/JALR)
        .S(wb_select[0]),
        .Y(wb_mux_1_y)
    );

    MUX_2x1_32 wb_mux_final (
        .I0(wb_mux_0_y),     // Falls Bit 1 == 0 -> obere Hälfte
        .I1(wb_mux_1_y),     // Falls Bit 1 == 1 -> untere Hälfte
        .S(wb_select[1]),
        .Y(write_data)
    );

    // Steuerwerk
    ctrl my_ctrl (
        .clk(clk),
        .res(res),
        .instr_valid(instr_valid),
        .data_valid(data_valid),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        
        .instr_req(instr_req),
        .pc_enable(pc_enable),
        .ir_enable(ir_enable),
        .reg_write(reg_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .wb_select(wb_select),
        .branch(branch),
        .jump(jump),
        .jump_reg(jump_reg),
        .data_req(data_req),
        .data_write_enable(data_write_enable),
        .alu_op(alu_op)
    );

endmodule