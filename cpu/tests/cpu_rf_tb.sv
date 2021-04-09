module cpu_rf_tb();

    logic        clk, rst_n;
    logic [3:0]  sel1, sel2, wrt_sel;
    logic [31:0] wrt_data;
    logic        wrt_en;
    logic [31:0] reg1, reg2;
    logic        err;

    integer errs;
    integer i, j;

    logic [31:0] mock_rf [0:15];

    cpu_rf rf(.clk(clk), .rst_n(rst_n), .sel1(sel1), .sel2(sel2), .wrt_sel(wrt_sel), .wrt_data(wrt_data), .wrt_en(wrt_en), .reg1(reg1), .reg2(reg2), .err(err));

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

        @(posedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        rst_n = 1'b1;
        
        for (i = 0; i < 100; i=i+1) begin
            $display("------------------------------------");
            //Dump registers
            for (j = 0; j < 16; j=j+1) begin
                sel1 = j;
                @(posedge clk); //TODO: Why do we need >1 clk cycle? Problem? Its a synchronous issue, idk
                #1;
                $display("Mock: Reg %0h: %0h", j, mock_rf[j]);
                $display("Real: Reg %0h: %0h", j, reg1);
            end
            $display("------------------------------------");

            @(posedge clk);
            sel1 = $random();
            sel2 = $random();
            wrt_sel = $random();
            wrt_data = $random();
            wrt_en = $random(); 
            @(posedge clk); //TODO: Why do we need >1 clk cycle? Problem?
            #1;
            if (wrt_en) begin
                mock_rf[wrt_sel] = wrt_data;
                $display("Writing to reg %0h, data = %0h", wrt_sel, wrt_data);
            end
            @(posedge clk); //TODO: Why do we need >1 clk cycle? Problem?
            #1;
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
            @(posedge clk);
        end
        
        
        
        if (errs == 0) $display("TEST PASSED");
        else $display("FAILED: errs = %0d", errs);
        $stop;
    end

    always #5 clk = ~clk;

endmodule