######### The PC #############
register pP { 
	pc : 64 = 0; 
	predPC : 64 = 0;
}

register cC { 
    SF : 1 = 0;
    ZF : 1 = 1;
}

register fD {
	icode : 4 = NOP;
	ifun : 4 = 0;
	valC : 64 = 0;
	valP : 64 = 0;
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
	valP : 64 = 0;
    rA : 4 = 0;
    rB : 4 = 0;
	srcA : 4 = 0;
	srcB : 4 = 0;
	dstM : 4 = REG_NONE;
	dstE : 4 = REG_NONE;
	Stat : 3 = STAT_AOK;
}

register eM {
	icode : 4 = NOP;
	ifun : 4 = 0;
	valA : 64 = 0;
	valB : 64 = 0;
	valC : 64 = 0;
	valP : 64 = 0;
	valE : 64 = 0;
	Cnd : 1 = 0;
	srcA : 4 = 0;
	srcB : 4 = 0;
	dstM : 4 = REG_NONE;
	dstE : 4 = REG_NONE;
	Stat : 3 = STAT_AOK;
}

register mW {
	icode : 4 = NOP;
	ifun : 4 = 0;
	valA : 64 = 0;
	valB : 64 = 0;
	valC : 64 = 0;
	valE : 64 = 0;
	valM : 64 = 0;
	dstM : 4 = REG_NONE;
	dstE : 4 = REG_NONE;
	Stat : 3 = STAT_AOK;
}

########## Fetch #############
wire cnd : 1, loadUse : 1, regs : 1, switch : 1;

cnd = M_icode == JXX && M_ifun != 0 && M_Cnd == 0;
loadUse = (E_icode == MRMOVQ && (E_dstM in {d_srcA, d_srcB}));

f_icode = i10bytes[4..8];
f_ifun = i10bytes[0..4];

regs = f_icode in {RRMOVQ, IRMOVQ, OPQ, CMOVXX, RMMOVQ, MRMOVQ, PUSHQ, POPQ};
switch = f_icode in {IRMOVQ, RMMOVQ, MRMOVQ, JXX, CALL};

f_rA = [
	regs : i10bytes[12..16];
	1 : 0;
];

f_rB = [
	f_icode in {PUSHQ, POPQ, CALL, RET} : REG_RSP;
	regs : i10bytes[8..12];
	1 : 0;
];

f_valC = [
	switch && regs : i10bytes[16..80];
	switch : i10bytes[8..72];
	1 : 0;
];


f_valP = [
	switch && regs : pc + 10;
	switch : pc + 9;
	regs : pc + 2;
	1 : pc + 1;
];

pc = [
	cnd : P_pc;
	W_icode == RET : W_valM;
	1 : P_predPC;
];

f_Stat = [
	f_icode == HALT  :  STAT_HLT;
	f_icode > 0xb  :  STAT_INS;
	p_pc > 0xfff  :  STAT_ADR;
	1  :  STAT_AOK;
];

p_pc = [
	f_icode == JXX && (f_ifun != 0)  :  f_valP;
	1  :  P_pc;
];
p_predPC = [
	f_icode in {JXX, CALL}  :  f_valC;
	f_icode == HALT  :  pc;
	1  :  f_valP;
];

wire popqloadUse : 1;
popqloadUse = (E_icode == POPQ && (E_rA == d_srcA || E_rA == d_srcB));

stall_P = loadUse 
			|| (f_Stat != STAT_AOK && f_Stat != STAT_HLT)
		    || (!cnd && (D_icode == RET || E_icode == RET || M_icode == RET));


########## Decode #############

stall_D = loadUse || popqloadUse;
bubble_D = ((!cnd && (D_icode == RET || E_icode == RET || M_icode == RET)) && !loadUse && !popqloadUse);


d_icode = D_icode;
d_ifun = D_ifun;
d_valC = D_valC;
d_valP = D_valP;
d_rA = D_rA;
d_rB = D_rB;
d_Stat = D_Stat;

