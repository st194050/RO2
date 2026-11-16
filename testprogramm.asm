addi x31, x0, 0       # x31 dient als Zähler für den aktuellen Testfall

# Test 1: LUI, AUIPC
addi x31, x31, 1
lui x1, 0x12345       # x1 = 0x12345000
auipc x2, 0x00001     # x2 = PC + 0x1000

# Test 2: ADDI
addi x31, x31, 1
addi x3, x0, 10       # x3 = 10
addi x4, x0, -5       # x4 = 0xFFFFFFFB

# Test 3: ADD, SUB
addi x31, x31, 1
add x5, x3, x4        # x5 = 5
sub x6, x3, x4        # x6 = 15

# Test 4: ANDI, ORI, XORI
addi x31, x31, 1
addi x7, x0, 15       # x7 = 15
andi x8, x7, 5        # x8 = 5
ori x9, x7, 16        # x9 = 31
xori x10, x7, 10      # x10 = 5

# Test 5: AND, OR, XOR
addi x31, x31, 1
addi x11, x0, 0xAA    # x11 = 0xAA
addi x12, x0, 0x55    # x12 = 0x55
and x13, x11, x12     # x13 = 0x00
or x14, x11, x12      # x14 = 0xFF
xor x15, x11, x12     # x15 = 0xFF

# Test 6: SLLI, SRLI, SRAI
addi x31, x31, 1
addi x16, x0, -4      # x16 = 0xFFFFFFFC
slli x17, x16, 2      # x17 = 0xFFFFFFF0
srli x18, x16, 2      # x18 = 0x3FFFFFFF
srai x19, x16, 2      # x19 = 0xFFFFFFFF

# Test 7: SLL, SRL, SRA
addi x31, x31, 1
addi x20, x0, 2       # x20 = 2
sll x21, x16, x20     # x21 = 0xFFFFFFF0
srl x22, x16, x20     # x22 = 0x3FFFFFFF
sra x23, x16, x20     # x23 = 0xFFFFFFFF

# Test 8: SLT, SLTU, SLTI, SLTIU 
addi x31, x31, 1
addi x24, x0, -1      # x24 = 0xFFFFFFFF
addi x25, x0, 1       # x25 = 1
slt x26, x24, x25     # x26 = 1   -1 < 1
sltu x27, x24, x25    # x27 = 0   0xFFFFFFFF > 1 vorzeichenlos
slti x28, x24, 0      # x28 = 1   -1 < 0
sltiu x29, x25, -1    # x29 = 1   1 < 0xFFFFFFFF, Imm vorzeichenerweitert
slt x30, x25, x25     # x30 = 0   gleich

# Test 9: Register x0 bleibt immer 0
addi x31, x31, 1
addi x0, x0, 5        # darf x0 nicht ändern
lui x0, 0xFFFFF       # darf x0 nicht ändern
add x24, x0, x0       # x24 = 0
addi x25, x0, 7       # x25 = 7

# Test 10: Grenzwerte der Direktwerte, Vorzeichenerweiterung
addi x31, x31, 1
addi x24, x0, 2047    # x24 = 0x000007FF
addi x25, x0, -2048   # x25 = 0xFFFFF800
lui x26, 0x80000      # x26 = 0x80000000
lui x27, 0xFFFFF      # x27 = 0xFFFFF000
addi x28, x26, -1     # x28 = 0x7FFFFFFF
addi x29, x28, 1      # x29 = 0x80000000 Überlauf ohne Fehler
addi x30, x0, 1024    # x30 = 0x00000400  funct7-Feld = 0100000, darf kein SUB werden

# Test 11: Schiebeoperationen, Grenzfälle
addi x31, x31, 1
addi x24, x0, 33      # nur die unteren 5 Bit zählen -> Schiebeweite 1
sll x25, x16, x24     # x25 = 0xFFFFFFF8
addi x26, x0, 1       # x26 = 1
slli x27, x26, 31     # x27 = 0x80000000
srli x28, x27, 31     # x28 = 1
srai x29, x27, 31     # x29 = 0xFFFFFFFF
slli x30, x26, 0      # x30 = 1

# Test 12: Quellregister = Zielregister
addi x31, x31, 1
addi x24, x0, 3       # x24 = 3
add x24, x24, x24     # x24 = 6
add x24, x24, x24     # x24 = 12
sub x25, x24, x24     # x25 = 0

# Test 13: x31 = 12; zwei NOPs damit der PC nicht sofort ins Leere läuft
addi x0, x0, 0
addi x0, x0, 0