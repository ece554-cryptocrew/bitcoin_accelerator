/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_pipereg
//
// Author: Logan Sisel
//
// Detail: Parametrizable width register for pipelines        
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_pipereg(clk, rst_n, pipe_in, pipe_out, pipe_en);
    
    parameter PIPE_WIDTH = 32;

    input             clk, rst_n;
    input      [PIPE_WIDTH-1:0] pipe_in;
    output reg [PIPE_WIDTH-1:0] pipe_out;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_out <= {PIPE_WIDTH{1'b0}};
        end
        else begin
            if (pipe_en) pipe_out <= pipe_in;
        end
    end

endmodule
