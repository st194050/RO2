
//Ausnahmen 
`define ALU_ADD  6'b000001 // ADD  (R Type, Bit 30 = 0, Bit 5 = 1)
`define ALU_SUB  6'b100001 // SUB  (R Type, Bit 30 = 1, Bit 5 = 1)
`define ALU_ADDI 6'b?00000 // ADDI (I Type, Bit 30 = ?, Bit 5 = 0)

// Rechenoperationen R und I Type zusammengefasst, da Bit 30 und Bit 5 für die Unterscheidung irrelevant sind
`define ALU_AND  6'b?1110? // Deckt AND und ANDI ab
`define ALU_OR   6'b?1100? // Deckt OR und ORI ab
`define ALU_XOR  6'b?1000? // Deckt XOR und XORI ab
`define ALU_SLT  6'b?0100? // Deckt SLT und SLTI ab
`define ALU_SLTU 6'b?0110? // Deckt SLTU und SLTIU ab

//Schiebeoperationen R und I Type zusammengefasst, da Bit 30 und Bit 5 für die Unterscheidung irrelevant sind
`define ALU_SLL  6'b00010? // Deckt SLL und SLLI ab
`define ALU_SRL  6'b01010? // Deckt SRL und SRLI ab
`define ALU_SRA  6'b11010? // Deckt SRA und SRAI ab

// Vergleichsoperationen
`define ALU_EQ   6'b?00011 
`define ALU_NE   6'b?00111 
`define ALU_LT   6'b?10011 
`define ALU_GE   6'b?10111 
`define ALU_LTU  6'b?11011 
`define ALU_GEU  6'b?11111 


module alu(
    input  [5:0]  S,
    input  [31:0] A,
    input  [31:0] B,
    output reg CMP,
    output reg [31:0] Q
);

always @(S, A, B) begin
    
    Q = 32'd0;
    CMP = 1'b0;

    casez (S)
     
        `ALU_ADD, `ALU_ADDI: Q = A + B;
        `ALU_SUB:            Q = A - B;
        `ALU_AND:            Q = A & B;
        `ALU_OR:             Q = A | B;
        `ALU_XOR:            Q = A ^ B;
        
        // Bei Schiebeoperationen nur die unteren 5 Bit des zweiten Operanden laut Tabelle 2
        `ALU_SLL:            Q = A << B[4:0];
        `ALU_SRL:            Q = A >> B[4:0];
        // Arithmetisches Schieben erhält das Vorzeichen, daher $signed()
        `ALU_SRA:            Q = $signed(A) >>> B[4:0]; 
        
        // Set Less Than 
        `ALU_SLT:            Q = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
        `ALU_SLTU:           Q = (A < B) ? 32'd1 : 32'd0;


        // Vergleichsoperationen für Branches (schreiben auf CMP)
        `ALU_EQ:   if (A == B) CMP = 1'b1;
        `ALU_NE:   if (A != B) CMP = 1'b1;
        
        // Vorzeichenbehaftete Vergleiche erfordern $signed()
        `ALU_LT:   if ($signed(A) < $signed(B)) CMP = 1'b1;
        `ALU_GE:   if ($signed(A) >= $signed(B)) CMP = 1'b1;
        
        // Vorzeichenlose Vergleiche
        `ALU_LTU:  if (A < B) CMP = 1'b1;
        `ALU_GEU:  if (A >= B) CMP = 1'b1;

        
        default: begin 
            Q = 32'd0;
            CMP = 1'b0;
        end
    endcase
end

endmodule