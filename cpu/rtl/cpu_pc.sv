/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_pc
//
// Author: Logan Sisel
//
// Detail: Contains the program counter.
//         Initializes to 0x0000.
//         pc_next is calculated at top level.        
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_pc(clk, rst_n, pc_next, pc);
    input             clk, rst_n;
    input      [15:0] pc_next;
    output reg [15:0] pc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0;
        end
        else begin
            pc <= pc_next;
        end
    end

endmodule
