///////////////////////////////////////////////////////////////////////////////
// Accelerator Control Unit
//
// This module is the brain of the Accelerator. It orchestrates the hashing
// operation within the block.
//
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module acc_control_unit
#(
    // CPU address line redirected from Data Memory for monitoring MMIO
    parameter MEM_LISTEN_ADDR_SIZE      = 16,
    // CPU data line redirected from Data Memory for monitoring MMIO
    parameter MEM_LISTEN_DATA_SIZE      = 32,

    // Address line going back to the Data Memory
    parameter MEM_ACC_READ_ADDR_SIZE    = 16,
    // Data line coming from the Data Memory
    parameter MEM_ACC_READ_DATA_SIZE    = 512,

    // Address line going out from the Accelerator to the Data Memory
    parameter MEM_ACC_WRITE_ADDR_SIZE   = 16,
    // Data line going out from the Accelerator to the Data Memory
    parameter MEM_ACC_WRITE_DATA_SIZE   = 32,

    // Starting address of the Host Communication Block in Data Memory
    parameter HCB_START_ADDR            = 16'h1000,
    // Offset of the Message from HCB starting address
    parameter HCB_MSG_OFFSET            = 16'h0008,
    // Starting address of the Accelerator Communication Block in Data Memory
    parameter ACB_START_ADDR            = 16'h5000,
    // Offset of h0 from ACB starting address
    parameter ACB_H0_OFFSET             = 16'h0008,

    // Set to write the Busy bit in the Status register
    parameter IS_WRITE_BUSY_BIT         = 1,

    // Set to indicate there is an Arbiter before we touch the Memory
    parameter IS_MEM_USE_ARBITER        = 1
)
(
    clk, rst_n,

    /// Input
    // CPU Data Memory monitoring
    mem_listen_addr, mem_listen_en, mem_listen_data,

    // Accelerator Data Memory line
    mem_acc_read_data,
    // Asserted by Arbiter when the Arbiter grants us our read access
    mem_acc_read_data_valid,

    // Asserted by Arbiter has written our data to the Memory
    mem_acc_write_done,

    // Output from the Compressor
    cm_out,

    /// Output
    // Accelerator memory read request to Data Memory
    mem_acc_read_addr, mem_acc_read_en,

    // Accelerator Data Memory write lines
    mem_acc_write_en, mem_acc_write_data, mem_acc_write_addr,

    // Message Scheduler initialization and enable signal
    ms_init, ms_enable,

    // Compressor initialization and enable signal
    cm_init, cm_enable
);

// Total cycles needed to complete one hash, counting from when we assert *_enable
localparam HASH_CYCLE_COUNT          = 64;

// Width of the resulting hash
localparam HASH_RESULT_LENGTH        = 256;

// Cycles needed to write the entire hash result
localparam HASH_WRITE_CYCLE          = HASH_RESULT_LENGTH / MEM_ACC_WRITE_DATA_SIZE;

// Address of h0 in ACB
localparam ACB_H0_ADDR               = ACB_START_ADDR + ACB_H0_OFFSET;

// Address of the message in HCB
localparam HCB_MSG_ADDR              = HCB_START_ADDR + HCB_MSG_OFFSET;

// ===============
/// I/O
// ===============
 input                                              clk, rst_n;

 input                [MEM_LISTEN_ADDR_SIZE - 1:0]  mem_listen_addr;
 input                                              mem_listen_en;
 input                [MEM_LISTEN_DATA_SIZE - 1:0]  mem_listen_data;

 input                                              mem_acc_read_data_valid;
 input              [MEM_ACC_READ_DATA_SIZE - 1:0]  mem_acc_read_data;

 input                                              mem_acc_write_done;

 input                  [HASH_RESULT_LENGTH - 1:0]  cm_out;

output      reg                                     mem_acc_read_en;
output      reg     [MEM_ACC_READ_ADDR_SIZE - 1:0]  mem_acc_read_addr;

output      reg                                     mem_acc_write_en;
output      reg    [MEM_ACC_WRITE_ADDR_SIZE - 1:0]  mem_acc_write_addr;
output      reg    [MEM_ACC_WRITE_DATA_SIZE - 1:0]  mem_acc_write_data;

output      reg                                     ms_init, ms_enable;
output      reg                                     cm_init, cm_enable;

// Internal
            reg  [$clog2(dummy_state.num()) - 1:0]  curr_state, next_state;
            reg   [$clog2(HASH_CYCLE_COUNT) - 1:0]  hash_cycle_counter;

           // Assert to start the hash_cycle counter
            reg                                     hash_cycle_counter_en;
           // Deassert to reset the hash_cycle counter
            reg                                     hash_cycle_counter_rst_n;

// ===============
/// States
// ===============
typedef enum {
    IDLE,             // Reset/Idle

    READ_MESSAGE,     // Read message from Data Memory

    WRITE_BUSY_BIT,   // Writing the busy bit to Data Memory

    INIT,             // Initialize both MS and CM

    HASH,             // Processing hash

    // @optimization(ryan): There might be better ways to do this than to
    // hard code all 8 parts of the write.
    WRITE_H0,         // Write h0 back to Data Memory
    WRITE_H1,         // Write h1 back to Data Memory
    WRITE_H2,         // Write h2 back to Data Memory
    WRITE_H3,         // Write h3 back to Data Memory
    WRITE_H4,         // Write h4 back to Data Memory
    WRITE_H5,         // Write h5 back to Data Memory
    WRITE_H6,         // Write h6 back to Data Memory
    WRITE_H7,         // Write h7 back to Data Memory

    WRITE_DONE_BIT    // Write the done bit to Data Memory

} state_t;
state_t dummy_state;  // Dummy state so we can use .num() to get the cardinality.

