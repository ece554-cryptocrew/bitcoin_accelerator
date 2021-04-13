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
	ADDI g14, g14, 1

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
	LDI g1, 0x1000 //Need to change specific bit should keep old info since already set to 0
	ADDI g0, g1, 0x80000000
	STI g0, 0x1000 // HCB_0

	LDI g1, 0x1100
	ADDI g0, g1, 0x80000000
	STI g0, 0x1100 // HCB_1
	
	LDI g1, 0x2000
	ADDI g0, g1, 0x80000000
	STI g0, 0x2000 // HCB_2
	
	LDI g1, 0X2100
	ADDI g0, g1, 0x80000000
	STI g0, 0x2100 // HCB_3
	
	LDI g1, 0x3000
	ADDI g0, g1, 0x80000000
	STI g0, 0x3000 // HCB_4
	
	LDI g1, 0x3100
	ADDI g0, g1, 0x80000000
	STI g0, 0x3100 // HCB_5

	LDI g1, 0x4000
	ADDI g0, g1, 0x80000000
	STI g0, 0x4000 // HCB_6
	
	LDI g1, 0x4100
	ADDI g0, g1, 0x80000000
	STI g0, 0x4100 // HCB_7

//Have loop that polls for
loop_begin
	LDI g0, 0x1000 // Status register for accelerator 1

	SUBI g1, g0, 0x40000001// Check if accelerator done By checking specific bit
	BGEZ accel_2
	SUBI g1, g0, 0x3FFFFFFF
	BLEZ accel_2 

	//TODO can i set msg_ready right away also do i need to unset hash_valid? what values does accel change and whe
	//Set msg_ready here check if it gets unset
	STI g14, 0x1054 // Update to new nonce
	ADDI g14, g14, 1 // Increament hash number	
	SUBI g0, g0, 0x40000000//Set hash_valid to false to ready
	ADDI g0, g0, 0x80000000 //Set msg_ready to ready
	STI g0, 0x1000 //Store new status values

	

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
	LDI g0, 0x1050
	SUB g1, g0, g10
	BNEQ  accel_2
 	LDI g0, 0x1054
	SUB g1, g0, g11
	BNEQ  accel_2
	LDI g0, 0x1058
	SUB g1, g0, g12
	BNEQ  accel_2
	LDI g0, 0x105C
	SUB g1, g0, g13
	BNEQ  accel_2
	JMP correct_hash_found //If passes all tests then hash matches and can finish 

accel_2

	JMP loop_begin

correct_hash_found
