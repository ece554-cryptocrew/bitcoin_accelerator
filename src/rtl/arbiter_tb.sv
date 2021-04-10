///////////////////////////////////////////////////////////////////////////////
// Arbiter Testbench
//
// @author: Ryan Liang <p@ryanl.io>
//
// All rights reserved.
///////////////////////////////////////////////////////////////////////////////



module arbiter_tb();

// Number of Clients for the Unit
localparam NUM_CLIENTS            = 8;

// Bits needed to represent the number of Clients in binary
localparam BIT_CLIENTS            = $clog2(NUM_CLIENTS);

// Address size for both the Memory and the Clients' ports
localparam ADDR_SIZE              = 16;

// Size of the write port to the Memory and the Clients
localparam WRITE_DATA_SIZE        = 32;

// Size of the read port to the Memory and the Clients
localparam READ_DATA_SIZE         = 512;

// Set to indicate there is another Arbiter in front of us
localparam HAVE_UPSTREAM_ARBITER  = 1;

// Mock memory register size
localparam MOCK_MEMORY_REG_SIZE   = 32;

// Mock memory register count
localparam MOCK_MEMORY_REG_COUNT  = 2 ** ADDR_SIZE;

/// Signals
 reg                                  clk, rst_n;


 reg             [NUM_CLIENTS - 1:0]  client_read_en;
 reg               [ADDR_SIZE - 1:0]  client_read_addr  [NUM_CLIENTS - 1:0];

 reg             [NUM_CLIENTS - 1:0]  client_write_en;
 reg         [WRITE_DATA_SIZE - 1:0]  client_write_data [NUM_CLIENTS - 1:0];
 reg               [ADDR_SIZE - 1:0]  client_write_addr [NUM_CLIENTS - 1:0];

wire          [READ_DATA_SIZE - 1:0]  mem_read_data;

 reg                                  upstream_write_done, upstream_read_valid;

// Outputs
wire          [READ_DATA_SIZE - 1:0]  client_read_data;

wire             [NUM_CLIENTS - 1:0]  client_read_valid;
wire             [NUM_CLIENTS - 1:0]  client_write_done;

wire                                  mem_read_en;
wire               [ADDR_SIZE - 1:0]  mem_read_addr;

wire                                  mem_write_en;
wire               [ADDR_SIZE - 1:0]  mem_write_addr;
wire         [WRITE_DATA_SIZE - 1:0]  mem_write_data;

                              integer test_number = 0;



/// DUT
arbiter
#(
    .NUM_CLIENTS(NUM_CLIENTS),
    .ADDR_SIZE(ADDR_SIZE),
    .WRITE_DATA_SIZE(WRITE_DATA_SIZE),
    .READ_DATA_SIZE(READ_DATA_SIZE),
    .HAVE_UPSTREAM_ARBITER(HAVE_UPSTREAM_ARBITER)
)
DUT
(
    .*
);

/// Mock Memory
// A very simple memory for the sake of testing the Arbiter.
// Write happens when write_en is high on rising clock edge
// Read happens when read_en is high in the same clock cycle, otherwise
// read_data is cleared to all 0s.
module mock_memory(read_en, read_addr, read_data, write_en, write_addr, write_data);

     input                                   read_en;
     input                [ADDR_SIZE - 1:0]  read_addr;

     input                                   write_en;
     input                [ADDR_SIZE - 1:0]  write_addr;
     input          [WRITE_DATA_SIZE - 1:0]  write_data;

    output reg       [READ_DATA_SIZE - 1:0]  read_data;

           reg [MOCK_MEMORY_REG_SIZE - 1:0]  registers [MOCK_MEMORY_REG_COUNT - 1:0];

    // Write on rising edge
    always_ff @(posedge clk, negedge clk) begin

        if (!rst_n)
            // Fill memory with random initial values
            for (integer i = 0; i < MOCK_MEMORY_REG_COUNT; i++)
                registers[i] = $random;

        else if (write_en)
            registers[write_addr] <= write_data;

    end

    // Read data is available on the same cycle
    always_comb begin
        read_data = '0;

        if (read_en)
            read_data = memory_read(read_addr);
    end

endmodule

mock_memory memory
(
    .read_en(mem_read_en),
    .read_addr(mem_read_addr),
    .read_data(mem_read_data),

    .write_en(mem_write_en),
    .write_addr(mem_write_addr),
    .write_data(mem_write_data)
);