// ===============
// FSM
// ===============
always_comb begin

    // Reset all signals
    next_state               = IDLE;

    ms_init                  = 1'b0;
    ms_enable                = 1'b0;
    cm_init                  = 1'b0;
    cm_enable                = 1'b0;

    hash_cycle_counter_en    = 1'b0;
    hash_cycle_counter_rst_n = 1'b1;

    mem_acc_read_en          = 1'b0;
    mem_acc_read_addr        = '0;

    mem_acc_write_en         = 1'b0;
    mem_acc_write_addr       = '0;
    mem_acc_write_data       = '0;

    case (curr_state)

        READ_MESSAGE: begin

            // Signal the Arbiter we need to read something
            mem_acc_read_en   = 1'b1;
            mem_acc_read_addr = ACB_START_ADDR;

            // If we interface with an Arbiter, we wait here until Arbiter gives us the data
            if (IS_MEM_USE_ARBITER && mem_acc_read_data_valid) begin

                // Write Busy bit in Status register if we are configured to do so
                if (IS_WRITE_BUSY_BIT) next_state = WRITE_BUSY_BIT;
                else                   next_state = HASH;

            end else
                next_state = READ_MESSAGE;

        end

        WRITE_BUSY_BIT: begin

            // Signal the Arbiter we have something to write
            mem_acc_write_en    = 1'b1;
            mem_acc_write_data  = { {(MEM_ACC_WRITE_DATA_SIZE - 3){1'b0}}, 1'b1, 1'b0, 1'b1 };
            mem_acc_write_addr  = ACB_START_ADDR;

            // If we interface with an Arbiter, we wait here until it has written the data
            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = INIT;
            else
                next_state = WRITE_BUSY_BIT;

        end

        INIT: begin
            // Transient state, just signal both units to init
            ms_init    = 1'b1;
            cm_init    = 1'b1;

            next_state = HASH;
        end

        HASH: begin
            ms_enable = 1'b1;
            cm_enable = 1'b1;

            // Start the cycle counter
            hash_cycle_counter_en = 1'b1;

            // Here we count some amount of cycles to determine if the hash is complete
            // @review(ryan): 64 might not be the right number
            if (hash_cycle_counter == HASH_CYCLE_COUNT) begin

                hash_cycle_counter_rst_n = 1'b0;
                next_state               = WRITE_H0;

            end else
                next_state = HASH;
        end

        WRITE_H0: begin

            // Write a portion (MEM_ACC_WRITE_DATA_SIZE) of the hash to the Data Memory
            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 0;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 1 - 1: MEM_ACC_WRITE_DATA_SIZE * 0];

            // If we interface with an Arbiter, we wait here until it has written the data
            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H1;
            else
                next_state = WRITE_H0;

        end

        WRITE_H1: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 1;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 2 - 1: MEM_ACC_WRITE_DATA_SIZE * 1];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H2;
            else
                next_state = WRITE_H1;

        end

        WRITE_H2: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 2;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 3 - 1: MEM_ACC_WRITE_DATA_SIZE * 2];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H3;
            else
                next_state = WRITE_H2;

        end

        WRITE_H3: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 3;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 4 - 1: MEM_ACC_WRITE_DATA_SIZE * 3];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H4;
            else
                next_state = WRITE_H3;

        end

        WRITE_H4: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 4;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 5 - 1: MEM_ACC_WRITE_DATA_SIZE * 4];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H5;
            else
                next_state = WRITE_H4;

        end

        WRITE_H5: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 5;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 6 - 1: MEM_ACC_WRITE_DATA_SIZE * 5];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H6;
            else
                next_state = WRITE_H5;

        end

        WRITE_H6: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 6;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 7 - 1: MEM_ACC_WRITE_DATA_SIZE * 6];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_H7;
            else
                next_state = WRITE_H6;

        end

        WRITE_H7: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_H0_ADDR + MEM_ACC_WRITE_DATA_SIZE * 7;
            mem_acc_write_data  = cm_out[MEM_ACC_WRITE_DATA_SIZE * 8 - 1: MEM_ACC_WRITE_DATA_SIZE * 7];

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = WRITE_DONE_BIT;
            else
                next_state = WRITE_H7;

        end

        WRITE_DONE_BIT: begin

            mem_acc_write_en    = 1'b1;
            mem_acc_write_addr  = ACB_START_ADDR;
            mem_acc_write_data  = { {(MEM_ACC_WRITE_DATA_SIZE - 3){1'b0}}, 1'b0, 1'b1, 1'b0 };

            if (IS_MEM_USE_ARBITER && mem_acc_write_done)
                next_state = IDLE;
            else
                next_state = WRITE_DONE_BIT;

        end

        // IDLE
        default: begin

            // Wait for CPU to write the valid bit
            if (mem_listen_en && mem_listen_addr == ACB_START_ADDR && mem_listen_data[0])
                next_state = READ_MESSAGE;
        end

    endcase
end

// =================
// State Transition
// =================
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) curr_state <= IDLE;
    else        curr_state <= next_state;
end

// =================
// Hash Cycle Counter
// =================
always_ff @(posedge clk, negedge rst_n) begin
         if (!rst_n || !hash_cycle_counter_rst_n) hash_cycle_counter <= '0;
    else if (hash_cycle_counter_en)               hash_cycle_counter <= hash_cycle_counter + 1;
end

endmodule
