# An example file in our custom HCL variant, with lots of comments

register pP {  
 pc:64 = 0; # 64-bits wide; 0 is its default value.
} 

# "pc" is a pre-defined input to the instruction memory and is the 
# address to fetch 10 bytes from (into pre-defined output "i10bytes").
pc = P_pc;

# we can define our own input/output "wires" of any number of 0<bits<=80
wire opcode:8, icode:4;

# the x[i..j] means "just the bits between i and j".  x[0..1] is the 
# low-order bit, similar to what the c code "x&1" does; "x&7" is x[0..3]
opcode = i10bytes[0..8];   # first byte read from instruction memory
icode = opcode[4..8];      # top nibble of that byte
ifun = opcode[0..4];

rA = i10bytes[12..16];
rB = i10bytes[8..12];
valC = i10bytes[16..80];
jXX = i10bytes[8..72];


/* we could also have done i10bytes[4..8] directly, but I wanted to
 * demonstrate more bit slicing... and all 3 kinds of comments      */
// this is the third kind of comment

# named constants can help make code readable
const TOO_BIG = 0xC; # the first unused icode in Y86-64

# some named constants are built-in: the icodes, ifuns, STAT_??? and REG_???
wire valE : 64;
wire rA : 4;
wire rB : 4;
wire valC : 64; 
wire jXX : 64;
wire ifun : 4;
wire conditionsMet : 1;

# Stat is a built-in output; STAT_HLT means "stop", STAT_AOK means 
# "continue".  The following uses the mux syntax described in the 
# textbook
Stat = [
    icode == HALT : STAT_HLT;
    icode >TOO_BIG : STAT_INS;
 1             : STAT_AOK;
];

reg_srcA = rA;
reg_srcB = rB;

# and a register to write; in this case the same one
reg_dstE = [
    icode == 3 : rB;
    icode == 2 && conditionsMet: rB;
    icode == 6 : rB;
    1: 0xF;
];
# and a value to write.  Let's decide what to do based on the ifun
reg_inputE = [
    icode == 3 : valC;
    icode == 2 : reg_outputA;
    icode == 6 : valE;
    icode == 4 : mem_input;
    1: 0;
];

register cC {
     SF:1 = 0;
     ZF:1 = 1;
}

c_ZF = [
    icode == OPQ : (valE == 0);
    1 : C_ZF;
];
c_SF = [
    icode == OPQ : (valE >= 0x8000000000000000);
    1 : C_SF;
];

mem_readbit=[
    icode == 4 : 0;
    1:1;
];

 mem_writebit=[
     icode == 4 : 1;
     1:0;
 ];

 mem_input=[
     icode == 4 : reg_outputA;
     1:0; 
 ];

 mem_addr=[
     icode ==4 : valE;
     1:0;
 ];

valE = [
    icode == 6 && ifun == 0: reg_outputA+reg_outputB;
    icode == 6 && ifun == 1: reg_outputB-reg_outputA;
    icode == 6 && ifun == 2: reg_outputA&reg_outputB;
    icode == 6 && ifun == 3: reg_outputA^reg_outputB;
    icode == 4 : reg_outputB+valC;
    1:0;
];

conditionsMet = [
    ifun == 0 : 1;
    ifun == 1 : C_SF || C_ZF; #LE
    ifun == 2 : C_SF == 1; #L
    ifun == 3 : C_ZF == 1; #E
    ifun == 4 : C_ZF == 0; #NE
    ifun == 5 : C_SF == 0 || C_ZF; #GE
    ifun == 6 : C_SF == 0 && C_ZF == 0; #G
    1: 0;
];


p_pc = [
 icode == 1 : P_pc+1;
 icode == 2  : P_pc+2;
 icode == 3 : P_pc+10;
 icode == 4 : P_pc+10;
 icode == RMMOVQ : P_pc+10;
 icode == MRMOVQ : 10;
 icode == OPQ  : P_pc+2;
 icode == JXX  : jXX;
 icode == CALL  : 9;
 icode == RET  : 1;
 icode == PUSHQ  : 2;
 icode == POPQ  : 2;
 icode == CMOVXX : 2;
 1        : P_pc+1 ;
];