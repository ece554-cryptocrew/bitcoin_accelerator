module accel_compressor_tb ();


logic clk, rst_n;
wire [255:0] cm_out;
logic hash_done;
logic cm_init, cm_enable;
logic [1023:0] temp;
logic [511:0] m0_packed, m1_packed, m2_packed;
logic [31:0] m0_unpacked [0:15];
logic [31:0] m1_unpacked [0:15];
logic [31:0] m2_unpacked [0:15];
logic [31:0] sigma0, sigma1;
logic [31:0] w [0:63];
logic [31:0] w_in;
integer f1, f2;

class blk_hdr_t;
    rand bit [639:0] blk_hdr; // unpadded block header
endclass

blk_hdr_t new_blk = new();

// DUT
accel_compressor_op DUT(.cm_out(cm_out), .hash_done(hash_done), // output
                        .cm_init(cm_init), .cm_enable(cm_enable), .w(w_in), // input
                        .clk(clk), .rst_n(rst_n));


// clock
initial clk = 0;
always
  #5 clk = ~clk;


// test compressor
initial begin

f1 = $fopen("hash_in.txt", "w");
f2 = $fopen("simu_out_accel.txt", "w");

for (int k = 0; k < 1000; k++) begin
    rst_n = 0;
    cm_enable = 0;
    cm_init = 0;
    if (new_blk.randomize() == 0)
        $display("failed to generate random number\n");
    // 1024 = 640(msg.) + 320(padding) + 64(length)
    // msg. length = 640; randomly generated
    temp = {new_blk.blk_hdr, 1'b1, 319'b0, 64'b10_1000_0000};
    {m0_packed, m1_packed} = temp;
    $fwrite(f1, "%h\n", new_blk.blk_hdr);
    $display("raw block header = %h\n", new_blk.blk_hdr);
    $display("padded block header = %h\n", temp);
    m0_unpacked = {>> 32 {m0_packed}};
    m1_unpacked = {>> 32 {m1_packed}};

    @(negedge clk);
    rst_n = 1;

/////////////////////////
//// stage 1 hashing ////
    // compute w_i
    for (int i = 0; i < 64; i++) begin
        if (i < 16)
            w[i] = m0_unpacked[i];
        else begin
            // sigma0 = ROTR7(x) XOR ROTR18(x) XOR [Logic]SHR3(x)
            sigma0 = {w[i-15][6:0], w[i-15][31:7]} ^ {w[i-15][17:0], w[i-15][31:18]} ^ {3'b0, w[i-15][31:3]};
            // sigma0 = ROTR17(x) XOR ROTR19(x) XOR [Logic]SHR10(x)
            sigma1 = {w[i-2][16:0], w[i-2][31:17]} ^ {w[i-2][18:0], w[i-2][31:19]} ^ {10'b0, w[i-2][31:10]};
            w[i] = sigma0 + w[i-7] + sigma1 + w[i-16];
        end
    end

    // @ IDLE
    cm_init = 1;
    @(posedge clk); // @ INIT
    cm_init = 0;
    cm_enable = 1;
    @(posedge clk); // @ UPD1
    cm_enable = 0;
    @(posedge clk); // @ HASH
    for (int i = 0; i < 64; i++) begin
        w_in = w[i];
        @(posedge clk);
    end
    @(posedge clk);
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    // $display("@ DONE, hashdone = %d\n", hash_done);
    $display("stage 1 hash = %h\n", cm_out);
    @(posedge clk); // @ IDLE
//// stage 1 hashing ////
/////////////////////////


/////////////////////////
//// stage 2 hashing ////
    // compute w_i
    for (int i = 0; i < 64; i++) begin
        if (i < 16)
            w[i] = m1_unpacked[i];
        else begin
            // sigma0 = ROTR7(x) XOR ROTR18(x) XOR [Logic]SHR3(x)
            sigma0 = {w[i-15][6:0], w[i-15][31:7]} ^ {w[i-15][17:0], w[i-15][31:18]} ^ {3'b0, w[i-15][31:3]};
            // sigma0 = ROTR17(x) XOR ROTR19(x) XOR [Logic]SHR10(x)
            sigma1 = {w[i-2][16:0], w[i-2][31:17]} ^ {w[i-2][18:0], w[i-2][31:19]} ^ {10'b0, w[i-2][31:10]};
            w[i] = sigma0 + w[i-7] + sigma1 + w[i-16];
        end
    end

    cm_enable = 1;
    @(posedge clk); // @ UPD1
    cm_enable = 0;
    @(posedge clk); // @ HASH
    for (int i = 0; i < 64; i++) begin
        w_in = w[i];
        @(posedge clk);
    end
    @(posedge clk);
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    $display("stage 2 hash = %h\n", cm_out);
    @(posedge clk); // @ IDLE
//// stage 2 hashing ////
/////////////////////////


/////////////////////////
//// stage 3 hashing ////
    // 512 = 256(stage 2 hash) + 192(padding) + 64(length)
    m2_packed = {cm_out, 1'b1, 191'b0, 64'b1_0000_0000};
    $display("stage 3 input = %h\n", m2_packed);
    m2_unpacked = {>> 32 {m2_packed}};
    // compute w_i
    for (int i = 0; i < 64; i++) begin
        if (i < 16)
            w[i] = m2_unpacked[i];
        else begin
            // sigma0 = ROTR7(x) XOR ROTR18(x) XOR [Logic]SHR3(x)
            sigma0 = {w[i-15][6:0], w[i-15][31:7]} ^ {w[i-15][17:0], w[i-15][31:18]} ^ {3'b0, w[i-15][31:3]};
            // sigma0 = ROTR17(x) XOR ROTR19(x) XOR [Logic]SHR10(x)
            sigma1 = {w[i-2][16:0], w[i-2][31:17]} ^ {w[i-2][18:0], w[i-2][31:19]} ^ {10'b0, w[i-2][31:10]};
            w[i] = sigma0 + w[i-7] + sigma1 + w[i-16];
        end
    end

    cm_init = 1;
    @(posedge clk); // @ INIT
    cm_init = 0;
    cm_enable = 1;
    @(posedge clk); // @ UPD1
    cm_enable = 0;
    @(posedge clk); // @ HASH
    for (int i = 0; i < 64; i++) begin
        w_in = w[i];
        @(posedge clk);
    end
    @(posedge clk);
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    $display("final hash = %h\n", cm_out);
    $fwrite(f2, "%h\n", cm_out);
    @(posedge clk); // @ INIT
//// stage 3 hashing ////
/////////////////////////
end // end for

    $fclose(f1);
    $fclose(f2);
    $stop;
end

endmodule
