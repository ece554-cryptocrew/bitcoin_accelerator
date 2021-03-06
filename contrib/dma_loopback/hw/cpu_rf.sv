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
        
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) reg1 <= 32'h0;
        else if (wrt_en && (wrt_sel == sel1)) reg1 <= wrt_data;
        else reg1 <= regs[sel1]; 
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) reg2 <= 32'h0;
        else if (wrt_en && (wrt_sel == sel2)) reg2 <= wrt_data;
        else reg2 <= regs[sel2]; 
    end

    // always_ff @(posedge clk) begin
    //     $display("                          R0:%0h R1:%0h R2:%0h R3:%0h R4:%0h R5:%0h R6:%0h R7:%0h R8:%0h", regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], regs[8]);
    // end


endmodule
