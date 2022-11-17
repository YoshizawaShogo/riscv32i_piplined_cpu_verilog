`include "define.vh"

module JUMP_CONTROLLER (
    input wire [2:0] br,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    output wire jump_flag
);
    // 条件分岐
    wire active_beq;
    assign active_beq = (rs1_data == rs2_data) ? 1'b1 : 1'b0;

    wire active_bne;
    assign active_bne = (rs1_data != rs2_data) ? 1'b1 : 1'b0;

    wire active_blt;
    assign active_blt = ($signed(rs1_data) < $signed(rs2_data)) ? 1'b1 : 1'b0;

    wire active_bge;
    assign active_bge = ($signed(rs1_data) > $signed(rs2_data)) ? 1'b1 : 1'b0;
    
    wire active_bltu;
    assign active_bltu = (rs1_data < rs2_data) ? 1'b1 : 1'b0;

    wire active_bgeu;
    assign active_bgeu = (rs1_data > rs2_data) ? 1'b1 : 1'b0;

    wire [31:0] jalr_target;
    assign jalr_target = (rs1_data + rs2_data) & ~32'b1;

    // output
    assign jump_flag = (br == `BR_BEQ) ? active_beq :
                       (br == `BR_BNE) ? active_bne :
                       (br == `BR_BLT) ? active_blt :
                       (br == `BR_BGE) ? active_bge :
                       (br == `BR_BLTU) ? active_bltu :
                       (br == `BR_BGEU) ? active_bgeu :
                       (br == `BR_JAL) ? 1'b1 : 1'b0;
endmodule