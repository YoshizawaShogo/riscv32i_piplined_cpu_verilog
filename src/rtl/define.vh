// RV32Iのみ(例外処理もなし)

// alu fn
`define ALU_X    4'd0
`define ALU_ADD  4'd1
`define ALU_SUB  4'd2
`define ALU_AND  4'd3
`define ALU_OR   4'd4
`define ALU_XOR  4'd5
`define ALU_SLL  4'd6
`define ALU_SRL  4'd7
`define ALU_SRA  4'd8
`define ALU_SLT  4'd9
`define ALU_SLTU 4'd10
`define ALU_JALR 4'd11

// branch fn
`define BR_X     3'd0
`define BR_BEQ   3'd1
`define BR_BNE   3'd2
`define BR_BLT   3'd3
`define BR_BGE   3'd4
`define BR_BLTU  3'd5
`define BR_BGEU  3'd6
`define BR_JAL   3'd7

// rs1
`define RS1_X    2'd0
`define RS1_RS1  2'd1
`define RS1_PC   2'd2

// rs2
`define RS2_X    2'd0
`define RS2_RS2  2'd1
`define RS2_IMI  2'd2

// mem_fn
`define MEM_LB   3'd0
`define MEM_LH   3'd1
`define MEM_LW   3'd2
`define MEM_LBU  3'd3
`define MEM_LHU  3'd4
`define MEM_SB   3'd5
`define MEM_SH   3'd6
`define MEM_SW   3'd7

// wb_sel
`define WB_X      2'd0
`define WB_ALU    2'd1
`define WB_MEM    2'd2
`define WB_PC     2'd3

// ecall
`define ECALL_N 1'b0
`define ECALL_Y 1'b1

/* 以下命令コード */
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf の p.116参照
// ロード・ストア
`define LUI     32'b?????????????????????????0110111
`define AUIPC   32'b?????????????????????????0010111
`define JAL     32'b?????????????????????????1101111
`define JALR    32'b?????????????????000?????1100111
`define BEQ     32'b?????????????????000?????1100011
`define BNE     32'b?????????????????001?????1100011
`define BLT     32'b?????????????????100?????1100011
`define BGE     32'b?????????????????101?????1100011
`define BLTU    32'b?????????????????110?????1100011
`define BGEU    32'b?????????????????111?????1100011
`define LB      32'b?????????????????000?????0000011
`define LH      32'b?????????????????001?????0000011
`define LW      32'b?????????????????010?????0000011
`define LBU     32'b?????????????????100?????0000011
`define LHU     32'b?????????????????101?????0000011
`define SB      32'b?????????????????000?????0100011
`define SH      32'b?????????????????001?????0100011
`define SW      32'b?????????????????010?????0100011
`define ADDI    32'b?????????????????000?????0010011
`define SLTI    32'b?????????????????010?????0010011
`define SLTIU   32'b?????????????????011?????0010011
`define XORI    32'b?????????????????100?????0010011
`define ORI     32'b?????????????????110?????0010011
`define ANDI    32'b?????????????????111?????0010011
`define SLLI    32'b0000000??????????001?????0010011
`define SRLI    32'b0000000??????????101?????0010011
`define SRAI    32'b0100000??????????101?????0010011
`define ADD     32'b0000000??????????000?????0110011
`define SUB     32'b0100000??????????000?????0110011
`define SLL     32'b0000000??????????001?????0110011
`define SLT     32'b0000000??????????010?????0110011
`define SLTU    32'b0000000??????????011?????0110011
`define XOR     32'b0000000??????????100?????0110011
`define SRL     32'b0000000??????????101?????0110011
`define SRA     32'b0100000??????????101?????0110011
`define OR      32'b0000000??????????110?????0110011
`define AND     32'b0000000??????????111?????0110011
`define FENCE   32'b0000????????00000000000000001111
`define FENCE_I 32'b00000000000000000001000000001111
`define ECALL   32'b00000000000000000000000001110011
`define CSRRW   32'??????????????????001?????1110011
`define CSRRS   32'??????????????????010?????1110011
`define CSRRC   32'??????????????????011?????1110011
`define CSRRWI  32'??????????????????101?????1110011
`define CSRRSI  32'??????????????????110?????1110011
`define CSRRCI  32'??????????????????111?????1110011