
// Integrate the control, compressor and the message scheduler
// mem_acc_read_data: a 512-bit message from memory
// hash_done: will be asserted when hashing is done
// hash: the SHA-256 hash of the block header(blk_hdr)


module accel(hash_done, hash, // output
             mem_acc_read_addr,
             mem_acc_read_en,
             mem_acc_write_en,
             mem_acc_write_data,
             mem_acc_write_addr,
             
             mem_listen_addr, // input
             mem_listen_en,
             mem_listen_data,
             mem_acc_read_data,
             mem_acc_read_data_valid,
             mem_acc_write_done,
             clk, rst_n
            );

input clk, rst_n;

// from memory
input [15:0] mem_listen_addr;
input mem_listen_en;
input [31:0] mem_listen_data;
input [511:0] mem_acc_read_data;
input mem_acc_read_data_valid;
input mem_acc_write_done;

output hash_done;
output [255:0] hash;

// to memory
output [15:0] mem_acc_read_addr;
output mem_acc_read_en;
output mem_acc_write_en;
output [31:0] mem_acc_write_data;
output [15:0] mem_acc_write_addr;

logic cm_update_A_H, cm_update_H0_7;
logic cm_rst_hash_n, cm_is_hashing;
logic ms_init, ms_enable;
logic should_save_hash;
logic [511:0] message; // message expanded by message scheduler
logic [255:0] intermediate_hash;
logic [31:0] w;
logic [6:0] cm_cycle_count;
logic [1:0] msg_sel;


acc_control_unit #() ctrl0
(
    // input
    .clk(clk), .rst_n(rst_n),

    .mem_listen_addr(mem_listen_addr),
    .mem_listen_en(mem_listen_en),
    .mem_listen_data(mem_listen_data),

    .mem_acc_read_data(mem_acc_read_data),
    .mem_acc_read_data_valid(mem_acc_read_data_valid),
    .mem_acc_write_done(mem_acc_write_done),

    .cm_out(hash),

    // output
    .mem_acc_read_addr(mem_acc_read_addr),
    .mem_acc_read_en(mem_acc_read_en),

    .mem_acc_write_en(mem_acc_write_en),
    .mem_acc_write_data(mem_acc_write_data),
    .mem_acc_write_addr(mem_acc_write_addr),

    .ms_init(ms_init),
    .ms_enable(ms_enable),

    .cm_is_hashing(cm_is_hashing),
    .cm_update_A_H(cm_update_A_H),
    .cm_update_H0_7(cm_update_H0_7),
    .cm_rst_hash_n(cm_rst_hash_n),
    .cm_cycle_count(cm_cycle_count),

    // Save intermediate hashes
    .should_save_hash(should_save_hash),

    // Message select
    .msg_sel(msg_sel),

    .hash_done(hash_done)
);

accel_compressor_op compr0 (.cm_out(hash),
                            .update_A_H(cm_update_A_H), .update_H0_7(cm_update_H0_7),
                            .rst_hash_n(cm_rst_hash_n), .is_hashing(cm_is_hashing), .i(cm_cycle_count),
                            .w(w), .clk(clk), .rst_n(rst_n));

acc_message_scheduler_op sche0 (.message(message), .ms_r0_out(w),
                                .ms_init(ms_init), .ms_enable(ms_enable),
                                .clk(clk), .rst_n(rst_n));

// intermediate hash register
always_ff @(posedge clk) begin
    if (!rst_n)
        intermediate_hash <= 0;
    else if (should_save_hash)
        intermediate_hash <= hash;
end


// next message to be expanded
// 2'b0x: message from data memory
// 2'b1x: saved hash
assign message = (msg_sel[1] == 0) ? mem_acc_read_data : {intermediate_hash, 1'b1, 191'b0, 64'b1_0000_0000};

endmodule
