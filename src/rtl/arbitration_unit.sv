module arbitration_unit
#(
    // Number of Clients this unit can support
    parameter NUM_CLIENTS            = 8
)
(
    clk, rst_n,

    /// Input
    // Bit array where a high indicates access is requested by Clients
    requests,

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

 input                         [NUM_CLIENTS - 1:0]  requests;

output    reg                  [NUM_CLIENTS - 1:0]  grants;

// Internal
          reg          [CLIENTS_SELECT_SIZE - 1:0]  last_selected;
          reg          [CLIENTS_SELECT_SIZE - 1:0]  curr_selected;

          reg                                       is_left_grant_set;
          reg                                       is_right_grant_set;

reg [CLIENTS_SELECT_SIZE - 1:0] selected;
always_comb begin

    grants                = '0;
    curr_selected         = '0;
    is_left_grant_set     = 0;
    is_right_grant_set    = 0;

    // Here we decide who gets a grant
    for (selected = 0; selected < NUM_CLIENTS; selected++) begin

        if (selected <= last_selected && !is_left_grant_set) begin
            if (requests[selected]) begin
                is_left_grant_set = 1;
                grants[selected]  = '1;
            end
        end

        if (selected > last_selected && !is_right_grant_set) begin
            if (requests[selected]) begin
                is_right_grant_set = 1;

                grants             = '0;     // Reset left grants
                grants[selected]   = '1;
            end
        end

    end

end

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) last_selected <= '0;
    else        last_selected <= curr_selected;
end

endmodule
