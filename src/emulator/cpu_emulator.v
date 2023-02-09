`timescale 1 us/ 100 ns
`default_nettype none

`include "define.vh"

module cpu_tb;
    parameter HALFCYCLE = 0.5; //500ns
    parameter CYCLE = 1;
    reg clk, reset;

    CPU cpu(.clk(clk), .reset(reset));

    always begin 
        #HALFCYCLE clk = ~clk;
        #HALFCYCLE clk = ~clk;

        $display("pc = %x, inst = %x. alu_out = %d, rf[] = %d",
                cpu.wb_debug_pc, cpu.wb_debug_inst, cpu.wb_debug_alu_out, cpu.reg_file.reg_file[10]);
        if (cpu.pc === 32'h0xxxxxxx) begin // xxxxxxxには文字列置換して、終了条件が入る
            $display("rf[10] = %d", cpu.reg_file.reg_file[10]);
            $finish;
        end
    end

    initial begin
        clk = 0;
        reset = 1; #CYCLE reset = 0;
    end

    initial #(100000 * CYCLE + HALFCYCLE) begin
        $display("Timeout_Error");
        $finish;
    end
endmodule

// memoryモジュール
`include "define.vh"

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
        $readmemh("build/isa_test/rv32ui-p-sw.hex", mem);
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