reg_srcA = [
	D_icode in {RMMOVQ, RRMOVQ, OPQ, CMOVXX, PUSHQ}  :  D_rA;
	1  :  REG_NONE;
];
reg_srcB = [
	D_icode in {RMMOVQ, MRMOVQ, OPQ, PUSHQ, POPQ, CALL, RET}  :  D_rB;
	1  :  REG_NONE;
];
d_dstM = [ 
	D_icode in {POPQ, MRMOVQ}  :  D_rA;
	D_icode in {IRMOVQ, RRMOVQ, OPQ, CMOVXX}  :  D_rB;
	1 :  REG_NONE;
];
d_dstE = [ 
	D_icode in {PUSHQ, POPQ, CALL, RET}  :  D_rB;
	1 :  REG_NONE;
];

d_valA = [
	reg_srcA == REG_NONE  :  0;
	reg_srcA == e_dstE  :  e_valE;
	reg_srcA == e_dstM && e_icode != POPQ  :  e_valE;
	M_icode == MRMOVQ && reg_srcA == m_dstM  :  m_valM;
	W_icode == MRMOVQ && reg_srcA == W_dstM  :  W_valM;
	reg_srcA == m_dstE  :  m_valE;
	reg_srcA == m_dstM  :  m_valE;
	reg_srcA == reg_dstE  :  reg_inputE;
	reg_srcA == reg_dstM  :  reg_inputM;
	1  :  reg_outputA;
];
d_valB = [
	reg_srcB == REG_NONE  :  0;
	reg_srcB == e_dstE  :  e_valE;
	reg_srcB == e_dstM  :  e_valE;
	M_icode == MRMOVQ && reg_srcB == m_dstM  :  m_valM;
	W_icode == MRMOVQ && reg_srcB == W_dstM  :  W_valM;
	reg_srcB == m_dstE  :  m_valE;
	reg_srcB == m_dstM  :  m_valE;
	reg_srcB == reg_dstE  :  reg_inputE;
	reg_srcB == reg_dstM  :  reg_inputM;
	1  :  reg_outputB;
];

d_srcA = reg_srcA;
d_srcB = reg_srcB;

########## Execute #############

bubble_E = loadUse || (M_icode == JXX && M_ifun != 0 && M_Cnd == 0)
			|| (E_icode == RET || M_icode == RET);

e_icode = E_icode;
e_ifun = E_ifun;
e_Stat = E_Stat;
e_valC = E_valC;
e_valP = E_valP;
e_srcA = E_srcA;
e_srcB = E_srcB;
e_valA = E_valA;
e_valB = E_valB;

wire operand1 : 64, operand2 : 64;

operand1 = [
	e_icode in { MRMOVQ, RMMOVQ, IRMOVQ }  :  e_valC;
	e_icode in { OPQ, RRMOVQ }  :  e_valA;
	e_icode in { PUSHQ, POPQ ,CALL, RET }  :  e_valB;
	1 :  0;
];
operand2 = [
	e_icode in { MRMOVQ, RMMOVQ, OPQ}  :  e_valB;
	e_icode in { PUSHQ, POPQ, CALL, RET }  :  8;
	1 :  0;
];

e_valE = [
	E_icode in { MRMOVQ, RMMOVQ }  :  operand1 + operand2;
	E_icode == OPQ && E_ifun == XORQ  :  operand1 ^ operand2;
	E_icode == OPQ && E_ifun == ANDQ  :  operand1 & operand2;
	E_icode == OPQ && E_ifun == ADDQ  :  operand1 + operand2;
	E_icode == OPQ && E_ifun == SUBQ  :  operand2 - operand1;
	E_icode == IRMOVQ  :  operand1;
	E_icode == RRMOVQ  :  operand1;
	E_icode == PUSHQ  :  operand1 - operand2;
	E_icode == POPQ  :  operand1 + operand2;
	E_icode == CALL  :  operand1 - operand2;
	E_icode == RET  :  operand1 + operand2;
	1  :  0;
];

