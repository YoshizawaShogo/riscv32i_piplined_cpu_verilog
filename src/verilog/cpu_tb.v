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

        $display("pc = %x, inst = %x. stall = %d, rf[10] = %d",
                cpu.pc, cpu.inst, cpu.stall_flag_at_if || cpu.stall_flag_at_id, cpu.reg_file.reg_file[10]);
        if (cpu.pc === 32'hxxxxxxxx) $finish;
    end

    initial begin
        clk = 0;
        reset = 1; #CYCLE reset = 0;
    end

    initial #(100000 * CYCLE) $finish;
endmodule