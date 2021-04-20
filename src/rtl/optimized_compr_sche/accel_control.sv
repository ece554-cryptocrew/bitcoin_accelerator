module accel_control(hash_done, save_hash, msg_sel,
                     update_A_H, update_H0_7,
                     rst_hash_n, is_hashing, i,
                     ms_init, ms_enable,
                     hash_start, clk, rst_n);

input hash_start;
input clk, rst_n;

output logic hash_done, is_hashing;
output logic save_hash;
output logic [1:0] msg_sel;
output logic ms_init, ms_enable;
output logic update_A_H, update_H0_7;
output logic rst_hash_n;
output logic [6:0] i;

// state machine
typedef enum reg [2:0] {IDLE, INIT, UPD1, HASH, UPD2, DONE} state_t;
state_t state, next_state;
logic done;
logic rst_i_n, rst_s_n; // i: 0->64; s: 0->2
logic stage_inc;
logic [1:0] s; // stage counter


assign done = (i == 7'b100_0000); // 64
assign hash_done = (s == 2'b11);
assign msg_sel = s;

// hashing counter
always_ff @(posedge clk) begin
    if (!rst_n)
        i <= 0;
    else if (!rst_i_n)
        i <= 0;
    else if (is_hashing)
        i <= i + 1;
end

// stage counter
always_ff @(posedge clk) begin
    if (!rst_n)
        s <= 0;
    else if (!rst_s_n)
        s <= 0;
    else if (stage_inc)
        s <= s + 1;
end


// state machine
always_ff @(posedge clk) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always_comb begin
    rst_i_n = 1;
    rst_s_n = 1;
    rst_hash_n = 1;
    is_hashing = 0;
    stage_inc = 0;
    update_A_H = 0;
    update_H0_7 = 0;
    ms_init = 0;
    ms_enable = 0;
    save_hash = 0;
    next_state = IDLE;

    case (state)
        // IDLE: reset counters; wait
        IDLE: begin
            rst_i_n = 0;
            if (hash_start) begin
                rst_s_n = 0;
                next_state = INIT;
            end
        end

        // INIT: set initial hash values
        INIT:  begin
            rst_hash_n = 0;
            next_state = UPD1;
        end

        // UPD1: [A:H] <- [H0:H7]
        UPD1: begin
           update_A_H = 1;
           ms_init = 1;
           next_state = HASH;
        end

        // HASH: hashing
        HASH: begin
            if (done)
                next_state = UPD2;
            else begin
                is_hashing = 1;
                ms_enable = 1;
                next_state = HASH;
            end
        end

        // UPD2: [H0:H7] <- [H0:H7] + [A:H]
        UPD2: begin
           update_H0_7 = 1;
           next_state = DONE; 
        end

        // DONE: hashing completed
        DONE: begin
            rst_i_n = 0;
            stage_inc = 1;
            save_hash = 1;
            if (s == 2'b0)
                next_state = UPD1;
            else if (s == 2'b1)
                next_state = INIT;
        end
    endcase
end

endmodule
