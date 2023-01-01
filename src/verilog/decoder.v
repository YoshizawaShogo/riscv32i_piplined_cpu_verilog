`include "define.vh"

module DECODER (
    input wire [31:0] inst,
    output wire [31:0] imm,
    output wire [4:0] rs1_addr, rs2_addr, rd_addr,
    output wire [4:0] alu_fn,
    output wire mem_wen,
    output wire [1:0] wb_sel,
    output wire [1:0] rs1,
    output wire [1:0] rs2,
    output wire [2:0] br,
    output wire ecall
);

// 内部信号
wire [6:0] opcode;
assign opcode = inst[6:0];

assign rs1_addr = inst[19:15];
assign rs2_addr = inst[24:20];
assign rd_addr = inst[11:7];

// 即値の扱い方 risc-v ISA manual参照(P.24)
assign imm = (opcode == `IMM_LUI || opcode == `IMM_AUIPC) ? {inst[31:12], 12'd0} : // U-format
             (opcode == `IMM_JAL) ? {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'd0} : // J-format
             (opcode == `IMM_JALR || opcode == `IMM_LOAD || opcode == `IMM_OPIMI) ? {{20{inst[31]}},inst[31],inst[30:25],inst[24:21],inst[20]} : // I-format
             (opcode == `IMM_BRANCH) ? {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'd0} : //B-format
             (opcode == `IMM_STORE) ? {{20{inst[31]}},inst[31],inst[30:25],inst[11:8],inst[7]} : 32'd0;// ? S-format : R-format(即値なし)

function [14:0] parse;
    input [31:0] inst;
    casex (inst) //    ALU_fn,    ALU_src1, ALU_src2, MEM_fn,  WB_select, branch, ecall
    `LW    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_MEM, `BR_X   , `ECALL_N };
    `SW    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_S, `WB_X  , `BR_X   , `ECALL_N };
    `ADD   : parse = {`ALU_ADD,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `ADDI  : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SUB   : parse = {`ALU_SUB,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `AND   : parse = {`ALU_AND,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `OR    : parse = {`ALU_OR,   `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `XOR   : parse = {`ALU_XOR,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `ANDI  : parse = {`ALU_AND,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `ORI   : parse = {`ALU_OR,   `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `XORI  : parse = {`ALU_XOR,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLL   : parse = {`ALU_SLL,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SRL   : parse = {`ALU_SRL,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SRA   : parse = {`ALU_SRA,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLLI  : parse = {`ALU_SLL,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SRLI  : parse = {`ALU_SRL,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SRAI  : parse = {`ALU_SRA,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLT   : parse = {`ALU_SLT,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLTU  : parse = {`ALU_SLTU, `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLTI  : parse = {`ALU_SLT,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `SLTIU : parse = {`ALU_SLTU, `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `BEQ   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BEQ , `ECALL_N };
    `BNE   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BNE , `ECALL_N };
    `BLT   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BLT , `ECALL_N };
    `BGE   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BGE , `ECALL_N };
    `BLTU  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BLTU, `ECALL_N };
    `BGEU  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BGEU, `ECALL_N };
    `JAL   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_PC , `BR_JAL , `ECALL_N };
    `JALR  : parse = {`ALU_JALR, `RS1_RS1, `RS2_IMI, `MEN_X, `WB_PC , `BR_JAL , `ECALL_N };
    `LUI   : parse = {`ALU_ADD,  `RS1_X,   `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `AUIPC : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N };
    `ECALL : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_Y };
    default: parse = {`ALU_X,    `RS1_X,   `RS2_X,   `MEN_X, `WB_X  , `BR_X   , `ECALL_N };
    endcase
endfunction

assign {alu_fn, rs1, rs2, mem_wen, wb_sel, br, ecall} = parse(inst);
endmodule