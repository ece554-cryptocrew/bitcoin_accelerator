//R0 zero register
//R1-R15 general purpose registers g0-g14



code_entry:
<<<<<<< HEAD
	ADDI g0, R0, 1//Set g0 to one
	//TODO learn how to properly set to a bitcoin header 
	ADDI g14, R0, 0x0 // Use g14 to be value to hash and increment
	ADDI g13, R0, 0xffff // Set g13 to bitcoin hash to acheive
	
  // MMIO Acceleration Communication Blocks (40 Bytes + Padding)
  // 0x5000 ACB_0    Stores the accelerator communication blocks. Used  
  // 0x5100 ACB_1    for communication between the on-board CPU and
  // 0x6000 ACB_2    the accelerator blocks which consists of the status 
  // 0x6100 ACB_3    of the hashing, starting memory address of input
  // 0x7000 ACB_4    message and the output hash.
  // 0x7100 ACB_5
  // 0x8000 ACB_6
  // 0x8100 ACB_7


  //TODO properly format so full header isloaded at each accelerator	
	STI g14, 1064 // Load value to be hashed into 
	ADDI g14, g14, 1 // Increament hash number
	STI g14, 1164 // Should these be 1000 and 1100?
	ADDI g14, g14, 1
	STI g14, 2064
	ADDI g14, g14, 1
	STI g14, 2164
	ADDI g14, g14, 1
	STI g14, 3064
	ADDI g14, g14, 1
	STI g14, 3164
	ADDI g14, g14, 1
	STI g14, 0x4064
	ADDI g14, g14, 1
	STI g14, 0x4164

//TODO do i need to set the hash_addr of Host Communication Block?



	// Tell all accelerators to begin
  // MMIO Host Communication Blocks (136 Bytes + Padding)
  // Stores the host communication blocks. Used for 
  // communication between the host and the accelerator
  // which consists of the status of the hashing, 
  // memory address of the result, input message, and
  // some reserved space for algorithmic purposes
	STI g0, 0x1000 // HCB_0
	STI g0, 0x1100 // HCB_1
	STI g0, 0x2000 // HCB_2
	STI g0, 0x2100 // HCB_3
	STI g0, 0x3000 // HCB_4
	STI g0, 0x3100 // HCB_5
	STI g0, 0x4000 // HCB_6
	STI g0, 0x4100 // HCB_7



loop_begin
	LDI g0, 0x1001 // Status register for accelerator 1
	SUBI g1, g0, 1 // Check if accelerator done
	BNEQ accel_2   // Jump if not complete
	LDI g0, 0x1048 // Get addres of the output hash
	LDB g1, g0, 64 // Get output hash  of completed hash probably need to check more value

//TODO figure out how much each load and store actually takes in
	SUBI g2, g1, g13 // Check if hash matches hash value

//TODO most likely need multiple loads and compares,need better understanding of header and hash to do so 
	BEQ correct_hash_found 
accel_2



correct_hash_found
