// memoryモジュール

module DATA_MEM (
    input wire clk,
    input wire [2:0] fn,
    input wire [31:0] addr, // 読み込みと書込みが同時に起こらないため、共有
    input wire [31:0] write_data,
    output wire [31:0] read_data
);
    // 1byte*16384行=16384byte=16KB
    reg [7:0] rom [0:2**16-1];
    initial begin
        $readmemh("build/isa/rv32ui-p-xori.hex", rom);
    end

    always @(posedge clk) begin
        // 書き込んでいないメモリにアクセスすることは想定しない。
        if (fn === `MEM_SW) begin
            rom[addr+3] <= write_data[31:24];
            rom[addr+2] <= write_data[23:16];
            rom[addr+1] <= write_data[15:8];
            rom[addr+0] <= write_data[7:0];
        end
        else if (fn === `MEM_SH) begin
            rom[addr+1] <= write_data[15:8];
            rom[addr+0] <= write_data[7:0];
        end
        else if (fn === `MEM_SB) begin
            rom[addr+0] <= write_data[7:0];
        end
    end
    

    assign read_data = (fn === `MEM_LW)  ? {rom[addr+3], rom[addr+2], rom[addr+1], rom[addr+0]} :
                       (fn === `MEM_LHU)  ? {rom[addr+1], rom[addr+0]} :
                       (fn === `MEM_LH) ? {{16{rom[addr+1][7]}}, rom[addr+1], rom[addr+0]} :
                       (fn === `MEM_LBU)  ? {rom[addr+0]} :
                       {{24{rom[addr+0][7]}}, rom[addr+0]}; // defaultで命令LBを実行
endmodule