addi x31, x0, 0       # x31 dient als Zähler für den aktuellen Testfall

# Test 1: LUI, AUIPC
addi x31, x31, 1
lui x1, 0x12345       
auipc x2, 0x00001     

# Test 2: ADDI
addi x31, x31, 1
addi x3, x0, 10       
addi x4, x0, -5       

# Test 3: ADD, SUB
addi x31, x31, 1
add x5, x3, x4        
sub x6, x3, x4        

# Test 4: ANDI, ORI, XORI
addi x31, x31, 1
addi x7, x0, 15       
andi x8, x7, 5        
ori x9, x7, 16        
xori x10, x7, 10      

# Test 5: AND, OR, XOR
addi x31, x31, 1
addi x11, x0, 0xAA    
addi x12, x0, 0x55    
and x13, x11, x12     
or x14, x11, x12      
xor x15, x11, x12     

# Test 6: SLLI, SRLI, SRAI
addi x31, x31, 1
addi x16, x0, -4      
slli x17, x16, 2      
srli x18, x16, 2      
srai x19, x16, 2      

# Test 7: SLL, SRL, SRA
addi x31, x31, 1
addi x20, x0, 2       
sll x21, x16, x20     
srl x22, x16, x20     
sra x23, x16, x20  