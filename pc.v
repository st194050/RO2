module pc(
    input [31:0] D, // Dateneingang des Program Counters
    input MODE, // Steuersignal zum Umschalten zwischen Inkrementieren und Laden
    input ENABLE, // Steuersignal zum Aktivieren des Program Counters
    input RES,
    input CLK,
    output reg [31:0] PC_OUT // Datenausgang des Program Counters
);

    always @(posedge CLK)
        begin
            if (RES == 1'b1)
                begin
                    PC_OUT <= 32'h1A00_0000; // Bei Reset mit Boot ROM Adresse initialisieren
                end
            else if (ENABLE == 1'b1)
                begin
                    if (MODE == 1'b0)
                        begin
                            PC_OUT<= D; // Betriebsstart: Laden des Program Counters mit dem Wert von D
                        end
                    else if (MODE == 1'b1)
                        begin
                            PC_OUT <= PC_OUT +4; // Betriebsstart: Inkrementieren des Program Counters um 4
                        end
                end
                // Wenn ENABLE nicht aktiv ist also ENABLE == 1'b0, bleibt der Program Counter unverändert
        end
endmodule