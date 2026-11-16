
// In der Stunde Kommentare auf Bezeichnungen pruefen 
//  ->Portnamen von REG_DRE_32 und MUX_2x1_32 (v_lib)
//  -> Opcode Namen aus riscv_isa_defines.v (statt der localparams unten)

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

    
    // Opcodes fuer den ImmGen
    // PRUEFEN: durch Defines aus riscv_isa_defines.v ersetzen
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;
    localparam [6:0] OP_BRANCH = 7'b1100011;

    // Ausgänge für Data Memory
    assign data_req          = 1'b0;
    assign data_adr          = 32'd0;
    assign data_write        = 32'd0;
    assign data_write_enable = 1'b0;
    assign data_be           = 4'd0;
    assign irq_ack           = 1'b0;
    assign irq_ack_id        = 5'd0;

    // Instruction Register
    wire [31:0] ir_out;
    wire        ir_enable;   // vom Steuerwerk

    // PRUEFEN: Portnamen von REG_DRE_32
    REG_DRE_32 instruction_register (
        .D(instr_read),
        .RES(res),
        .E(ir_enable),
        .CLK(clk),
        .Q(ir_out)
    );

    wire [6:0] opcode = ir_out[6:0];
    wire [4:0] rd     = ir_out[11:7];
    wire [2:0] funct3 = ir_out[14:12];
    wire [4:0] rs1    = ir_out[19:15];
    wire [4:0] rs2    = ir_out[24:20];
    wire [6:0] funct7 = ir_out[31:25];

    // Immediate Generator
    wire [31:0] imm_ext;

    assign imm_ext =
        // U Type (LUI, AUIPC)
        (opcode == OP_LUI || opcode == OP_AUIPC) ? {ir_out[31:12], 12'b0} :
        // B Type (Branch), inklusive Shift left 1 
        (opcode == OP_BRANCH) ? {{19{ir_out[31]}}, ir_out[31], ir_out[7],
                                 ir_out[30:25], ir_out[11:8], 1'b0} :
        // I-Type und Fallback
        {{20{ir_out[31]}}, ir_out[31:20]};

   // PC
    wire [31:0] pc_out;
    wire        pc_enable;   // vom Steuerwerk
    wire        branch;      // vom Steuerwerk
    wire        cmp;         // von der ALU

    assign instr_adr = pc_out;

    wire [31:0] branch_target = pc_out + imm_ext;
    wire        branch_taken  = branch & cmp;
    wire        pc_mode       = ~branch_taken;   // 1: +4, 0: Sprungziel laden

    pc my_pc (
        .D(branch_target),
        .MODE(pc_mode),
        .ENABLE(pc_enable),
        .RES(res),
        .CLK(clk),
        .PC_OUT(pc_out)
    );

    // regset Instanz
    wire        reg_write;   // vom Steuerwerk
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

    
    // Multiplexer vor der ALU
    // PRUEFEN: Portnamen von MUX_2x1_32
    wire        alu_src_a;   // vom Steuerwerk
    wire        alu_src_b;   // vom Steuerwerk
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    MUX_2x1_32 mux_a (
        .D0(read_data_1),    // S=0: rs1
        .D1(pc_out),         // S=1: PC (AUIPC)
        .S(alu_src_a),
        .Q(alu_in_a)
    );

    MUX_2x1_32 mux_b (
        .D0(read_data_2),    // S=0: rs2
        .D1(imm_ext),        // S=1: Direktwert
        .S(alu_src_b),
        .Q(alu_in_b)
    );

    
    // ALU
    wire [5:0]  alu_op;      // vom Steuerwerk
    wire [31:0] alu_q;

    alu my_alu (
        .S(alu_op),
        .A(alu_in_a),
        .B(alu_in_b),
        .CMP(cmp),
        .Q(alu_q)
    );

    // WB Mux
    wire wb_select;             // vom Steuerwerk

    MUX_2x1_32 wb_mux (
        .D0(alu_q),          // S=0: ALU-Ergebnis
        .D1(imm_ext),        // S=1: Direktwert (LUI)
        .S(wb_select),
        .Q(write_data)
    );

    // Steuerwerk
    ctrl my_ctrl (
        .clk(clk),
        .res(res),
        .instr_valid(instr_valid),
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
        .alu_op(alu_op)
    );

endmodule