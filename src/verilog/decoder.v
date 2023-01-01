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
wire [2:0] imm_type;

assign rs1_addr = inst[19:15];
assign rs2_addr = inst[24:20];
assign rd_addr = inst[11:7];


function [17:0] parse;
    input [31:0] inst;
    casex (inst) //    ALU_fn,    ALU_src1, ALU_src2, MEM_fn,  WB_select, branch, ecall
    `LW    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_MEM, `BR_X   , `ECALL_N, `IMM_I };
    `SW    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_S, `WB_X  , `BR_X   , `ECALL_N, `IMM_S };
    `ADD   : parse = {`ALU_ADD,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `ADDI  : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SUB   : parse = {`ALU_SUB,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `AND   : parse = {`ALU_AND,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `OR    : parse = {`ALU_OR,   `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `XOR   : parse = {`ALU_XOR,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `ANDI  : parse = {`ALU_AND,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `ORI   : parse = {`ALU_OR,   `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `XORI  : parse = {`ALU_XOR,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SLL   : parse = {`ALU_SLL,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SRL   : parse = {`ALU_SRL,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `SRA   : parse = {`ALU_SRA,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `SLLI  : parse = {`ALU_SLL,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SRLI  : parse = {`ALU_SRL,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SRAI  : parse = {`ALU_SRA,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SLT   : parse = {`ALU_SLT,  `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `SLTU  : parse = {`ALU_SLTU, `RS1_RS1, `RS2_RS2, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_X };
    `SLTI  : parse = {`ALU_SLT,  `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `SLTIU : parse = {`ALU_SLTU, `RS1_RS1, `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_I };
    `BEQ   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BEQ , `ECALL_N, `IMM_B };
    `BNE   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BNE , `ECALL_N, `IMM_B };
    `BLT   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BLT , `ECALL_N, `IMM_B };
    `BGE   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BGE , `ECALL_N, `IMM_B };
    `BLTU  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BLTU, `ECALL_N, `IMM_B };
    `BGEU  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_X  , `BR_BGEU, `ECALL_N, `IMM_B };
    `JAL   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_PC , `BR_JAL , `ECALL_N, `IMM_J };
    `JALR  : parse = {`ALU_JALR, `RS1_RS1, `RS2_IMI, `MEN_X, `WB_PC , `BR_JAL , `ECALL_N, `IMM_I };
    `LUI   : parse = {`ALU_ADD,  `RS1_X,   `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_U };
    `AUIPC : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_N, `IMM_U };
    `ECALL : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEN_X, `WB_ALU, `BR_X   , `ECALL_Y, `IMM_X };
    default: parse = {`ALU_X,    `RS1_X,   `RS2_X,   `MEN_X, `WB_X  , `BR_X   , `ECALL_N, `IMM_X };
    endcase
endfunction


// 即値の扱い方 risc-v ISA manual参照(P.24)
assign {alu_fn, rs1, rs2, mem_wen, wb_sel, br, ecall, imm_type} = parse(inst);
assign imm = (imm_type === `IMM_U) ? {inst[31:12], 12'd0} : // U-format
             (imm_type === `IMM_J) ? {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'd0} : // J-format
             (imm_type === `IMM_I) ? {{20{inst[31]}},inst[31],inst[30:25],inst[24:21],inst[20]} : // I-format
             (imm_type === `IMM_B) ? {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'd0} : //B-format
             (imm_type === `IMM_S) ? {{20{inst[31]}},inst[31],inst[30:25],inst[11:8],inst[7]} : 32'd0;// ? S-format : R-format(即値なし)

endmodule