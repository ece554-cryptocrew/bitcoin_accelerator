module accelerators
#(
    // Number of accelerators we have in parallel
    parameter NUM_ACCELERATORS       = 8,

    // Address size for both the Memory and the Clients' ports
    parameter ADDR_SIZE              = 32,

    // Size of the write port to the Memory and the Clients
    parameter WRITE_DATA_SIZE        = 32,

    // Size of the read port to the Memory and the Clients
    parameter READ_DATA_SIZE         = 512,

    // Set to indicate there is an Arbiter before we touch the Memory
    parameter IS_MEM_USE_ARBITER     = 1
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

    // Signals from upstream Arbiter, used when HAVE_UPSTREAM_ARBITER is set
    upstream_write_done, upstream_read_valid,

    /// Output
    // Accelerator memory read request to Data Memory
    mem_acc_read_addr, mem_acc_read_en,

    // Accelerator Data Memory write lines
    mem_acc_write_en, mem_acc_write_data, mem_acc_write_addr
);

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

output                                              mem_acc_read_en;
output              [MEM_ACC_READ_ADDR_SIZE - 1:0]  mem_acc_read_addr;

output                                              mem_acc_write_en;
output             [MEM_ACC_WRITE_ADDR_SIZE - 1:0]  mem_acc_write_addr;
output             [MEM_ACC_WRITE_DATA_SIZE - 1:0]  mem_acc_write_data;

/// Internals
          wire            [NUM_ACCELERATORS - 1:0]  arbiter_read_en;
          wire                   [ADDR_SIZE - 1:0]  arbiter_read_addr  [NUM_ACCELERATORS - 1:0];
          wire              [READ_DATA_SIZE - 1:0]  arbiter_read_data;
          wire            [NUM_ACCELERATORS - 1:0]  arbiter_read_valid;

          wire            [NUM_ACCELERATORS - 1:0]  arbiter_write_en;
          wire                   [ADDR_SIZE - 1:0]  arbiter_write_addr [NUM_ACCELERATORS - 1:0];
          wire             [WRITE_DATA_SIZE - 1:0]  arbiter_write_data [NUM_ACCELERATORS - 1:0];
          wire            [NUM_ACCELERATORS - 1:0]  arbiter_write_done;

/// Modules
arbiter
#(
    .NUM_CLIENTS(NUM_ACCELERATORS),
    .ADDR_SIZE(ADDR_SIZE),
    .WRITE_DATA_SIZE(WRITE_DATA_SIZE),
    .READ_DATA_SIZE(READ_DATA_SIZE),
    .HAVE_UPSTREAM_ARBITER(IS_MEM_USE_ARBITER)
)
acc_arbiter
(
    .clk, .rst_n,

    /// Input
    .client_read_en(arbiter_read_en),
    .client_read_addr(arbiter_read_addr),

    .client_write_en(arbiter_write_en),
    .client_write_data(arbiter_write_data),
    .client_write_addr(arbiter_write_addr),

    .mem_read_data(mem_acc_read_data),

    .upstream_write_done,
    .upstream_read_valid,

    /// Output
    .client_read_data(arbiter_read_data),

    .client_read_valid(arbiter_read_valid),
    .client_write_done(arbiter_write_done),

    .mem_read_en(mem_acc_read_en),
    .mem_read_addr(mem_acc_read_addr),

    .mem_write_en(mem_acc_write_en),
    .mem_write_addr(mem_acc_write_addr),
    .mem_write_data(mem_acc_write_data)
);

genvar i;
generate
for (i = 0; i < NUM_ACCELERATORS; i++) begin
    accel accelerator
    (
        .clk, .rst_n,

        /// Inputs
        .mem_listen_addr,
        .mem_listen_en,
        .mem_listen_data,

        .mem_acc_read_data(arbiter_read_data),
        .mem_acc_read_data_valid(arbiter_read_valid[i]),
        .mem_acc_write_done(arbiter_write_done[i]),

        /// Outputs
        .mem_acc_read_en(arbiter_read_en[i]),
        .mem_acc_read_addr(arbiter_read_addr[i]),

        .mem_acc_write_en(arbiter_write_en[i]),
        .mem_acc_write_addr(arbiter_write_addr[i]),
        .mem_acc_write_data(arbiter_write_data[i]),

        // Not used
        .hash_done(), .hash()
    );
end
endgenerate
