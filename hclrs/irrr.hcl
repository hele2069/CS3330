# An example file in our custom HCL variant, with lots of comments

register pP {  
    # our own internal register. P_pc is its output, p_pc is its input.
	pc:64 = 0; # 64-bits wide; 0 is its default value.
	
	# we could add other registers to the P register bank
	# register bank should be a lower-case letter and an upper-case letter, in that order.
	
	# there are also two other signals we can optionally use:
	# "bubble_P = true" resets every register in P to its default value
	# "stall_P = true" causes P_pc not to change, ignoring p_pc's value
} 

register cC {
	SF : 1 = 0;
	ZF : 1 = 1; 
}

c_ZF = [
	icode == OPQ : (valE == 0); 
	1 : C_ZF;
];

c_SF = [
	icode == OPQ : (valE >= 0x8000000000000000);
	1 : C_SF; 
];

# "pc" is a pre-defined input to the instruction memory and is the 
# address to fetch 10 bytes from (into pre-defined output "i10bytes").
pc = P_pc;

# we can define our own input/output "wires" of any number of 0<bits<=80
wire opcode:8, icode:4;
wire valC : 64;
wire rA : 4;
wire rB : 4; 
wire jXX : 64;
wire valE : 64;
wire ifun : 4; 
wire conditionsMet : 1; 

# the x[i..j] means "just the bits between i and j".  x[0..1] is the 
# low-order bit, similar to what the c code "x&1" does; "x&7" is x[0..3]
opcode = i10bytes[0..8];   # first byte read from instruction memory
icode = opcode[4..8];      # top nibble of that byte
rB = i10bytes[8..12];
rA = i10bytes[12..16];
valC = i10bytes[16..80];
jXX = i10bytes[8..72];
reg_srcB = rB; 
ifun = opcode[0..4];

/* we could also have done i10bytes[4..8] directly, but I wanted to
 * demonstrate more bit slicing... and all 3 kinds of comments      */
// this is the third kind of comment

# named constants can help make code readable
const TOO_BIG = 0xC; # the first unused icode in Y86-64

# some named constants are built-in: the icodes, ifuns, STAT_??? and REG_???


# Stat is a built-in output; STAT_HLT means "stop", STAT_AOK means 
# "continue".  The following uses the mux syntax described in the 
# textbook
Stat = [
	icode == HALT : STAT_HLT;
	icode > 7 : STAT_INS; 
	1             : STAT_AOK;
];

# let's also read and write a register in the register file; to do that we
# first pick a register to read
reg_srcA = rA;
# and a register to write; in this case the same one
reg_dstE = [
	icode == 3 : rB;
	icode == 2 : rB;
	1 : 0xF; 
];

# and a value to write.  Let's decide what to do based on the ifun
reg_inputE = [
	icode == IRMOVQ : valC; 
	icode == RRMOVQ : reg_outputA; 
	1 : 0; 
];

valE = [
	icode == 6 && ifun == 0 : reg_outputA + reg_outputB;
	icode == 6 && ifun == 1 : reg_outputB - reg_outputA;
	icode == 6 && ifun == 2 : reg_outputA & reg_outputB;
	icode == 6 && ifun == 3 : reg_outputA ^ reg_outputB;
	icode == 4 : reg_outputB + valC;
	1 : 0; 
]; 

conditionsMet = [
	ifun == 0 : 1; 
	ifun == 1 : C_SF || C_ZF; 
	ifun == 2 : C_SF == 1; 
	ifun == 3 : C_ZF == 1;
	ifun == 4 : C_ZF == 0;
	ifun == 5 : C_SF == 0 || C_ZF;
	ifun == 6 : C_SF == 0 && C_ZF == 0; 
	1 : 0; 
];


# to make progress, we have to update the PC...
p_pc = [
	icode == 1 : P_pc + 1; 
	icode == 3 : P_pc + 10; 
	icode == 2 : P_pc + 2; 
	icode == 4 : P_pc + 10; 
	icode == 7 : jXX; 
	icode == 6 : P_pc + 2; 
	1 : P_pc + 1; 
]; # you may use math ops directly...
