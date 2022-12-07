########## the PC and condition codes registers #############
register fF { pc:64 = 0; }

register dW {
	 icode:4 = 0;
	 regoutputA:64 = 0;
	 dstE:4 = 0;
	 valC:64 = 0;
	 Stat:3 = 0;
}


########## Fetch #############
pc = ;

wire ifun:4, rA:4, rB:4;

d_icode = i10bytes[4..8];
ifun = i10bytes[0..4];
rA = i10bytes[12..16];
rB = i10bytes[8..12];

d_valC = [
	d_icode in { JXX } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

wire offset:64, valP:64;
offset = [
	d_icode in { HALT, NOP, RET } : 1;
	d_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	d_icode in { JXX, CALL } : 9;
	1 : 10;
];

valP = [
	d_icode == HALT : F_pc;
        1 : F_pc + offset;
];


########## Decode #############

# source selection
reg_srcA = [
	d_icode in {RRMOVQ} : rA;
	1 : REG_NONE;
];

d_regoutputA = [
	reg_dstE != REG_NONE && reg_dstE == reg_srcA : reg_inputE;
	1 : reg_outputA;
];

# destination selection
d_dstE = [
	d_icode in {IRMOVQ, RRMOVQ} : rB;
	1 : REG_NONE;
];

d_Stat = [
	d_icode == HALT : STAT_HLT;
	d_icode > 0xb : STAT_INS;
	1 : STAT_AOK;
];



########## Execute #############



########## Memory #############




########## Writeback #############

reg_dstE = W_dstE;

reg_inputE = [ #we handle the "forwarding" actions (something + 0) here
	W_icode == RRMOVQ : W_regoutputA;
	W_icode in {IRMOVQ} : W_valC;
        1: 0xBADBADBAD;
];

Stat = W_Stat;

f_pc = valP;


