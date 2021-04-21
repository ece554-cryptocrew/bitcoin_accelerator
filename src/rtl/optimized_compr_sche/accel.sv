
// Integrate the control, compressor and the message scheduler.
// blk_hdr: a raw block header(80 bytes) to be hashed
// hash_start: assert to start hashing blk_hdr
// hash_done: will be asserted when hashing is done
// hash: the SHA-256 hash of the block header(blk_hdr)


module accel(hash_done, hash,
             hash_start, blk_hdr,
             clk, rst_n);

input hash_start;
input [639:0] blk_hdr;
input clk, rst_n;

output hash_done;
output [255:0] hash;

logic update_A_H, update_H0_7;
logic rst_hash_n, is_hashing;
logic ms_init, ms_enable;
logic save_hash;
logic [1023:0] blk_hdr_full;
logic [511:0] message_next;
logic [255:0] intermediate_hash;
logic [31:0] w;
logic [6:0] i;
logic [1:0] msg_sel;


acc_control_unit
#(

)
ctrl0
(
    .clk(clk), .rst_n(rst_n),

    .mem_listen_addr(),
    .mem_listen_en(),
    .mem_listen_data(),

    .mem_acc_read_data(),
    .mem_acc_read_data_valid(),
    .mem_acc_write_done(),

    .cm_out(hash),

    /// Output
    .mem_acc_read_addr(),
    .mem_acc_read_en(),

    .mem_acc_write_en(),
    .mem_acc_write_data(),
    .mem_acc_write_addr(),

    .ms_init(ms_init),
    .ms_enable(ms_enable),

    .cm_is_hashing(is_hashing),
    .cm_update_A_H(update_A_H),
    .cm_update_H0_7(update_H0_7),
    .cm_rst_hash_n(rst_hash_n),
    .cm_cycle_count(i),

    // Save intermediate hashes
    .should_save_hash(save_hash),

    // Message select
    .msg_sel(msg_sel),

    .hash_done(hash_done)
);

accel_compressor_op compr0 (.cm_out(hash),
                            .update_A_H(update_A_H), .update_H0_7(update_H0_7),
                            .rst_hash_n(rst_hash_n), .is_hashing(is_hashing), .i(i),
                            .w(w), .clk(clk), .rst_n(rst_n));

acc_message_scheduler_op sche0 (.message(message_next), .ms_r0_out(w),
                                .ms_init(ms_init), .ms_enable(ms_enable),
                                .clk(clk), .rst_n(rst_n));

// intermediate hash register
always_ff @(posedge clk) begin
    if (!rst_n)
        intermediate_hash <= 0;
    else if (save_hash)
        intermediate_hash <= hash;
end

// full block header
assign blk_hdr_full = {blk_hdr, 1'b1, 319'b0, 64'b10_1000_0000};

// next message to be expanded
// 2'b00: lower
// 2'b01: upper
// 2'b1x: saved hash
assign message_next = (msg_sel == 2'b00) ? blk_hdr_full[1023:512] :
                      (msg_sel == 2'b01) ? blk_hdr_full[511:0]    :
                      {intermediate_hash, 1'b1, 191'b0, 64'b1_0000_0000};

endmodule
