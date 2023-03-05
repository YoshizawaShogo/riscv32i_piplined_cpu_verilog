`include "define.vh"
module memory_interface (
    input wire clk,
    
    output wire mem_we,
    output wire [31:0] mem_pc,
    output wire [31:0] mem_write_data,
    output wire [31:0] mem_addr,

    input wire [31:0] mem_inst,
    input wire [31:0] mem_read_data,


    output wire [31:0] cpu_inst,
    output wire [31:0] cpu_read_data,
    input wire [31:0] cpu_pc,
    input wire [2:0] cpu_mem_fn,
    input wire [31:0] cpu_addr,
    input wire [31:0] cpu_write_data
);
    assign mem_we = (cpu_mem_fn === `MEM_SW) || (cpu_mem_fn === `MEM_SH) || (cpu_mem_fn === `MEM_SB);
    assign mem_pc = cpu_pc >> 2;
    assign mem_write_data = cpu_write_data; // SWとSBに未対応
    assign mem_addr = cpu_addr >> 2;
    
    assign cpu_inst = mem_inst;
    assign cpu_read_data =  (cpu_mem_fn === `MEM_LW)  ? mem_read_data :
                            (cpu_mem_fn === `MEM_LHU)  ? {{16{1'b0}}, mem_read_data[15:0]} : //todo
                            (cpu_mem_fn === `MEM_LH) ? {{16{mem_read_data[15]}}, mem_read_data[15:0]} :
                            (cpu_mem_fn === `MEM_LBU)  ? {{24{1'b0}}, mem_read_data[7:0]} :
                            {{24{mem_read_data[7]}}, mem_read_data[7:0]}; // defaultで命令LBを実行
endmodule