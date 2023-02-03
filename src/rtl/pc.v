module PC #(
    parameter XLEN = 32
) (
    input wire clk, reset,
    input wire jump_flag,
    input wire stall,
    input wire [XLEN-1:0] jump_target,
    output wire [XLEN-1:0] pc
);
    reg [XLEN-1:0] pc_reg;

    always @(posedge clk) begin
        if (reset) pc_reg <= 0;
        else if (jump_flag) pc_reg <= jump_target;
        else if (stall) pc_reg <= pc_reg;
        else pc_reg <= pc + 4;
    end

    assign pc = pc_reg;

endmodule