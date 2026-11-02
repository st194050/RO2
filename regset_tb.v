module regset_tb();

    reg [31:0] D;
    reg [4:0] A_D, A_Q0, A_Q1;
    reg write_enable, RES, CLK;
    wire [31:0] Q0, Q1;

    regset dut (
        .D(D),
        .A_D(A_D),
        .A_Q0(A_Q0),
        .A_Q1(A_Q1),
        .write_enable(write_enable),
        .RES(RES),
        .CLK(CLK),
        .Q0(Q0),
        .Q1(Q1)
    );

    initial begin

        CLK = 0;
        write_enable = 0;
        $srandom(42); // Startwert für den Zufallszahlengenerator

        // Test 1: Steuerleitung zurücksetzen und Reset überprüfen
            -> Spezifikation verlangt, dass ein aktives RES bei der nächsten Taktflanke alle
                Register auf 0 setzt. Der Test überprüft, ob dies korrekt funktioniert.

        RES = 1;
        @(negedge CLK);
        RES = 0;

        for (int i = 0; i < 32; i++) 
            begin
                A_Q0 = i;
                A_Q1 = i;
                @(negedge CLK);
                if (Q0 !== 32'd0 || Q1 !== 32'd0) 
                    begin
                        $display("Test fehlgeschlagen: Register %d nicht auf 0 zurückgesetzt", i);
                        $finish;
                    end
            end

        // Test 2: Nullregister darf nicht überschrieben werden
            -> Spezifikation verlangt, dass das Nullregister immer den Wert 0 hat.
                Der Test überprüft, ob ein Schreibversuch in das Nullregister korrekt ignoriert wird.

        A_D = 5'd0;
        D = $urandom;
        write_enable = 1;
        @(negedge CLK);
        write_enable = 0;
        A_Q0 = 5'd0;
        @(negedge CLK);
        if (Q0 != 32'd0)
            begin
                $display("Test fehlgeschlagen: Nullregister wurde überschrieben");
                $finish;
            end

        // Test 3: Zufällige Werte in zufällige Register schreiben und überprüfen
           -> Spezifikation verlangt, dass die Register korrekt beschrieben und gelesen werden können.
                Der Test schreibt zufällige Werte in zufällige Register und überprüft, ob die Werte korrekt gelesen werden.

        for (int i = 1; i < 32; i++)
            begin
                // Zufällige Werte generieren und in das Register schreiben
                A_D = i;
                D = $urandom;
                write_enable = 1;
                @(negedge CLK);
                write_enable = 0;

                // Überprüfen ob der Wert korrekt geschrieben wurde
                A_Q0 = i;
                @(negedge CLK);
                if (Q0 !== D) 
                    begin
                        $display("Test fehlgeschlagen: Register %d hat den falschen Wert", i);
                        $finish;
                    end
            end

        $display("Alle Tests erfolgreich bestanden!");
        $finish;
    end
    always #5 CLK = ~CLK; // Taktgenerator mit einer Periode von 10 Zeiteinheiten
endmodule