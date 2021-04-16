module acc_compr_sche_op_tb ();


logic clk, rst_n;
wire [255:0] cm_out;
logic hash_done;
logic cm_init, cm_enable;
logic ms_init, ms_enable;
logic [1023:0] temp;
logic [511:0] message;
logic [31:0] w_in;
integer f1, f2;

class blk_hdr_t;
    rand bit [639:0] blk_hdr; // unpadded block header
endclass

blk_hdr_t new_blk = new();

// DUTS
accel_compressor_op compr0(.cm_out(cm_out), .hash_done(hash_done), // output
                           .cm_init(cm_init), .cm_enable(cm_enable), .w(w_in), // input
                           .clk(clk), .rst_n(rst_n));

acc_message_scheduler_op sche0(.ms_r0_out(w_in), // output
                               .ms_init(ms_init), .ms_enable(ms_enable), .message(message), // input
                               .clk(clk), .rst_n(rst_n));


// clock
initial clk = 0;
always
  #5 clk = ~clk;


// test compressor
initial begin

f1 = $fopen("hash_in.txt", "w");
f2 = $fopen("simu_out_accel.txt", "w");

rst_n = 0;
@(negedge clk);
rst_n = 1;

for (int k = 0; k < 1000; k++) begin

    cm_enable = 0;
    cm_init = 0;
    ms_enable = 0;
    ms_init = 0;

    if (new_blk.randomize() == 0)
        $display("failed to generate random number\n");
    
    // 1024 = 640(msg.) + 320(padding) + 64(length)
    // msg. length = 640; randomly generated
    temp = {new_blk.blk_hdr, 1'b1, 319'b0, 64'b10_1000_0000};
    $fwrite(f1, "%h\n", new_blk.blk_hdr);
    $display("raw block header = %h\n", new_blk.blk_hdr);
    $display("padded block header = %h\n", temp);


// msg. scheduler
// ms_init = 1
// @ posedge(clk) -> load [w0:w15], ms_ro_out = w0
// ms_enable = 1
// @ posedge(clk) -> ms_ro_out = w1

// compressor
// cm_init = 1 -> @ posedge(clk) -> @ INIT -> @ posedge(clk) -> hash reset
// cm_enable = 1 -> @ posedge(clk) -> @ UPD1-> @ posedge(clk) -> ([A:H] <- [H0:H7])

// when @UPD1, assert ms_init
// for every cycle @HASH, assert ms_enable

/////////////////////////
//// stage 1 hashing ////
    message = temp[1023:512];
    // @ IDLE
    cm_init = 1;
    @(posedge clk); // @ INIT
    cm_init = 0;
    cm_enable = 1;
    @(posedge clk); // @ UPD1
    ms_init = 1;
    cm_enable = 0;
    @(posedge clk); // @ HASH
    ms_init = 0;
    ms_enable = 1;
    for (int i = 0; i < 64; i++) begin
        @(posedge clk);
    end
    @(posedge clk);
    ms_enable = 0;
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    // $display("@ DONE, hashdone = %d\n", hash_done);
    $display("stage 1 hash = %h\n", cm_out);
    @(posedge clk); // @ IDLE
//// stage 1 hashing ////
/////////////////////////


/////////////////////////
//// stage 2 hashing ////
    message = temp[511:0];
    cm_enable = 1;
    @(posedge clk); // @ UPD1
    cm_enable = 0;
    ms_init = 1;
    @(posedge clk); // @ HASH
    ms_init = 0;
    ms_enable = 1;
    for (int i = 0; i < 64; i++) begin
        @(posedge clk);
    end
    @(posedge clk);
    ms_enable = 0;
    @(posedge clk); // @ UPD2
    @(posedge clk); // @ DONE
    $display("stage 2 hash = %h\n", cm_out);
    @(posedge clk); // @ IDLE
//// stage 2 hashing ////
/////////////////////////


/////////////////////////
//// stage 3 hashing ////
    // 512 = 256(stage 2 hash) + 192(padding) + 64(length)
    message = {cm_out, 1'b1, 191'b0, 64'b1_0000_0000};
    $display("stage 3 input = %h\n", message);
    cm_init = 1;
    @(posedge clk); // @ INIT
    cm_init = 0;
    cm_enable = 1;
    @(posedge clk); // @ UPD1
    cm_enable = 0;
    ms_init = 1;
    @(posedge clk); // @ HASH
    ms_init = 0;
    ms_enable = 1;
    for (int i = 0; i < 64; i++) begin
        @(posedge clk);
    end
    @(posedge clk);
    ms_enable = 0;
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
