
start:
    auipc x20, 0            # x20 = Adresse dieses Befehls (Programmanfang)
    addi  x1, x0, 12        # x1 = 12
    addi  x2, x0, 5         # x2 = 5
    addi  x3, x0, -8        # x3 = -8 = 0xFFFFFFF8

#  R-Type 
    add   x4, x1, x2        # 12 + 5 = 17
    addi  x28, x0, 17
    bne   x4, x28, fail
    sub   x4, x1, x2        # 12 - 5 = 7
    addi  x28, x0, 7
    bne   x4, x28, fail
    sll   x4, x1, x2        # 12 << 5 = 384
    addi  x28, x0, 384
    bne   x4, x28, fail
    slt   x4, x3, x1        # -8 < 12 (vorzeichenbehaftet) -> 1
    addi  x28, x0, 1
    bne   x4, x28, fail
    sltu  x4, x3, x1        # 0xFFFFFFF8 < 12 (ohne Vorzeichen) -> 0
    bne   x4, x0, fail
    xor   x4, x1, x2        # 12 ^ 5 = 9
    addi  x28, x0, 9
    bne   x4, x28, fail
    srl   x4, x3, x2        # 0xFFFFFFF8 >> 5 (logisch) = 0x07FFFFFF
    lui   x28, 0x08000      # x28 = 0x08000000
    addi  x28, x28, -1      # x28 = 0x07FFFFFF
    bne   x4, x28, fail
    sra   x4, x3, x2        # -8 >> 5 (arithmetisch) = -1
    addi  x28, x0, -1
    bne   x4, x28, fail
    or    x4, x1, x2        # 12 | 5 = 13
    addi  x28, x0, 13
    bne   x4, x28, fail
    and   x4, x1, x2        # 12 & 5 = 4
    addi  x28, x0, 4
    bne   x4, x28, fail

# I-Type (ALU) 
    addi  x4, x1, -2        # 12 - 2 = 10
    addi  x28, x0, 10
    bne   x4, x28, fail
    slti  x4, x3, 0         # -8 < 0 -> 1
    addi  x28, x0, 1
    bne   x4, x28, fail
    sltiu x4, x3, 1         # 0xFFFFFFF8 < 1 (ohne Vorzeichen) -> 0
    bne   x4, x0, fail
    xori  x4, x1, 10        # 12 ^ 10 = 6
    addi  x28, x0, 6
    bne   x4, x28, fail
    ori   x4, x1, 3         # 12 | 3 = 15
    addi  x28, x0, 15
    bne   x4, x28, fail
    andi  x4, x1, 4         # 12 & 4 = 4
    addi  x28, x0, 4
    bne   x4, x28, fail
    slli  x4, x2, 4         # 5 << 4 = 80
    addi  x28, x0, 80
    bne   x4, x28, fail
    srli  x4, x3, 28        # 0xFFFFFFF8 >> 28 = 0xF
    addi  x28, x0, 15
    bne   x4, x28, fail
    srai  x4, x3, 2         # -8 >> 2 = -2
    addi  x28, x0, -2
    bne   x4, x28, fail

# LUI / AUIPC 
    lui   x4, 0x00007       # x4 = 0x7000
    srli  x4, x4, 12        # x4 = 7
    addi  x28, x0, 7
    bne   x4, x28, fail
    auipc x14, 0            # x14 = eigene Adresse
    auipc x15, 0            # x15 = eigene Adresse = x14 + 4
    sub   x4, x15, x14
    addi  x28, x0, 4
    bne   x4, x28, fail

# SW / LW 
    addi  x21, x20, 1024    # x21 = Datenbereich (Programmanfang + 0x400)
    sw    x1, 0(x21)        # Mem[x21+0] = 12
    sw    x3, 4(x21)        # Mem[x21+4] = -8
    addi  x22, x21, 16
    sw    x2, -8(x22)       # Mem[x21+8] = 5  (negativer Offset!)
    lw    x4, 0(x21)
    addi  x28, x0, 12
    bne   x4, x28, fail
    lw    x4, 4(x21)
    addi  x28, x0, -8
    bne   x4, x28, fail
    lw    x4, -8(x22)
    addi  x28, x0, 5
    bne   x4, x28, fail

# Branches: je "genommen" und "nicht genommen" 
    beq   x1, x1, b1        # genommen
    jal   x0, fail
b1: beq   x1, x2, fail      # nicht genommen
    bne   x1, x2, b2        # genommen
    jal   x0, fail
b2: bne   x1, x1, fail      # nicht genommen
    blt   x3, x1, b3        # -8 < 12 -> genommen
    jal   x0, fail
b3: blt   x1, x3, fail      # 12 < -8 -> nicht genommen
    bge   x1, x3, b4        # 12 >= -8 -> genommen
    jal   x0, fail
b4: bge   x3, x1, fail      # -8 >= 12 -> nicht genommen
    bltu  x1, x3, b5        # 12 < 0xFFFFFFF8 (unsigned) -> genommen
    jal   x0, fail
b5: bltu  x3, x1, fail      # nicht genommen
    bgeu  x3, x1, b6        # genommen
    jal   x0, fail
b6: bgeu  x1, x3, fail      # nicht genommen

#  JAL / JALR 
    jal   x17, func         # Aufruf, x17 = Rueckkehradresse
    auipc x18, 0            # (Rueckkehrpunkt) x18 = eigene Adresse = x17
    jal   x0, after_func
func:
    addi  x27, x0, 42
    jalr  x0, 0(x17)        # Rueckkehr
after_func:
    bne   x17, x18, fail    # Link-Wert (PC+4) richtig?
    addi  x28, x0, 42
    bne   x27, x28, fail    # Funktion wurde ausgefuehrt?

    auipc x19, 0            # x19 = P
    jalr  x29, 13(x19)      # Ziel = (P+13) & ~1 = P+12, x29 = P+8
    jal   x0, fail          # wird uebersprungen (P+8)
    sub   x4, x29, x19      # (P+12) x4 = 8
    addi  x28, x0, 8
    bne   x4, x28, fail


    addi  x31, x0, 1        # alles bestanden
    jal   x0, done
fail:
    addi  x31, x0, -1       # Fehler
done:
    jal   x0, done          # Endlosschleife
