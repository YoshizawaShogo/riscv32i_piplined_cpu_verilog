module CLK_DIV (
    input wire clk_in,
    input reset,
    output reg clk_out 
);
    reg [31:0] cnt;
    
    always @(posedge clk_in) begin
            if (cnt >= 32'h02FAF080) begin
                clk_out <= !clk_out;
                cnt <= 0;
            end
            else begin
                cnt <= cnt + 1;
            end
    end
endmodule