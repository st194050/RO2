module ctrl_ampel (
    input CLK,
    input RES,
    input BTN,
    input TICK,
    output reg [2:0] RGB,
    output reg CNTR_RES
);

    // Zustandsdefinitionen 
    parameter Z_ROT       = 3'd0;
    parameter Z_ROT_WAIT  = 3'd1;
    parameter Z_GELB1_RES = 3'd2;
    parameter Z_GELB1     = 3'd3;
    parameter Z_GRUEN_RES = 3'd4;
    parameter Z_GRUEN     = 3'd5;
    parameter Z_GELB2_RES = 3'd6;
    parameter Z_GELB2     = 3'd7;

    reg [2:0] state = Z_ROT; // Initialzustand ist Rot


    always @(posedge CLK or posedge RES) begin
        if (RES == 1'b1) begin
            state <= Z_ROT;
        end else begin
            case (state)
                Z_ROT:       if (BTN == 1'b1)  state <= Z_ROT_WAIT;
                Z_ROT_WAIT:  if (TICK == 1'b1) state <= Z_GELB1_RES;
                Z_GELB1_RES:                   state <= Z_GELB1; // Unbedingter Übergang
                Z_GELB1:     if (TICK == 1'b1) state <= Z_GRUEN_RES;
                Z_GRUEN_RES:                   state <= Z_GRUEN;
                Z_GRUEN:     if (TICK == 1'b1) state <= Z_GELB2_RES;
                Z_GELB2_RES:                   state <= Z_GELB2;
                Z_GELB2:     if (TICK == 1'b1) state <= Z_ROT;
                default:                       state <= Z_ROT; // Fallback für Sicherheit
            endcase
        end
    end

    
    always @(state) begin
        // Default Werte initialisieren um Latches zu vermeiden
        RGB = 3'b100;      // Rot als default
        CNTR_RES = 1'b0;   

        case (state)
            Z_ROT: begin
                RGB = 3'b100;      
                CNTR_RES = 1'b1;   // Zähler auf 0 halten
            end
            Z_ROT_WAIT: begin
                RGB = 3'b100;      
                CNTR_RES = 1'b0;   // Zähler darf laufen
            end
            Z_GELB1_RES: begin
                RGB = 3'b110;      // Gelb
                CNTR_RES = 1'b1;   // Zähler auf 0 halten
            end
            Z_GELB1: begin
                RGB = 3'b110;      // Gelb
                CNTR_RES = 1'b0;
            end
            Z_GRUEN_RES: begin
                RGB = 3'b010;      // Grün
                CNTR_RES = 1'b1;   // Reset
            end
            Z_GRUEN: begin
                RGB = 3'b010;      // Grün
                CNTR_RES = 1'b0;   // Zähler darf laufen
            end
            Z_GELB2_RES: begin
                RGB = 3'b110;      // Gelb
                CNTR_RES = 1'b1;   // Reset
            end
            Z_GELB2: begin
                RGB = 3'b110;      // Gelb
                CNTR_RES = 1'b0;   // Zähler darf laufen
            end
            default: begin
                RGB = 3'b100;      // Rot
                CNTR_RES = 1'b1;   // Zähler auf 0 halten
            end
        endcase
    end
endmodule