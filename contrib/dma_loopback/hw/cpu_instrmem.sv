/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_instrmem
//
// Author: Logan Sisel
//
// Detail: Instruction memory for the CPU.
//         Read only, byte Addressable, 64k Bytes (2^16 addresses).
//         Reads access 4 bytes at...
//           mem[addr], mem[addr+1]...
//         Initialized by loader on reset, first instruction at 0x0000.
//         
// Mem Map: 
// Instruction Memory
// 0x0000-0xFFFF
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_instrmem (clk, rst_n, addr, wrt_en, wrt_data, rd_out);

    input             clk, rst_n;
    input      [15:0] addr; 
    input             wrt_en;
    input      [31:0] wrt_data;
    output reg [31:0] rd_out;

    localparam MEM_SIZE = 65536;

    logic [7:0] mem [0:MEM_SIZE-1];

    // Read logic
    // Set rd_out to 0 if invalid address
    //assign rd_out = (addr % 4 == 0) ? mem[addr+3:addr] : 32'h0; //TODO: does this work? no
    always_ff @(posedge clk or negedge rst_n) begin
        rd_out[7:0] <= mem[addr];
        rd_out[15:8] <= mem[addr+1];
        rd_out[23:16] <= mem[addr+2];
        rd_out[31:24] <= mem[addr+3];
    end

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < MEM_SIZE/16; i = i + 1) begin
                mem[i*16] <= 8'h0;
                mem[i*16+1] <= 8'h0;
                mem[i*16+2] <= 8'h0;
                mem[i*16+3] <= 8'h0;
                mem[i*16+4] <= 8'h0;
                mem[i*16+5] <= 8'h0;
                mem[i*16+6] <= 8'h0;
                mem[i*16+7] <= 8'h0;
                mem[i*16+8] <= 8'h0;
                mem[i*16+9] <= 8'h0;
                mem[i*16+10] <= 8'h0;
                mem[i*16+11] <= 8'h0;
                mem[i*16+12] <= 8'h0;
                mem[i*16+13] <= 8'h0;
                mem[i*16+14] <= 8'h0;
                mem[i*16+15] <= 8'h0;
            end
        end
        else if (wrt_en) begin
            mem[addr]   <= wrt_data[7:0];
            mem[addr+1] <= wrt_data[15:8];
            mem[addr+2] <= wrt_data[23:16];
            mem[addr+3] <= wrt_data[31:24];
        end
    end

endmodule
