///////////////////////////////////////////////////////////////////////////////
// Accelerator SHA256 Message Scheduler
//
// This module is the one of the workers of the Accelerator. It extends the
// original message according to the SHA256 algorithm.
//
// The internals of this unit are based around a group of Circular Buffers
// made up of 16 32-bit registers.
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_message_schduler
#(
)
(
    clk, rst_n,

    /// Input
    // Message Scheduler initialization and enable signal
    ms_init, ms_enable,

    // Original message
    message,

    /// Output
    // Output, should be the content of the top register of the circular buffer
    ms_r0_out
);
// Size of the input message port
localparam MESSAGE_SIZE      = 512;

// How many registers in the circular buffer
localparam CB_REG_COUNT      = 16;

// Size of each register in the circular buffer
localparam CB_REG_SIZE       = 32;

// ===============
/// I/O
// ===============
 input                                              clk, rst_n;

 input                                              ms_init, ms_enable;

 input                        [MESSAGE_SIZE - 1:0]  message;

output                         [CB_REG_SIZE - 1:0]  ms_r0_out;

// Internals
            reg                [CB_REG_SIZE - 1:0]  circular_buffer [CB_REG_COUNT - 1:0];
           wire                [CB_REG_SIZE - 1:0]  sigma_0;
           wire                [CB_REG_SIZE - 1:0]  sigma_1;
           wire                [CB_REG_SIZE - 1:0]  w;


/// ====================
/// Circular Buffer
/// ====================
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin

        for (integer i = 0; i < CB_REG_COUNT; i++) begin
            circular_buffer[i] <= '0;
        end

    end else if (ms_init) begin

        for (integer i = 0; i < CB_REG_COUNT; i++)
            circular_buffer[i] <= message[CB_REG_SIZE * i +: CB_REG_SIZE];

    end else if (ms_enable) begin

        for (integer i = 0; i < CB_REG_COUNT; i++) begin
            if (i == 15) circular_buffer[0]     <= w;
            else         circular_buffer[i + 1] <= circular_buffer[i];
        end

    end
end

/// ====================
/// Math
/// ====================
assign sigma_0 = (circular_buffer[2]  >>  7) ^ (circular_buffer[2]  >> 18) ^ (circular_buffer[2]  >> 3);
assign sigma_1 = (circular_buffer[15] >> 17) ^ (circular_buffer[15] >> 19) ^ (circular_buffer[15] >> 10);
assign w       = circular_buffer[1] + sigma_0 + circular_buffer[10] + sigma_1;

endmodule
