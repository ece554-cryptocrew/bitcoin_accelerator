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
module miner (clk, rst_n, );

    input clk, rst_n;
    

    cpu   cpu0 (.clk(clk), 
                .rst_n(rst_n), 
                .ex_im_wrt_en(), 
                .ex_mem_wrt_en(), 
                .ex_mem_rd_en(), 
                .ex_addr(hc_corrected_address[15:0]), 
                .ex_wrt_data(hc_common_data_bus_write_out), 
                .accel_wrt_data(), 
                .accel_addr(), 
                .accel_wrt_en(), 
                .ex_rd_data(hc_common_data_bus_read_in),  
                .accel_rd_data(), 
                .cpu_wrt_en(), 
                .cpu_wrt_data(), 
                .cpu_addr());
    
    mem_ctrl  #(.WORD_SIZE(32), 
                .CL_SIZE_WIDTH(512), 
                .ADDR_BITCOUNT(17)) 
     mem_ctrl0 (.clk(clk), 
                .rst_n(rst_n), 
                .host_init(he_host_init), 
                .host_rd_ready(he_host_rd_ready), 
                .host_wr_ready(he_host_wr_ready), 
                .op(op), 
                .raw_address(he_raw_address), 
                .address_offset(he_address_offset), 
                .common_data_bus_read_in(hc_common_data_bus_read_in), 
                .common_data_bus_write_out(hc_common_data_bus_write_out), 
                .host_data_bus_read_in(he_host_data_bus_read_in),
                .host_data_bus_write_out(he_host_data_bus_write_out), 
                .corrected_address(hc_corrected_address), 
                .ready(ready), 
                .tx_done(tx_done), 
                .rd_valid(rd_valid), 
                .host_re(he_host_re), 
                .host_we(he_host_we), 
                .host_rgo(he_host_rgo), 
                .host_wgo(he_host_wgo));




endmodule