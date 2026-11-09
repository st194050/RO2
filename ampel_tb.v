`timescale 1ns / 1ps

module ampel (
    input CLK,
    input RESN, 
    input BTN,
    output [2:0] RGB
 );

    ampel dut (
        .CLK(CLK),
        .RESN(RESN),
        .BTN(BTN),
        .RGB(RGB)
    );

    initial begin
        CLK = 1'b0;
        BTN = 1'b0;
        RESN = 1'b0; // Reset aktivieren
        #1;
        RESN = 1'b1; // Reset deaktivieren
    end

    always begin
        #0.5 CLK = ~CLK; // Takt mit 1ns Periode
    end
endmodule
