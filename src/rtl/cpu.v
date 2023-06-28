module CPU #(
    parameter DATA_LEN = 32,
    parameter INST_LEN = 32,
    parameter ADDR_LEN = 5
) (
    input wire clk, reset,
    output wire [DATA_LEN-1:0] pc,
    output reg [2:0] ex_mem_mem_fn,
    output reg [DATA_LEN-1:0] ex_mem_alu_out,
    output reg [DATA_LEN-1:0] ex_mem_rs2_data,
    input wire [INST_LEN-1:0] inst,
    input wire [DATA_LEN-1:0] mem_out
);

// todo: 分岐予測
wire local_clk;

wire [DATA_LEN-1:0] alu_out;
wire [DATA_LEN-1:0] rs1_data, rs2_data;
// wire [DATA_LEN-1:0] pc;

wire [1:0] rs1;
wire [1:0] rs2;
wire [2:0] br;
wire ecall;
wire [DATA_LEN-1:0] imm;
wire [ADDR_LEN-1:0] rs1_addr, rs2_addr, rd_addr;
wire [3:0] alu_fn;
wire [2:0] mem_fn;
wire [1:0] wb_sel;

// wire [INST_LEN-1:0] inst;
// wire [DATA_LEN-1:0] mem_out;

// IF_ID
reg [DATA_LEN-1:0] if_id_pc;
reg [INST_LEN-1:0] if_id_inst;

// ID_EX
reg [DATA_LEN-1:0] id_ex_pc;
reg [INST_LEN-1:0] id_ex_inst;
reg [3:0] id_ex_alu_fn;
reg [1:0] id_ex_rs1;
reg [DATA_LEN-1:0] id_ex_rs1_data;
reg [1:0] id_ex_rs2;
reg [DATA_LEN-1:0] id_ex_rs2_data;
reg [ADDR_LEN-1:0] id_ex_rd_addr;
reg [DATA_LEN-1:0] id_ex_imm;
reg [2:0] id_ex_mem_fn;
reg [1:0] id_ex_wb_sel;
reg [2:0] id_ex_br;
reg id_ex_ecall;

// EX_MEM
reg [DATA_LEN-1:0] ex_mem_pc;
reg [INST_LEN-1:0] ex_mem_inst;
reg ex_mem_ecall;
// reg [DATA_LEN-1:0] ex_mem_rs2_data;
// reg [DATA_LEN-1:0] ex_mem_alu_out;
// reg [2:0] ex_mem_mem_fn;
reg [1:0] ex_mem_wb_sel;
reg [ADDR_LEN-1:0] ex_mem_rd_addr;

// MEM_WB
reg [DATA_LEN-1:0] mem_wb_pc;
reg [INST_LEN-1:0] mem_wb_inst;
reg mem_wb_ecall;
assign local_clk = !mem_wb_ecall & clk;

reg [DATA_LEN-1:0] mem_wb_rs2_data;
reg [DATA_LEN-1:0] mem_wb_alu_out;
reg [2:0] mem_wb_mem_fn; // ストールのため
reg [DATA_LEN-1:0] mem_wb_mem_out;
reg [1:0] mem_wb_wb_sel;
reg [ADDR_LEN-1:0] mem_wb_rd_addr;

// WB_reg for debug
// Design Compilerでは、最適化により取り除かれるため、面積に影響なし
reg [DATA_LEN-1:0] wb_debug_pc;
reg [INST_LEN-1:0] wb_debug_inst;
reg wb_debug_ecall;
reg [DATA_LEN-1:0] wb_debug_rs2_data;
reg [DATA_LEN-1:0] wb_debug_alu_out;
reg [2:0] wb_debug_mem_fn;
reg [DATA_LEN-1:0] wb_debug_mem_out;
reg [1:0] wb_debug_wb_sel;
reg [ADDR_LEN-1:0] wb_debug_rd_addr;

