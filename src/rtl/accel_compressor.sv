/*
cm_init: asserted to start with a new block header
cm_enable: asserted to start hashing each 512-bit block
done: asserted for 1 cycle after finishing each of 64 rounds of hashing
cm_out: 256-bit hash
*/

module accel_compressor (cm_out, hash_done, cm_init, cm_enable, w, clk, rst_n);

input cm_init;
input cm_enable;
input [31:0] w;
input clk, rst_n;
output reg hash_done;
output [255:0] cm_out;

logic [31:0] k [0:63]; // constants
logic [31:0] hash_init [0:7]; // initial hash values
logic [31:0] hash [0:7]; // hash values
logic [31:0] hash_next [0:7];
logic [6:0] i; // counter


// SHA-256 signals
logic [31:0] A, B, C, D, E, F, G, H;
logic [31:0] A_next, B_next, C_next, D_next, E_next, F_next, G_next, H_next;
logic [31:0] T1, T2, Maj_ABC, Ch_EFG, Sigma0_A, Sigma1_E;

// state machine
typedef enum reg [2:0] {IDLE, INIT, UPD1, HASH, UPD2, DONE} state_t;
state_t state, next_state;
logic update_A_H, update_H0_7;
logic rst_i_n, rst_hash_n;
logic is_hashing;
logic done;

