/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_stall
//
// Author: Adam Pryor
//
// Detail: Outputs two single bit stall signals if stall detected
//		   
//		   
//
/////////////////////////////////////////////////////////////////////////////////////
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
	output logic rw_stall,
	output logic jb_stall);


	assign rw_stall = (((if_instr[31:24] == 8'b00010001) || // Type L Instructions
			       (if_instr[31:24] == 8'b00010011) ||
			       (if_instr[31:24] == 8'b00010101) ||
			       (if_instr[31:24] == 8'b00100111) ||
			       (if_instr[31:24] == 8'b00100011) ||
			       (if_instr[31:24] == 8'b00100101) ||
			       (if_instr[31:24] == 8'b10000101) ||
			       (if_instr[31:24] == 8'b10000111)) && 
				
			       ((dec_wrt_en == 1'b1 && (dec_wrt_reg == if_instr[19:16])) ||
			       (exec_wrt_en == 1'b1 && (exec_wrt_reg == if_instr[19:16])) ||
			       (mem_wrt_en == 1'b1 && (mem_wrt_reg == if_instr[19:16])))) ? 1'b1 : 



			       (((if_instr[31:24] == 8'b00010000) || // Type R Instructions
			       (if_instr[31:24] == 8'b00010010) ||
			       (if_instr[31:24] == 8'b00010100) ||
			       (if_instr[31:24] == 8'b00010110) ||
			       (if_instr[31:24] == 8'b00100000) ||
			       (if_instr[31:24] == 8'b00100010) ||
			       (if_instr[31:24] == 8'b00100100)) &&

				((dec_wrt_en == 1'b1 && ((dec_wrt_reg == if_instr[19:16]) || (dec_wrt_reg == if_instr[15:12]))) ||
			       (exec_wrt_en == 1'b1 && ((exec_wrt_reg == if_instr[19:16]) || (exec_wrt_reg == if_instr[15:12]))) ||
			       (mem_wrt_en == 1'b1 && ((mem_wrt_reg == if_instr[19:16])   ||(mem_wrt_reg == if_instr[15:12]))))) ? 1'b1 : 

																	1'b0;
				
	assign jb_stall = exec_jb_stall | dec_jb_stall;


endmodule
	
