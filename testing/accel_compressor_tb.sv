module accel_compressor_tb ();


logic clk, rst_n;
wire [255:0] cm_out;
logic hash_done;
logic cm_init, cm_enable;
logic [511:0] m0_packed, m1_packed;
logic [31:0] m0_unpacked [0:15];
logic [31:0] m1_unpacked [0:15];
logic [31:0] sigma0, sigma1;
logic [31:0] w [0:63];
logic [31:0] w_in;

class blk_hdr_t;
    rand bit [1023:0] blk_hdr;
endclass

blk_hdr_t new_blk = new();

// DUT
accel_compressor DUT(.cm_out(cm_out), .hash_done(hash_done), // output
                     .cm_init(cm_init), .cm_enable(cm_enable), .w(w_in), // input
                     .clk(clk), .rst_n(rst_n));


// clock
initial clk = 0;
always
  #5 clk = ~clk;


// test compressor
initial begin
    rst_n = 0;
    cm_enable = 0;
    cm_init = 0;
    if (new_blk.randomize() == 0)
        $display("failed to generate random number\n");
    {m0_packed, m1_packed} = new_blk.blk_hdr;
    m0_unpacked = {>> 32 {m0_packed}};
    m1_unpacked = {>> 32 {m1_packed}};

    @(negedge clk);
    rst_n = 1;

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

    // round 1 hashing
    // @ IDLE
    cm_init = 1;
    @(posedge clk);
    // @ INIT
    cm_init = 0;
    cm_enable = 1;
    @(posedge clk);
    // @ UPD1
    cm_enable = 0;
    @(posedge clk);
    // @ HASH
    for (int i = 0; i < 64; i++) begin
        w_in = w[i];
        @(posedge clk);
    end
    @(posedge clk); // last (64th) hash
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    $display("@ DONE, hashdone = %d\n", hash_done);
    $display("@ DONE, cm_out = %h\n", cm_out);

    $stop;
end

endmodule
