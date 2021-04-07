module cpu_stall(

	input logic [31:0] if_instr,
	input logic [3:0] dec_wrt_reg,
	input logic dec_wrt_en,
	input logic dec_jb_stall,
	input logic [3:0] exec_wrt_reg,
	input logic exec_wrt_en,
	input logic exec_jb_stall,
	input logic [3:0] mem_wrt_reg,
	input logic mem_wrt_en,
	input logic mem_jb_stall,
	input logic [3:0] wb_wrt_reg,
	input logic wb_wrt_en,
	input logic wb_jb_stall,
	output logic rd_wrt_stall,
	output logic jb_stall);





endmodule
	
