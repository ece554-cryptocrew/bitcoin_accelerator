/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu
//
// Author: Logan Sisel/Adam Pryor
//
// Detail: Top level for the CPU.
//         The ex_ signals are for reading/writing to the memory controller
//         The cpu_ and accel_ signals are for interfacing with the accelerators
// 
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu (clk, rst_n, ex_im_wrt_en, ex_mem_wrt_en, ex_mem_rd_en, ex_addr, ex_wrt_data, accel_wrt_data, accel_addr, accel_wrt_en, 
            ex_rd_data, ex_rd_valid, accel_rd_data, cpu_wrt_en, cpu_wrt_data, cpu_addr);

    input          clk, rst_n;
    input          ex_im_wrt_en;
    input          ex_mem_wrt_en;
    input          ex_mem_rd_en;
    input  [15:0]  ex_addr;
    input  [31:0]  ex_wrt_data;
    input  [31:0]  accel_wrt_data;
    input  [15:0]  accel_addr;
    input          accel_wrt_en;
    output [31:0]  ex_rd_data;
    output         ex_rd_valid;
    output [511:0] accel_rd_data;
    output         cpu_wrt_en;
    output [31:0]  cpu_wrt_data;
    output [15:0]  cpu_addr;

    // Net List //

    logic [15:0]  mem_cpu_addr; 
    logic [31:0]  mem_cpu_wrt_data; 
    logic         mem_cpu_wrt_en;
    logic         mem_cpu_rd_en;
    logic [15:0]  mem_ex_addr; 
    logic [31:0]  mem_ex_wrt_data; 
    logic         mem_ex_wrt_en;
    logic         mem_ex_rd_en;
    logic [15:0]  mem_accel_addr; 
    logic [31:0]  mem_accel_wrt_data; 
    logic         mem_accel_wrt_en;
    logic [31:0]  mem_cpu_rd_data; 
    logic [31:0]  mem_ex_rd_data;
    logic [511:0] mem_accel_rd_data; 

    logic [31:0]  alu_A, alu_B, alu_Out;
    logic [7:0]   alu_Op;
    logic         alu_OF, alu_OF_en;
    logic         alu_CF, alu_CF_en;
    logic         alu_ZF, alu_ZF_en;
    logic         alu_NF, alu_NF_en;

    logic         NF_flg, ZF_flg, OF_flg, CF_flg;

    logic [15:0]  im_addr; 
    logic         im_wrt_en;
    logic [31:0]  im_wrt_data;
    logic [31:0]  im_rd_out;

    logic [15:0]  im_rd_addr;
    logic [15:0]  im_wrt_addr;

    logic [31:0]  ctrl_instr;
    logic [7:0]   ctrl_alu_op;
    logic         ctrl_alu_imm_src;
    logic         ctrl_rf_write_en;
    logic         ctrl_datamem_write_en;
    logic         ctrl_datamem_read_en;
    logic         ctrl_rf_write_mem_src;
    logic         ctrl_pc_src;
    logic         ctrl_pc_jmp_src;
    logic         ctrl_err;

    logic [15:0]  pc_new;
    logic [15:0]  pc_out;

    logic [3:0]   rf_sel1, rf_sel2, rf_wrt_sel;
    logic [31:0]  rf_wrt_data;
    logic         rf_wrt_en;
    logic [31:0]  rf_reg1, reg2;
    logic         rf_err;
    logic [31:0]  rf_instr;

    logic [31:0]  stl_if_instr;
    logic [3:0]   stl_dec_wrt_reg;
    logic         stl_dec_wrt_en;
    logic         stl_dec_jb_stall;
    logic [3:0]   stl_exec_wrt_reg;
    logic         stl_exec_wrt_en;
    logic         stl_exec_jb_stall;
    logic [3:0]   stl_mem_wrt_reg;
    logic         stl_mem_wrt_en;
    logic         stl_mem_jb_stall;
    logic [3:0]   stl_wb_wrt_reg;
    logic         stl_wb_wrt_en;
    logic         stl_wb_jb_stall;
    logic         stl_rw_stall;
    logic         stl_jb_stall;

    localparam IFID_WIDTH = 64; // TODO: change to make pipe stages wider as needed
    localparam IDEX_WIDTH = 160;
    localparam EXMEM_WIDTH = 128;
    localparam MEMWB_WIDTH = 128;

    logic [IFID_WIDTH-1:0]  IFID_in, IFID_out;
    logic [IDEX_WIDTH-1:0]  IDEX_in, IDEX_out;
    logic [EXMEM_WIDTH-1:0] EXMEM_in, EXMEM_out;
    logic [MEMWB_WIDTH-1:0] MEMWB_in, MEMWB_out;
    logic                   IFID_en, IDEX_en, EXMEM_en, MEMWB_en;

    // Module Instantiations //

    cpu_datamem mem(.clk(clk), .rst_n(rst_n), .cpu_addr(mem_cpu_addr), .cpu_wrt_data(mem_cpu_wrt_data), .cpu_wrt_en(mem_cpu_wrt_en), .cpu_rd_en(mem_cpu_rd_en),
                    .ex_wrt_en(mem_ex_wrt_en), .ex_rd_en(mem_ex_rd_en), .ex_addr(mem_ex_addr), .ex_wrt_data(mem_ex_wrt_data), .accel_addr(mem_accel_addr), .accel_wrt_data(mem_accel_wrt_data),
                    .accel_wrt_en(mem_accel_wrt_en), .ex_rd_data(mem_ex_rd_data), .cpu_rd_data(mem_cpu_rd_data), .accel_rd_data(mem_accel_rd_data));

    cpu_alu alu(.A(alu_A), .B(alu_B), .Op(alu_Op), .Out(alu_Out), .OF(alu_OF), .OF_en(alu_OF_en), .CF(alu_CF), 
                .CF_en(alu_CF_en), .ZF(alu_ZF), .ZF_en(alu_ZF_en), .NF(alu_NF), .NF_en(alu_NF_en));

    cpu_instrmem im(.clk(clk), .rst_n(rst_n), .addr(im_addr), .wrt_en(im_wrt_en), .wrt_data(im_wrt_data), .rd_out(im_rd_out));

    cpu_control ctrl(.instr(ctrl_instr), .alu_op(ctrl_alu_op), .alu_imm_src(ctrl_alu_imm_src), .rf_write_en(ctrl_rf_write_en), .datamem_write_en(ctrl_datamem_write_en),
                     .datamem_read_en(ctrl_datamem_read_en), .rf_write_mem_src(ctrl_rf_write_mem_src), .pc_src(ctrl_pc_src), .pc_jmp_src(ctrl_pc_jmp_src), .err(ctrl_err));

    cpu_pc pc(.clk(clk), .rst_n(rst_n), .pc_next(pc_next), .pc_out(pc_out));

    cpu_rf rf(.clk(clk), .rst_n(rst_n), .sel1(rf_sel1), .sel2(rf_sel2), .wrt_sel(rf_wrt_sel), 
              .wrt_data(rf_wrt_data), .wrt_en(rf_wrt_en), .reg1(rf_reg1), .reg2(rf_reg2), .err(rf_err));

    cpu_stall stl(.if_instr(stl_if_instr), .dec_wrt_reg(stl_dec_wrt_reg), .dec_wrt_en(stl_dec_wrt_en), .dec_jb_stall(stl_dec_jb_stall), .exec_wrt_reg(stl_exec_wrt_reg), 
                 .exec_wrt_en(stl_exec_wrt_en), .exec_jb_stall(stl_exec_jb_stall), .mem_wrt_reg(stl_mem_wrt_reg), .mem_wrt_en(stl_mem_wrt_en), .mem_jb_stall(stl_mem_jb_stall), 
                 .wb_wrt_reg(stl_wb_wrt_reg), .wb_wrt_en(stl_wb_wrt_en), .wb_jb_stall(stl_wb_jb_stall), .rw_stall(stl_rw_stall), .jb_stall(stl_jb_stall));


    // Pipeline Connections //

    /* [31:0] is reserved for control/stall signals
    UNUSED = 31:17, alu_op = 16:9, alu_imm_src 8, rf_write_en = 7, datamem_write_en = 6, datamem_read_en = 5, rf_write_mem_src = 4,
    pc_src = 3, pc_jmp_src = 2, rw_stall = 1, jb_stall = 0 */
    cpu_pipereg #(.PIPE_WIDTH(IFID_WIDTH)) IFID_pipe (.clk(clk), .rst_n(rst_n), .pipe_in(IFID_in), .pipe_out(IFID_out), .pipe_en(IFID_en));
    cpu_pipereg #(.PIPE_WIDTH(IDEX_WIDTH)) IDEX_pipe (.clk(clk), .rst_n(rst_n), .pipe_in(IDEX_in), .pipe_out(IDEX_out), .pipe_en(IDEX_en));
    cpu_pipereg #(.PIPE_WIDTH(EXMEM_WIDTH)) EXMEM_pipe (.clk(clk), .rst_n(rst_n), .pipe_in(EXMEM_in), .pipe_out(EXMEM_out), .pipe_en(EXMEM_en));
    cpu_pipereg #(.PIPE_WIDTH(MEMWB_WIDTH)) MEMWB_pipe (.clk(clk), .rst_n(rst_n), .pipe_in(MEMWB_in), .pipe_out(MEMWB_out), .pipe_en(MEMWB_en));

    // Misc Registers //

    //Flags
    cpu_pipereg #(.PIPE_WIDTH(1)) NF_flag (.clk(clk), .rst_n(rst_n), .pipe_in(alu_NF), .pipe_out(NF_flg), .pipe_en(alu_NF_en));
    cpu_pipereg #(.PIPE_WIDTH(1)) ZF_flag (.clk(clk), .rst_n(rst_n), .pipe_in(alu_ZF), .pipe_out(ZF_flg), .pipe_en(alu_ZF_en));
    cpu_pipereg #(.PIPE_WIDTH(1)) OF_flag (.clk(clk), .rst_n(rst_n), .pipe_in(alu_OF), .pipe_out(OF_flg), .pipe_en(alu_OF_en));
    cpu_pipereg #(.PIPE_WIDTH(1)) CF_flag (.clk(clk), .rst_n(rst_n), .pipe_in(alu_CF), .pipe_out(CF_flg), .pipe_en(alu_CF_en));

    //Misc
    cpu_pipereg #(.PIPE_WIDTH(1)) Ex_rd_vld (.clk(clk), .rst_n(rst_n), .pipe_in(ex_rd_en), .pipe_out(ex_rd_valid), .pipe_en(1'b1)); // rd valid should be good cycle after rd request

    // Top Level Logic //

    //All External Outputs
    assign ex_rd_data = mem_ex_rd_data;
    assign ex_rd_valid = 1'b0; //TODO
    assign accel_rd_data = mem_accel_rd_data;
    assign cpu_wrt_en = mem_cpu_wrt_en;
    assign cpu_wrt_data = mem_cpu_wrt_data;
    assign cpu_addr = mem_cpu_addr;
    
    //IF //TODO: PC logic
    assign IFID_in[31:0] = 32'h0; //reserved //TODO: remove?
    assign IFID_in[63:32] = im_rd_out; //instruction
    assign IFID_en = 1'b1; //TODO: fix for stalls
    assign im_rd_addr = pc_new;
    assign im_addr = (im_wrt_en) ? im_wrt_addr : im_rd_addr; // read from pc if not writing from external

    assign pc_new = pc_out + 4; //TODO
    //external inputs    
    assign im_wrt_addr = ex_addr;
    assign im_wrt_en = ex_im_wrt_en;
    assign im_wrt_data = ex_wrt_data;

    //ID //TODO: done?
    assign IDEX_in[31:0] = {15'h0, ctrl_alu_op, ctrl_alu_imm_src, ctrl_rf_write_en, ctrl_datamem_write_en, ctrl_datamem_read_en, //ctrl
                            ctrl_rf_write_mem_src, ctrl_pc_src, ctrl_pc_jmp_src, stl_rw_stall, stl_jb_stall}; 
    assign IDEX_in[63:32] = rf_reg1;
    assign IDEX_in[95:64] = rf_reg2;
    assign IDEX_in[127:96] = {{16{rf_instr[15]}}, rf_instr[15:0]}; // imm TODO: for sure sign extended?
    assign IDEX_in[159:128] = rf_instr[23:20]; //wb reg
    assign IDEX_en = 1'b1; //TODO: fix for stalls
    assign rf_instr = IFID_out[63:32];
    //(uses prev pipe stage to keep synchronus because of 1 cycle reads)
    assign rf_sel1 = im_instr[19:16]; //Rs 
    assign rf_sel2 = (im_instr[31:24] == 8'b10000111 || im_instr[31:24] == 8'b10000011) ? im_instr[23:20] : im_instr[15:12]; //Rd : Rt (Rd is second src reg for stores only) 

    //EX //TODO: flag outputs
    assign EXMEM_in[31:0] = IDEX_out[31:0]; //ctrl
    assign EXMEM_in[63:32] = alu_Out; //alu output
    assign EXMEM_in[95:64] = IDEX_out[95:64]; //pass reg2 for mem data
    assign EXMEM_in[127:96] = IDEX_out[159:128]; //wb reg pass through
    assign EXMEM_en = 1'b1; //TODO: fix for stalls
    assign alu_A = IDEX_out[63:32]; //reg1
    assign alu_B = (IDEX_out[8]) ? IDEX_out[127:96] : IDEX_out[95:64]; //imm : reg2

    //MEM //TODO: done?
    assign MEMWB_in[31:0] = EXMEM_out[31:0]; //ctrl
    assign MEMWB_in[63:32] = mem_cpu_rd_data; //cpu rd out data
    assign MEMWB_in[95:64] = EXMEM_out[63:32]; //from alu out, op result pass through
    assign MEMWB_in[127:96] = EXMEM_out[127:96]; //wb reg pass through
    assign MEMWB_en = 1'b1; //TODO: fix for stalls
    //(uses prev pipe stage to keep synchronus because of 1 cycle reads)
    assign mem_cpu_addr = EXMEM_out[63:32]; //from alu out, addr for mem //TODO: move pipe inside wrapper? no logic between mem modules and pipes
    assign mem_cpu_wrt_data = EXMEM_out[95:64]; //from reg2 //TODO: move pipe inside wrapper? no logic between mem modules and pipes
    assign mem_cpu_wrt_en = EXMEM_out[6]; //ctrl
    assign mem_cpu_rd_en = EXMEM_out[5]; //ctrl
    //external inputs
    assign mem_accel_addr = accel_addr;
    assign mem_accel_wrt_data = accel_wrt_data;
    assign mem_accel_wrt_en = accel_wrt_en;
    assign mem_ex_addr = ex_addr;
    assign mem_ex_wrt_data = ex_wrt_data;
    assign mem_ex_wrt_en = ex_mem_wrt_en;
    assign mem_ex_rd_en = ex_mem_rd_en;

    //WB //TODO: done?
    assign rf_wrt_data = (MEMWB_out[4]) ? MEMWB_out[63:32] : MEMWB_out[95:64]; //mem : alu
    assign rf_wrt_sel = MEMWB_out[127:96]; //wb reg
    assign rf_wrt_en = MEMWB_out[7]; //ctrl wrt en

    //Stall detection //TODO: done?
    assign stl_if_instr = im_rd_out; // next instruction
    assign stl_dec_wrt_reg = rf_instr[23:20]; //wb reg
    assign stl_dec_wrt_en = ctrl_rf_write_en; //wb en
    assign stl_dec_jb_stall = (rf_instr[31:28] == 4'b0011); //if j or b instruction
    assign stl_exec_wrt_reg = IDEX_out[159:128]; //wb reg
    assign stl_exec_wrt_en = IDEX_out[7]; //wb en
    assign stl_exec_jb_stall = IDEX_out[0]; //active jb stall
    assign stl_mem_wrt_reg = EXMEM_out[127:96]; //wb reg
    assign stl_mem_wrt_en = EXMEM_out[7]; //wb en
    assign stl_mem_jb_stall = EXMEM_out[0]; //active jb stall
    assign stl_wb_wrt_reg = MEMWB_out[127:96]; //wb reg
    assign stl_wb_wrt_en = MEMWB_out[7]; //wb en
    assign stl_wb_jb_stall = MEMWB_out[0]; //active jb stall

endmodule
