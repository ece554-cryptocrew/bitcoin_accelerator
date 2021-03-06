///////////////////////////////////////////////////////////////////////////////
// Arbitration Unit Testbench
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////

module arbitration_unit_tb();

// Number of Clients for the Unit
localparam NUM_CLIENTS     = 8;

// Bits needed to represent the number of Clients in binary
localparam BIT_CLIENTS     = $clog2(NUM_CLIENTS);

/// Signals
reg                           clk, rst_n;

reg      [NUM_CLIENTS - 1:0]  requests;
reg      [NUM_CLIENTS - 1:0]  grants;
reg                           hold;

/// DUT
arbitration_unit
#(
    .NUM_CLIENTS(NUM_CLIENTS),
    .CAN_HOLD(1)
)
DUT
(
    .*
);

/// Tests
initial begin

    clk      = 0;
    rst_n    = 0;
    hold     = 0;
    requests = '0;

    // Reset all
    @(posedge clk);
    rst_n    = 1;
    @(posedge clk);

    // #1: Only one request
    check(8'b0000_0001, 8'b0000_0001);

    // #2: Still the one request, continuous access
    check(8'b0000_0001, 8'b0000_0001);

    // #3: One request, different index
    check(8'b1000_0000, 8'b1000_0000);

    // #4: Still the one request, continuous access
    check(8'b1000_0000, 8'b1000_0000);

    // #5: Two requests
    check(8'b0000_0011, 8'b0000_0001);

    // #6: Two requests, round-robin
    check(8'b0000_0011, 8'b0000_0010);

    // #7: Two requests, round-robin, goes back
    check(8'b0000_0011, 8'b0000_0001);

    // #8: Three requests, different and skipped index
    check(8'b0001_1100, 8'b0000_0100);

    // #9: Three requests, different and skipped index
    check(8'b0111_0000, 8'b0001_0000);

    // #10: Two requests, wrapped around
    check(8'b0000_0011, 8'b0000_0001);

    // #11: No requests
    check(8'b0000_0000, 8'b0000_0000);

    // #12: No requests, then all requests
    check(8'b1111_1111, 8'b0000_0010);

    // #13: No requests, then all requests
    check(8'b1111_1111, 8'b0000_0100);

    // #14: All requests, round-robin
    check(8'b1111_1111, 8'b0000_1000);

    // #15: All requests, round-robin
    check(8'b1111_1111, 8'b0001_0000);

    // #16: All requests, round-robin
    check(8'b1111_1111, 8'b0010_0000);

    // #17: All requests, round-robin
    check(8'b1111_1111, 8'b0100_0000);

    // #18: All requests, round-robin
    check(8'b1111_1111, 8'b1000_0000);

    // #19: All requests, round-robin
    check(8'b1111_1111, 8'b0000_0001);

    // #20: All requests, round-robin
    check(8'b1111_1111, 8'b0000_0010);

    // #21: All requests, round-robin
    check(8'b1111_1111, 8'b0000_0100);

    // #22: Some requests, pull low on request next in line
    check(8'b1111_0111, 8'b0001_0000);

    // #23: Hold. On the cycle of hold nothing changes - grant already moved
    // to next in line because of next clock cycle.
    hold = 1;
    check(8'b1111_0111, 8'b0010_0000);

    // #24: Check if held
    check(8'b1111_0111, 8'b0010_0000);

    // #25: Still hold
    check(8'b1111_0111, 8'b0010_0000);

    // #26: Release. On the cycle of release nothing changes
    hold = 0;
    check(8'b1111_0111, 8'b0010_0000);

    // #27: Unhold
    check(8'b1111_0111, 8'b0100_0000);

    // #28: Hold, add new clients
    hold = 1;
    check(8'b0000_0001, 8'b0000_0001);

    // #29: Hold, add new clients
    check(8'b0000_0011, 8'b0000_0001);

    // #30: Hold, add new clients
    check(8'b0000_0111, 8'b0000_0001);

    // #31: Corner case, hold on startup, request at index 0
    rst_n = 0; @(posedge clk);
    rst_n = 1; @(posedge clk);
    check(8'b0000_0001, 8'b0000_0001);

    // #32: Hold on startup, add second request
    check(8'b0000_0011, 8'b0000_0001);

    // #33: Corner case setup, move last_selected to current request
    hold = 0; @(posedge clk);
    hold = 1;
    check(8'b0000_0010, 8'b0000_0010);

    // #34: Corner case, hold, add second request in direction of Round-Robin
    check(8'b0010_0010, 8'b0000_0010);

    success;
end

/// Helpers

// Helper to set the requests line and check the grant.
// It fails and halts the test if there is a mismatch.
integer test_number = 0;
task check;
input [NUM_CLIENTS - 1:0] rqsts;
input [NUM_CLIENTS - 1:0] should_grant;

begin
    test_number += 1;

    requests = rqsts;

    // Here we wait for one step because the Unit is purely combinational and
    // the grant is available on the same clock cycle.
    #1 if (grants != should_grant) fail(should_grant);

    @(posedge clk);
end

endtask


// Fail and halt the test
task fail;
input [NUM_CLIENTS - 1:0] should_grant;

begin
    $display(
        "Mismatch at Test #%0d: Requested: %b, Granted: %b, Should Be: %b\n",
        test_number, requests, grants, should_grant
    );

    $stop();
end

endtask


// Success and exit
task success;
begin
    $display("Test passed");
    $stop();
end
endtask


/// Clock
always #2 clk = !clk;

endmodule
