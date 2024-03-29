`timescale 1 us/ 100 ns
`default_nettype none

`include "define.vh"

module cpu_tb;
    parameter HALFCYCLE = 0.5; //500ns
    parameter CYCLE = 1;
    parameter DATA_LEN = 32;
    parameter INST_LEN = `INST_LEN;
    parameter ADDR_LEN = 5;
    
    reg clk;
    reg reset;
    wire [DATA_LEN-1:0] pc;
    wire [2:0] ex_mem_mem_fn;
    wire [DATA_LEN-1:0] ex_mem_alu_out;
    wire [DATA_LEN-1:0] ex_mem_rs2_data;
    wire [INST_LEN-1:0] inst;
    wire [DATA_LEN-1:0] mem_out;

    CPU #(
        .INST_LEN(INST_LEN)
    ) cpu (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .ex_mem_mem_fn(ex_mem_mem_fn),
        .ex_mem_alu_out(ex_mem_alu_out),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .inst(inst),
        .mem_out(mem_out)
    );

    MEM mem (
        .clk(clk), // input
        .pc(pc), // input
        .mem_fn(ex_mem_mem_fn), // input
        .addr(ex_mem_alu_out), // input
        .write_data(ex_mem_rs2_data), // input
        .inst(inst), // output
        .read_data(mem_out) // output
    );

    always begin 
        #HALFCYCLE clk = ~clk;
        #HALFCYCLE clk = ~clk;

        $display("pc = %x, alu_out = %d, rf[] = %d, DASM(%x)",
                cpu.wb_debug_pc, cpu.wb_debug_alu_out, cpu.reg_file.reg_file[10], cpu.wb_debug_inst);
        if(cpu.mem_wb_ecall) begin
            $display("\t%D #ECALL was called.", cpu.reg_file.reg_file[10]);
            $finish;
        end
        if (cpu.wb_debug_pc === 32'hfffffffe) begin // xxxxxxxには文字列置換して、終了条件が入る
            $display("\t%D #Reached the END_ADDRESS", cpu.reg_file.reg_file[10]);
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
    string HEX_FILE;
    reg [7:0] mem [0:2**16-1];
    initial begin
        if (! $value$plusargs("HEX_FILE=%s", HEX_FILE)) begin
            $display("ERROR: Please input HEX_FILE.");
            $finish(1);
        end
        $readmemh(HEX_FILE, mem);
    end

    always @(posedge clk) begin
        // 書き込んでいないメモリにアクセスすることは想定しないため、reset無し
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