module cpu_rf_tb();

    logic        clk, rst_n;
    logic [3:0]  sel1, sel2, wrt_sel;
    logic [31:0] wrt_data;
    logic        wrt_en;
    logic [31:0] reg1, reg2;
    logic        err;

    integer errs;
    integer i;

    reg [31:0] mock_rf [0:15];

    cpu_rf DUT(.clk(clk), 
               .rst_n(rst_n),  
               .sel1(sel1),  
               .sel2(sel2),  
               .wrt_sel(wrt_sel),  
               .wrt_data(wrt_data),  
               .wrt_en(wrt_en),  
               .reg1(reg1),  
               .reg2(reg2),  
               .err(err));

    initial begin
        clk = 1'b0;
        rst_n = 1'b1;
        errs = 0;
        sel1 = 4'h0;
        sel2 = 4'h0;
        wrt_sel = 4'h0;
        wrt_en = 1'b0;

        for (i = 0; i < 16; i=i+1) begin
            mock_rf[i] = 32'h0;
        end

        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
        
        for (i = 0; i < 100; i=i+1) begin
            @(negedge clk);
            sel1 = $random();
            sel2 = $random();
            wrt_sel = $random();
            wrt_data = $random();
            wrt_en = $random(); 
            $display("%0d", i);

            assert (reg1 == mock_rf[sel1]) $display("reg1 good: reg = %0h data = %0h", sel1, reg1);
                else begin
                    $display("ERROR: REG 1 BAD DATA: reg = %0h data = %0h expecteddata = %0h", sel1, reg1, mock_rf[sel1]);
                    errs++;
                end
            assert (reg2 == mock_rf[sel2]) $display("reg2 good: reg = %0h data = %0h", sel2, reg2);
                else begin
                    $display("ERROR: REG 2 BAD DATA: reg = %0h data = %0h expecteddata = %0h", sel2, reg2, mock_rf[sel2]);
                    errs++;
                end
            @(negedge clk);
            if (wrt_en) begin
                mock_rf[wrt_sel] = wrt_data;
                $display("Writing to reg %0h, data = %0h", wrt_sel, wrt_data);
            end
            
        end
        
        
        
        if (errs == 0) $display("TEST PASSED");
        else $display("FAILED: errs = %0d", errs);
        $stop;
    end

    always #5 clk = ~clk;

endmodule