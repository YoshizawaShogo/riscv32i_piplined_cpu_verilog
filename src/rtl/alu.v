`include "define.vh"

module ALU #(
    parameter DATA_LEN = 32,
    parameter ADDR_LEN = 5
) (
    input wire [3:0] fn,
    input wire [DATA_LEN-1:0] src1,
    input wire [DATA_LEN-1:0] src2,
    output wire [DATA_LEN-1:0] out
);

    // 算術演算
    wire [DATA_LEN-1:0] add_out;
    assign add_out = src1 + src2;

    wire [DATA_LEN-1:0] sub_out;
    assign sub_out = src1 - src2;
    
    // 論理演算
    wire [DATA_LEN-1:0] and_out;
    assign and_out = src1 & src2;

    wire [DATA_LEN-1:0] or_out;
    assign or_out = src1 | src2;

    wire [DATA_LEN-1:0] xor_out;
    assign xor_out = src1 ^ src2;

    // シフト
    wire [DATA_LEN-1:0] sll_out;
    assign sll_out = src1 << src2[ADDR_LEN-1:0];

    wire [DATA_LEN-1:0] srl_out;
    assign srl_out = src1 >> src2[ADDR_LEN-1:0];

    wire [DATA_LEN-1:0] sra_out;
    assign sra_out = $signed(src1) >>> src2[ADDR_LEN-1:0];

    // 比較
    wire [DATA_LEN-1:0] slt_out;
    assign slt_out = ($signed(src1) < $signed(src2)) ? 1 : 0;

    wire [DATA_LEN-1:0] sltu_out;
    assign sltu_out = (src1 < src2) ? 1 : 0;

    wire [DATA_LEN-1:0] jalr_out;
    assign jalr_out = (src1 + src2) & ~1;

    assign out = (fn == `ALU_X) ? 0 : // 0 は適当
                 (fn == `ALU_ADD) ? add_out :
                 (fn == `ALU_SUB) ? sub_out :
                 (fn == `ALU_AND) ? and_out :
                 (fn == `ALU_OR) ? or_out :
                 (fn == `ALU_XOR) ? xor_out :
                 (fn == `ALU_SLL) ? sll_out :
                 (fn == `ALU_SRL) ? srl_out :
                 (fn == `ALU_SRA) ? sra_out :
                 (fn == `ALU_SLT) ? slt_out :
                 (fn == `ALU_SLTU) ? sltu_out :
                 (fn == `ALU_JALR) ? jalr_out :
                 1; // 1 は適当

endmodule