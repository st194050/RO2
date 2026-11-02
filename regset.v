module regset (
    input [31:0] D, // Dateneingang des Registersatzes
    input [4:0] A_D, // Zieladresse fpr die Eingangsdaten D
    input [4:0] A_Q0,
    input [4:0] A_Q1, // Adressen für Ausgangsdaten Q0 und Q1 des Registersatzes
    input write_enable, // Steuersignal zum Schreiben in den Registersatz
    input RES, // Reset -> bei RES = 1 werden bei nächste Taktflanke alle Register auf 0 gesetzt
    input CLK, // Takteingang
    output [31:0] Q0, 
    output [31:0] Q1 // Datenausgänge
);
    reg [31:0] registers [31:0]; // 32 Register mit je 32 Bit
    
    // Asynchrones Lesen der Register
    assign Q0 = (A_Q0 == 5'd0) ? 32'd0 : registers[A_Q0]; // Register 0 ist immer 0, sonst Wert aus dem Registersatz
    assign Q1 = (A_Q1 == 5'd0) ? 32'd0 : registers[A_Q1];

    // Synchrones Schreiben und Reset der Register bei positiver Taktflanke
    always @(posedge CLK) 
        begin
            if (RES == 1'b1) 
            begin
                // Reset: Alle Register auf 0 setzen
                integer i;
                for (i = 0; i < 32; i = i + 1) 
                    begin
                    registers[i] <= 32'd0;
                    end
            end
            else if (write_enable && A_D != 5'd0) 
                begin
            // Schreiben in das Register, wenn write_enable aktiv ist und A_D nicht 0 ist
            registers[A_D] <= D;
                end
        end
endmodule