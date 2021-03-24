module cpu_control (instr, alu_op, alu_imm_src, rf_write_en, datamem_write_en, rf_write_mem_src, pc_jb_src, pc_imm_src);

    input  [31:0] instr;
    output [7:0]  alu_op;
    output        alu_imm_src;
    output        rf_write_en;
    output        datamem_write_en
    output        rf_write_mem_src;
    output        pc_jb_src;
    output        pc_imm_src;

    assign alu_op = instr[31:24];
    assign alu_imm_src = instr[24];
    assign rf_write_en = ;
    assign datamem_write_en = ;
    assign rf_write_mem_src = ;
    assign pc_jb_src = ;
    assign pc_imm_src = ;
    
endmodule