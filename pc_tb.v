module pc_tb();

    reg [31:0] D;
    reg MODE, ENABLE, RES, CLK;
    wire [31:0] PC_OUT;
    reg [31:0] old_PC;

    pc dut (
        .D(D),
        .MODE(MODE),
        .ENABLE(ENABLE),
        .RES(RES),
        .CLK(CLK),
        .PC_OUT(PC_OUT)
    );

    initial begin
        CLK = 0;
        ENABLE = 0;
        MODE = 0;
        D = 32'd0;
        $srandom(42); // Startwert für den Zufallszahlengenerator

        // Test 1: Reset überprüfen
            //-> Spezifikation verlangt, dass bei einem aktiven RES der Program Counter auf die Boot ROM Adresse initialisiert wird.
                //Der Test überprüft, ob dies korrekt funktioniert.

        RES = 1;
        @(negedge CLK); // Warten auf die nächste Taktflanke
        RES = 0;
        if (PC_OUT !== 32'h1A00_0000) 
            begin
                $display("Test fehlgeschlagen: Program Counter nicht korrekt initialisiert nach Reset");
                $finish;
            end

        // Test 2: Laden des Program Counters überprüfen
            //-> Spezifikation verlangt, dass bei ENABLE = 1 und MODE = 1 der Program Counter mit dem Wert von D geladen wird.
                //Der Test überprüft, ob dies korrekt funktioniert
        
        ENABLE = 1;
        MODE = 1; // Laden des Program Counters
        D = $urandom; // Zufälliger Wert für D
        @(negedge CLK); // Warten auf die nächste Taktflanke
        if (PC_OUT != D)
            begin
                $display("Test fehlgeschlagen: Program Counter nicht korrekt geladen");
                $finish;
            end

        // Test 3: Inkrementieren des Program Counters überprüfen
            //-> Spezifikation verlangt, dass bei ENABLE = 1 und MODE = 0 der Program Counter um 4 inkrementiert wird.
                //Der Test überprüft, ob dies korrekt funktioniert

        ENABLE = 1;
        MODE = 0; // Inkrementieren des Program Counters
        D = $urandom; // Zufälliger Wert für D
        old_PC = PC_OUT;
        @(negedge CLK); // Warten auf die nächste Taktflanke
        if (PC_OUT != old_PC + 4)
            begin
                $display("Test fehlgeschlagen: Program Counter nicht korrekt inkrementiert");
                $finish;
            end

        // Test 4: ENABLE = 0, Program Counter sollte unverändert bleiben
            //-> Spezifikation verlangt, dass bei ENABLE = 0 der Program Counter unverändert bleibt

        ENABLE = 0; // Deaktivieren des Program Counters
        MODE = 1; // Betirebsart ändern, um zu überprüfen, dass der Program Counter unverändert bleibt
        D = $urandom; // Zufälliger Wert für D
        old_PC = PC_OUT;
        @(negedge CLK); // Warten auf die nächste Taktflanke
        @(negedge CLK); // Warten auf die nächste Taktflanke um sicherzustellen, dass der Program Counter unverändert bleibt
        if (PC_OUT != old_PC)
            begin
                $display("Test fehlgeschlagen: Program Counter hat sich verändert, obwohl ENABLE = 0");
                $finish;
            end
            $display("Alle Tests erfolgreich bestanden");
        $finish;
    end 
    always #5 CLK = ~CLK; // Taktgenerator mit einer Periode von 10 Zeiteinheiten
endmodule
