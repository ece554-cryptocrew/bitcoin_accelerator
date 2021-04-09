/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_alu
//
// Author: Adam Pryor
//
// Detail: Does operation on A and B based on opcode.
//		   Fields for each resulting flag, plus fields for 
//		   whether each flag should be updated (_en).
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_alu(A, B, Op, Out, OF, OF_en, CF, CF_en, ZF, ZF_en, NF, NF_en); 

input  [31:0] A;
input  [31:0] B;
input  [7:0]  Op;
output [31:0] Out;
output        OF, OF_en;
output        CF, CF_en;
output        ZF, ZF_en;
output        NF, NF_en; //TODO: update flags and flag enables for each function

logic [31:0] top42muxOut;
logic [31:0] bot42muxOut;
logic [31:0] bPassthrough;
logic [31:0] rotateOut; 
logic [31:0] topFinalMuxOut;
logic [31:0] bottomFinalMuxOut;
logic [63:0] multiply;

assign multiply = A*B;
assign bPassthrough = Op[2] ? (A + B) : B; // Mux on diagram with Op[2]
assign top42muxOut = Op[2] ? (Op[1] ? (multiply >> 32) : (A * B)) : (Op[1] ? (A - B) : (A + B)); // Top 4:2 mux.  If Op[2:1] is 3 or 2, then Mult, if 1, Sub, if 0 add //TODO: Fix for MULTH
assign bot42muxOut = Op[2] ? rotateOut : Op[1] ? (A >> B) : (A << B); // Bot 4:2 mux.  If Op[2:1] is 3 or 2 then rotate by B etc..
assign topFinalMuxOut = Op[4] ? top42muxOut : bot42muxOut;
assign bottomFinalMuxOut = Op[7] ? (Op[2] ? (A+B) : B) : A;
assign Out = (Op[4] || Op[5]) ? topFinalMuxOut : bottomFinalMuxOut;

always_comb begin

case(B[4:0])
	5'h0: rotateOut = A;
	5'h1: rotateOut = {A[0],A[31:1]};
	5'h2: rotateOut = {A[1:0],A[31:2]};
	5'h3: rotateOut = {A[2:0],A[31:3]};
	5'h4: rotateOut = {A[3:0],A[31:4]};
	5'h5: rotateOut = {A[4:0],A[31:5]};
	5'h6: rotateOut = {A[5:0],A[31:6]};
	5'h7: rotateOut = {A[6:0],A[31:7]};
	5'h8: rotateOut = {A[7:0],A[31:8]};
	5'h9: rotateOut = {A[8:0],A[31:9]};
	5'h10: rotateOut = {A[9:0],A[31:10]};
	5'h11: rotateOut = {A[10:0],A[31:11]};
	5'h12: rotateOut = {A[11:0],A[31:12]};
	5'h13: rotateOut = {A[12:0],A[31:13]};
	5'h14: rotateOut = {A[13:0],A[31:14]};
	5'h15: rotateOut = {A[14:0],A[31:15]};
	5'h16: rotateOut = {A[15:0],A[31:16]};
	5'h17: rotateOut = {A[16:0],A[31:17]};
	5'h18: rotateOut = {A[17:0],A[31:18]};
	5'h19: rotateOut = {A[18:0],A[31:19]};
	5'h20: rotateOut = {A[19:0],A[31:20]};
	5'h21: rotateOut = {A[20:0],A[31:21]};
	5'h22: rotateOut = {A[21:0],A[31:22]};
	5'h23: rotateOut = {A[22:0],A[31:23]};
	5'h24: rotateOut = {A[23:0],A[31:24]};
	5'h25: rotateOut = {A[24:0],A[31:25]};
	5'h26: rotateOut = {A[25:0],A[31:26]};
	5'h27: rotateOut = {A[26:0],A[31:27]};
	5'h28: rotateOut = {A[27:0],A[31:28]};
	5'h29: rotateOut = {A[28:0],A[31:29]};
	5'h30: rotateOut = {A[29:0],A[31:30]};
	5'h31: rotateOut = {A[30:0],A[31]};
endcase

end

endmodule
