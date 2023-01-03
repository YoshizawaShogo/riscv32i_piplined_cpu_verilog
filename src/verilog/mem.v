// memoryモジュール

module MEM (
    input wire clk,
    input wire [31:0] pc,
    input wire [2:0] mem_fn,
    input wire [31:0] addr, // 読み込みと書込みが同時に起こらないため、共有
    input wire [31:0] write_data,
    output wire [31:0] inst,
    output wire [31:0] read_data
);
    // 1byte*16384行=16384byte=16KB
    reg [7:0] mem [0:2**16-1];
    initial begin
        $readmemh("build/isa/rv32ui-p-xori.hex", mem);
    end

    always @(posedge clk) begin
        // 書き込んでいないメモリにアクセスすることは想定しない。
        if (mem_fn === `MEM_SW) begin
            mem[addr+3] <= write_data[31:24];
            mem[addr+2] <= write_data[23:16];
            mem[addr+1] <= write_data[15:8];
            mem[addr+0] <= write_data[7:0];
        end
        else if (mem_fn === `MEM_SH) begin
            mem[addr+1] <= write_data[15:8];
            mem[addr+0] <= write_data[7:0];
        end
        else if (mem_fn === `MEM_SB) begin
            mem[addr+0] <= write_data[7:0];
        end
    end
    
    assign inst = {mem[pc+3], mem[pc+2], mem[pc+1], mem[pc]};
    assign read_data = (mem_fn === `MEM_LW)  ? {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]} :
                       (mem_fn === `MEM_LHU)  ? {mem[addr+1], mem[addr+0]} :
                       (mem_fn === `MEM_LH) ? {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr+0]} :
                       (mem_fn === `MEM_LBU)  ? {mem[addr+0]} :
                       {{24{mem[addr+0][7]}}, mem[addr+0]}; // defaultで命令LBを実行
endmodule