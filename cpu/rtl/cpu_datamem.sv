/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_datamem
//
// Author: Logan Sisel
//
// Detail: Data memory module for the CPU.
//         Wrapper for the actual mem.
//         Handles Arbitration for CPU and accelerators.
//
/////////////////////////////////////////////////////////////////////////////////////

// TODO: Mem arbitration should be BEFORE pipe

module cpu_datamem (clk, rst_n, cpu_addr, cpu_wrt_data, cpu_wrt_en, cpu_rd_en, 
                    accel_addr, accel_wrt_data, accel_wrt_en, accel_rd_en, cpu_rd_data, accel_rd_data);

    input                clk, rst_n;
    input        [15:0]  cpu_addr; 
    input        [31:0]  cpu_wrt_data; 
    input                cpu_wrt_en;
    input                cpu_rd_en;
    input        [15:0]  accel_addr; 
    input        [31:0]  accel_wrt_data; 
    input                accel_wrt_en;
    input                accel_rd_en;
    output logic [31:0]  cpu_rd_data; 
    output logic [511:0] accel_rd_data; 
    //output logic         err;

    logic [15:0]  addr_arb;
    logic [31:0]  wrt_data_arb;
    logic         wrt_en_arb;
    logic [511:0] rd_data_raw;
    logic         arb; // 1 if choosing CPU, 0 if choosing Accel

    datamem_mem datamem(.clk(clk), .rst_n(rst_n), .addr(addr_arb), .wrt_data(wrt_data_arb), .wrt_en(wrt_en_arb), .rd_data(rd_data_raw));

    assign accel_rd_data = rd_data_raw;
    assign cpu_rd_data = rd_data_raw[31:0];

    assign addr_arb = (arb) ? cpu_addr : accel_addr;
    assign wrt_data_arb = (arb) ? cpu_wrt_data : accel_wrt_data;
    assign wrt_en_arb = (arb) ? cpu_wrt_en : accel_wrt_en;

    // TODO: is this the arbritration we want? Currently gives priority to CPU if it needs to write or read
    // TODO: add fifo for storing accel reads and writes
    assign arb = (cpu_wrt_en | cpu_rd_en);

endmodule
