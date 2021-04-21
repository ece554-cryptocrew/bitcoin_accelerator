; Core Instructions
; -
; This test tests each arithmetic (i.e. all except loads, stores, branches or jumps)
; instruction in the CryptoCrew core instruction set

; Adds and Subtractions
addi $g0, $g0, 2   ; $g0 = 2
add  $g1, $g0, $g0 ; $g1 = $g0 + $g0 (4)
subi $g1, $g1, 1   ; $g1 = $g1 - 1   (3)
sub  $g1, $g1, $g0 ; $g1 = $g1 - $g0 (1)


// TODO
; Multiplications
multli $g2, $zero, 10   ; $g2 = 0
multl  $g2, $v0, $zero  ; $v1 = 777
multhi $g3 $a1, $a2     ; $a0 = -1 (signed)
multh  $g3, $a0, 2      ; $a1 = 2

; Shifts
lsi
rsi
rori
ls
rs
ror
sll $s1, $a1, 1 ; $s1 = 4
srl $s2, $a1, 1 ; $s2 = 1

; Stores
sb $a0, 1024($zero)
sh $a0, 2048($zero)
sw $a0, 3072($zero)

; Loads
lbu $t1, 0x1024($zero)
lhu $t2, 0x2048($zero)
lw $t3, 0x3072($zero)

; Branches and CV Setting
slt $s3, $s1, $s2 ; $s3 = 0
slti $s4, $s1, 0x100 ; $s4 = 1
sltiu $s5, $zero, -1 ; $s5 = 1 - Note in unsigned -1 is the largest integer
sltu $s6, $zero, $a0 ; $s6 = 1 - same as previous

beq $v0, $v0, SKIP_1
ori $k0, $zero, -1 ; error condition

SKIP_1:
bne $s3, $s5, SKIP_2
ori $k0, $zero, -1

TMP:
jr $ra
ori $k0, $zero, -1

SKIP_2:
j SKIP_3
ori $k0, $zero, -1

SKIP_3:
jal TMP
add $zero, $zero, 0 ; No-op
add $zero, $zero, 0 ; No-op
add $zero, $zero, 0 ; No-op
add $zero, $zero, 0 ; No-op
.exit
