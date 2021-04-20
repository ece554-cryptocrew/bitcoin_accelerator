// test bench for an accelerator

module accel_tb ();

logic clk, rst_n;
logic hash_start;
logic hash_done;
logic [255:0] hash;
logic [639:0] blk_hdr;
integer f1, f2;

accel accel0 (.hash_done(hash_done), .hash(hash),
              .hash_start(hash_start), .blk_hdr(blk_hdr),
              .clk(clk), .rst_n(rst_n));


// generate random block headers(raw)
class blk_hdr_t;
    rand bit [639:0] blk_hdr;
endclass

blk_hdr_t new_blk = new();


// clock
initial clk = 0;
always
    #5 clk = ~clk;

initial begin
f1 = $fopen("hash_in.txt", "w");
f2 = $fopen("simu_out_accel.txt", "w");

rst_n = 0;
@(negedge clk);
rst_n = 1;

for (int k = 0; k < 1000; k++) begin

    if (new_blk.randomize() == 0)
        $display("failed to generate random number\n");
    
    $fwrite(f1, "%h\n", new_blk.blk_hdr);
    $display("raw block header = %h\n", new_blk.blk_hdr);

    blk_hdr = new_blk.blk_hdr;
    hash_start = 1;

    @(posedge clk);
    hash_start = 0;

    @(posedge hash_done);
    $display("final hash = %h\n", hash);
    $fwrite(f2, "%h\n", hash);

end // end for

$fclose(f1);
$fclose(f2);
$stop;

end // end initial

endmodule

