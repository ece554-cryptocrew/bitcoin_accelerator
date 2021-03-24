module cpu_alu();

input [31:0] A;
input [31:0] B;
input [7:0] Op;
output [31:0] Flags;
output [31:0] Out;

logic [32:0] top42muxOut;
logic [32:0] bot42muxOut;
logic [32:0] bPassthrough;

assign bPassthrough = Op[2] ? (A + B) : B; // Mux on diagram with Op[2]
assign top42muxOut = Op[2] ? (A * B) : Op[1] ? (A - B) : (A + B); // Top 4:2 mux.  If Op[2:1] is 3 or 2, then Mult, if 1, Sub, if 0 add
assign bot42muxOut = Op[2] ? 

endmodule
