module cpu_datamem_tb();

    logic                clk, rst_n;
    logic        [15:0]  cpu_addr; 
    logic        [31:0]  cpu_wrt_data; 
    logic                cpu_wrt_en;
    logic                cpu_rd_en;
    logic        [15:0]  ex_addr; 
    logic        [31:0]  ex_wrt_data; 
    logic                ex_wrt_en;
    logic        [15:0]  accel_addr; 
    logic        [31:0]  accel_wrt_data; 
    logic                accel_wrt_en;
    logic        [31:0]  cpu_rd_data; 
    logic        [511:0] accel_rd_data;

    integer total_errs, errs;
    integer i, j;

    typedef enum {EX, CPU, ACCEL} mode_t;
    mode_t mode;

    localparam MEM_SIZE = 65536;

    logic [7:0] mock_mem [0:MEM_SIZE-1];
    logic [31:0] mock_cpu_rd_data;

    cpu_datamem DUT (.clk(clk), .rst_n(rst_n), .cpu_addr(cpu_addr), .cpu_wrt_data(cpu_wrt_data), .cpu_wrt_en(cpu_wrt_en), .cpu_rd_en(cpu_rd_en),
                     .ex_wrt_en(ex_wrt_en), .ex_addr(ex_addr), .ex_wrt_data(ex_wrt_data), .accel_addr(accel_addr), .accel_wrt_data(accel_wrt_data),
                     .accel_wrt_en(accel_wrt_en), .cpu_rd_data(cpu_rd_data), .accel_rd_data(accel_rd_data));

    initial begin
        clk = 1'b0;
        rst_n = 1'b1;
        errs = 0;
        total_errs = 0;
        cpu_addr = 16'h0;
        cpu_wrt_data = 32'h0;
        cpu_wrt_en = 1'h0;
        cpu_rd_en = 1'h0;
        ex_addr = 16'h0;
        ex_wrt_data = 32'h0;
        ex_wrt_en = 1'h0;
        accel_addr = 16'h0;
        accel_wrt_data = 32'h0;
        accel_wrt_en = 1'h0;
        mode = EX;

        for (i = 0; i < MEM_SIZE; i=i+1) begin
            mock_mem[i] = 32'h0;
        end

        @(posedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        rst_n = 1'b1;
        
        for (i = 0; i < 3000; i=i+1) begin
            @(posedge clk);
            cpu_addr = $urandom_range(15); // tight address space to allow for overwrites
            cpu_wrt_data = $urandom();
            cpu_wrt_en = $urandom();
            cpu_rd_en = 1'h0; // disable for now, only used for priority checking anyways
            ex_addr = $urandom_range(15);
            ex_wrt_data = $urandom();
            ex_wrt_en = $urandom();
            accel_addr = $urandom_range(15);
            accel_wrt_data = $urandom();
            accel_wrt_en = $urandom();
            mode = (ex_wrt_en) ? EX : ((cpu_wrt_en | cpu_rd_en) ? CPU : ACCEL); // priority is EX wrt > CPU wrt/rd > ACCEL wrt/rd
            @(posedge clk); //TODO: Why do we need >1 clk cycle? Problem?
            #1;
            $display("------------------------------------");
            if (mode == EX) $display("mode=EX");
            if (mode == CPU) $display("mode=CPU");
            if (mode == ACCEL) $display("mode=ACCEL");

            if (mode == EX && ex_wrt_en) begin
                mock_mem[ex_addr]  = ex_wrt_data[7:0];
                mock_mem[ex_addr+1] = ex_wrt_data[15:8];
                mock_mem[ex_addr+2] = ex_wrt_data[23:16];
                mock_mem[ex_addr+3] = ex_wrt_data[31:24];
                $display("Writing to addr %0h, data = %0h", ex_addr, ex_wrt_data);
            end
            else if (mode == CPU && cpu_wrt_en) begin
                mock_mem[cpu_addr]  = cpu_wrt_data[7:0];
                mock_mem[cpu_addr+1] = cpu_wrt_data[15:8];
                mock_mem[cpu_addr+2] = cpu_wrt_data[23:16];
                mock_mem[cpu_addr+3] = cpu_wrt_data[31:24];
                $display("Writing to addr %0h, data = %0h", cpu_addr, cpu_wrt_data);
            end
            else if (mode == ACCEL && accel_wrt_en) begin
                mock_mem[accel_addr]  = accel_wrt_data[7:0];
                mock_mem[accel_addr+1] = accel_wrt_data[15:8];
                mock_mem[accel_addr+2] = accel_wrt_data[23:16];
                mock_mem[accel_addr+3] = accel_wrt_data[31:24];
                $display("Writing to addr %0h, data = %0h", accel_addr, accel_wrt_data);
            end

            @(posedge clk); //TODO: Why do we need >1 clk cycle? Problem?
            #1;
            errs = 0;
            if (mode == EX) begin
                mock_cpu_rd_data = {mock_mem[ex_addr+3], mock_mem[ex_addr+2], mock_mem[ex_addr+1], mock_mem[ex_addr]};
                assert (cpu_rd_data == mock_cpu_rd_data)
                    $display("Valid @ addr = %0h, data = %0h", ex_addr, cpu_rd_data);
                else begin
                    $display("ERROR: BAD DATA: ex_addr = %0h, data = %0h, expecteddata = %0h", ex_addr, cpu_rd_data, mock_cpu_rd_data);
                    errs++;
                end
            end
            if (mode == CPU) begin
                mock_cpu_rd_data = {mock_mem[cpu_addr+3], mock_mem[cpu_addr+2], mock_mem[cpu_addr+1], mock_mem[cpu_addr]};
                assert (cpu_rd_data == mock_cpu_rd_data)
                    $display("Valid @ addr = %0h, data = %0h", cpu_addr, cpu_rd_data);
                else begin
                    $display("ERROR: BAD DATA: cpu_addr = %0h, data = %0h, expecteddata = %0h", cpu_addr, cpu_rd_data, mock_cpu_rd_data);
                    errs++;
                end
            end
            if (mode == ACCEL) begin
                mock_cpu_rd_data = {mock_mem[accel_addr+3], mock_mem[accel_addr+2], mock_mem[accel_addr+1], mock_mem[accel_addr]};
                assert (cpu_rd_data == mock_cpu_rd_data)
                    $display("Valid @ addr = %0h, data = %0h", accel_addr, cpu_rd_data);
                else begin
                    $display("ERROR: BAD DATA: accel_addr = %0h, data = %0h, expecteddata = %0h", accel_addr, cpu_rd_data, mock_cpu_rd_data);
                    errs++;
                end
            end
            if (errs != 0) total_errs++;
        end        
        
        if (total_errs == 0) $display("TEST PASSED");
        else $display("FAILED: errs = %0d", total_errs);
        $stop;
    end

    always #5 clk = ~clk;

endmodule