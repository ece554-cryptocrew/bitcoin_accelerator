
module accel_compressor_op (cm_out,
                            update_A_H, update_H0_7,
                            rst_hash_n, is_hashing,
                            w, i, 
                            clk, rst_n);

input update_A_H, update_H0_7;
input rst_hash_n;
input is_hashing;
input [31:0] w;
input [6:0] i;
input clk, rst_n;

output [255:0] cm_out;

logic [31:0] k [0:63]; // constants
logic [31:0] hash_init [0:7]; // initial hash values
logic [31:0] hash [0:7]; // hash values
logic [31:0] hash_next [0:7];


// SHA-256 signals
logic [31:0] A, A0, A1, B, C, D, E, F, G, H;
logic [31:0] A0_next, A1_next, B_next, C_next, D_next, E_next, F_next, G_next, H_next;
logic [31:0] Maj_ABC, Ch_EFG, Sigma0_A, Sigma1_E;

// carry save adders
logic [31:0] csa1_S, csa1_C, csa2_S, csa2_C;
logic [31:0] csa3_S, csa3_C, csa4_S, csa4_C;
logic [31:0] csa5_S, csa5_C, csa6_S, csa6_C;
csa #(.dim(32)) csa1(.X(k[i]), .Y(H), .Z(w), .S(csa1_S), .C(csa1_C));
csa #(.dim(32)) csa2(.X(Ch_EFG), .Y(csa1_S), .Z({csa1_C[30:0], 1'b0}), .S(csa2_S), .C(csa2_C));
csa #(.dim(32)) csa3(.X(Sigma1_E), .Y(csa2_S), .Z({csa2_C[30:0], 1'b0}), .S(csa3_S), .C(csa3_C));
csa #(.dim(32)) csa4(.X(Maj_ABC), .Y(csa3_S), .Z({csa3_C[30:0], 1'b0}), .S(csa4_S), .C(csa4_C));
csa #(.dim(32)) csa5(.X(Sigma0_A), .Y(csa4_S), .Z({csa4_C[30:0], 1'b0}), .S(csa5_S), .C(csa5_C));
csa #(.dim(32)) csa6(.X(D), .Y(csa3_S), .Z({csa3_C[30:0], 1'b0}), .S(csa6_S), .C(csa6_C));


// SHA-256
assign cm_out = { >> {hash} }; // pack H
assign Maj_ABC = (A & B) ^ (B & C) ^ (C & A);
assign Ch_EFG = (E & F) ^ ((~E) & G);
// SIGMA0(A) = ROTR(A,2) XOR ROTR(A,13) XOR ROTR(A,22)
assign Sigma0_A = {A[1:0], A[31:2]} ^ {A[12:0], A[31:13]} ^ {A[21:0], A[31:22]};
// SIGMA1(E) = ROTR(E,6) XOR ROTR(E,11) XOR ROTR(E,25)
assign Sigma1_E = {E[5:0], E[31:6]} ^ {E[10:0], E[31:11]} ^ {E[24:0], E[31:25]};
assign A = A0 + A1;
assign A0_next = update_A_H ? hash[0] : (is_hashing ? csa5_S : A0);
assign A1_next = update_A_H ? 0 : (is_hashing ? {csa5_C[30:0], 1'b0} : A1);
assign B_next = update_A_H ? hash[1] : (is_hashing ?  A : B);
assign C_next = update_A_H ? hash[2] : (is_hashing ?  B : C);
assign D_next = update_A_H ? hash[3] : (is_hashing ?  C : D);
assign E_next = update_A_H ? hash[4] : (is_hashing ? (csa6_S + {csa6_C[30:0], 1'b0}) : E);
assign F_next = update_A_H ? hash[5] : (is_hashing ?  E : F);
assign G_next = update_A_H ? hash[6] : (is_hashing ?  F : G);
assign H_next = update_A_H ? hash[7] : (is_hashing ?  G : H);


// SHA-256 registers
always_ff @(posedge clk) begin
    if (!rst_n) begin
        A0 <= 0;
        A1 <= 0;
        B <= 0;
        C <= 0;
        D <= 0;
        E <= 0;
        F <= 0;
        G <= 0;
        H <= 0;
    end
    else begin
        A0 <= A0_next;
        A1 <= A1_next;
        B <= B_next;
        C <= C_next;
        D <= D_next;
        E <= E_next;
        F <= F_next;
        G <= G_next;
        H <= H_next;
    end
end


// hash value registers
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


/////////////////////
///// CONSTANTS /////
/////////////////////

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
