`include "define.vh"

module DECODER #(
    parameter INST_LEN = 32,
    parameter DATA_LEN = 32
) (
    input wire [INST_LEN-1:0] inst,
    output wire [DATA_LEN-1:0] imm,
    output wire [4:0] rs1_addr, rs2_addr, rd_addr,
    output wire [3:0] alu_fn,
    output wire [1:0] rs1,
    output wire [1:0] rs2,
    output wire [2:0] mem_fn,
    output wire [1:0] wb_sel,
    output wire [2:0] br,
    output wire ecall
);

// 内部信号
localparam IMM_X = 3'd0;
localparam IMM_I = 3'd1;
localparam IMM_S = 3'd2;
localparam IMM_B = 3'd3;
localparam IMM_U = 3'd4;
localparam IMM_J = 3'd5;
wire [2:0] imm_type;

assign rs1_addr = inst[INST_LEN-13:INST_LEN-17];
assign rs2_addr = inst[INST_LEN-8:INST_LEN-12];
assign rd_addr = inst[INST_LEN-21:INST_LEN-25];


function [19:0] parse;
    input [INST_LEN-1:0] inst;
    casex (inst) //    ALU_fn,    ALU_src1, ALU_src2, MEM_fn,  WB_select, branch, ecall, imm
    `LUI    : parse = {`ALU_ADD,  `RS1_X,   `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_U };
    `AUIPC  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_U };
    `JAL    : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_PC , `BR_JAL , `ECALL_N, IMM_J };
    `JALR   : parse = {`ALU_JALR, `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_PC , `BR_JAL , `ECALL_N, IMM_I };
    `BEQ    : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BEQ , `ECALL_N, IMM_B };
    `BNE    : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BNE , `ECALL_N, IMM_B };
    `BLT    : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BLT , `ECALL_N, IMM_B };
    `BGE    : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BGE , `ECALL_N, IMM_B };
    `BLTU   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BLTU, `ECALL_N, IMM_B };
    `BGEU   : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_X  , `BR_BGEU, `ECALL_N, IMM_B };
    `LB     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_MEM, `BR_X   , `ECALL_N, IMM_I };
    `LH     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LH,  `WB_MEM, `BR_X   , `ECALL_N, IMM_I };
    `LW     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LW,  `WB_MEM, `BR_X   , `ECALL_N, IMM_I };
    `LBU    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LBU, `WB_MEM, `BR_X   , `ECALL_N, IMM_I };
    `LHU    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LHU, `WB_MEM, `BR_X   , `ECALL_N, IMM_I };
    `SB     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_SB,  `WB_X  , `BR_X   , `ECALL_N, IMM_S };
    `SH     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_SH,  `WB_X  , `BR_X   , `ECALL_N, IMM_S };
    `SW     : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_SW,  `WB_X  , `BR_X   , `ECALL_N, IMM_S };
    `ADDI   : parse = {`ALU_ADD,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SLTI   : parse = {`ALU_SLT,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SLTIU  : parse = {`ALU_SLTU, `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `XORI   : parse = {`ALU_XOR,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `ORI    : parse = {`ALU_OR,   `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `ANDI   : parse = {`ALU_AND,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SLLI   : parse = {`ALU_SLL,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SRLI   : parse = {`ALU_SRL,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SRAI   : parse = {`ALU_SRA,  `RS1_RS1, `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `ADD    : parse = {`ALU_ADD,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `SUB    : parse = {`ALU_SUB,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `SLL    : parse = {`ALU_SLL,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_I };
    `SLT    : parse = {`ALU_SLT,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `SLTU   : parse = {`ALU_SLTU, `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `XOR    : parse = {`ALU_XOR,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `SRL    : parse = {`ALU_SRL,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `SRA    : parse = {`ALU_SRA,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `OR     : parse = {`ALU_OR,   `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    `AND    : parse = {`ALU_AND,  `RS1_RS1, `RS2_RS2, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_N, IMM_X };
    // `define FENCE   32'b0000????????00000000000000001111
    // `FENCE_I: parse = {`ALU_X,    `RS1_X,   `RS2_X,   `MEM_LB,  `WB_X  , `BR_X   , `ECALL_N, `IMM_X };
    `ECALL  : parse = {`ALU_ADD,  `RS1_PC,  `RS2_IMI, `MEM_LB,  `WB_ALU, `BR_X   , `ECALL_Y, IMM_X };
    // `define CSRRW   32'??????????????????001?????1110011
    // `define CSRRS   32'??????????????????010?????1110011
    // `define CSRRC   32'??????????????????011?????1110011
    // `define CSRRWI  32'??????????????????101?????1110011
    // `define CSRRSI  32'??????????????????110?????1110011
    // `define CSRRCI  32'??????????????????111?????1110011
    default : parse = {`ALU_X,    `RS1_X,   `RS2_X,   `MEM_LB,  `WB_X  , `BR_X   , `ECALL_N, IMM_X };
    endcase
endfunction


// 即値の扱い方 risc-v ISA manual参照(P.24)
assign {alu_fn, rs1, rs2, mem_fn, wb_sel, br, ecall, imm_type} = parse(inst);
assign imm = (imm_type == IMM_U) ? {inst[INST_LEN-1:INST_LEN-20], {12{1'd0}}} : // U-format
             (imm_type == IMM_J) ? {{11{inst[INST_LEN-1]}},inst[INST_LEN-1],inst[INST_LEN-13:INST_LEN-20],inst[INST_LEN-12],inst[INST_LEN-2:INST_LEN-11],1'd0} : // J-format
             (imm_type == IMM_I) ? {{20{inst[INST_LEN-1]}},inst[INST_LEN-1],inst[INST_LEN-2:INST_LEN-7],inst[INST_LEN-8:INST_LEN-11],inst[INST_LEN-12]} : // I-format
             (imm_type == IMM_B) ? {{19{inst[INST_LEN-1]}},inst[INST_LEN-1],inst[INST_LEN-25],inst[INST_LEN-2:INST_LEN-7],inst[INST_LEN-21:INST_LEN-24],1'd0} : //B-format
             (imm_type == IMM_S) ? {{20{inst[INST_LEN-1]}},inst[INST_LEN-1],inst[INST_LEN-2:INST_LEN-7],inst[INST_LEN-21:INST_LEN-24],inst[INST_LEN-25]} : 0;// ? S-format : R-format(即値なし)

endmodule