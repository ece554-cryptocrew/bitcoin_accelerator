///////////////////////////////////////////////////////////////////////////////
// Arbitration Unit
//
// This module is the brain of an Arbiter. Upon requests from Clients, which
// are indicated through the `requests` port, the Unit selects one single
// Client and grants it exclusive access to a shared resource, through the
// `grants` port.
//
// This module selects grantees in a Round-Robin fashion. This means, when
// multiple requests are raised to access the resource, each Client will only
// have access to the resource for one single clock cycle, even if they keep
// their requests rasied. If there is only one single request, that client will
// be granted continuous access across clock cycles.
//
// Granting of access happens in the SAME cycle that the request is raised.
//
///////////////////////////////////////////////////////////////////////////////
//
// Example:
//
// @ Clock 0:
//               +---+---+---+---+---+---+
//   Requests:   | 0 | 0 | 1 | 1 | 1 | 0 |
//               +---+---+---+---+---+---+
//               +---+---+---+---+---+---+
//     Grants:   | 0 | 0 | 0 | 0 | 1 | 0 |
//               +---+---+---+---+---+---+
//
// @ Clock 1:
//               +---+---+---+---+---+---+
//   Requests:   | 0 | 0 | 1 | 1 | 1 | 0 |
//               +---+---+---+---+---+---+
//               +---+---+---+---+---+---+
//     Grants:   | 0 | 0 | 0 | 1 | 0 | 0 |
//               +---+---+---+---+---+---+
//
// @ Clock 2:
//               +---+---+---+---+---+---+
//   Requests:   | 0 | 0 | 1 | 1 | 1 | 0 |
//               +---+---+---+---+---+---+
//               +---+---+---+---+---+---+
//     Grants:   | 0 | 0 | 1 | 0 | 0 | 0 |
//               +---+---+---+---+---+---+
//
// @ Clock 3:
//               +---+---+---+---+---+---+
//   Requests:   | 0 | 0 | 1 | 1 | 1 | 0 |
//               +---+---+---+---+---+---+
//               +---+---+---+---+---+---+
//     Grants:   | 0 | 0 | 0 | 0 | 1 | 0 |
//               +---+---+---+---+---+---+
//
// @ Clock 4:
//               +---+---+---+---+---+---+
//   Requests:   | 0 | 0 | 0 | 0 | 1 | 0 |
//               +---+---+---+---+---+---+
//               +---+---+---+---+---+---+
//     Grants:   | 0 | 0 | 0 | 0 | 1 | 0 |
//               +---+---+---+---+---+---+
//
///////////////////////////////////////////////////////////////////////////////
//
// Usage:
//
// @ NUM_CLIENTS - Number of clients that can be connected on both `requests`
//                 port and `grants` port.
//
// > requests - Each Client should occupy a single bit on the port. The
//              Client should pull the bit high when they want to access the
//              shared resource, and block on their corresponding grant.
//
// > hold - Assert to hold the current grant unchanged across clock cycles.
//          Deassert to release the hold, and grant will be re-evaluated on
//          the next cycle.
//          Requires to set CAN_HOLD to 1 in parameters.
//
// < grants - Each Client should occupy a single bit on the port. When the
//            Unit pulls a bit high, the Client occupying the bit is granted
//            exclusive access to the resource.
//
///////////////////////////////////////////////////////////////////////////////
//
// Internals:
//
// Both requests and grants are treated as arrays with their MSB on the left.
//
// Internally, this Unit has a register that remembers the index of the Client
// that was granted access on the previous clock cycle. This index splits
// the request array into two parts, left and right. This is to support
// wrapping around to the other side of the array.
//
///////////////////////////////////////////////////////////////////////////////
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module arbitration_unit
#(
    // Number of Clients this unit can support
    parameter NUM_CLIENTS            = 8,

    // Set to enable holds
    parameter CAN_HOLD               = 0
)
(
    clk, rst_n,

    /// Input
    // Bit array where a high indicates access is requested by Clients
    requests,

    // Assert to hold the grant until deassertion
    hold,

    /// Output
    // Bit array where a high indicates access is granted to Clients
    grants
);

// How many bits needed to represent number of clients in binary
localparam CLIENTS_SELECT_SIZE        = NUM_CLIENTS > 1 ? $clog2(NUM_CLIENTS) : 1;

// ===============
/// I/O
// ===============
 input                                              clk, rst_n;

 input                                              hold;
 input                         [NUM_CLIENTS - 1:0]  requests;

output    reg                  [NUM_CLIENTS - 1:0]  grants;

// Internal
          reg          [CLIENTS_SELECT_SIZE - 1:0]  last_selected;

          // Keep record of what we have selected in the current cycle,
          // to keep the logic purely combinational.
          reg          [CLIENTS_SELECT_SIZE - 1:0]  curr_selected;

          // Have we granted access to Client in the left and right part
          // This ensures we only choose one single Client
          reg                                       is_left_grant_set;
          reg                                       is_right_grant_set;

          // @fix: Solves a corner case.
          // With hold held high, at current clock cycle, a singlar
          // request goes high in the *right* part of the requests . On the
          // next clock cycle, a second request shows up in the left part.
          // Since last_selected is still at the last position because of
          // the hold, left part takes priority and grant is awarded to
          // the second request despite the hold on the first request.
          reg                                       force_hold_in_right;

/// Logic
integer selected;
always_comb begin

    // Reset everything
    grants                = '0;
    curr_selected         = '0;
    is_left_grant_set     = 0;
    is_right_grant_set    = 0;

    // Here we decide who gets a grant
    for (selected = 0; selected < NUM_CLIENTS; selected++) begin

        // We check the right part first, so results from left side,
        // i.e. Clients next in line of the Round-Robin, will override
        // the decision made here.
        if (selected <= last_selected && !is_right_grant_set) begin
            if (requests[selected]) begin
                is_right_grant_set = 1;

                grants[selected]   = '1;
                curr_selected      = selected;
            end
        end

        // Check the left part. This part takes priority.
        if (!force_hold_in_right && selected > last_selected && !is_left_grant_set) begin
            if (requests[selected]) begin
                is_left_grant_set  = 1;

                grants             = '0;     // Reset right grants
                grants[selected]   = '1;
                curr_selected      = selected;
            end
        end

    end

end

// Advance the pointer to previous grantee on clock cycle, so
// each Client is only granted access for one single cycle.
//
// Only update the pointer when HOLD is not turned on or is not currently held
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)                   last_selected <= '0;
    else if (!(CAN_HOLD && hold)) last_selected <= curr_selected;
end

// Force grants to happen in right part of the request array.
// @see: comments above force_hold_in_right.
always_ff @(posedge clk, negedge rst_n) begin

    // On reset, force hold in case of request at index 0, because
    // last_selected is reset to 0
    if (!rst_n)  force_hold_in_right <= 1;

    // Force grant to right part of array if:
    // 1. Hold is requested
    // 2. The grantee is in the right part of array
    else if (CAN_HOLD && hold && is_right_grant_set && !is_left_grant_set)  force_hold_in_right <= 1;

    // Otherwise, release force hold so we can award grants to requests in the left part
    else force_hold_in_right <= 0;

end

endmodule
