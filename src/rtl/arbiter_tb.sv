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
    always @(posedge clk)
        if (write_en) registers[write_addr] <= write_data;

    // Read data is available on the same cycle
    always_comb begin
        read_data = '0;

        if (READ_DATA_SIZE <= MOCK_MEMORY_REG_SIZE && read_en)
            read_data = registers[read_addr];
        else if (read_en)
            for (integer i = 0; i < READ_DATA_SIZE / MOCK_MEMORY_REG_SIZE; i++)
                read_data[i * MOCK_MEMORY_REG_SIZE +: MOCK_MEMORY_REG_SIZE] = registers[read_addr + i];
    end

    // Fill memory with random initial values
    initial
        for (integer i = 0; i < MOCK_MEMORY_REG_COUNT; i++)
            registers[i] = $random;

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
reg [WRITE_DATA_SIZE - 1:0] saved_read_addr;
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

    // #1: Single read
    saved_read_addr = $random;
    client_read(0, saved_read_addr);
    check_read(0, saved_read_addr);

    success;
end


/// Helpers

task check_read;
input                integer client_index;
input      [ADDR_SIZE - 1:0] read_addr;
begin
    if (client_read_data != memory_read(read_addr))
        fail_read(client_index, read_addr, client_read_data, memory_read(read_addr));
end
endtask

// Directly read from the mock memory and return the value
function [READ_DATA_SIZE - 1:0] memory_read;
input [ADDR_SIZE - 1:0] read_addr;

begin
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
    #1;
end

endtask

// Fail and halt the test, used then a read is wrong
task fail_read;
input               integer  client_index;
input      [ADDR_SIZE - 1:0] read_addr;
input [READ_DATA_SIZE - 1:0] client_read;
input [READ_DATA_SIZE - 1:0] memory_read;

begin
    $display(
        "Read data mismatch for Client %d at address 0x%h: should be 0x%h, got 0x%h",
        client_index, read_addr, memory_read, client_read
    );

    $stop();
end
endtask

// Fail and halt the test
task fail;
begin
    $display(
        "Failed"
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
