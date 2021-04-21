module cpu_control_tb ();
    
    logic        clk;
    logic [31:0] instr;
    logic [7:0]  alu_op;
    logic        alu_imm_src;
    logic        rf_write_en;
    logic        datamem_write_en;
    logic        datamem_read_en;
    logic        rf_write_mem_src;
    logic        pc_src;
    logic        pc_jmp_src;
    logic        err;

    integer i;
    integer cases;
    integer errs;

    // opcodes
    localparam ADDI   = 8'b00010001;
    localparam ADD    = 8'b00010000;
    localparam SUBI   = 8'b00010011;               
    localparam SUB    = 8'b00010010;
    localparam MULTLI = 8'b00010101;
    localparam MULTL  = 8'b00010100;
    localparam MULTHI = 8'b00010111;
    localparam MULTH  = 8'b00010110;
    localparam LSI    = 8'b00100001;
    localparam LS     = 8'b00100000;
    localparam RSI    = 8'b00100011;
    localparam RS     = 8'b00100010;
    localparam RORI   = 8'b00100101;
    localparam ROR    = 8'b00100100;
    localparam LDB    = 8'b10000101;
    localparam LDI    = 8'b10000001;
    localparam STB    = 8'b10000111;
    localparam STI    = 8'b10000011;
    localparam BNEQ   = 8'b00110011;
    localparam BLTZ   = 8'b00110101;
    localparam BGTZ   = 8'b00110111;
    localparam BLEZ   = 8'b00111001;
    localparam BGEZ   = 8'b00111011;
    localparam JMP    = 8'b00111101;
    localparam JMPI   = 8'b00111111;

    

    cpu_control DUT(.instr(instr),
                .alu_op(alu_op),
                .alu_imm_src(alu_imm_src), 
                .rf_write_en(rf_write_en),
                .datamem_write_en(datamem_write_en),
                .datamem_read_en(datamem_read_en),
                .rf_write_mem_src(rf_write_mem_src),
                .pc_src(pc_src),
                .pc_jmp_src(pc_jmp_src),
                .err(err));

    initial begin
        clk = 1'b0;
        errs = 0;
        cases = 0;
        instr = 32'h0;
        
        //////////////////////////////////////////////////
        //               MATH OPERATIONS                //
        //////////////////////////////////////////////////

        @(posedge clk);
        $display("ADDI");
        instr[31:24] = ADDI;
        @(negedge clk);
        assert (alu_op == ADDI) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (rf_write_mem_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_mem_src=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        @(posedge clk);
        $display("ADD");
        instr[31:24] = ADD;
        @(negedge clk);
        assert (alu_op == ADD) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (rf_write_mem_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_mem_src=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        @(posedge clk);
        $display("MULTHI");
        instr[31:24] = MULTHI;
        @(negedge clk);
        assert (alu_op == MULTHI) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (rf_write_mem_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_mem_src=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        @(posedge clk);
        $display("MULTL");
        instr[31:24] = MULTL;
        @(negedge clk);
        assert (alu_op == MULTL) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (rf_write_mem_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_mem_src=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        //////////////////////////////////////////////////
        //               LOADS AND STORES               //
        //////////////////////////////////////////////////

        @(posedge clk);
        $display("LDB");
        instr[31:24] = LDB;
        @(negedge clk);
        assert (alu_op == LDB) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (rf_write_mem_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_mem_src=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        @(posedge clk);
        $display("STI");
        instr[31:24] = STI;
        @(negedge clk);
        assert (alu_op == STI) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (alu_imm_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_imm_src=%b", alu_op);
            end
        assert (rf_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (pc_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end

        //////////////////////////////////////////////////
        //              JUMPS AND BRANCHES              //
        //////////////////////////////////////////////////

        @(posedge clk);
        $display("BNEQ");
        instr[31:24] = BNEQ;
        @(negedge clk);
        assert (alu_op == BNEQ) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (rf_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (pc_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end
        assert (pc_jmp_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_jmp_src=%b", alu_op);
            end

        @(posedge clk);
        $display("BGEZ");
        instr[31:24] = BGEZ;
        @(negedge clk);
        assert (alu_op == BGEZ) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (rf_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (pc_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end
        assert (pc_jmp_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_jmp_src=%b", alu_op);
            end

        @(posedge clk);
        $display("JMP");
        instr[31:24] = JMP;
        @(negedge clk);
        assert (alu_op == JMP) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (rf_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (pc_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end
        assert (pc_jmp_src == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_jmp_src=%b", alu_op);
            end

        @(posedge clk);
        $display("JMPI");
        instr[31:24] = JMPI;
        @(negedge clk);
        assert (alu_op == JMPI) cases++;
            else begin cases++; errs++;
                $display("FAILED: alu_op=%b", alu_op);
            end
        assert (rf_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: rf_write_en=%b", alu_op);
            end
        assert (datamem_write_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_write_en=%b", alu_op);
            end
        assert (datamem_read_en == 1'b0) cases++;
            else begin cases++; errs++;
                $display("FAILED: datamem_read_en=%b", alu_op);
            end
        assert (pc_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_src=%b", alu_op);
            end
        assert (pc_jmp_src == 1'b1) cases++;
            else begin cases++; errs++;
                $display("FAILED: pc_jmp_src=%b", alu_op);
            end

        if (errs == 0) $display("TEST PASSED, cases=%d", cases);
        else $display("FAILED: cases=%d errs=%d", cases, errs);
        $stop;
    end

    always #5 clk = ~clk;

endmodule