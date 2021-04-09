///////////////////////////////////////////////////////////////////////////////
// Arbiter
//
// This module coordinates the Reads and Writes to a shared upstream memory
// among its connected Clients, making sure at any given time, there
// is only one Client accessing the shared memory. All other non-active Client
// are blocked until their turn, which is signaled by read_valid and
// write_done signals.
//
// This module is written at best effort to be a general Aribiter. However, it
// is made with the intent in mind to sit between the Data Memory and all
// Accelerators. See Arbitration Unit for the core logic, if adaptation is
// needed.
//
// This module also supports interfacing with another upstream Arbiter.
//
///////////////////////////////////////////////////////////////////////////////
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module arbiter
#(
    // Number of Clients this Arbiter can support
    parameter NUM_CLIENTS            = 8,

    // Address size for both the Memory and the Clients' ports
    parameter ADDR_SIZE              = 32,

    // Size of the write port to the Memory and the Clients
    parameter WRITE_DATA_SIZE        = 32,

    // Size of the read port to the Memory and the Clients
    parameter READ_DATA_SIZE         = 512,

    // Set to indicate there is another Arbiter in front of us
    parameter HAVE_UPSTREAM_ARBITER  = 0
)
(
    clk, rst_n,

    /// Input
    // Downstream read ports
    client_read_en, client_read_addr,

    // Downstream write ports
    client_write_en, client_write_data, client_write_addr,

    // Read data returned from shared memory
    mem_read_data,

    // Signals from upstream Arbiter, used when HAVE_UPSTREAM_ARBITER is set
    upstream_write_done, upstream_read_valid,

    /// Output
    // Read data sent back to the Client
    client_read_data,

    // Done signals returned to the granted Client
    client_read_valid, client_write_done,

    // Read address sent to the shared memory
    mem_read_en, mem_read_addr,

    // Write address and data sent to the shared memory
    mem_write_en, mem_write_addr, mem_write_data
);

/// ==================
/// I/O
/// ==================
 input                                              clk, rst_n;

 input                         [NUM_CLIENTS - 1:0]  client_read_en;
 input                           [ADDR_SIZE - 1:0]  client_read_addr  [NUM_CLIENTS - 1:0];

 input                         [NUM_CLIENTS - 1:0]  client_write_en;
 input                     [WRITE_DATA_SIZE - 1:0]  client_write_data [NUM_CLIENTS - 1:0];
 input                           [ADDR_SIZE - 1:0]  client_write_addr [NUM_CLIENTS - 1:0];

 input                      [READ_DATA_SIZE - 1:0]  mem_read_data;

 input                                              upstream_write_done, upstream_read_valid;

output                      [READ_DATA_SIZE - 1:0]  client_read_data;

output    reg                  [NUM_CLIENTS - 1:0]  client_read_valid;
output    reg                  [NUM_CLIENTS - 1:0]  client_write_done;

output                                              mem_read_en;
output    reg                    [ADDR_SIZE - 1:0]  mem_read_addr;

output                                              mem_write_en;
output    reg                    [ADDR_SIZE - 1:0]  mem_write_addr;
output    reg              [WRITE_DATA_SIZE - 1:0]  mem_write_data;

// Internals
          // Grants coming from the arbitration units
          wire                 [NUM_CLIENTS - 1:0]  client_read_grants;
          wire                 [NUM_CLIENTS - 1:0]  client_write_grants;

          // Hold grants if needed
          wire                                      should_hold_read;
          wire                                      should_hold_write;


/// ==================
/// Arbitration Units
/// ==================
arbitration_unit
#(
    .NUM_CLIENTS(NUM_CLIENTS),
    .CAN_HOLD(HAVE_UPSTREAM_ARBITER)
)
au_0
(
    .clk, .rst_n,

    .requests(client_read_en), .hold(should_hold_read),

    .grants(client_read_grants)
);

arbitration_unit
#(
    .NUM_CLIENTS(NUM_CLIENTS),
    .CAN_HOLD(HAVE_UPSTREAM_ARBITER)
)
au_1
(
    .clk, .rst_n,

    .requests(client_write_en), .hold(should_hold_write),

    .grants(client_write_grants)
);

/// ==================
/// Assignments
/// ==================
// Pull hold signals low if there is no upstream arbiter
assign should_hold_read  = HAVE_UPSTREAM_ARBITER && !upstream_read_valid;
assign should_hold_write = HAVE_UPSTREAM_ARBITER && !upstream_write_done;

/// ==================
/// Outputs
/// ==================
integer index;
always_comb begin

    mem_read_addr      = '0;
    mem_write_addr     = '0;
    mem_write_data     = '0;
    client_read_valid  = '0;
    client_write_done  = '0;

    // Assign read addr when we have grants
    for (index = 0; index < NUM_CLIENTS; index++)
        if (client_read_grants[index]) begin

            if (upstream_read_valid)
                // @review/@mightnotwork: depending on the Read timings on the
                // shared Memory, we might need to assert this during the next
                // clock cycle.
                client_read_valid[index] = 1;

            mem_read_addr            = client_read_addr[index];

        end

    // Assign write addr and data when we have grants
    for (index = 0; index < NUM_CLIENTS; index++)
        if (client_write_grants[index]) begin

            if (upstream_write_done)
                // The timings here should work out because this signal is
                // asserted to tell the Client they can stop holding the write
                // lines, but the write to the memory should happen on this
                // clock cycle.
                client_write_done[index] = 1;

            mem_write_addr           = client_write_addr[index];
            mem_write_data           = client_write_data[index];
        end

end

// Redirect read data from memory
// All Clients get the data, read_valid will signal the correct Client
assign client_read_data = mem_read_data;

// Write/Read enable goes high whenever we have a grant
assign mem_read_en  = |client_read_grants;
assign mem_write_en = |client_write_grants;

endmodule
