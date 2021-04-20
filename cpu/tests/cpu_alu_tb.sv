module cpu_alu_tb();
    
    logic clk;
    logic [31:0] A, B, Out;
    logic [7:0] Op;
    logic OF, OF_en, CF, CF_en, ZF, ZF_en, NF, NF_en;

    logic [31:0] Out_ex;
    logic [63:0] Out_big_ex;
    logic OF_ex, OF_en_ex, CF_ex, CF_en_ex, ZF_ex, ZF_en_ex, NF_ex, NF_en_ex;

    integer i;
    integer en_errs;
    integer ex_errs;
    integer flg_errs;

    localparam CYCLES = 10;

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

    cpu_alu DUT(.A(A), .B(B), .Op(Op), .Out(Out), .OF(OF), .OF_en(OF_en), .CF(CF), .CF_en(CF_en), .ZF(ZF), .ZF_en(ZF_en), .NF(NF), .NF_en(NF_en));

    initial begin
        clk = 1'b0;
        en_errs = 0;
        ex_errs = 0;
        flg_errs = 0;
        Op = 8'h0;
        A = 32'h0;
        B = 32'h0;
        @(posedge clk);

        $display("-----------------------------------------------------\n");
        $display("ADD\n");
        Op = ADD;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_ex = A + B;
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 1;
            ZF_en_ex = 1;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end

        $display("-----------------------------------------------------\n");
        $display("SUB\n");
        Op = SUB;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_ex = A-B;
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 1;
            ZF_en_ex = 1;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end
        
        $display("-----------------------------------------------------\n");
        $display("MULTL\n");
        Op = MULTL;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_big_ex = A * B;
            Out_ex = Out_big_ex[31:0];
            $display("test: %0h", Out_big_ex);
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 1;
            ZF_en_ex = 1;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end

        $display("-----------------------------------------------------\n");
        $display("MULTH\n");
        Op = MULTH;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_big_ex = A * B;
            Out_ex = Out_big_ex[63:32];
            $display("test: %0h", Out_big_ex);
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 1;
            ZF_en_ex = 1;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end

        $display("-----------------------------------------------------\n");
        $display("RSI\n");
        Op = RSI;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_ex = A >> B;
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 0;
            ZF_en_ex = 0;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end

        $display("-----------------------------------------------------\n");
        $display("LDB\n");
        Op = LDB;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_ex = A + B;
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 0;
            ZF_en_ex = 0;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end
        
        $display("-----------------------------------------------------\n");
        $display("LDI\n");
        Op = LDI;
        for (i=0; i<CYCLES; i=i+1) begin
            $display("------------------------------");
            @(posedge clk);
            A = $random();
            B = $random();
            $display("A=%0h, B=%0h", A, B);
            // Calculate expected values
            Out_ex = B;
            NF_ex = (Out_ex < 0);
            ZF_ex = (Out_ex == 0);
            NF_en_ex = 0;
            ZF_en_ex = 0;
            @(posedge clk);
            // Assertions
            assert (Out_ex == Out) $display("Out");
                else begin
                    $display("ERROR: Out_ex: %0h, Out: %0h", Out_ex, Out);
                    ex_errs++;
                end
            assert (ZF == ZF_ex) $display("ZF");
                else begin
                    $display("ERROR: ZF_ex: %0h, ZF: %0h", ZF_ex, ZF);
                    flg_errs++;
                end
            assert (NF == NF_ex) $display("NF");
                else begin
                    $display("ERROR: NF_ex: %0h, NF: %0h", NF_ex, NF);
                    flg_errs++;
                end
            assert (ZF_en == ZF_en_ex) $display("ZF_en");
                else begin
                    $display("ERROR: ZF_en_ex: %0h, ZF_en: %0h", ZF_en_ex, ZF_en);
                    en_errs++;
                end
            assert (NF_en == NF_en_ex) $display("NF_en");
            else begin
                    $display("ERROR: NF_en_ex: %0h, NF_en: %0h", NF_en_ex, NF_en);
                    en_errs++;
                end
        end

        if (en_errs == 0 && ex_errs == 0 && flg_errs == 0) $display("TEST PASSED");
        else $display("FAILED: ex_errs: %0d, en_errs: %0d, flg_errs: %0d", ex_errs, en_errs, flg_errs);
        $stop;
    end

    always #5 clk = ~clk;

endmodule