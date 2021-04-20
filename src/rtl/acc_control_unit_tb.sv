module acc_control_unit_tb();

// CPU address line redirected from Data Memory for monitoring MMIO
localparam MEM_LISTEN_ADDR_SIZE      = 16;
// CPU data line redirected from Data Memory for monitoring MMIO
localparam MEM_LISTEN_DATA_SIZE      = 32;

// Address line going back to the Data Memory
localparam MEM_ACC_READ_ADDR_SIZE    = 16;
// Data line coming from the Data Memory
localparam MEM_ACC_READ_DATA_SIZE    = 512;

// Address line going out from the Accelerator to the Data Memory
localparam MEM_ACC_WRITE_ADDR_SIZE   = 16;
// Data line going out from the Accelerator to the Data Memory
localparam MEM_ACC_WRITE_DATA_SIZE   = 32;

// Starting address of the Host Communication Block in Data Memory
localparam HCB_START_ADDR            = 16'h1000;
// Offset of the Message from HCB starting address
localparam HCB_MSG_OFFSET            = 16'h0008;
// Starting address of the Accelerator Communication Block in Data Memory
localparam ACB_START_ADDR            = 16'h5000;
// Offset of h0 from ACB starting address
localparam ACB_H0_OFFSET             = 16'h0008;

// Width of the resulting hash
localparam HASH_RESULT_LENGTH        = 256;

// Address of h0 in ACB
localparam ACB_H0_ADDR               = ACB_START_ADDR + ACB_H0_OFFSET;

// @review: is this still 65?
localparam HASH_CYCLE_COUNT          = 65;

/// Signals
 reg                                              clk, rst_n;

 reg                [MEM_LISTEN_ADDR_SIZE - 1:0]  mem_listen_addr;
 reg                                              mem_listen_en;
 reg                [MEM_LISTEN_DATA_SIZE - 1:0]  mem_listen_data;

 reg                                              mem_acc_read_data_valid;
 reg              [MEM_ACC_READ_DATA_SIZE - 1:0]  mem_acc_read_data;

 reg                                              mem_acc_write_done;

 reg                  [HASH_RESULT_LENGTH - 1:0]  cm_out;

wire                                              mem_acc_read_en;
wire              [MEM_ACC_READ_ADDR_SIZE - 1:0]  mem_acc_read_addr;

wire                                              mem_acc_write_en;
wire             [MEM_ACC_WRITE_ADDR_SIZE - 1:0]  mem_acc_write_addr;
wire             [MEM_ACC_WRITE_DATA_SIZE - 1:0]  mem_acc_write_data;

wire                                              ms_init, ms_enable;
wire                                              cm_init, cm_enable;

int test_number = 0;

/// Copy of the internal states
typedef enum {
    IDLE,             // Reset/Idle

    READ_MESSAGE,     // Read message from Data Memory

    WRITE_BUSY_BIT,   // Writing the busy bit to Data Memory

    INIT,             // Initialize both MS and CM

    HASH,             // Processing hash

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

/// DUT
acc_control_unit
#(

)
DUT
(
    .*
);

