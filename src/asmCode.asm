;R0 zero register
;R1-R15 general purpose registers g0-g14

code_entry:
	; use g14 to be the current nonce value
	ADDI $g14, $zero, 0x00000000 
	
	;use g6 - g13 to hold proper output hash
	ADDI $g6, $zero, 0x00000000
	ADDI $g7, $zero, 0x00000000
	ADDI $g8, $zero, 0x00000000
	ADDI $g9, $zero, 0x00000000
	ADDI $g10, $zero, 0x00000000
	ADDI $g11, $zero, 0x00000000
	ADDI $g12, $zero, 0x00000000
	ADDI $g13, $zero, 0x00000000
 
  ; add constants for:
  ; - version number (4 bytes)
  ; - bits (4 bytes)
  ; nonce (4 bytes) starts at 0 and goes to 32 - it will overflow which will
  	; 0x5000 ACB_0    Stores the accelerator communication blocks. Used  
  	; 0x5100 ACB_1    for communication between the on-board CPU and
  	; 0x6000 ACB_2    the accelerator blocks which consists of the status 
  	; 0x6100 ACB_3    of the hashing, starting memory address of input
  	; 0x7000 ACB_4    message and the output hash.
  	; 0x7100 ACB_5
  	; 0x8000 ACB_6
  	; 0x8100 ACB_7


  	;Update each nonce value loader should set rest of header
	STI $g14, $zero, 0x1054  ; Load the value to be hashed into
	ADDI $g14, $g14, 1 ; Increament hash number
	STI $g14, $zero, 0x1154 ;  Should these be 1000 and 1100? Why is the offset 54?
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x2054
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x2154
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x3054
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x3154
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x4054
	ADDI $g14, $g14, 1
	STI $g14, $zero, 0x4154
	ADDI $g14, $g14, 1

	
	; do i need to set the hash_addr of Host Communication Block?
	; We will handle on loader


  	; Tell all accelerators to begin - by properly setting msg_ready to true
  
  	; MMIO Host Communication Blocks (136 Bytes + Padding)
  	; Stores the host communication blocks. Used for 
  	; communication between the host and the accelerator
  	; which consists of the status of the hashing, 
  	; memory address of the result, input message, and
  	; some reserved space for algorithmic purposes

	; Tell all accelerators to begin
	;Do this by properly setting msg_ready signal to true

	LDI $g1, $zero, 0x5000 ;Need to change specific bit should keep old info since already set to 0
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x5000 ; ACB_0

	LDI $g1, $zero, 0x5100
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x5100 ; ACB_1
	
	LDI $g1, $zero, 0x6000
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x6000 ; ACB_2
	
	LDI $g1, $zero, 0X6100
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x6100 ; ACB_3
	
	LDI $g1, $zero, 0x7000
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x7000 ; ACB_4
	
	LDI $g1, $zero, 0x7100
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x7100 ; ACB_5

	LDI $g1, $zero, 0x8000
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x8000 ; ACB_6
	
	LDI $g1, $zero, 0x8100
	ADDI $g0, $g1, 0x80000000
	STI $g0, $zero, 0x8100 ; ACB_7

