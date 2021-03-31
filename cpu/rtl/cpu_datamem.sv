/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_datamem
//
// Author: Logan Sisel
//
// Detail: Data memory module for the CPU.
//         Byte Addressable, 64k Bytes (2^16 addresses).
//         Reads that access more than one byte (all) use access at...
//           data_mem[addr], data_mem[addr+1], ... , data_mem[addr+(size-1)]
//         Writes from CPU and Accel: 4 Bytes
//         Reads to CPU: 4 Bytes
//         Reads to Accel: 64 Bytes
//         
// Mem Map: 
//
// Host Communication
// 0x1000 (HCB_0) 
// 0x1100 (HCB_1)
// 0x2000 (HCB_2)
// 0x2100 (HCB_3)
// 0x3000 (HCB_4)
// 0x3100 (HCB_5)
// 0x4000 (HCB_6)
// 0x4100 (HCB_7)
//
// Accelerator Communication (40 Bytes)
// 0x5000 (ACB_0)
// 0x5100 (ACB_1)
// 0x6000 (ACB_2)
// 0x6100 (ACB_3)
// 0x7000 (ACB_4)
// 0x7100 (ACB_5)
// 0x8000 (ACB_6)
// 0x8100 (ACB_7)
//
// Stack
// 0x9000-0xFFFF
//
/////////////////////////////////////////////////////////////////////////////////////

module cpu_datamem (clk, rst_n, cpu_addr, cpu_wrt_data, cpu_wrt_en, cpu_rd_en, 
                    accel_addr, accel_wrt_data, accel_wrt_en, accel_rd_en, cpu_rd_data, accel_rd_data, err);

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
    output logic         err;

    localparam MEM_SIZE = 65536;

    logic [7:0] data_mem [0:MEM_SIZE-1]; // TODO: ensure little endian?

    // Error if cpu and accel to write at same time
    // Dont allow access within read/write size from top of mem, would overflow
    assign err = (accel_wrt_en & cpu_wrt_en) || 
                 ((cpu_wrt_en | cpu_rd_en) && (cpu_addr >= MEM_SIZE-3)) || 
                 ((accel_wrt_en) && (accel_addr >= MEM_SIZE-3)) ||
                 ((accel_rd_en) && (accel_addr >= MEM_SIZE-511));

    // Read logic
    // If not reading or invalid read (overflow), output 0
    always_comb begin
        if (cpu_rd_en && cpu_addr < MEM_SIZE-3) begin
            for (integer i = 0; i < 3; i = i + 1) begin
                cpu_rd_data[i] = data_mem[cpu_addr+i]; //TODO: Pretty sure this is wrong
            end
        end 
        else cpu_rd_data = 32'h0;
    end
    always_comb begin
        if (accel_rd_en && accel_addr < MEM_SIZE-63) begin
            for (integer i = 0; i < 63; i = i + 1) begin
                accel_rd_data[i] = data_mem[accel_addr+i]; //TODO: Pretty sure this is wrong
            end
        end 
        else accel_rd_data = 512'h0;
    end
        

    // Write logic
    // Priority goes to CPU write if both asserted, but also throws error
    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < MEM_SIZE; i = i + 1) begin
                data_mem[i] <= 8'h0;
            end
        end
        else if (cpu_wrt_en && cpu_addr < MEM_SIZE-3) begin
            for (integer i = 0; i < 4; i = i + 1) begin
                data_mem[cpu_addr+i] <= cpu_wrt_data[(8*i)+:8];
            end
        end
        else if (accel_wrt_en && accel_addr < MEM_SIZE-3) begin
            for (integer i = 0; i < 4; i = i + 1) begin
                data_mem[accel_addr+i] <= accel_wrt_data[(8*i)+:8];
            end
        end
    end

endmodule
