//R0 zero register
//R1-R15 general purpose registers g0-g14



code_entry:
	ADDI g0, R0, 1 // Set g0 to one
	ADDI g14, R0, 0 // Use g14 to be current value to hash
	
	STI g14, 1064 // Load value to be hashed into 
	ADDI g14, g14, 1 // Increament hash number
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
	

	// Tell all accelerators to begin
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
	BNEQ 
