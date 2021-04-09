//R0 zero register
//R1-R15 general purpose registers g0-g14
code_entry:
	ADDI g14, R0, 0x00000000 // Use g14 to be current nonce value
	//use g6 - g13 to hold proper output hash
	ADDI g6, R0, 0x00000000
	ADDI g7, R0, 0x00000000
	ADDI g8, R0, 0x00000000
	ADDI g9, R0, 0x00000000
	ADDI g10, R0, 0x00000000
	ADDI g11, R0, 0x00000000
	ADDI g12, R0, 0x00000000
	ADDI g13, R0, 0x00000000


  // TODO bitcoin header 
  // add constants for:
  // - version number (4 bytes)
  // - bits (4 bytes)
  // nonce (4 bytes) starts at 0 and goes to 32 - it will overflow which will
  // change the merkle root (32 bytes)

  // MMIO Acceleration Communication Blocks (40 Bytes + Padding)
  // 0x5000 ACB_0    Stores the accelerator communication blocks. Used  
  // 0x5100 ACB_1    for communication between the on-board CPU and
  // 0x6000 ACB_2    the accelerator blocks which consists of the status 
  // 0x6100 ACB_3    of the hashing, starting memory address of input
  // 0x7000 ACB_4    message and the output hash.
  // 0x7100 ACB_5
  // 0x8000 ACB_6
  // 0x8100 ACB_7


  //Update each nonce value loader should set rest of header
	STI g14, 0x1054 // Load value to be hashed into
	ADDI g14, g14, 1 // Increament hash number
	STI g14, 0x1154 // Should these be 1000 and 1100?
	ADDI g14, g14, 1
	STI g14, 0x2054
	ADDI g14, g14, 1
	STI g14, 0x2154
	ADDI g14, g14, 1
	STI g14, 0x3054
	ADDI g14, g14, 1
	STI g14, 0x3154
	ADDI g14, g14, 1
	STI g14, 0x4054
	ADDI g14, g14, 1
	STI g14, 0x4154

//TODO do i need to set the hash_addr of Host Communication Block?
//We will handle on loader



	// Tell all accelerators to begin
	//Do this by properly setting msg_ready signal to true
  // MMIO Host Communication Blocks (136 Bytes + Padding)
  // Stores the host communication blocks. Used for 
  // communication between the host and the accelerator
  // which consists of the status of the hashing, 
  // memory address of the result, input message, and
  // some reserved space for algorithmic purposes
	ADDI g0, R0, 0x80000000
	STI g0, 0x1000 // HCB_0
	ADDI g0, R0, 0x80000000
	STI g0, 0x1100 // HCB_1
	ADDI g0, R0, 0x80000000
	STI g0, 0x2000 // HCB_2
	ADDI g0, R0, 0x80000000
	STI g0, 0x2100 // HCB_3
	ADDI g0, R0, 0x80000000
	STI g0, 0x3000 // HCB_4
	ADDI g0, R0, 0x80000000
	STI g0, 0x3100 // HCB_5
	ADDI g0, R0, 0x80000000
	STI g0, 0x4000 // HCB_6
	ADDI g0, R0, 0x80000000
	STI g0, 0x4100 // HCB_7

//Have loop that polls for
loop_begin
	LDI g0, 0x1000 // Status register for accelerator 1
	ANDI g1, 0x40000000 // Check if accelerator done TODO check without and
	BNEQ accel_2   // Jump if not complete
	LDI g0, 0x1040 // Get addres of the output hash
	SUB g1, g0, g6 //See if first part of hash is correct
	BNEQ accel_2
	LDI g0, 0x1044 //Second
	SUB g1, g0, g7
	BNEQ accel_2
	LDI g0, 0x1048
	SUB g1, g0, g8
	BNEQ accel_2
	LDI g0, 0x104C
	SUB g1, g0, g9
	BNEQ accel_2
 

	SUBI g2, g1, g13 // Check if hash matches hash value

	BEQ correct_hash_found 
accel_2



correct_hash_found
