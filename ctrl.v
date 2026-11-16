module ctrl (
    input  wire clk,
    input  wire        res,
    input  wire        instr_valid,
    
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    
    output reg         instr_req,
    output reg         pc_enable,
    output reg         ir_enable,
    output reg         reg_write,
    output reg         alu_src_a,
    output reg         alu_src_b,
    output reg         wb_select,
    output wire        branch,
    output wire [5:0]  alu_op
);

    // Zustände 
    localparam S_FETCH      = 3'd0;
    localparam S_DECODE     = 3'd1;
    localparam S_EXEC_R     = 3'd2;
    localparam S_EXEC_I     = 3'd3;
    localparam S_EXEC_LUI   = 3'd4;
    localparam S_EXEC_AUIPC = 3'd5;
    localparam S_EXEC_NOP   = 3'd6; 
    
    reg [2:0] state;

    // Zustandlogik
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
                        7'b0110011: state <= S_EXEC_R;
                        7'b0010011: state <= S_EXEC_I;
                        7'b0110111: state <= S_EXEC_LUI;
                        7'b0010111: state <= S_EXEC_AUIPC;
                        default:    state <= S_EXEC_NOP; // Unbekannt -> NOP
                    endcase
                end
                
                S_EXEC_R, S_EXEC_I, S_EXEC_LUI, S_EXEC_AUIPC, S_EXEC_NOP: begin
                    state <= S_FETCH;
                end
                
                default: state <= S_FETCH;
            endcase
        end
    end

    // Steuerlogik
    always @(*) begin
        // Defaulteinstellungen
        instr_req = 1'b0;
        pc_enable = 1'b0;
        ir_enable = 1'b0;
        reg_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        wb_sel    = 1'b0;

        case (state)
            S_FETCH: begin
                instr_req = 1'b1;
                ir_enable = 1'b1; 
            end
            
            S_DECODE: begin
                // Warten, keine Ausgaben
            end
            
            S_EXEC_R: begin
                alu_src_a = 1'b0;
                alu_src_b = 1'b0;
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end
            
            S_EXEC_I: begin
                alu_src_a = 1'b0;
                alu_src_b = 1'b1; 
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end
            
            S_EXEC_LUI: begin
                wb_sel    = 1'b1; 
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end
            
            S_EXEC_AUIPC: begin
                alu_src_a = 1'b1; 
                alu_src_b = 1'b1; 
                reg_write = 1'b1;
                pc_enable = 1'b1;
            end
            
            S_EXEC_NOP: begin
                pc_enable = 1'b1; // Weiter zum nächsten Befehl
            end
        endcase
    end
    
    // Für dieses Aufgabenblatt deaktiviert
    assign branch = 1'b0; 

    //  ALUOp
    assign alu_op = 
        (opcode == 7'b0010111) ? 6'b000001  : // AUIPC
        (funct3 == 3'b000) ? ((opcode == 7'b0110011 && funct7 == 7'b0100000) ? 6'b100001 /*SUB*/ : 6'b000001 /*ADD*/) :
        (funct3 == 3'b001) ? 6'b000101  : // SLL
        (funct3 == 3'b010) ? 6'b001001  : // SLT
        (funct3 == 3'b011) ? 6'b001101  : // SLTU
        (funct3 == 3'b100) ? 6'b010001  : // XOR
        (funct3 == 3'b101) ? ((funct7 == 7'b0100000) ? 6'b110101 /*SRA*/ : 6'b010101 /*SRL*/) :
        (funct3 == 3'b110) ? 6'b011001  : // OR
        (funct3 == 3'b111) ? 6'b011101  : // AND
                             6'b000001 ; // Default: ADD

endmodule