assign done = (i == 7'b100_0000); // 64
assign cm_out = { >> {hash} }; // pack H
assign T1 = H + Sigma1_E + Ch_EFG + k[i] + w;
assign T2 = Sigma0_A + Maj_ABC;
assign Maj_ABC = (A & B) ^ (B & C) ^ (C & A);
assign Ch_EFG = (E & F) ^ ((~E) & G);
// SIGMA0(A) = ROTR(A,2) XOR ROTR(A,13) XOR ROTR(A,22)
assign Sigma0_A = {A[1:0], A[31:2]} ^ {A[12:0], A[31:13]} ^ {A[21:0], A[31:22]};
// SIGMA1(E) = ROTR(E,6) XOR ROTR(E,11) XOR ROTR(E,25)
assign Sigma1_E = {E[5:0], E[31:6]} ^ {E[10:0], E[31:11]} ^ {E[24:0], E[31:25]};
assign A_next = update_A_H ? hash[0] : (is_hashing ? (T1 + T2) : A);
assign B_next = update_A_H ? hash[1] : (is_hashing ?  A : B);
assign C_next = update_A_H ? hash[2] : (is_hashing ?  B : C);
assign D_next = update_A_H ? hash[3] : (is_hashing ?  C : D);
assign E_next = update_A_H ? hash[4] : (is_hashing ? (D + T1) : E);
assign F_next = update_A_H ? hash[5] : (is_hashing ?  E : F);
assign G_next = update_A_H ? hash[6] : (is_hashing ?  F : G);
assign H_next = update_A_H ? hash[7] : (is_hashing ?  G : H);


// state machine
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always_comb begin
    rst_i_n = 1;
    rst_hash_n = 1;
    is_hashing = 0;
    hash_done = 0;
    update_A_H = 0;
    update_H0_7 = 0;
    next_state = IDLE;

    case (state)
        // IDLE: reset counter i; wait
        IDLE: begin
            rst_i_n = 0;
            if (cm_init)
                next_state = INIT;
            else if (cm_enable)
                next_state = UPD1; 
        end

        // INIT: set initial hash values
        INIT:  begin
            rst_hash_n = 0;
            if (cm_enable)
                next_state = UPD1;
            else
                next_state = INIT;
        end

        // UPD1: [A:H] <- [H0:H7]
        UPD1: begin
           update_A_H = 1;
           next_state = HASH; 
        end

        // HASH: hashing
        HASH: begin
            if (done)
                next_state = UPD2;
            else begin
                is_hashing = 1;
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
           hash_done = 1;
           next_state = IDLE; 
        end
    endcase
end


// SHA-256 registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        A <= 0;
        B <= 0;
        C <= 0;
        D <= 0;
        E <= 0;
        F <= 0;
        G <= 0;
        H <= 0;
    end
    else begin
        A <= A_next;
        B <= B_next;
        C <= C_next;
        D <= D_next;
        E <= E_next;
        F <= F_next;
        G <= G_next;
        H <= H_next;
    end
end


// hash values
assign hash_next[0] = hash[0] + A;
assign hash_next[1] = hash[1] + B;
assign hash_next[2] = hash[2] + C;
assign hash_next[3] = hash[3] + D;
assign hash_next[4] = hash[4] + E;
assign hash_next[5] = hash[5] + F;
assign hash_next[6] = hash[6] + G;
assign hash_next[7] = hash[7] + H;

always_ff @(posedge clk) begin
    if (!rst_n)
        hash <= { >> {0}};
    else if (!rst_hash_n)
        hash <= hash_init;
    else if (update_H0_7)
        hash <= hash_next;
end


// hashing counter
always_ff @(posedge clk) begin
    if (!rst_n)
        i <= 0;
    else if (!rst_i_n)
        i <= 0;
    else if(is_hashing)
        i <= i + 1;
end


// initial hash values
assign hash_init[0] = 32'h6a09e667;
assign hash_init[1] = 32'hbb67ae85;
assign hash_init[2] = 32'h3c6ef372;
assign hash_init[3] = 32'ha54ff53a;
assign hash_init[4] = 32'h510e527f;
assign hash_init[5] = 32'h9b05688c;
assign hash_init[6] = 32'h1f83d9ab;
assign hash_init[7] = 32'h5be0cd19;


// k constants
assign k[0] = 32'h428a2f98;
assign k[1] = 32'h71374491;
assign k[2] = 32'hb5c0fbcf;
assign k[3] = 32'he9b5dba5;
assign k[4] = 32'h3956c25b;
assign k[5] = 32'h59f111f1;
assign k[6] = 32'h923f82a4;
assign k[7] = 32'hab1c5ed5;

assign k[8] = 32'hd807aa98;
assign k[9] = 32'h12835b01;
assign k[10] = 32'h243185be;
assign k[11] = 32'h550c7dc3;
assign k[12] = 32'h72be5d74;
assign k[13] = 32'h80deb1fe;
assign k[14] = 32'h9bdc06a7;
assign k[15] = 32'hc19bf174;

assign k[16] = 32'he49b69c1;
assign k[17] = 32'hefbe4786;
assign k[18] = 32'h0fc19dc6;
assign k[19] = 32'h240ca1cc;
assign k[20] = 32'h2de92c6f;
assign k[21] = 32'h4a7484aa;
assign k[22] = 32'h5cb0a9dc;
assign k[23] = 32'h76f988da;

assign k[24] = 32'h983e5152;
assign k[25] = 32'ha831c66d;
assign k[26] = 32'hb00327c8;
assign k[27] = 32'hbf597fc7;
assign k[28] = 32'hc6e00bf3;
assign k[29] = 32'hd5a79147;
assign k[30] = 32'h06ca6351;
assign k[31] = 32'h14292967;

assign k[32] = 32'h27b70a85;
assign k[33] = 32'h2e1b2138;
assign k[34] = 32'h4d2c6dfc;
assign k[35] = 32'h53380d13;
assign k[36] = 32'h650a7354;
assign k[37] = 32'h766a0abb;
assign k[38] = 32'h81c2c92e;
assign k[39] = 32'h92722c85;

assign k[40] = 32'ha2bfe8a1;
assign k[41] = 32'ha81a664b;
assign k[42] = 32'hc24b8b70;
assign k[43] = 32'hc76c51a3;
assign k[44] = 32'hd192e819;
assign k[45] = 32'hd6990624;
assign k[46] = 32'hf40e3585;
assign k[47] = 32'h106aa070;

assign k[48] = 32'h19a4c116;
assign k[49] = 32'h1e376c08;
assign k[50] = 32'h2748774c;
assign k[51] = 32'h34b0bcb5;
assign k[52] = 32'h391c0cb3;
assign k[53] = 32'h4ed8aa4a;
assign k[54] = 32'h5b9cca4f;
assign k[55] = 32'h682e6ff3;

assign k[56] = 32'h748f82ee;
assign k[57] = 32'h78a5636f;
assign k[58] = 32'h84c87814;
assign k[59] = 32'h8cc70208;
assign k[60] = 32'h90befffa;
assign k[61] = 32'ha4506ceb;
assign k[62] = 32'hbef9a3f7;
assign k[63] = 32'hc67178f2;


endmodule
