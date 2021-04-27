/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_rf
//
// Author: Logan Sisel
//
// Detail: R0 is zero register.
//         R1-15 are general purpose.
//         
/////////////////////////////////////////////////////////////////////////////////////
module cpu_rf(clk, rst_n, sel1, sel2, wrt_sel, wrt_data, wrt_en, reg1, reg2, err);

    input         clk, rst_n;
    input  [3:0]  sel1, sel2, wrt_sel;
    input  [31:0] wrt_data;
    input         wrt_en;
    output logic [31:0] reg1, reg2;
    output logic        err;

    logic [31:0] regs [0:15];

    // Error if trying to write non-zero number to R0, R0 stays zero
    assign err = ((wrt_data != 32'h0) & (wrt_sel == 4'h0) & wrt_en);

    // Read logic
    // assign reg1 = regs[sel1]; // TODO: Think this is supposed to be done synchro, not sure
    // assign reg2 = regs[sel2];


    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < 16; i = i + 1) begin
                regs[i] <= 32'h0;
            end
        end
        else if (wrt_en) begin
            regs[wrt_sel] <= wrt_data;
        end
        reg1 <= regs[sel1];
        reg2 <= regs[sel2];
    end

endmodule