initial begin
    clk                     = 0;
    rst_n                   = 0;

    mem_listen_en           = 0;
    mem_listen_addr         = '0;
    mem_listen_data         = '0;

    mem_acc_read_data       = '0;
    mem_acc_read_data_valid = 0;

    mem_acc_write_done      = 0;
    cm_out                  = '0;

    next_cycle;
    rst_n = 1;
    next_cycle;

    mem_listen_en   = 1;
    mem_listen_addr = ACB_START_ADDR;
    mem_listen_data = 32'h1;

    next_cycle;

    // #1: Check if memory listener works
    mem_listen_en   = 0;
    mem_listen_addr = '0;
    mem_listen_data = '0;
    check_state(READ_MESSAGE);

    // #2, #3: Check read en and addr
    check_mem_read(HCB_START_ADDR);

    mem_acc_read_data_valid = 1;
    next_cycle();
    mem_acc_read_data_valid = 0;

    // #4: Check busy bit state
    check_state(WRITE_BUSY_BIT);

    // #5, #6: Check busy bit is getting set
    check_mem_write(ACB_START_ADDR, 32'h00000005);

    mem_acc_write_done = 1;
    next_cycle();
    mem_acc_write_done = 0;

    // #7: Check init state
    check_state(INIT);

    // #8: Check init signals
    test_number += 1;
    if (ms_init != 1 || cm_init != 1) begin
        $display("Signal mismatch in Test #%0d: *_init signals not pulled high", test_number);
        $stop;
    end

    next_cycle;

    // #9: Check hash state
    check_state(HASH);

    // #10, 11: Check init signals
    test_number += 1;
    if (ms_enable != 1 || cm_enable != 1) begin
        $display("Signal mismatch in Test #%0d: *_enable signals not pulled high", test_number);
        $stop;
    end

    // Wait for hash cycles
    // @review: is this still 65 or no
    repeat(HASH_CYCLE_COUNT) next_cycle;

    cm_out = $random;

    // #12, 13, 14: Check hash write back
    check_state(WRITE_H0);
    check_mem_write(ACB_H0_ADDR, cm_out[31:0]);
    write_done;

    // #15, 16, 17: Check hash write back
    check_state(WRITE_H1);
    check_mem_write(ACB_H0_ADDR + 32, cm_out[63:32]);
    write_done;

    // #18, 19, 20: Check hash write back
    check_state(WRITE_H2);
    check_mem_write(ACB_H0_ADDR + 32 * 2, cm_out[32 * 3 - 1:32 * 2]);
    write_done;

    // #21, 22, 23: Check hash write back
    check_state(WRITE_H3);
    check_mem_write(ACB_H0_ADDR + 32 * 3, cm_out[32 * 4 - 1:32 * 3]);
    write_done;

    // #24, 25, 26: Check hash write back
    check_state(WRITE_H4);
    check_mem_write(ACB_H0_ADDR + 32 * 4, cm_out[32 * 5 - 1:32 * 4]);
    write_done;

    // #27, 28, 29: Check hash write back
    check_state(WRITE_H5);
    check_mem_write(ACB_H0_ADDR + 32 * 5, cm_out[32 * 6 - 1:32 * 5]);
    write_done;

    // #30, 31, 32: Check hash write back
    check_state(WRITE_H6);
    check_mem_write(ACB_H0_ADDR + 32 * 6, cm_out[32 * 7 - 1:32 * 6]);
    write_done;

    // #33, 34, 35: Check hash write back
    check_state(WRITE_H7);
    check_mem_write(ACB_H0_ADDR + 32 * 7, cm_out[32 * 8 - 1:32 * 6]);
    write_done;

    // #36, 37, 38: Check write done bit
    check_state(WRITE_DONE_BIT);
    check_mem_write(ACB_START_ADDR, 32'h00000002);
    write_done;

    // #39: Check return to idle state
    check_state(IDLE);

    $display("Test passed");
    $stop;

end


/// Tasks
task check_mem_write;
input [MEM_ACC_WRITE_ADDR_SIZE-1 : 0] write_addr;
input [MEM_ACC_WRITE_DATA_SIZE-1 : 0] write_data;

begin
    test_number += 1;
    if (write_addr != mem_acc_write_addr) begin
        $display(
            "Signal mismatch in Test #%0d: write addr should be %h, got %h",
            test_number, write_addr, mem_acc_write_addr
        );
        $stop;
    end

    test_number += 1;
    if (write_data != mem_acc_write_data) begin
        $display(
            "Signal mismatch in Test #%0d: write data should be %h, got %h",
            test_number, write_data, mem_acc_write_data
        );
        $stop;
    end
end

endtask

task check_mem_read;
input [MEM_ACC_READ_ADDR_SIZE - 1:0] read_addr;

begin
    test_number += 1;
    if (mem_acc_read_en != 1) begin
        $display(
            "Signal mismatch in Test #%0d: memory_acc_read_en is not high",
            test_number
        );
        $stop;
    end

    test_number += 1;
    if (mem_acc_read_addr != read_addr) begin
        $display(
            "Signal mismatch in Test #%0d: mem_acc_read_addr wrong, got: %h, should be: %h",
            test_number, mem_acc_read_addr, read_addr
        );
        $stop;
    end
end

endtask


task check_state;
input state_t should_be;

begin
    next_step;
    test_number += 1;

    if (DUT.curr_state != should_be)
        fail_state(should_be);
end

endtask


task write_done;
mem_acc_write_done = 1;
next_cycle;
mem_acc_write_done = 0;
endtask


// Advance one cycle
task next_cycle;
    @(posedge clk);
endtask


// Advance one cycle
task next_step;
    #1;
endtask


// Fail and halt the test because state mismatch
task fail_state;
input state_t should_be;

begin
    $display(
        "State mismatch at Test #%0d: current: %s, should be: %s\n",
        test_number, DUT.curr_state.name(), should_be.name()
    );

    $stop();
end

endtask


always #5 clk = !clk;

endmodule