;Have loop that polls for
loop_begin 

	LDI $g0, $zero, 0x5000 ; Status register for accelerator 1
	
	SUBI $g1, $g0, 0x40000001
	BGEZ accel_2
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_2

	LDI $g1, $zero, 0x5008 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_1_end
	LDI $g0, $zero, 0x500C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_1_end
	LDI $g0, $zero, 0x5010
	SUB $g1, $g0, $g8
	BNEQ accel_1_end
	LDI $g0, $zero, 0x5014
	SUB $g1, $g0, $g9
	BNEQ accel_1_end
	LDI $g0, $zero, 0x5018
	SUB $g1, $g0, $g10
	BNEQ  accel_1_end
 	LDI $g0, $zero, 0x501C
	SUB $g1, $g0, $g11
	BNEQ  accel_1_end
	LDI $g0, $zero, 0x5020
	SUB $g1, $g0, $g12
	BNEQ  accel_1_end
	LDI $g0, $zero, 0x5024
	SUB $g1, $g0, $g13
	BNEQ  accel_1_end
	ADDI $g4, $zero, 0x1054 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_1_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x1054 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to ready TODO does not check is already set may be needed
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x5000 ;Store new status values
accel_2
	LDI $g0, $zero, 0x5100 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_3
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_3 

	LDI $g0, $zero, 0x5108 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_2_end
	LDI $g0, $zero, 0x510C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_2_end
	LDI $g0, $zero, 0x5110
	SUB $g1, $g0, $g8
	BNEQ accel_2_end
	LDI $g0, $zero, 0x5114
	SUB $g1, $g0, $g9
	BNEQ accel_2_end
	LDI $g0, $zero, 0x5118
	SUB $g1, $g0, $g10
	BNEQ  accel_2_end
 	LDI $g0, $zero, 0x511C
	SUB $g1, $g0, $g11
	BNEQ  accel_2_end
	LDI $g0, $zero, 0x5120
	SUB $g1, $g0, $g12
	BNEQ  accel_2_end
	LDI $g0, $zero, 0x5124
	SUB $g1, $g0, $g13
	BNEQ  accel_2_end
	ADDI $g4, $zero, 0x1154 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_2_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x1154 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000 ;Set hash_valid to false to ready TODO does not check is already set may be needed
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x5100 ;Store new status values
accel_3
	LDI $g0, $zero, 0x6000 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001 ; Check if accelerator done By checking specific bit
	BGEZ accel_4
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_4 

	LDI $g0, $zero, 0x6008   ;Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_3_end
	LDI $g0, $zero, 0x600C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_3_end
	LDI $g0, $zero, 0x6010
	SUB $g1, $g0, $g8
	BNEQ accel_3_end
	LDI $g0, $zero, 0x6014
	SUB $g1, $g0, $g9
	BNEQ accel_3_end
	LDI $g0, $zero, 0x6018
	SUB $g1, $g0, $g10
	BNEQ  accel_3_end
 	LDI $g0, $zero, 0x601C
	SUB $g1, $g0, $g11
	BNEQ  accel_3_end
	LDI $g0, $zero, 0x6020
	SUB $g1, $g0, $g12
	BNEQ  accel_3_end
	LDI $g0, $zero, 0x6024
	SUB $g1, $g0, $g13
	BNEQ  accel_3_end
	ADDI $g4, $zero, 0x2054 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_3_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x2054 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x6000 ;Store new status values
accel_4

	LDI $g0, $zero, 0x6100 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_5
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_5 

	LDI $g0, $zero, 0x6108 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_4_end
	LDI $g0, $zero, 0x610C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_4_end
	LDI $g0, $zero, 0x6110
	SUB $g1, $g0, $g8
	BNEQ accel_4_end
	LDI $g0, $zero, 0x6114
	SUB $g1, $g0, $g9
	BNEQ accel_4_end
	LDI $g0, $zero, 0x6118
	SUB $g1, $g0, $g10
	BNEQ  accel_4_end
 	LDI $g0, $zero, 0x611C
	SUB $g1, $g0, $g11
	BNEQ  accel_4_end
	LDI $g0, $zero, 0x6120
	SUB $g1, $g0, $g12
	BNEQ  accel_4_end
	LDI $g0, $zero, 0x6124
	SUB $g1, $g0, $g13
	BNEQ  accel_4_end
	ADDI $g4, $zero, 0x2154 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_4_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x2154 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x6100 ;Store new status values
accel_5

	LDI $g0, $zero, 0x7000 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_6
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_6 

	LDI $g0, $zero, 0x7008 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_5_end
	LDI $g0, $zero, 0x700C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_5_end
	LDI $g0, $zero, 0x7010
	SUB $g1, $g0, $g8
	BNEQ accel_5_end
	LDI $g0, $zero, 0x7014
	SUB $g1, $g0, $g9
	BNEQ accel_5_end
	LDI $g0, $zero, 0x7018
	SUB $g1, $g0, $g10
	BNEQ  accel_5_end
 	LDI $g0, $zero, 0x701C
	SUB $g1, $g0, $g11
	BNEQ  accel_5_end
	LDI $g0, $zero, 0x7020
	SUB $g1, $g0, $g12
	BNEQ  accel_5_end
	LDI $g0, $zero, 0x7024
	SUB $g1, $g0, $g13
	BNEQ  accel_5_end
	ADDI $g4, $zero, 0x3054 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_5_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x2054 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x6000 ;Store new status values
