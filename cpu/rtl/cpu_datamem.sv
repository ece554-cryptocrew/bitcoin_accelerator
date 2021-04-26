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

module cpu_datamem (clk, rst_n, cpu_addr, cpu_wrt_data, cpu_wrt_en, cpu_rd_en, ex_wrt_en, ex_rd_en, ex_addr, ex_wrt_data, 
                    accel_addr, accel_wrt_data, accel_wrt_en, accel_rd_en, accel_wrt_done, accel_rd_valid, cpu_rd_data, ex_rd_data, accel_rd_data);

    input                clk, rst_n;
    input        [15:0]  cpu_addr; 
    input        [31:0]  cpu_wrt_data; 
    input                cpu_wrt_en;
    input                cpu_rd_en;
    input        [15:0]  ex_addr; 
    input        [31:0]  ex_wrt_data; 
    input                ex_wrt_en;
    input                ex_rd_en;
    input        [15:0]  accel_addr; 
    input        [31:0]  accel_wrt_data; 
    input                accel_wrt_en;
    input                accel_rd_en;
    output               accel_wrt_done, accel_rd_valid;
    output logic [31:0]  cpu_rd_data; 
    output logic [31:0]  ex_rd_data;
    output logic [511:0] accel_rd_data; 

    logic [15:0]  addr_arb;
    logic [31:0]  wrt_data_arb;
    logic         wrt_en_arb;
    logic [511:0] rd_data_raw;
    logic         ex_priority, cpu_priority;
    logic         accel_wrt_done_next, accel_rd_valid_next;

    cpu_datamem_mem datamem(.clk(clk), .rst_n(rst_n), .addr(addr_arb), .wrt_data(wrt_data_arb), .wrt_en(wrt_en_arb), .rd_data(rd_data_raw));

    assign accel_rd_data = rd_data_raw;
    assign cpu_rd_data = rd_data_raw[31:0];
    assign ex_rd_data = rd_data_raw[31:0];

    assign addr_arb = (ex_priority) ? ex_addr : ((cpu_priority) ? cpu_addr : accel_addr);
    assign wrt_data_arb = (ex_priority) ? ex_wrt_data : ((cpu_priority) ? cpu_wrt_data : accel_wrt_data);
    assign wrt_en_arb = (ex_priority) ? ex_wrt_en : ((cpu_priority) ? cpu_wrt_en : accel_wrt_en);

    // TODO: is this the arbritration we want? Currently gives priority to host if writing or reading, 
    //       then to cpu if writing or reading, then to accel
    // TODO: add fifo for storing accel reads and writes
    assign ex_priority = (ex_wrt_en | ex_rd_en);
    assign cpu_priority = (cpu_wrt_en | cpu_rd_en);

    assign accel_wrt_done_next = (!ex_priority && !cpu_priority) && (accel_wrt_en);
    assign accel_rd_valid_next = (!ex_priority && !cpu_priority) && (accel_rd_en);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accel_wrt_done <= 1'b0;
            accel_rd_valid <= 1'b0;
        end
        else begin
            accel_wrt_done <= accel_wrt_done_next;
            accel_rd_valid <= accel_rd_valid_next;
        end
    end

endmodule
