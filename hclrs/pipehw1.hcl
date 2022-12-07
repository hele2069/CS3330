## Homework 
## Yiwei He yh9vhg

########## the PC and condition codes registers #############
register fF { 
    pc : 64 = 0; 
}

register cC { 
    SF : 1 = 0;
    ZF : 1 = 1;
}

register fD {
	icode : 4 = NOP;
	ifun : 4 = 0;
	valC : 64 = 0;
    rA : 4 = 0;
    rB : 4 = 0;
	Stat : 3 = STAT_AOK;
}

register dE {
	icode : 4 = NOP;
	ifun : 4 = 0;
	valA : 64 = 0;
	valB : 64 = 0;
	valC : 64 = 0;
	srcA : 4 = 0;
	srcB : 4 = 0;
	dstE : 4 = 0;
	Stat : 3 = STAT_AOK;
}

register eM {
	icode : 4 = NOP;
	valA : 64 = 0;
	valB : 64 = 0;
	valC : 64 = 0;
	valE : 64 = 0;
	srcA : 4 = 0;
	srcB : 4 = 0;
	dstE : 4 = 0;
	Stat : 3 = STAT_AOK;
}

register mW {
	icode : 4 = NOP;
	valA : 64 = 0;
	valB : 64 = 0;
	valC : 64 = 0;
	valE : 64 = 0;
	dstE : 4 = 0;
	Stat : 3 = STAT_AOK;
}

########## Fetch #############
pc = F_pc;

wire regs : 1, switch : 1, valP : 64;

f_ifun = i10bytes[0..4];
f_icode = i10bytes[4..8];

switch = f_icode in {IRMOVQ};
regs = f_icode in {IRMOVQ, RRMOVQ, OPQ, CMOVXX};

f_rA = [
	regs : i10bytes[12..16];
	1 : 0;
];

f_rB = [
	regs : i10bytes[8..12];
	1 : 0;
];

f_valC = [
	switch && regs : i10bytes[16..80];
	switch : i10bytes[8..72];
	1 : 0;
];

valP = [
	switch && regs : pc + 10;
	switch : pc + 9;
	regs : pc + 2;
	1 : pc + 1;
];

f_Stat = [
	f_icode == HALT : STAT_HLT;
	f_icode in {NOP, RRMOVQ, IRMOVQ, OPQ, CMOVXX} : STAT_AOK;
	1 : STAT_INS;
];

# register update
f_pc = [
	1 : valP;
];

stall_F = f_Stat != STAT_AOK;

########## Decode #############
d_icode = D_icode;
d_ifun = D_ifun;
d_valC = D_valC;
d_Stat = D_Stat;

reg_srcA = [
	D_icode in {RRMOVQ, OPQ, CMOVXX} : D_rA;
	1 : 0;
];
d_srcA = reg_srcA;

reg_srcB = [
	D_icode == OPQ : D_rB;
	1 : 0;
];
d_srcB = reg_srcB;

d_dstE = [
	D_icode in {IRMOVQ, RRMOVQ, OPQ, CMOVXX} : D_rB;
	1 : REG_NONE; # 0
];

d_valA = [
	(d_srcA == e_dstE) && (d_srcA != REG_NONE): e_valE;	
	(d_srcA == m_dstE) && (d_srcA != REG_NONE): m_valE;
	(d_srcA == reg_dstE) && (d_srcA != REG_NONE) : reg_inputE;
	1 : reg_outputA;
];

d_valB = [
	(d_srcB == e_dstE) && (d_srcB != REG_NONE) : e_valE;
	(d_srcB == m_dstE) && (d_srcB != REG_NONE) : m_valE;
	(d_srcB == reg_dstE) && (d_srcB != REG_NONE)  : reg_inputE;
	1 : reg_outputB;
];

########## Execute #############
e_icode = E_icode;
e_Stat = E_Stat;
e_valC = E_valC;
e_srcA = E_srcA;
e_srcB = E_srcB;

wire conditionsMet : 1, is_RRmoveq : 1, is_cmovXX : 1, is_JXX : 1;
is_RRmoveq = (E_icode == RRMOVQ && E_ifun == 0);
is_cmovXX = (E_icode == CMOVXX && E_ifun != 0);
is_JXX = (E_icode == JXX);
stall_C = (E_icode != OPQ);
c_ZF = (e_valE == 0);
c_SF = (e_valE >= 0x9000000);

e_valA = [
	1 : E_valA;
];

e_valB = [
	1 : E_valB;
];

e_valE = [
	E_icode == OPQ && E_ifun == XORQ : e_valA ^ e_valB;
	E_icode == OPQ && E_ifun == ANDQ : e_valA & e_valB;
	E_icode == OPQ && E_ifun == ADDQ : e_valA + e_valB;
	E_icode == OPQ && E_ifun == SUBQ : e_valB - e_valA;
	E_icode == IRMOVQ : e_valC;
	E_icode == RRMOVQ : e_valA;
	1 : 0;
];

e_dstE = [
	conditionsMet : REG_NONE;
	1 :	E_dstE;
];

conditionsMet = 
    is_cmovXX && (
	(E_ifun == 6  && (C_SF || C_ZF)) ||
	(E_ifun == LE && !(C_SF || C_ZF)) ||
	(E_ifun == GE && C_SF) ||
	(E_ifun == 2  && !C_SF) ||
	(E_ifun == NE && C_ZF) ||
	(E_ifun == 3  && !C_ZF ));

########## Memory #############
m_icode = M_icode;
m_valC = M_valC;
m_valE = M_valE;
m_dstE = M_dstE;
m_Stat = M_Stat;

m_valA = [
	1 : M_valA;
];

m_valB = [
	1 : M_valB;
];

########## Writeback #############

reg_inputE = [
	W_icode == RRMOVQ : W_valA;
	W_icode == IRMOVQ : W_valC;
	W_icode == OPQ : W_valE;
    1 : 0;
];

reg_dstE = [
	1: W_dstE;
];


########## PC and Status updates #############

Stat = W_Stat;