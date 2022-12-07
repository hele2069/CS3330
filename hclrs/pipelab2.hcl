# Yiwei He, yh9vhg; Da Lin, dl2de

######### The PC #############
register fF { pc:64 = 0; }


########## Fetch #############
pc = F_pc;

f_icode = i10bytes[4..8];
f_ifun = i10bytes[0..4];
f_rA = i10bytes[12..16];
f_rB = i10bytes[8..12];

f_valC = [
    f_icode in { JXX } : i10bytes[8..72];
    1 : i10bytes[16..80];
];

wire offset:64, valP:64;
offset = [
    f_icode in { HALT, NOP, RET } : 1;
    f_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
    f_icode in { JXX, CALL } : 9;
    1 : 10;
];
valP = F_pc + offset;

########## Decode #############

register fD {
    icode : 4 = NOP;
    ifun : 4 = 0;
    rA : 4 = REG_NONE;
    rB : 4 = REG_NONE;
    valC : 64 = 0;
}

reg_srcA = [
    d_icode == RMMOVQ : D_rA;
    1 : REG_NONE;
];
reg_srcB = [
    d_icode in {RMMOVQ, MRMOVQ} : D_rB;
    1 : REG_NONE;
];


d_valA = [
    reg_srcA == REG_NONE : 0;
    reg_srcA == m_dstM : m_valM;
    reg_srcA == W_dstM : W_valM;
    1: reg_outputA;
];

d_valB = [
    reg_srcB == REG_NONE : 0;
    reg_srcB == m_dstM : m_valM;
    reg_srcB == W_dstM : W_valM;
    1: reg_outputB;
];

d_dstM = [
    d_icode == MRMOVQ : D_rA;
    1: REG_NONE;
];


wire loadUse:1;

loadUse = [
    E_dstM in {reg_srcA, reg_srcB} && e_icode == MRMOVQ: 1;
    1 : 0;
];
/* keep the PC the same next cycle */
stall_F = loadUse;  /* or add a MUX for f_pc */
    
/* keep same instruction in decode next cycle */
stall_D = loadUse;
    
/* send nop to execute next cycle */
bubble_E = loadUse;

d_icode = D_icode;
d_ifun = D_ifun;
d_valC = D_valC;

########## Execute #############

register dE {
    icode : 4 = NOP;
    ifun : 4 = 0;
    valA : 64 = 0;
    valB : 64 = 0;
    valC : 64 = 0;
    dstM : 4 = REG_NONE;
}

wire operand1:64, operand2:64;

operand1 = [
    e_icode in { MRMOVQ, RMMOVQ } : E_valC;
    1: 0;
];
operand2 = [
    e_icode in { MRMOVQ, RMMOVQ } : e_valB;
    1: 0;
];

#wire valE:64;

e_valE = [
    e_icode in { MRMOVQ, RMMOVQ } : operand1 + operand2;
    1 : 0;
];

e_icode = E_icode;
e_ifun = E_ifun;
e_valA = E_valA;
e_valB = E_valB;
e_dstM = E_dstM;


########## Memory #############

register eM {
    icode : 4 = NOP;
    ifun : 4 = 0;
    valA : 64 = 0;
    valB : 64 = 0;
    valE : 64 = 0;
    dstM : 4 = REG_NONE;
}


mem_readbit = m_icode in { MRMOVQ };
mem_writebit = m_icode in { RMMOVQ };
mem_addr = [
    m_icode in { MRMOVQ, RMMOVQ } : M_valE;
        1: 0xBADBADBAD;
];
mem_input = [
    m_icode in { RMMOVQ } : m_valA;
        1: 0xBADBADBAD;
];

m_valM = [
    m_icode in {MRMOVQ} : mem_output;
        1: 0xBADBADBAD;
];

m_icode = M_icode;
m_ifun = M_ifun;
m_valA = M_valA;
m_valB = M_valB;
m_valE = M_valE;
m_dstM = M_dstM;

########## Writeback #############

register mW {
    icode : 4 = NOP;
    ifun : 4 = 0;
    valA : 64 = 0;
    valB : 64 = 0;
    valE : 64 = 0;
    valM : 64 = 0;
    dstM : 4 = 0;
}

reg_dstM = [ 
    W_icode == MRMOVQ : W_dstM;
    1: REG_NONE;
];
reg_inputM = W_valM;


Stat = [
    W_icode == HALT : STAT_HLT;
    W_icode > 0xb : STAT_INS;
    1 : STAT_AOK;
];

f_pc = valP;



