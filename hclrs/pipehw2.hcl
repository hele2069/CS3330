# Yiwei He (yh9vhg)

register fF {
	predPC:64 = 0;
}

register cC {
	SF:1 = 0;
	ZF:1 = 1;
}

register fD {
	stat:3 = STAT_AOK;
	icode:4 = NOP;
	ifun:4 = ALWAYS;
	rA:4 = 0;
	rB:4 = 0;
	valC:64 = 0;
	valP:64 = 0;
}

register dE {
	stat:3 = STAT_AOK;
	icode:4 = NOP;
	ifun:4 = ALWAYS;
	valA:64 = 0;
	valB:64 = 0;
	valC:64 = 0;
	srcA:4 = REG_NONE;
	srcB:4 = REG_NONE;
	dstE:4 = REG_NONE;
	dstM:4 = REG_NONE;
}

register eM {
	stat:3 = STAT_AOK;
	icode:4 = NOP;
	valA:64 = 0;
	valE:64 = 0;
	Cnd:1 = 1;
	dstE:4 = REG_NONE;
	dstM:4 = REG_NONE;
}

register mW {
	stat:3 = STAT_AOK;
	icode:4 = NOP;
	valE:64 = 0;
	valM:64 = 0;
	dstE:4 = REG_NONE;
	dstM:4 = REG_NONE;
}

########## Fetch #############
f_icode = i10bytes[4..8];
f_ifun = i10bytes[0..4];
f_rA = i10bytes[12..16];
f_rB = i10bytes[8..12];
wire offset:64;

pc = [
	M_icode == JXX && !M_Cnd : M_valA;
	W_icode == RET : W_valM;
	1 : F_predPC;
];

f_valC = [
	f_icode in { JXX, CALL } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

offset = [
	f_icode in { HALT, NOP, RET } : 1;
	f_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	f_icode in { JXX, CALL } : 9;
	1 : 10;
];
f_valP = pc + offset;

f_predPC = [
	(loadUse) || f_stat == STAT_HLT : pc;
	f_icode in { JXX, CALL } : f_valC;
	1 : f_valP;
];

f_stat = [
    f_icode == HALT : STAT_HLT;
    f_icode > 0xc : STAT_INS;
    1 : STAT_AOK;
];

########## Decode #############
d_icode = D_icode;
d_ifun = D_ifun;
d_valC = D_valC;
d_stat = D_stat;

# source selection
reg_srcA = [
    D_icode in { RMMOVQ, RRMOVQ, OPQ, PUSHQ } : D_rA;
	D_icode in { POPQ, RET } : REG_RSP;
    1 : REG_NONE;
];
d_srcA = reg_srcA;

reg_srcB = [
    D_icode in { RMMOVQ, MRMOVQ, IRMOVQ, RRMOVQ, OPQ } : D_rB;
	D_icode in { PUSHQ, POPQ, CALL, RET } : REG_RSP;
    1 : REG_NONE;
];
d_srcB = reg_srcB;

d_valA = [
	D_icode in { CALL, JXX } : D_valP;
	reg_srcA == e_dstE : e_valE;
	reg_srcA == M_dstM : m_valM;
	reg_srcA == M_dstE : M_valE;
	reg_srcA == W_dstM : W_valM;
	reg_srcA == W_dstE : W_valE;
	1 : reg_outputA;
];

d_valB = [
	reg_srcB == e_dstE : e_valE;
 	reg_srcB == M_dstM : m_valM; 
  	reg_srcB == M_dstE : M_valE;
  	reg_srcB == W_dstM : W_valM; 
  	reg_srcB == W_dstE : W_valE; 
  	1 : reg_outputB;
];

d_dstE = [
	D_icode in { IRMOVQ, RRMOVQ, OPQ } : D_rB;
	D_icode in { PUSHQ, POPQ, CALL, RET } : REG_RSP;
	1 : REG_NONE;
];

d_dstM = [
    D_icode in { MRMOVQ, POPQ } : D_rA;
    1: REG_NONE;
];

########## Execute #############
e_icode = E_icode;
e_stat = E_stat;
e_valA = E_valA;
stall_C = (E_icode != OPQ) || !(m_stat == STAT_AOK) || !(W_stat == STAT_AOK);
c_ZF = (e_valE == 0);
c_SF = (e_valE >= 0x9000000000000);

wire aluA:64, aluB:64, alufun:4;

aluA = [
	E_icode in { RRMOVQ, OPQ } : E_valA;
	E_icode in { MRMOVQ, RMMOVQ, IRMOVQ } : E_valC;
	E_icode in { PUSHQ, CALL } : -8;
	E_icode in { POPQ, RET } : 8;
	1 : 0;
];

aluB = [
	E_icode in { MRMOVQ, RMMOVQ, OPQ, PUSHQ, POPQ, CALL, RET }: E_valB;
	E_icode in { RRMOVQ, IRMOVQ } : 0;
	1 : 0;
];

alufun = [
	E_icode == OPQ : E_ifun;
	1 : ADDQ;
];

e_valE = [
	alufun == ADDQ : aluB + aluA;
	alufun == SUBQ : aluB - aluA;
	alufun == ANDQ : aluB & aluA;
	alufun == XORQ : aluB ^ aluA;
	1 : 0;
];

e_dstE = [
	E_icode == CMOVXX && !e_Cnd : REG_NONE;
	1 : E_dstE;
];
e_dstM = E_dstM;

e_Cnd = [
    E_ifun == ALWAYS : 1;
    E_ifun == LE : C_ZF || C_SF;
    E_ifun == LT : C_SF;
    E_ifun == EQ : C_ZF;
    E_ifun == NE : !C_ZF;
    E_ifun == GE : C_ZF || !C_SF;
    E_ifun == GT : !C_SF && !C_ZF;
    1 : 0;
];

########## Memory #############
m_stat = M_stat;
m_icode = M_icode;
m_valE = M_valE;
m_valM = mem_output;
m_dstE = M_dstE;
m_dstM = M_dstM;

mem_readbit = M_icode in { MRMOVQ, POPQ, RET };
mem_writebit = M_icode in { RMMOVQ, PUSHQ, CALL };
mem_input = M_valA;

mem_addr = [
    M_icode in { MRMOVQ, RMMOVQ, PUSHQ, CALL } : M_valE;
	M_icode in { POPQ, RET } : M_valA;
    1: 0x99999999;
];

########## Writeback #############
reg_dstE = [
    W_icode in { IRMOVQ, RRMOVQ, OPQ, PUSHQ, POPQ, CALL, RET } : W_dstE;
    1 : REG_NONE;
];
reg_dstM = W_dstM;

reg_inputE = [
	W_icode in { IRMOVQ, RRMOVQ, OPQ, PUSHQ, POPQ, CALL, RET } : W_valE;
    1: 0x99999999;
];

reg_inputM = [
    W_icode in { MRMOVQ, POPQ } : W_valM;
    1: 0x99999999;
];

########## PC and Status updates #############
Stat = [
	W_stat == STAT_BUB : STAT_AOK;
	1 : W_stat;
];

wire processing:1, loadUse:1, mispred:1;
processing = (RET in {D_icode, E_icode, M_icode});
loadUse = (E_icode in {MRMOVQ, POPQ}) && (E_dstM in {d_srcA, d_srcB});
mispred = (E_icode == JXX && !e_Cnd);

stall_F = processing;
stall_D = loadUse;

bubble_D = (processing && !loadUse) || mispred;
bubble_E = (loadUse || mispred);