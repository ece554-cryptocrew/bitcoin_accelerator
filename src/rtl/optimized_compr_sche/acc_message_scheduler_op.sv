///////////////////////////////////////////////////////////////////////////////
// Accelerator SHA256 Message Scheduler
//
// This module is the one of the workers of the Accelerator. It extends the
// original message according to the SHA256 algorithm.
//
// The internals of this unit are based around a group of Circular Buffers
// made up of 16 32-bit registers.
//
// @author: Ryan Liang <p@ryanl.io>, Zhiyuan Lei
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_message_schduler_op (clk, rst_n, ms_init, ms_enable, message, ms_r0_out);

// Size of the input message port
localparam MESSAGE_SIZE = 512;

// How many registers in the circular buffer
localparam CB_REG_COUNT = 16;

// Size of each register in the circular buffer
localparam CB_REG_SIZE  = 32;

// ===============
/// I/O
// ===============
input clk, rst_n;

input ms_init, ms_enable;

input  [MESSAGE_SIZE - 1 : 0]  message;

output [CB_REG_SIZE - 1 : 0]   ms_r0_out;

// Internals
reg  [CB_REG_SIZE - 1 : 0]  buff      [0 : CB_REG_COUNT - 1];
wire [CB_REG_SIZE - 1 : 0]  buff_init [0 : CB_REG_COUNT - 1];
wire [CB_REG_SIZE - 1 : 0]  sigma_0;
wire [CB_REG_SIZE - 1 : 0]  sigma_1;
wire [CB_REG_SIZE - 1 : 0]  w;
logic [31:0] csa7_S, csa7_C, csa8_S, csa8_C;

// carry save adders
csa #(.dim(32)) csa7(.X(sigma_0), .Y(buff[0]), .Z(buff[9]), .S(csa7_S), .C(csa7_C));
csa #(.dim(32)) csa8(.X(sigma_1), .Y(csa7_S), .Z({csa7_C[30:0], 1'b0}), .S(csa8_S), .C(csa8_C));

assign buff_init = { >> CB_REG_SIZE {message} };

/// ====================
/// Math
/// ====================
assign sigma_0 = {buff[1][6:0], buff[1][31:7]} ^ {buff[1][17:0], buff[1][31:18]} ^ {3'b0, buff[1][31:3]};
assign sigma_1 = {buff[14][16:0], buff[14][31:17]} ^ {buff[14][18:0], buff[14][31:19]} ^ {10'b0, buff[14][31:10]};
assign w = csa8_S + {csa8_C[30:0], 1'b0};


/// ====================
/// Circular Buffer
/// ====================
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin

        for (integer i = 0; i < CB_REG_COUNT; i++) begin
            buff[i] <= '0;
        end

    end else if (ms_init) begin

        buff <= buff_init;

    end else if (ms_enable) begin

        for (integer i = 0; i < CB_REG_COUNT; i++) begin
            if (i == (CB_REG_COUNT - 1))
                buff[i] <= w;
            else
                buff[i] <= buff[i + 1];
        end

    end
end


/// ====================
/// Output
/// ====================
assign ms_r0_out = buff[0];

endmodule