/// Tests
reg [WRITE_DATA_SIZE - 1:0] saved_write_data [NUM_CLIENTS - 1:0];
initial begin

    clk                 = 0;
    rst_n               = 0;

    client_read_en      = '0;
    client_read_addr    = '{NUM_CLIENTS{'0}};

    client_write_en     = '0;
    client_write_data   = '{NUM_CLIENTS{'0}};
    client_write_addr   = '{NUM_CLIENTS{'0}};

    upstream_write_done = 0;
    upstream_read_valid = 0;

    // Reset
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // #1, 2: Single read
    client_read(0, 16'h7A34);
    check_read_data(0);        // grant && combinational -> data available in same cycle
    check_read_valid(0, 0);    // !upstream_read_valid -> data invalid
    next_cycle;

    // #3, 4: Add competing read, no upstream read valid
    client_read(1, 16'h83DB);
    check_read_data(0);        // !upstream_read_valid && hold -> data stays muxed to first grant
    check_read_valid(0, 0);    // !upstream_read_valid -> data invalid
    next_cycle;

    // #5, 6: Add another competing read, no upstream read valid
    client_read(2, 16'h3F2A);
    check_read_data(0);        // !upstream_read_valid && hold -> data stays muxed to first grant
    check_read_valid(0, 0);    // !upstream_read_valid -> data invalid
    next_cycle;

    // #7, 8: Assert upstream read valid
    set_upstream_read_valid;
    check_read_data(0);        // upstream_read_valid && hold -> data stays muxed to first grant
    check_read_valid(0, 1);    // upstream_read_valid -> data valid in same cycle
    next_cycle;

    // #9, 10: Unassert upstream read valid
    unset_upstream_read_valid;
    check_read_data(1);        // next_cycle && !valid && hold -> data muxed to second grant
    check_read_valid(1, 0);    // !valid -> data invalid
    next_cycle;

    // #11, 12: Assert upstream read valid
    set_upstream_read_valid;
    check_read_data(1);        // valid && hold -> data stays muxed to second grant
    check_read_valid(1, 1);    // valid -> data valid
    next_cycle;

    // #13, 14: Continue asserting upstream read valid
    next_step;
    check_read_data(2);        // valid -> grant moves onto Client 2
    check_read_valid(2, 1);    // valid -> data valid
    next_cycle;

    // #15, 16: Continue asserting upstream read valid
    next_step;
    check_read_data(0);        // valid -> grant moves onto Client 0
    check_read_valid(0, 1);    // valid -> data valid
    next_cycle;

    // #17, 18: Deassert request from Client 1
    client_unread(1);
    check_read_data(2);        // valid -> grant moves onto Client 2
    check_read_valid(2, 1);    // valid -> data valid
    next_cycle;

    // #19, 20: Deassert all
    client_unread(0);
    client_unread(2);
    if (|client_read_data) begin
        $display(
            "Read Data not cleared when no request is high. [requested=%b, granted=%b]",
            client_read_en, DUT.client_read_grants
        );
        $stop;
    end
    if (|client_read_valid) begin
        $display(
            "Read Valid not cleared when no request is high. [requested=%b, granted=%b]",
            client_read_en, DUT.client_read_grants
        );
        $stop;
    end
    next_cycle;
    test_number += 2;

    // #21: one write request, no write done
    client_write(0, 16'h03AF, 32'h6AFF0AB9);
    next_cycle;
    check_write_data(0, 32'h6AFF0AB9);

    // #22, 23, 24, 25: three other write request, no write done
    saved_write_data[1] = memory_read(16'h8379);
    client_write(1, 16'h8379, 32'h03A11B8B);

    saved_write_data[2] = memory_read(16'h0001);
    client_write(2, 16'h0001, 32'h8A9B0C1D);

    saved_write_data[7] = memory_read(16'h1A01);
    client_write(7, 16'h1A01, 32'h01234567);

    next_cycle;

    // Nothing should change, Client 0's data is already written
    check_write_data(0, 32'h6AFF0AB9);
    check_write_data(1, saved_write_data[1]);
    check_write_data(2, saved_write_data[2]);
    check_write_data(7, saved_write_data[7]);

    // #26, 27, 28: upstream_write_done high for one cycle
    set_upstream_write_done;   next_cycle;
    unset_upstream_write_done; next_cycle;      // Write happens on this cycle
    check_write_data(1, 32'h03A11B8B);
    check_write_data(2, saved_write_data[2]);
    check_write_data(7, saved_write_data[7]);
    next_cycle;

    // #29, 30: Unassert upstream_write_done
    check_write_data(2, saved_write_data[2]);
    check_write_data(7, saved_write_data[7]);
    next_cycle;

    // #31, 32: Reassert upstream_write_done
    set_upstream_write_done; next_cycle;
    next_cycle;                                // Write happens on this cycle
    check_write_data(2, 32'h8A9B0C1D);
    check_write_data(7, saved_write_data[7]);
    next_cycle;

    // #33, 34: Continuing asserting upstream_write_done
    check_write_data(7, 32'h01234567);

    success;
end


/// Helpers
// Check if a Client's read request is properly satisfied, i.e.
// the read data matches data in memory.
task check_read_data;

    input                       integer client_index;

           reg        [ADDR_SIZE - 1:0] read_addr;
           reg   [READ_DATA_SIZE - 1:0] read_data;

    begin
        test_number += 1;

        read_addr = client_read_addr[client_index];
        read_data = memory_read(read_addr);

        if (client_read_data != read_data)
            fail_read_data(client_index, read_addr);
    end

endtask


// Check if a Client's read request is properly satisfied, i.e.
// the valid bit is set
task check_read_valid;

    input                       integer client_index;
    input                           bit valid;

    begin
        test_number += 1;

        if (client_read_valid[client_index] != valid)
            fail_read_valid(client_index, valid);
    end

endtask


// Check if a Client's write request is properly satisfied, i.e.
// the written data matches data in memory.
task check_write_data;

    input                       integer client_index;
    input       [WRITE_DATA_SIZE - 1:0] write_data;

           reg        [ADDR_SIZE - 1:0] write_addr;
           reg  [WRITE_DATA_SIZE - 1:0] memory_data;

    begin
        test_number += 1;

        write_addr  = client_write_addr[client_index];
        memory_data = memory_read(write_addr);

        if (write_data != memory_data)
            fail_write_data(client_index, write_addr);
    end

endtask


// Directly read from the mock memory and return the value
function [READ_DATA_SIZE - 1:0] memory_read;

    input [ADDR_SIZE - 1:0] read_addr;

    begin

        // Might need to fill more than one register size of the data to the
        // read line
        if (READ_DATA_SIZE <= MOCK_MEMORY_REG_SIZE)
            memory_read = memory.registers[read_addr];
        else
            for (integer i = 0; i < READ_DATA_SIZE / MOCK_MEMORY_REG_SIZE; i++)
                memory_read[i * MOCK_MEMORY_REG_SIZE +: MOCK_MEMORY_REG_SIZE] = memory.registers[read_addr + i];
    end

endfunction


// Send read request from a client at a certain index
task client_read;

    input                integer client_index;
    input      [ADDR_SIZE - 1:0] read_addr;

    begin
        client_read_en[client_index]   = 1;
        client_read_addr[client_index] = read_addr;

        // Wait one step so the result is available on the same clock cycle
        next_step;
    end

endtask


// Deassert read request from a client at a certain index
task client_unread;

    input                integer client_index;

    begin
        client_read_en[client_index]   = 0;

        // Wait one step so the result is available on the same clock cycle
        next_step;
    end

endtask


// Send write request from a client at a certain index
task client_write;

    input                    integer client_index;
    input          [ADDR_SIZE - 1:0] write_addr;
    input    [WRITE_DATA_SIZE - 1:0] write_data;

    begin
        client_write_en[client_index]   = 1;
        client_write_addr[client_index] = write_addr;
        client_write_data[client_index] = write_data;

        next_step;
    end

endtask


// Deassert write request from a client at a certain index
task client_unwrite;

    input                    integer client_index;

    begin
        client_write_en[client_index]   = 0;
    end

endtask


// Assert upstream_read_valid bit and advance one step
task set_upstream_read_valid;
    upstream_read_valid = 1;
    next_step;
endtask


// Unassert upstream_read_valid bit and advance one step
task unset_upstream_read_valid;
    upstream_read_valid = 0;
    next_step;
endtask


// Assert upstream_write_done bit and advance one step
task set_upstream_write_done;
    upstream_write_done = 1;
    next_step;
endtask


// Unassert upstream_write_done bit and advance one step
task unset_upstream_write_done;
    upstream_write_done = 0;
    next_step;
endtask


// Advance one cycle
task next_cycle;
    @(posedge clk);
endtask


// Advance one cycle
task next_step;
    #1;
endtask


// Fail and halt the test, used then a read is wrong
task fail_read_data;

    input               integer  client_index;
    input      [ADDR_SIZE - 1:0] read_addr;

    begin
        $display(
            "Test #%0d: Read Data mismatch for Client %0d at address 0x%h. [requested=%b, granted=%b]",
            test_number, client_index, read_addr, client_read_en, DUT.client_read_grants
        );

        $stop();
    end

endtask


// Fail and halt the test, used then a read is wrong
task fail_read_valid;

    input               integer  client_index;
    input                   bit  valid;

    begin
        $display(
            "Test #%0d: read_valid is %0s for Client %0d when upstream_read_valid is %0s. [requested=%b, granted=%b]",
            test_number,
            valid ? "not set" : "set",
            client_index,
            upstream_read_valid ? "set" : "not set",
            client_read_en,
            DUT.client_read_grants
        );

        $stop();
    end

endtask


// Fail and halt the test, used then a write is wrong
task fail_write_data;

    input               integer  client_index;
    input      [ADDR_SIZE - 1:0] write_addr;

    begin
        $display(
            "Test #%0d: Write Data mismatch for Client %0d at address 0x%h. [requested=%b, granted=%b, mem_write_addr=0x%h]",
            test_number, client_index, write_addr, client_write_en, DUT.client_write_grants, mem_write_addr
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
