module cpu_rf(clk, rst_n, sel1, sel2, wrt_sel, wrt_data, rf_write_en, reg1, reg2);

    input         clk, rst_n;
    input  [3:0]  sel1, sel2, wrt_sel;
    input  [31:0] wrt_data;
    input         rf_write_en;
    output [31:0] reg1, reg2;

endmodule