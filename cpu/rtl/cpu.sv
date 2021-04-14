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
module cpu (clk, rst_n, ex_wrt_en, ex_wrt_addr, ex_wrt_data, accel_wrt_data, accel_addr, accel_wrt_en, 
            ex_rd_data, ex_rd_valid, accel_rd_data, cpu_wrt_en, cpu_wrt_data, cpu_addr);

    input          clk, rst_n;
    input          ex_wrt_en;
    input  [15:0]  ex_wrt_addr;
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

endmodule