stall_C = (E_icode != OPQ);
c_ZF = (e_valE == 0);
c_SF = (e_valE >= 0x8000000000000000);

wire conditionsNotMet :  1, isRRmovq : 1, iscmovXX : 1, isJXX : 1;
isRRmovq = E_icode == RRMOVQ && E_ifun == 0;
iscmovXX = E_icode == CMOVXX && E_ifun != 0;
isJXX	 = E_icode == JXX && E_ifun != 0;

conditionsNotMet = [
	(iscmovXX && E_ifun == LE && (!C_SF && !C_ZF)) :  1;
	(iscmovXX && E_ifun == GE && C_SF)  :  1;
	(iscmovXX && E_ifun == 3  && !C_ZF )  :  1; # E not defined, use 3
	(iscmovXX && E_ifun == 6  && (C_SF || C_ZF))  :  1;	# G -- 6
	(iscmovXX && E_ifun == 2  && !C_SF)  :  1 ; # L -- 2
	(iscmovXX && E_ifun == NE && C_ZF)  :  1;
	(isJXX && E_ifun == LE && (!C_SF && !C_ZF)) :  1;
	(isJXX && E_ifun == GE && C_SF)  :  1;
	(isJXX && E_ifun == 3  && !C_ZF )  :  1; # E not defined, use 3
	(isJXX && E_ifun == 6  && (C_SF || C_ZF))  :  1;	# G -- 6
	(isJXX && E_ifun == 2  && !C_SF)  :  1 ; # L -- 2
	(isJXX && E_ifun == NE && C_ZF)  :  1;
	1  :  0;
];
e_Cnd = [
	isJXX  :  !conditionsNotMet;
	1  :  M_Cnd;
];
e_dstM = [
	iscmovXX && conditionsNotMet  :  REG_NONE;
	1  :  E_dstM;
];
e_dstE = E_dstE;

########## Memory #############
bubble_M = (M_icode == JXX && M_ifun != 0 && M_Cnd == 0) || (M_icode == RET);

m_icode = M_icode;
m_ifun = M_ifun;

m_valC = M_valC;
m_valE = M_valE;
m_valA = M_valA;
m_valB = M_valB;

m_dstM = M_dstM;
m_dstE = M_dstE;
m_Stat = M_Stat;

mem_readbit = m_icode in { MRMOVQ, POPQ, RET };
mem_writebit = m_icode in { RMMOVQ, PUSHQ, CALL };
mem_addr = [
	m_icode in { MRMOVQ, RMMOVQ, PUSHQ, CALL }  :  m_valE;
	m_icode in { POPQ, RET }  :  m_valB;
	1 : 0;
];
mem_input = [
	m_icode in { RMMOVQ, PUSHQ }  :  m_valA;
	m_icode in { CALL }  :  M_valP;
	1 : 0;
];
m_valM = [
	m_icode in {MRMOVQ, POPQ, RET}  :  mem_output;
	1  :  0;
];


########## Writeback #############
reg_dstM = [
	1  :  W_dstM;
];
reg_inputM = [
	W_icode in {MRMOVQ, POPQ}  :  W_valM;
	W_icode == RRMOVQ  :  W_valA;
	W_icode in {IRMOVQ}  :  W_valC;
	W_icode in {OPQ}  :  W_valE;
	1 : 0;
];

reg_inputE = [
	W_icode in { PUSHQ, POPQ, CALL, RET }  :  W_valE;
	1  :  0;
];

reg_dstE = [
	W_icode in { PUSHQ, POPQ, CALL, RET } && W_dstE != W_dstM  :  W_dstE;
	1  :  REG_NONE;
];

Stat = W_Stat;