accel_6

	LDI $g0, $zero, 0x7100 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_6
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_6 

	LDI $g0, $zero, 0x7108 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_3_end
	LDI $g0, $zero, 0x710C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_6_end
	LDI $g0, $zero, 0x7110
	SUB $g1, $g0, $g8
	BNEQ accel_6_end
	LDI $g0, $zero, 0x7114
	SUB $g1, $g0, $g9
	BNEQ accel_6_end
	LDI $g0, $zero, 0x7118
	SUB $g1, $g0, $g10
	BNEQ  accel_6_end
 	LDI $g0, $zero, 0x711C
	SUB $g1, $g0, $g11
	BNEQ  accel_6_end
	LDI $g0, $zero, 0x7120
	SUB $g1, $g0, $g12
	BNEQ  accel_6_end
	LDI $g0, $zero, 0x7124
	SUB $g1, $g0, $g13
	BNEQ  accel_6_end
	ADDI $g4, $zero, 0x3154 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_6_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x3154 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x7100 ;Store new status values
accel_7

	LDI $g0, $zero, 0x8000 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_7
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_7 

	LDI $g0, $zero, 0x8008 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_7_end
	LDI $g0, $zero, 0x800C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_7_end
	LDI $g0, $zero, 0x8010
	SUB $g1, $g0, $g8
	BNEQ accel_7_end
	LDI $g0, $zero, 0x8014
	SUB $g1, $g0, $g9
	BNEQ accel_7_end
	LDI $g0, $zero, 0x8018
	SUB $g1, $g0, $g10
	BNEQ  accel_7_end
 	LDI $g0, $zero, 0x801C
	SUB $g1, $g0, $g11
	BNEQ  accel_7_end
	LDI $g0, $zero, 0x8020
	SUB $g1, $g0, $g12
	BNEQ  accel_7_end
	LDI $g0, $zero, 0x8024
	SUB $g1, $g0, $g13
	BNEQ  accel_7_end
	ADDI $g4, $zero, 0x4054 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_7_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x4054 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x8000 ;Store new status values
accel_8

	LDI $g0, $zero, 0x8100 ; Status register for accelerator 1

	SUBI $g1, $g0, 0x40000001; Check if accelerator done By checking specific bit
	BGEZ accel_8
	SUBI $g1, $g0, 0x3FFFFFFF
	BLEZ accel_8 

	LDI $g0, $zero, 0x8108 ; Get first part the output hash
	SUB $g1, $g0, $g6 ;See if first part of hash is correct
	BNEQ accel_8_end
	LDI $g0, $zero, 0x810C ;Second
	SUB $g1, $g0, $g7
	BNEQ accel_8_end
	LDI $g0, $zero, 0x8110
	SUB $g1, $g0, $g8
	BNEQ accel_8_end
	LDI $g0, $zero, 0x8114
	SUB $g1, $g0, $g9
	BNEQ accel_8_end
	LDI $g0, $zero, 0x8118
	SUB $g1, $g0, $g10
	BNEQ  accel_8_end
 	LDI $g0, $zero, 0x811C
	SUB $g1, $g0, $g11
	BNEQ  accel_8_end
	LDI $g0, $zero, 0x8120
	SUB $g1, $g0, $g12
	BNEQ  accel_8_end
	LDI $g0, $zero, 0x8124
	SUB $g1, $g0, $g13
	BNEQ  accel_8_end
	ADDI $g4, $zero, 0x4154 ;Store address to then save final hash
	JMP correct_hash_found ;If passes all tests then hash matches and can finish 

accel_8_end
	;Set msg_ready here check if it gets unset
	STI $g14, $zero, 0x4154 ; Update to new nonce uses post incrament
	ADDI $g14, $g14, 1 ; Increament hash number	
	SUBI $g0, $g0, 0x40000000;Set hash_valid to false to read
	ADDI $g0, $g0, 0x80000000 ;Set msg_ready to ready
	STI $g0, $zero, 0x8100 ;Store new status values

	JMP loop_begin

correct_hash_found
	LDB $g0, $g4, 0x0;get final nonce value
	STI $g0, $zero, 0x9000 ;send it to the host
	ADDI $g0, $zero, 1
	STI $g0, $zero, 0x9100
  		; halt and send
		; are we going to package the header for transmission to the bitcoin network? 
		; are we going to send it to a GUI to show in our demo and compare speeds?
