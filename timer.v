module timer(
    input CLK,   
    input RES,   
    output TICK  // Signal, dass 5 Sekunden vergangen sind
);
    
    // Wir brauchen 4 Bit um 1010 darzustellen
    reg [3:0] counter = 4'd0;

    // Dieser Block wird immer exakt bei der steigenden Taktflanke ausgeführt
    always @(posedge CLK) begin
        if (RES == 1'b1) begin
            // Wenn das Steuerwerk RES auf 1 setzt, 
            // fängt der Zähler beim nächsten Takt wieder bei 0 an.
            counter <= 4'd0;
        end else if (counter < 4'd10) begin
            // counter erhöhen bis 10 erreicht wird.
            counter <= counter + 1'b1;
        end
        
    end
    // Wenn der counter 10 erreicht, wird TICK auf 1 gesetzt, sonst auf 0
    assign TICK = (counter == 4'd10) ? 1'b1 : 1'b0;
endmodule