// 制御
wire stall_flag_at_id;
assign stall_flag_at_id = ((id_ex_wb_sel == `WB_MEM) && (id_ex_rd_addr  == rs1_addr || id_ex_rd_addr  == rs2_addr)) ? 1 : 0;

wire stall_flag_at_if;
assign stall_flag_at_if = (id_ex_br == `BR_X) && (br == `BR_X)  ? 0 : 1;

always @(posedge local_clk) begin
    if (reset) begin
        id_ex_ecall <= 0;
        mem_wb_ecall <= 0;
        ex_mem_ecall <= 0;
        wb_debug_ecall <= 0;
    end
    else begin
        // IF_ID
        if (stall_flag_at_if && !stall_flag_at_id) begin
            if_id_inst <= 0;
        end else if (stall_flag_at_id) begin
            if_id_pc <= if_id_pc;
            if_id_inst <= if_id_inst;
        end else begin
            if_id_pc <= pc;
            if_id_inst <= inst;
        end

        // ID_EX
        if (stall_flag_at_id) begin
            id_ex_br <= `BR_X;
            id_ex_mem_fn <= `MEM_LB;
            id_ex_wb_sel <= `WB_X;
        end else begin
            id_ex_pc <= if_id_pc;
            id_ex_inst <= if_id_inst;
            id_ex_rs1 <= rs1;
            // フォワーディング
            if(rs1_addr == 0) id_ex_rs1_data <= 0;
            else if(id_ex_rd_addr == rs1_addr && id_ex_wb_sel == `WB_PC) id_ex_rs1_data <= id_ex_pc + 4;
            else if(id_ex_rd_addr == rs1_addr && id_ex_wb_sel == `WB_ALU) id_ex_rs1_data <= alu_out;
            else if(ex_mem_rd_addr == rs1_addr && ex_mem_wb_sel == `WB_PC) id_ex_rs1_data <= ex_mem_pc + 4;
            else if(ex_mem_rd_addr == rs1_addr && ex_mem_wb_sel == `WB_ALU) id_ex_rs1_data <= ex_mem_alu_out;
            else if(ex_mem_rd_addr == rs1_addr && ex_mem_wb_sel == `WB_MEM) id_ex_rs1_data <= mem_out;
            else if(mem_wb_rd_addr == rs1_addr && mem_wb_wb_sel == `WB_PC) id_ex_rs1_data <= mem_wb_pc + 4;
            else if(mem_wb_rd_addr == rs1_addr && mem_wb_wb_sel == `WB_ALU) id_ex_rs1_data <= mem_wb_alu_out;
            else if(mem_wb_rd_addr == rs1_addr && mem_wb_wb_sel == `WB_MEM) id_ex_rs1_data <= mem_wb_mem_out;
            else id_ex_rs1_data <= rs1_data;

            id_ex_rs2 <= rs2;
            // フォワーディング
            if(rs2_addr == 0) id_ex_rs2_data <= 0;
            else if(id_ex_rd_addr == rs2_addr && id_ex_wb_sel == `WB_PC) id_ex_rs2_data <= id_ex_pc + 4;
            else if(id_ex_rd_addr == rs2_addr && id_ex_wb_sel == `WB_ALU) id_ex_rs2_data <= alu_out;
            else if(ex_mem_rd_addr == rs2_addr && ex_mem_wb_sel == `WB_PC) id_ex_rs2_data <= ex_mem_pc + 4;
            else if(ex_mem_rd_addr == rs2_addr && ex_mem_wb_sel == `WB_ALU) id_ex_rs2_data <= ex_mem_alu_out;
            else if(ex_mem_rd_addr == rs2_addr && ex_mem_wb_sel == `WB_MEM) id_ex_rs2_data <= mem_out;
            else if(mem_wb_rd_addr == rs2_addr && mem_wb_wb_sel == `WB_PC) id_ex_rs2_data <= mem_wb_pc + 4;
            else if(mem_wb_rd_addr == rs2_addr && mem_wb_wb_sel == `WB_ALU) id_ex_rs2_data <= mem_wb_alu_out;
            else if(mem_wb_rd_addr == rs2_addr && mem_wb_wb_sel == `WB_MEM) id_ex_rs2_data <= mem_wb_mem_out;
            else id_ex_rs2_data <= rs2_data;
            id_ex_rd_addr <= rd_addr;
            id_ex_br <= br;
            id_ex_ecall <= ecall;
            id_ex_alu_fn <= alu_fn;
            id_ex_imm <= imm;
            id_ex_mem_fn <= mem_fn;
            id_ex_wb_sel <= wb_sel;
        end

        // EX_MEM
        ex_mem_pc <= id_ex_pc;
        ex_mem_inst <= id_ex_inst;
        ex_mem_ecall <= id_ex_ecall;
        ex_mem_rs2_data <= id_ex_rs2_data;
        ex_mem_alu_out <= alu_out;
        ex_mem_mem_fn <= id_ex_mem_fn;
        ex_mem_wb_sel <= id_ex_wb_sel;
        ex_mem_rd_addr <= id_ex_rd_addr;

        // MEM_WB
        mem_wb_pc <= ex_mem_pc;
        mem_wb_inst <= ex_mem_inst;
        mem_wb_ecall <= ex_mem_ecall;
        mem_wb_alu_out <= ex_mem_alu_out;
        mem_wb_mem_fn <= ex_mem_mem_fn;
        mem_wb_mem_out <= mem_out;
        mem_wb_wb_sel <= ex_mem_wb_sel;
        mem_wb_rd_addr <= ex_mem_rd_addr;

        // WB reg for debug
        wb_debug_pc <= mem_wb_pc;
        wb_debug_inst <= mem_wb_inst;
        wb_debug_ecall <= mem_wb_ecall;
        wb_debug_rs2_data <= mem_wb_rs2_data;
        wb_debug_alu_out <= mem_wb_alu_out;
        wb_debug_mem_fn <= mem_wb_mem_fn;
        wb_debug_mem_out <= mem_wb_mem_out;
        wb_debug_wb_sel <= mem_wb_wb_sel;
        wb_debug_rd_addr <= mem_wb_rd_addr;
    
    end
    
end

wire [DATA_LEN-1:0] alu_src1;
assign alu_src1 = (id_ex_rs1 == `RS1_X)   ? 0          :
                  (id_ex_rs1 == `RS1_RS1) ? id_ex_rs1_data :
                  (id_ex_rs1 == `RS1_PC)  ? id_ex_pc       : 0;

wire [DATA_LEN-1:0] alu_src2;
assign alu_src2 = (id_ex_rs2 == `RS2_X)   ? 0          :
                  (id_ex_rs2 == `RS2_RS2) ? id_ex_rs2_data :
                  (id_ex_rs2 == `RS2_IMI) ? id_ex_imm       : 0;

wire jump_flag;
assign jump_flag = (id_ex_br == `BR_BEQ) && (id_ex_rs1_data == id_ex_rs2_data) ? 1 :
                   (id_ex_br == `BR_BNE) && (id_ex_rs1_data != id_ex_rs2_data) ? 1 :
                   (id_ex_br == `BR_BLT) && ($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data)) ? 1 :
                   (id_ex_br == `BR_BGE) && ($signed(id_ex_rs1_data) >= $signed(id_ex_rs2_data)) ? 1 :
                   (id_ex_br == `BR_BLTU) && (id_ex_rs1_data < id_ex_rs2_data) ? 1 :
                   (id_ex_br == `BR_BGEU) && (id_ex_rs1_data >= id_ex_rs2_data) ? 1 :
                   (id_ex_br == `BR_JAL) ? 1 : 0;
               
wire [DATA_LEN-1:0] mem_write_value;
assign mem_write_value = (ex_mem_mem_fn) ? ex_mem_rs2_data : ex_mem_rs2_data;

wire [DATA_LEN-1:0] rf_write_value;
assign rf_write_value = (mem_wb_wb_sel == `WB_ALU) ? mem_wb_alu_out    :
                        (mem_wb_wb_sel == `WB_MEM) ? mem_wb_mem_out    :
                        (mem_wb_wb_sel == `WB_PC)  ? mem_wb_pc + 4 : 0 ;



PC pc_mod (
    .clk(local_clk), // input
    .reset(reset), // input
    .stall(stall_flag_at_if || stall_flag_at_id), // input
    .jump_flag(jump_flag), // input
    .jump_target(alu_out), // input
    .pc(pc) // output
);

DECODER #(
    .INST_LEN(INST_LEN)
) decoder (
    .inst(if_id_inst), // input
    .imm(imm), // output
    .rs1_addr(rs1_addr), // output
    .rs2_addr(rs2_addr), // output
    .rd_addr(rd_addr), // output
    .alu_fn(alu_fn), // output
    .mem_fn(mem_fn), // output
    .wb_sel(wb_sel), // output
    .rs1(rs1), // output 
    .rs2(rs2), // output
    .br(br),
    .ecall(ecall) //
);

REG_FILE reg_file (
    .clk(local_clk), // input
    .reset(reset), // input
    .write_en(mem_wb_wb_sel != `WB_X), // input
    .write_addr(mem_wb_rd_addr), // input
    .write_value(rf_write_value), // input
    .rs1_addr(rs1_addr), // input
    .rs2_addr(rs2_addr), // input
    .rs1_data(rs1_data), // output
    .rs2_data(rs2_data) // output
);

ALU #(
    .DATA_LEN(DATA_LEN),
    .ADDR_LEN(ADDR_LEN)
) alu (
    .fn(id_ex_alu_fn), // input
    .src1(alu_src1), // input
    .src2(alu_src2), // input
    .out(alu_out) // output
);
    
endmodule