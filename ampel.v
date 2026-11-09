module ampel (
    input CLK,
    input RESN, 
    input BTN,
    output [2:0] RGB
);
    wire RES;
    wire TICK;
    wire CNTR_RES;

    // Inverter
    assign RES = ~RESN;

    // timer instanz
    timer i_timer (
        .CLK(CLK),
        .RES(CNTR_RES), // Reset kommt vom controller
        .TICK(TICK)
    );

    // ctrl_ampel instanz
    ctrl_ampel i_ctrl (
        .CLK(CLK),
        .RES(RES),      
        .BTN(BTN),
        .TICK(TICK),
        .RGB(RGB),
        .CNTR_RES(CNTR_RES) 
    );

endmodule