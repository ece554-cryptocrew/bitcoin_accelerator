/////////////////////////////////////////////////////////////////////////////////////
//
// Module: datamem
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

module cpu_datamem_mem (clk, rst_n, addr, wrt_data, wrt_en, rd_data);

    input                clk, rst_n;
    input        [15:0]  addr; 
    input        [31:0]  wrt_data; 
    input                wrt_en;
    output logic [511:0] rd_data; 

    localparam MEM_SIZE = 65536;

    logic [7:0] data_mem [0:MEM_SIZE-1]; // TODO: ensure little endian?

    // Read logic
    // If not reading or invalid read (overflow), output 0
    always_comb begin
        if (rd_en && addr < MEM_SIZE-63) begin
            rd_data[7:0]     = data_mem[addr+0];
            rd_data[15:8]    = data_mem[addr+1];
            rd_data[23:16]   = data_mem[addr+2];
            rd_data[31:24]   = data_mem[addr+3];
            rd_data[39:32]   = data_mem[addr+4];
            rd_data[47:40]   = data_mem[addr+5];
            rd_data[55:48]   = data_mem[addr+6];
            rd_data[63:56]   = data_mem[addr+7];
            rd_data[71:64]   = data_mem[addr+8];
            rd_data[79:72]   = data_mem[addr+9];
            rd_data[87:80]   = data_mem[addr+10];
            rd_data[95:88]   = data_mem[addr+11];
            rd_data[103:96]  = data_mem[addr+12];
            rd_data[111:104] = data_mem[addr+13];
            rd_data[119:112] = data_mem[addr+14];
            rd_data[127:120] = data_mem[addr+15];
            rd_data[135:128] = data_mem[addr+16];
            rd_data[143:136] = data_mem[addr+17];
            rd_data[151:144] = data_mem[addr+18];
            rd_data[159:152] = data_mem[addr+19];
            rd_data[167:160] = data_mem[addr+20];
            rd_data[175:168] = data_mem[addr+21];
            rd_data[183:176] = data_mem[addr+22];
            rd_data[191:184] = data_mem[addr+23];
            rd_data[199:192] = data_mem[addr+24];
            rd_data[207:200] = data_mem[addr+25];
            rd_data[215:208] = data_mem[addr+26];
            rd_data[223:216] = data_mem[addr+27];
            rd_data[231:224] = data_mem[addr+28];
            rd_data[239:232] = data_mem[addr+29];
            rd_data[247:240] = data_mem[addr+30];
            rd_data[255:248] = data_mem[addr+31];
            rd_data[263:256] = data_mem[addr+32];
            rd_data[271:264] = data_mem[addr+33];
            rd_data[279:272] = data_mem[addr+34];
            rd_data[287:280] = data_mem[addr+35];
            rd_data[295:288] = data_mem[addr+36];
            rd_data[303:296] = data_mem[addr+37];
            rd_data[311:304] = data_mem[addr+38];
            rd_data[319:312] = data_mem[addr+39];
            rd_data[327:320] = data_mem[addr+40];
            rd_data[335:328] = data_mem[addr+41];
            rd_data[343:336] = data_mem[addr+42];
            rd_data[351:344] = data_mem[addr+43];
            rd_data[359:352] = data_mem[addr+44];
            rd_data[367:360] = data_mem[addr+45];
            rd_data[375:368] = data_mem[addr+46];
            rd_data[383:376] = data_mem[addr+47];
            rd_data[391:384] = data_mem[addr+48];
            rd_data[399:392] = data_mem[addr+49];
            rd_data[407:400] = data_mem[addr+50];
            rd_data[415:408] = data_mem[addr+51];
            rd_data[423:416] = data_mem[addr+52];
            rd_data[431:424] = data_mem[addr+53];
            rd_data[439:432] = data_mem[addr+54];
            rd_data[447:440] = data_mem[addr+55];
            rd_data[455:448] = data_mem[addr+56];
            rd_data[463:456] = data_mem[addr+57];
            rd_data[471:464] = data_mem[addr+58];
            rd_data[479:472] = data_mem[addr+59];
            rd_data[487:480] = data_mem[addr+60];
            rd_data[495:488] = data_mem[addr+61];
            rd_data[503:496] = data_mem[addr+62];
            rd_data[511:504] = data_mem[addr+63];
        end 
        else begin
            rd_data = 512'h0;
        end
    end
    
        
    // Write logic
    // Priority goes to CPU write if both asserted, but also throws error
    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < MEM_SIZE; i = i + 1) begin
                data_mem[i] <= 8'h0;
            end
        end
        else if (wrt_en && addr < MEM_SIZE-3) begin
            data_mem[addr]   <= wrt_data[7:0];
            data_mem[addr+1] <= wrt_data[15:8];
            data_mem[addr+2] <= wrt_data[23:16];
            data_mem[addr+3] <= wrt_data[31:24];
        end
    end

endmodule
