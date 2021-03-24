/////////////////////////////////////////////////////////////////////////////////////
//
// Module: cpu_control
//
// Author: Logan Sisel
//
// Signals and Descriptions:
//   alu_op - Sends the opcode to the ALU to determine operation
//   alu_imm_src - Chooses between 2nd register operand (0) and immediate operand (1) to go to ALU
//   rf_write_en - Enables register file to write back
//   datamem_write_en - Enables the data memory to write
//   datamem_read_en - Enables the data memory to read (needed for overflow checking)
//   rf_write_mem_src - Chooses between output of data memory read (1) or ALU output (0) for writing data to 
//   pc_jb_src - Chooses between normal incremented PC (0) or new PC resulting from a jump or branch (1) to go to the PC
//   pc_imm_src - Chooses between PC+immediate (0) or just the immediate (1) to go to the PC for jumps (JMP vs JMPI)         
//
/////////////////////////////////////////////////////////////////////////////////////
module cpu_control (instr, alu_op, alu_imm_src, rf_write_en, datamem_write_en, datamem_read_en, rf_write_mem_src, pc_jb_src, pc_imm_src);

    input  [31:0] instr;
    output [7:0]  alu_op;
    output        alu_imm_src;
    output        rf_write_en;
    output        datamem_write_en;
    output        datamem_read_en;
    output        rf_write_mem_src;
    output        pc_jb_src;
    output        pc_imm_src;
    output        err;

    //Error if invalid opcode;
    assign err = 1'b0; //TODO: Do we want this?

    assign alu_op = instr[31:24];
    assign alu_imm_src = instr[24];
    assign rf_write_en = ; //TODO: Finish
    assign datamem_write_en = ;
    assign datamem_read_en = ;
    assign rf_write_mem_src = ;
    assign pc_jb_src = ;
    assign pc_imm_src = ;
    
endmodule