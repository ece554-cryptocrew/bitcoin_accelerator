module cpu_instrmem (clk, rst_n, addr, rd_data);

    input clk, rst_n;
    input [15:0] instr_addr; //byte addressable
    output [15:0] instr;

endmodule