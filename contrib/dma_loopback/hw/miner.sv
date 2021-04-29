/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu
//
// Author: Logan Sisel
//
// Detail: Top level for miner design.
//         Contains CPU, Block of Accelerators, 
//         and Memory Controller to/from the host.
//         hc_ signals connect host controller and CPU.
//         he_ signals connect host controller and external signals.
//         ac_ signals connect accelerator block and CPU.
//
/////////////////////////////////////////////////////////////////////////////////////
module miner (
    input clk, rst_n,
    input host_init,
    input host_rd_ready,
    input host_wr_ready,
    input [63:0] address_offset,
    input [511:0] host_data_bus_read_in,
    output [511:0] host_data_bus_write_out,
    output [63:0] corrected_address,
    output host_re,
	output host_we,
	output host_rgo,
	output host_wgo
    );

    logic [1:0]  hc_op;
    logic [31:0] hc_common_data_bus_read_in;
    logic [31:0] hc_common_data_bus_write_out;
    logic        hc_ready, tx_done, rd_valid;
    logic [63:0] hc_raw_address;

    logic [31:0]  ac_accel_wrt_data;
    logic [15:0]  ac_accel_addr;
    logic [15:0]  ac_accel_rd_addr;
    logic [15:0]  ac_accel_wrt_addr;
    logic         ac_accel_wrt_en;
    logic         ac_accel_rd_en;
    logic [511:0] ac_accel_rd_data;
    logic         ac_cpu_wrt_en;
    logic [31:0]  ac_cpu_wrt_data;
    logic [15:0]  ac_cpu_addr;
    logic         ac_mem_acc_write_done;
    logic         ac_mem_acc_read_data_valid;

    logic         ac_upstream_write_done;
    logic         ac_upstream_read_valid;

    // always_ff @(posedge clk) begin
    //     if (host_wgo | host_we) $display("                  MINER host_wgo:%h host_we:%h addr:%h wData:%0h", host_wgo, host_we, corrected_address, host_data_bus_write_out);    
    // end
    
    cpu   cpu0 (.clk(clk), 
                .rst_n(rst_n),  
                .ex_addr(hc_raw_address), 
                .ex_wrt_data(hc_common_data_bus_write_out), 
                .accel_wrt_data(ac_accel_wrt_data), 
                .accel_addr(ac_accel_addr), 
                .accel_wrt_en(ac_accel_wrt_en),
                .accel_rd_en(ac_accel_rd_en),
                .accel_wrt_done(ac_upstream_write_done),
                .accel_rd_valid(ac_upstream_read_valid),
                .ex_rd_data(hc_common_data_bus_read_in), 
                .accel_rd_data(ac_accel_rd_data), 
                .cpu_wrt_en(ac_cpu_wrt_en), 
                .cpu_wrt_data(ac_cpu_wrt_data), 
                .cpu_addr(ac_cpu_addr),
                .ready(hc_ready), 
                .tx_done(hc_tx_done), 
                .rd_valid(hc_rd_valid),
                .op(hc_op));
    
    mem_ctrl  #(.WORD_SIZE(32), 
                .CL_SIZE_WIDTH(512), 
                .ADDR_BITCOUNT(64)) 
     mem_ctrl0 (.clk(clk), 
                .rst_n(rst_n), 
                .host_init(host_init), 
                .host_rd_ready(host_rd_ready), 
                .host_wr_ready(host_wr_ready), 
                .op(hc_op), 
                .raw_address(hc_raw_address), 
                .address_offset(address_offset), 
                .common_data_bus_read_in(hc_common_data_bus_read_in), 
                .common_data_bus_write_out(hc_common_data_bus_write_out), 
                .host_data_bus_read_in(host_data_bus_read_in), 
                .host_data_bus_write_out(host_data_bus_write_out), 
                .corrected_address(corrected_address), 
                .ready(hc_ready), 
                .tx_done(hc_tx_done), 
                .rd_valid(hc_rd_valid), 
                .host_re(host_re), 
                .host_we(host_we), 
                .host_rgo(host_rgo), 
                .host_wgo(host_wgo));

    accelerators accelerators0(.clk(clk), 
                               .rst_n(rst_n),
                               .mem_listen_addr(ac_cpu_addr), 
                               .mem_listen_en(ac_cpu_wrt_en),
                               .mem_listen_data(ac_cpu_wrt_data),
                               .mem_acc_read_data(ac_accel_rd_data),
                               .mem_acc_read_data_valid(ac_mem_acc_read_data_valid),
                               .mem_acc_write_done(ac_mem_acc_write_done),
                               .upstream_write_done(ac_upstream_write_done), 
                               .upstream_read_valid(ac_upstream_read_valid), 
                               .mem_acc_read_addr(ac_accel_rd_addr),
                               .mem_acc_read_en(ac_accel_rd_en),
                               .mem_acc_write_en(ac_accel_wrt_en), 
                               .mem_acc_write_data(ac_accel_wrt_data), 
                               .mem_acc_write_addr(ac_accel_wrt_addr));

    assign ac_accel_addr = (ac_accel_wrt_en) ? ac_accel_wrt_addr : ac_accel_rd_addr;

    assign ac_mem_acc_write_done = 1'b0;
    assign ac_mem_acc_read_data_valid = 1'b0;

endmodule