//R0 zero register
//R1-R15 general purpose registers g0-g14



code_entry:
	ADDI g0, R0, 1//Set g0 to one
	//TODO learrn how to properly set to a false bitcoin header 
	ADDI g14, R0, 0x0 // Use g14 to be value to hash and increment
	ADDI g13, R0, 0xffff //Set g13 to bitcoin hash to acheive
	//TODO properly format so full header isloaded at each accelerator	
	STI g14, 1064 //load value to be hashed into 
	ADDI g14, g14, 1 //Increament hash number
	STI g14, 1164
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

	//Tell all accelerators to begin
	STI g0, 0x1000
	STI g0, 0x1100
	STI g0, 0x2000
	STI g0, 0x2100
	STI g0, 0x3000
	STI g0, 0x3100
	STI g0, 0x4000
	STI g0, 0x4100 



loop_begin
	LDI g0, 0x1001 //Status register for accelerator 1
	SUBI g1, g0, 1//Check if accelerator done
	BNEQ accel_2 //Jump if not complete
	LDI g0, 0x1048 //Get addres of the output hash
	LDB g1, g0, 64 //Get output hash  of completed hash probably need to check more value
	//TODO figure out how much each load and store actually takes in
	SUBI g2, g1, g13 //check if hash matches hash value
	//TODO most likely need multiple loads and compares,need better understanding of header and hash to do so 
	BEQ correct_hash_found 
accel_2



correct_hash_found
