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
        $display("pc = %x, inst = %x, fn = %d, rs1 = %d, rs2 = %d, alu = %d, reg[%d]=%d, jump = %d,%d, rb = %d", cpu.pc, cpu.inst, cpu.alu.fn, cpu.alu_src1, cpu.alu_src2, cpu.alu_out, cpu.reg_file.rs2_addr, cpu.reg_file.rs2_data, cpu.jump_flag, cpu.id_ex_rs2_data, cpu.rf_write_value);
    end

    initial begin
        clk = 0;
        reset = 1; #10 reset = 0;
    end

    initial #(100 * CYCLE) $finish;
endmodule