module cpu_datamem (clk, rst_n, cpu_addr, cpu_wrt_data, cpu_wrt_en, accel_addr, accel_wrt_data, accel_wrt_en, cpu_rd_data, accel_rd_data);

    input          clk, rst_n;
    input  [15:0]  cpu_addr; //byte addressable
    input  [31:0]  cpu_wrt_data;
    input          cpu_wrt_en;
    input  [15:0]  accel_addr; //byte addressable
    input  [31:0]  accel_wrt_data;
    input          accel_wrt_en;
    output [31:0]  cpu_rd_data;
    output [511:0] accel_rd_data;

endmodule