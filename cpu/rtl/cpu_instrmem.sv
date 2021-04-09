/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_instrmem
//
// Author: Logan Sisel
//
// Detail: Instruction memory for the CPU.
//         Read only, byte Addressable, 64k Bytes (2^16 addresses).
//         Reads access 2 bytes at...
//           instr_mem[instr_addr], instr_mem[instr_addr+1]
//         Initialized by loader on reset, first instruction at 0x0000.
//         
// Mem Map: 
// Instruction Memory
// 0x0000-0xFFFF
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_instrmem (clk, rst_n, instr_addr, wrt_en, wrt_addr, wrt_data, instr_out, err);

    input             clk, rst_n;
    input      [15:0] instr_addr; 
    input             wrt_en;
    input      [15:0] wrt_addr;
    input      [31:0] wrt_data;
    output reg [31:0] instr_out;
    output reg        err;

    localparam MEM_SIZE = 65536;

    logic [31:0] instr_mem [0:MEM_SIZE-1];

    // Error if instruction instr_addr not at valid location
    // Should be a multiple of 4 (0x0000, 0x0004, etc)
    assign err = (instr_addr % 4 != 0);

    // Read logic
    // Set instr_out to 0 if invalid address
    //assign instr_out = (instr_addr % 4 == 0) ? instr_mem[instr_addr+3:instr_addr] : 32'h0; //TODO: does this work? no
    always_comb begin
        if (instr_addr % 4 == 0) begin
            instr_out[7:0] = instr_mem[instr_addr];
            instr_out[15:8] = instr_mem[instr_addr+1];
            instr_out[23:16] = instr_mem[instr_addr+2];
            instr_out[31:24] = instr_mem[instr_addr+3];
            /*
            for (integer i = 0; i < 3; i = i + 1) begin
                instr_out[i] = instr_mem[instr_addr+i]; //TODO: Pretty sure this is wrong
            end
            */
        end 
        else begin
            instr_out = 32'h0;
        end
    end

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < MEM_SIZE; i = i + 1) begin
                instr_mem[i] <= 8'h0;
            end
        end
        else if (wrt_en && wrt_addr < MEM_SIZE-3) begin
            instr_mem[wrt_addr]   <= wrt_data[7:0];
            instr_mem[wrt_addr+1] <= wrt_data[15:8];
            instr_mem[wrt_addr+2] <= wrt_data[23:16];
            instr_mem[wrt_addr+3] <= wrt_data[31:24];
        end
    end

endmodule
