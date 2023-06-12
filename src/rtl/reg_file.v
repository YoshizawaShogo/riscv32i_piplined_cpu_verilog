module REG_FILE (
    input wire clk,
    input wire reset,

    input wire write_en,
    input wire [4:0] write_addr,
    input wire [31:0] write_value,

    input wire [4:0] rs1_addr, rs2_addr,
    output wire [31:0] rs1_data, rs2_data,
    output wire [3:0] reg10
);

    reg [31:0] reg_file [0:31];

    always @(posedge clk) begin
        if (reset) begin
            reg_file[0] <= 32'b0; //zero ゼロレジスタ
            reg_file[1] <= 32'hfffffffe; // 終了条件も兼ねている
            reg_file[2] <= 32'h8000; //sp スタックポイント //適当
            // reg_file[3] <= 32'b0; //
            // reg_file[4] <= 32'b0; //
            // reg_file[5] <= 32'b0; //
            // reg_file[6] <= 32'b0; //
            // reg_file[7] <= 32'b0; //
            // reg_file[8] <= 32'b0; //
            // reg_file[9] <= 32'b0; //
            // reg_file[10] <= 32'b0; //
            // reg_file[11] <= 32'b0; //
            // reg_file[12] <= 32'b0; //
            // reg_file[13] <= 32'b0; //
            // reg_file[14] <= 32'b0; //
            // reg_file[15] <= 32'b0; //
            // reg_file[16] <= 32'b0; //
            // reg_file[17] <= 32'b0; //
            // reg_file[18] <= 32'b0; //
            // reg_file[19] <= 32'b0; //
            // reg_file[20] <= 32'b0; //
            // reg_file[21] <= 32'b0; //
            // reg_file[22] <= 32'b0; //
            // reg_file[23] <= 32'b0; //
            // reg_file[24] <= 32'b0; //
            // reg_file[25] <= 32'b0; //
            // reg_file[26] <= 32'b0; //
            // reg_file[27] <= 32'b0; //
            // reg_file[28] <= 32'b0; //
            // reg_file[29] <= 32'b0; //
            // reg_file[30] <= 32'b0; //
            // reg_file[31] <= 32'b0; //
        end
        else if (write_en && write_addr != 1'b0) begin
            reg_file[write_addr] <= write_value;
        end
    end

    assign rs1_data = reg_file[rs1_addr];
    assign rs2_data = reg_file[rs2_addr];
    assign reg10 = reg_file[10];

endmodule