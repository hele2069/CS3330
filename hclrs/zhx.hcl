/** Haoxiang Zhang (hz4tt)*/
########## the PC and condition codes registers #############
register fF {
	 predPC:64 = 0;
}

register fD {
	 stat : 3 = STAT_BUB;
	 icode : 4 = NOP;
	 ifun : 4 = ALWAYS;
	 rA : 4 = REG_NONE;
	 rB : 4 = REG_NONE;
	 valC : 64 = 0;
	 valP : 64 = 0;
}

register dE {
	 stat : 3 = STAT_BUB;
	 icode : 4 = NOP;
	 ifun : 4 = ALWAYS;
	 valC : 64 = 0;
	 dstE : 4 = REG_NONE;
	 dstM : 4 = REG_NONE;
	 rvalA : 64 = 0;
	 rvalB : 64 = 0;
	 valP : 64 = 0;
}

register eM {
	 stat : 3 = STAT_BUB;
	 icode : 4 = NOP;
	 dstE : 4 = REG_NONE;
	 dstM : 4 = REG_NONE;
	 valE : 64 = 0;
	 rvalA : 64 = 0;
	 valP : 64 = 0;
	 SF:1 = 0;
	 ZF:1 = 0;
	 mispredict : 1 = 0;
}

register mW {
	 stat : 3 = STAT_BUB;
	 icode : 4 = NOP;
	 dstE : 4 = REG_NONE;
	 dstM : 4 = REG_NONE;
	 valE : 64 = 0;
	 valM : 64 = 0;
}

register cC {
	 SF:1 = 0;
	 ZF:1 = 0;
}

########## Fetch #############
pc = [
	M_mispredict : M_valP;
	W_icode == RET : W_valM;
	1 : F_predPC;
];

f_icode = i10bytes[4..8];
f_ifun = i10bytes[0..4];
f_rA = i10bytes[12..16];
f_rB = i10bytes[8..12];
 
f_valC = [
        f_icode in { JXX, CALL } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

wire offset:64;
offset = [
	f_icode in { HALT, NOP, RET } : 1;
	f_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	f_icode in { JXX, CALL } : 9;
	1 : 10;
];

f_valP = [
       f_icode in {JXX, CALL}: pc + offset;
       W_icode == RET : W_valM + offset;
       1:F_predPC + offset;
];
f_stat = [
	f_icode == HALT : STAT_HLT;
	f_icode > 0xb : STAT_INS;
	1 : STAT_AOK;
];


########## Decode #############

d_stat = D_stat;
d_icode = D_icode;
d_ifun = D_ifun;
d_valC = D_valC;
d_valP = D_valP;

# source selection
reg_srcA = [
	 d_icode in {RRMOVQ, OPQ, RMMOVQ, PUSHQ, POPQ}: D_rA;
	 1 : REG_NONE;
];

reg_srcB = [
	 d_icode in {OPQ, RMMOVQ, MRMOVQ}: D_rB;
	 d_icode in {PUSHQ, POPQ, CALL, RET} : REG_RSP;
	 1: REG_NONE;
];

d_rvalA = [
	reg_srcA == REG_NONE: 0;
	reg_srcA == e_dstE : e_valE;
	reg_srcA == m_dstE : m_valE;
	reg_srcA == m_dstM : m_valM; # forward post-memory
	reg_srcA == W_dstE : W_valE;
	reg_srcA == W_dstM : W_valM; # forward pre-writeback
	1 : reg_outputA;
];

d_rvalB = [
	reg_srcB == REG_NONE: 0;
	reg_srcB == e_dstE : e_valE;
	reg_srcB == m_dstM : m_valM; # forward post-memory
	reg_srcB == m_dstE : m_valE;
	reg_srcB == W_dstM : W_valM; # forward pre-writeback
	reg_srcB == W_dstE : W_valE;
	1 : reg_outputB;
];

# destination selection
d_dstE = [
       d_icode in {IRMOVQ, RRMOVQ, OPQ}: D_rB;
       D_icode in { PUSHQ, POPQ, CALL, RET} : REG_RSP;
       1 : REG_NONE;
];

d_dstM = [
	D_icode in { MRMOVQ, POPQ } : D_rA;
	1 : REG_NONE;
];


########## Execute #############

e_stat = E_stat;
e_icode = E_icode;
e_dstM = E_dstM;
e_rvalA = E_rvalA;
e_valP = E_valP;

e_dstE = [
       E_icode == CMOVXX && !conditionsMet : REG_NONE;
       1 : E_dstE;
];

e_valE = [
	 e_icode == OPQ && E_ifun == ADDQ : E_rvalA + E_rvalB;
	 e_icode == OPQ && E_ifun == SUBQ : E_rvalB - E_rvalA;
	 e_icode == OPQ && E_ifun == ANDQ : E_rvalA & E_rvalB;
	 e_icode == OPQ && E_ifun == XORQ : E_rvalA ^ E_rvalB;
         e_icode in {IRMOVQ} : E_valC;
         e_icode in {RRMOVQ} : E_rvalA;
	 e_icode in {RMMOVQ, MRMOVQ}: E_rvalB + E_valC;
	 e_icode in {CALL, PUSHQ}: E_rvalB - 8;
	 e_icode in {RET, POPQ}: E_rvalB + 8;
	 1 : 0x0;
];

c_ZF = (e_valE == 0);
c_SF = (e_valE >= 0x8000000000000000);
stall_C = (e_icode != OPQ);
e_ZF = c_ZF;
e_SF = c_SF;

wire conditionsMet:1;

conditionsMet = [
	 E_ifun == ALWAYS : true;
	 E_ifun == LE : C_SF || C_ZF;
	 E_ifun == LT : C_SF; 
	 E_ifun == EQ : C_ZF;
	 E_ifun == NE : !C_ZF;
	 E_ifun == GE : !C_SF;
	 E_ifun == GT : !C_SF && !C_ZF;
	 1 : false;
];

e_mispredict = [
	 !conditionsMet && e_icode == JXX : 1;
	 1 : 0;
];

########## Memory #############

m_stat = M_stat;
m_icode = M_icode;
m_dstE = M_dstE;
m_valE = M_valE;
m_dstM = M_dstM;
m_valM = mem_output;

mem_addr = [ # output to memory system
	M_icode in { RMMOVQ, MRMOVQ, PUSHQ, CALL} : M_valE;
	M_icode in {POPQ,RET} : M_valE - 8;
	1 : 0; # Other instructions don't need address
];
mem_readbit =  M_icode in { MRMOVQ, POPQ, RET }; # output to memory system
mem_writebit = M_icode in { RMMOVQ, PUSHQ, CALL}; # output to memory system
mem_input = [
	  M_icode in {CALL} : M_valP; 
	  1:M_rvalA;
];

########## Writeback #############

reg_dstE = W_dstE;
reg_inputE = W_valE;
reg_dstM = W_dstM;
reg_inputM = W_valM;

########## PC and Status updates #############


Stat = W_stat;

wire loadUse : 1, return : 1;
loadUse = (E_icode in {MRMOVQ, POPQ, RET}) && (E_dstM in {reg_srcA, reg_srcB}); 
return = D_icode==RET || E_icode==RET || M_icode==RET;

stall_F = !e_mispredict && (loadUse || f_stat != STAT_AOK || return);

stall_D = loadUse;
bubble_D = !loadUse && (e_mispredict || return);

bubble_E = e_mispredict || loadUse;


f_predPC = [
	 e_mispredict : e_valP;
	 f_icode == HALT : F_predPC;
	 f_icode in {JXX, CALL} : f_valC;
	 1 : f_valP;
];
