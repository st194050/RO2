`include "riscv_isa_defines.v" 

module ctrl (
    input  wire        clk,
    input  wire        res,
    input  wire        instr_valid,
    input  wire        data_valid,   // Handshake vom Datenspeicher
    
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    
    output reg         instr_req,
    output reg         pc_enable,
    output reg         ir_enable,
    output reg         reg_write,
    output reg         alu_src_a,
    output reg         alu_src_b,
    output reg [1:0]   wb_select,    
    output reg         branch,       
    output reg         jump,         
    output reg         jump_reg,     
    output reg         data_req,         
    output reg         data_write_enable,
    output wire [5:0]  alu_op
);

    
    localparam S_FETCH       = 4'd0;
    localparam S_DECODE      = 4'd1;
    localparam S_EXEC_R      = 4'd2;
    localparam S_EXEC_I      = 4'd3;
    localparam S_EXEC_LUI    = 4'd4;
    localparam S_EXEC_AUIPC  = 4'd5;
    localparam S_EXEC_LOAD   = 4'd6;
    localparam S_EXEC_STORE  = 4'd7;
    localparam S_EXEC_BRANCH = 4'd8;
    localparam S_EXEC_JAL    = 4'd9;
    localparam S_EXEC_JALR   = 4'd10;
    localparam S_TRAP        = 4'd11; 
    
    reg [3:0] state;

    
    always @(posedge clk or posedge res) begin
        if (res == 1'b1) begin
            state <= S_FETCH;
        end else begin
            case (state)
                S_FETCH: begin
                    if (instr_valid == 1'b1) begin
                        state <= S_DECODE;
                    end
                end
                
                S_DECODE: begin
                    case (opcode)
                        `OPCODE_OP:     state <= S_EXEC_R;
                        `OPCODE_OPIMM:  state <= S_EXEC_I;
                        `OPCODE_LUI:    state <= S_EXEC_LUI;
                        `OPCODE_AUIPC:  state <= S_EXEC_AUIPC;
                        `OPCODE_LOAD:   state <= S_EXEC_LOAD;
                        `OPCODE_STORE:  state <= S_EXEC_STORE;
                        `OPCODE_BRANCH: state <= S_EXEC_BRANCH;
                        `OPCODE_JAL:    state <= S_EXEC_JAL;
                        `OPCODE_JALR:   state <= S_EXEC_JALR;
                        default:        state <= S_TRAP; // Unbekannt -> Falle
                    endcase
                end

                S_EXEC_LOAD, S_EXEC_STORE: begin
                    if (data_valid == 1'b1) begin
                        state <= S_FETCH;
                    end
                end
                
                S_EXEC_R, S_EXEC_I, S_EXEC_LUI, S_EXEC_AUIPC, S_EXEC_BRANCH, S_EXEC_JAL, S_EXEC_JALR: begin
                    state <= S_FETCH;
                end
                
                //  Der Prozessor bleibt hier für immer gefangen
                S_TRAP: begin
                    state <= S_TRAP;
                end
                
                default: state <= S_TRAP;
            endcase
        end
    end

    
    always @(*) begin
        // Defaulteinstellungen (verhindert Latches)
        instr_req = 1'b0;
        pc_enable = 1'b0;
        ir_enable = 1'b0;
        reg_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        wb_select = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        jump_reg  = 1'b0;
        data_req  = 1'b0;
        data_write_enable = 1'b0;

        case (state)
            S_FETCH: begin
                instr_req = 1'b1;
                ir_enable = 1'b1; 
            end
            
            S_DECODE: begin /* Warten */ end
            
            S_EXEC_R: begin
                alu_src_a = 1'b0; alu_src_b = 1'b0;
                reg_write = 1'b1; pc_enable = 1'b1;
            end
            
            S_EXEC_I: begin
                alu_src_a = 1'b0; alu_src_b = 1'b1; 
                reg_write = 1'b1; pc_enable = 1'b1;
            end
            
            S_EXEC_LUI: begin
                wb_select = 2'b01; reg_write = 1'b1; pc_enable = 1'b1;
            end
            
            S_EXEC_AUIPC: begin
                alu_src_a = 1'b1; alu_src_b = 1'b1; 
                reg_write = 1'b1; pc_enable = 1'b1;
            end

            S_EXEC_LOAD: begin
                alu_src_a = 1'b0; alu_src_b = 1'b1; // Adressrechnung rs1 + imm
                data_req  = 1'b1;
                wb_select = 2'b10;                  // 10 = data_read
                
                
                if (data_valid == 1'b1) begin
                    reg_write = 1'b1;
                    pc_enable = 1'b1;
                end
            end

            S_EXEC_STORE: begin
                alu_src_a = 1'b0; alu_src_b = 1'b1; 
                data_req  = 1'b1;
                data_write_enable = 1'b1;
                
                if (data_valid == 1'b1) begin
                    pc_enable = 1'b1;
                end
            end

            S_EXEC_BRANCH: begin
                branch = 1'b1;
                pc_enable = 1'b1;
            end

            S_EXEC_JAL: begin
                jump      = 1'b1;
                wb_select = 2'b11; // 11 = PC + 4 (Rücksprungadresse)
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end

            S_EXEC_JALR: begin
                jump      = 1'b1;
                jump_reg  = 1'b1;  // Zieladresse aus ALU
                alu_src_a = 1'b0; alu_src_b = 1'b1; 
                wb_select = 2'b11; 
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end
            
            S_TRAP: begin
                // Der Fangzustand setzt aktiv KEINE Signale!
                // Alles bleibt auf 0 (durch Defaults am Block-Anfang).
            end
        endcase
    end
    
   
    assign alu_op = 
        (opcode == `OPCODE_AUIPC || opcode == `OPCODE_LOAD || opcode == `OPCODE_STORE || opcode == `OPCODE_JALR) ? 6'b000001 :
         
        (opcode == `OPCODE_BRANCH) ? (
            (funct3 == 3'b000) ? 6'b000011 : // EQ
            (funct3 == 3'b001) ? 6'b000111 : // NE
            (funct3 == 3'b100) ? 6'b010011 : // LT
            (funct3 == 3'b101) ? 6'b010111 : // GE
            (funct3 == 3'b110) ? 6'b011011 : // LTU
            (funct3 == 3'b111) ? 6'b011111 : // GEU
            6'b000001
        ) :
        
        (funct3 == 3'b000) ? ((opcode == `OPCODE_OP && funct7 == 7'b0100000) ? 6'b100001 : 6'b000001) :
        (funct3 == 3'b001) ? 6'b000101 : // SLL
        (funct3 == 3'b010) ? 6'b001001 : // SLT
        (funct3 == 3'b011) ? 6'b001101 : // SLTU
        (funct3 == 3'b100) ? 6'b010001 : // XOR
        (funct3 == 3'b101) ? ((funct7 == 7'b0100000) ? 6'b110101 : 6'b010101) : // SRA : SRL
        (funct3 == 3'b110) ? 6'b011001 : // OR
        (funct3 == 3'b111) ? 6'b011101 : // AND
                             6'b000001 ; 

endmodule
