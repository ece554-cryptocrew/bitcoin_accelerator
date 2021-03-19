//////////////////////////////////////////////////////////////////////////////
//
//    CLASS - Cloud Loader and ASsembler System
//    Copyright (C) 2021 Winor Chen
//
//    This program is free software; you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation; either version 2 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License along
//    with this program; if not, write to the Free Software Foundation, Inc.,
//    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//////////////////////////////////////////////////////////////////////////////
#include "mips.h"

namespace priscas
{
	int friendly_to_numerical(const char * fr_name)
	{
		//TODO change this for change register names
		int len = strlen(fr_name);
		if(len < 2) return INVALID;

		REGISTERS reg_val
			=
			// Can optimize based off of 
			fr_name[1] == 'a' ?
				!strcmp("$a0", fr_name) ? $a0 :
				!strcmp("$a1", fr_name) ? $a1 :
				!strcmp("$a2", fr_name) ? $a2 :
				!strcmp("$a3", fr_name) ? $a3 :
				!strcmp("$at", fr_name) ? $at : INVALID
			:

			fr_name[1] == 'f' ?
				!strcmp("$fp", fr_name) ? $fp : INVALID
			:

			fr_name[1] == 'g' ?
				!strcmp("$gp", fr_name) ? $gp : INVALID
			:

			fr_name[1] == 'k' ?
				!strcmp("$k0", fr_name) ? $k0 :
				!strcmp("$k1", fr_name) ? $k1 : INVALID
			:

			fr_name[1] == 'r' ?
				!strcmp("$ra", fr_name) ? $ra : INVALID
			:

			fr_name[1] == 's' ?
				!strcmp("$s0", fr_name) ? $s0 :
				!strcmp("$s1", fr_name) ? $s1 :
				!strcmp("$s2", fr_name) ? $s2 :
				!strcmp("$s3", fr_name) ? $s3 :
				!strcmp("$s4", fr_name) ? $s4 :
				!strcmp("$s5", fr_name) ? $s5 :
				!strcmp("$s6", fr_name) ? $s6 :
				!strcmp("$s7", fr_name) ? $s7 :
				!strcmp("$sp", fr_name) ? $sp : INVALID
			:

			fr_name[1] == 't' ?
				!strcmp("$t0", fr_name) ? $t0 :
				!strcmp("$t1", fr_name) ? $t1 :
				!strcmp("$t2", fr_name) ? $t2 :
				!strcmp("$t3", fr_name) ? $t3 :
				!strcmp("$t4", fr_name) ? $t4 :
				!strcmp("$t5", fr_name) ? $t5 :
				!strcmp("$t6", fr_name) ? $t6 :
				!strcmp("$t7", fr_name) ? $t7 :
				!strcmp("$t8", fr_name) ? $t8 :
				!strcmp("$t9", fr_name) ? $t9 : INVALID
			:

			fr_name[1] == 'v' ?
				!strcmp("$v0", fr_name) ? $v0 :
				!strcmp("$v1", fr_name) ? $v1 : INVALID
			:
			fr_name[1] == 'z' ?
				!strcmp("$zero", fr_name) ? $zero : INVALID
			: INVALID;

		return reg_val;
	}

	std::string MIPS_32::get_reg_name(int id)
	{
		std::string name =
			id == 0 ? "$zero" :
			id == 1 ? "$g1" :
			id == 2 ? "$g2" :
			id == 3 ? "$g3" :
			id == 4 ? "$g4" :
			id == 5 ? "$g5" :
			id == 6 ? "$g6" :
			id == 7 ? "$g7" :
			id == 8 ? "$g8" :
			id == 9 ? "$g9" :
			id == 10 ? "$g10" :
			id == 11 ? "$g11" :
			id == 12 ? "$flg" :
			id == 13 ? "$sp" :
			id == 14 ? "$bp" :
			id == 15 ? "$pc" :
		if(name == "")
		{
			throw reg_oob_exception();
		}
		
		return name;
	}

	bool l_inst(opcode operation)
	{
		return
		
			operation == ADDI ? true :
			operation == SUBI ? true:
			operation == MULTLI ? true:
			operation == MULTHI ? true:
			operation == LSI ? true:
			operation == RSI ? true:
			operation == RORI ? true:
			operation == LDB ? true:
			operation == STB ? true:	
			false ;
	}

	bool r_inst(opcode operation)
	{
		return
			operation == ADD ? true : 
			operation == SUB ? true:
			operation == MULTL ? true:
			operation == MULTH ? true:
			operation == LS ? true:
			operation == RS ? true:
			operation == ROR ? true:
			false ;
	}

	bool i_inst(opcode operation)
	{
		return
			operation == BEQ ? true :
			operation == BNEQ ? true:
			operation == BLTZ ? true:
		 	operation == BGTZ ? true:
			operation == JMP ? true:
			operation == JMPI ? true:
			operation == LDI ? true:
			operation == STI ? true: //last two encoding alittle different than rest	
			false;
	}

	bool d_inst(opcode operation)
	{
		return
			operation == PUSH ? true:
			operation == POP ? true:
			false;
	}

	bool mem_inst(opcode operation)
	{
		return
			(mem_write_inst(operation) || mem_read_inst(operation))?
			true : false;
	}

	bool mem_write_inst(opcode operation)
	{
		return
			(operation == STI || operation == STB || operation == POP)? //POP?
			true : false;
	}

	bool mem_read_inst(opcode operation)
	{
		return
			(operation == LDI || operation == LDB)?
			true : false;
	}

	bool reg_write_inst(opcode operation)
	{
		return
			(mem_read_inst(operation)) || (l_inst(operation) && operation !=STB) || (r_inst(operation)|| operation == POP);
	}

	bool shift_inst(opcode operation)
	{
		return
			operation == RS ? true :
			operation == LS ? true :
			operation == ROR ? true:
			operation == LSI ? true:
			operation == RSI ? true:
			operation == RORI ? true:
			false;
	}

	bool jorb_inst(opcode operation)
	{
		// First check jumps
		bool is_jump = operation == JMP:
				operation ==JMPI:
				false;


		bool is_branch =
			operation == BEQ ? true :
			operation == BNEQ ? true :
			operation == BLTZ ? true :
			operation == BGTZ ? true :
			operation == BLEZ ? true:
		 	operation == BGEZ ? true:
			false;

		return is_jump || is_branch;
	}
	//TODO fix encoding of each type of instruction
	BW_32 generic_mips32_encode(int rs, int rt, int rd, int funct, int imm_shamt_jaddr, opcode op)
	{
		BW_32 w = 0;

		if(r_inst(op))
		{
			w = (w.AsUInt32() | (funct & ((1 << 6) - 1)  ));
			w = (w.AsUInt32() | ((imm_shamt_jaddr & ((1 << 5) - 1) ) << 6 ));
			w = (w.AsUInt32() | ((rd & ((1 << 5) - 1) ) << 11 ));
			w = (w.AsUInt32() | ((rt & ((1 << 5) - 1) ) << 16 ));
			w = (w.AsUInt32() | ((rs & ((1 << 5) - 1) ) << 21 ));
			w = (w.AsUInt32() | ((op & ((1 << 6) - 1) ) << 26 ));
		}

		if(i_inst(op))
		{
			w = (w.AsUInt32() | (imm_shamt_jaddr & ((1 << 16) - 1)));
			w = (w.AsUInt32() | ((rt & ((1 << 5) - 1) ) << 16 ));
			w = (w.AsUInt32() | ((rs & ((1 << 5) - 1) ) << 21 ));
			w = (w.AsUInt32() | ((op & ((1 << 6) - 1) ) << 26 ));
		}

		if(j_inst(op))
		{
			w = (w.AsUInt32() | (imm_shamt_jaddr & ((1 << 26) - 1)));
			w = (w.AsUInt32() | ((op & ((1 << 6) - 1) ) << 26 ));
		}

		return w;
	}

	BW_32 offset_to_address_br(BW_32 current, BW_32 target)
	{
		BW_32 ret = target.AsUInt32() - current.AsUInt32();
		ret = ret.AsUInt32() - 4;
		ret = (ret.AsUInt32() >> 2);
		return ret;
	}

	// Main interpretation routine
	mBW MIPS_32::assemble(const Arg_Vec& args, const BW& baseAddress, syms_table& jump_syms) const
	{
		if(args.size() < 1)
			return std::shared_ptr<BW>(new BW_32());

		priscas::opcode current_op = priscas::SYS_RES;

		int rs = 0;
		int rt = 0;
		int rd = 0;
		int imm = 0;

		// Mnemonic resolution
		
		if("addi" == args[0]) { current_op = priscas::ADDI;}
		else if("subi" == args[0]) { current_op = priscas::SUBI;}
		else if("multli" == args[0]) { current_op = priscas::MULTLI;}
		else if("multhi" == args[0]) { current_op = priscas::MULTHI; }
		else if("lsi" == args[0]) { current_op = priscas::LSI; }
		else if("rsi" == args[0]) { current_op = priscas::RSI; }
		else if("rori" == args[0]) { current_op = priscas::RORI; }
		else if("ldb" == args[0]) { current_op = priscas::LDB; }
		else if("stb" == args[0]) { current_op = priscas::STB; }
		else if("add" == args[0]) { current_op = priscas::ADD; }	
		else if("sub" == args[0]) { current_op = priscas::SUB; }	
		else if("multl" == args[0]) { current_op = priscas::MULTL; }	
		else if("multh" ==  args[0]) { current_op = priscas::MULTH; }
		else if("ls" == args[0]) { current_op = priscas::LS; }
		else if("rs" == args[0]) { current_op = priscas::RS; }
		else if("ror" == args[0]) { current_op = priscas::ROR; }
		else if("beq" == args[0]) { current_op = priscas::BEQ; }
		else if("bneq" == args[0]) { current_op = priscas::BNEQ; }
		else if("bltz" == args[0]) { current_op = priscas::BLTZ; }
		else if("bgtz" == args[0]) { current_op = priscas::BGTZ; }
		else if("blez" == args[0]) { current_op = priscas::BLEZ; }
		else if("bgez" == args[0]) { current_op = priscas::BGEZ; }	
		else if("jmp" == args[0]) { current_op = priscas::JMP;}
		else if("jmpi" == args[0]) { current_op = priscas::JMPI; }	
		else if("ldi" == args[0]) { current_op = priscas::LDI; }
		else if("sti" == args[0]) { current_op = priscas::STI; }
		else if("push" == args[0]) { current_op = priscas::PUSH;}
		else if("pop" == args[0]) { current_op = priscas::POP;}	
		else
		{
			throw mt_bad_mnemonic();
		}

		// Check for insufficient arguments
		if(args.size() >= 1)
		{
			if	(
					(l_inst(current_op) && args.size() != 4 && f_code != priscas::JR) ||
					(r_inst(current_op) && args.size() != 4 && f_code == priscas::JR) ||
					(i_inst(current_op) && args.size() != 2 && !mem_inst(current_op)) ||
					(i_inst(current_op) && args.size() != 3 && mem_inst(current_op)) ||
					(d_inst(current_op) && args.size() != 2)				
				)
			{
				throw priscas::mt_asm_bad_arg_count();
			}

			// Now first argument parsing
			if(l_inst(current_op))
			{
					if((rd = priscas::friendly_to_numerical(args[1].c_str())) <= priscas::INVALID)
						rd = priscas::get_reg_num(args[1].c_str());
			}

			else if(r_inst(current_op))
			{
				// later, check for branches
				if((rd = priscas::friendly_to_numerical(args[1].c_str())) <= priscas::INVALID)
				rd = priscas::get_reg_num(args[1].c_str());
			}

			else if(i_inst(current_op))//TODO make sure this part works as intended
			{
				if(jump_syms.has(args[1]))
				{
					priscas::BW_32 label_PC = static_cast<int32_t>(jump_syms.lookup_from_sym(std::string(args[1].c_str())));
					imm = (label_PC.AsUInt32() >> 2);
				}

				else
				{
					imm = priscas::get_imm(args[1].c_str());
				}
			}
			else if(d_inst(current_op))
			{
				if((rd = priscas::friendly_to_numerical(args[1].c_str())) <= proscas::INVALID)
					rd = priscas::get_reg_num(args[1].c_str());	
			}
			else
			{
				priscas::mt_bad_mnemonic();
			} 
		}

		// Second Argument Parsing
		
		if(args.size() > 2)
		{
			if(l_inst(current_op))
			{
				if((rs = priscas::friendly_to_numerical(args[2].c_str())) <= priscas::INVALID)
					rs = priscas::get_reg_num(args[2].c_str());
		
			}
						
			else if(r_inst(current_op))
			{
				/* UNSURE IF NEEDED?
				if(mem_inst(current_op))
				{
					bool left_parenth = false; bool right_parenth = false;
					std::string wc = args[2];
					std::string imm_s = std::string();
					std::string reg = std::string();

					for(size_t i = 0; i < wc.length(); i++)
					{
						if(wc[i] == '(') { left_parenth = true; continue; }
						if(wc[i] == ')') { right_parenth = true; continue; }

						if(left_parenth)
						{
							reg.push_back(wc[i]);
						}

						else
						{
							imm_s.push_back(wc[i]);
						}
					}

					if(!right_parenth || !left_parenth) throw mt_unmatched_parenthesis();
					if((rs = priscas::friendly_to_numerical(reg.c_str())) <= priscas::INVALID) rs = priscas::get_reg_num(reg.c_str());
					imm = priscas::get_imm(imm_s.c_str());
								
				}

				else
				{
				*/
					// later, MUST check for branches
				if((rs = priscas::friendly_to_numerical(args[2].c_str())) <= priscas::INVALID)
					rs = priscas::get_reg_num(args[2].c_str());
				//}
			}

			else if(i_inst(current_op)) //To handle LDI STI will need to code up encoding special
			{
				if((rd = priscas::friendlt_to_numerical(args[2].c_str()))<= priscas::INVALID)
					rd = priscas::get_reg_num(args[2].c_str());
			}	
		}

		if(args.size() > 3)
		{
			// Third Argument Parsing
			if(r_inst(current_op))
			{
						
				if((rt = priscas::friendly_to_numerical(args[3].c_str())) <= priscas::INVALID)
					rt = priscas::get_reg_num(args[3].c_str());
			
			
			}
						
			else if(l_inst(current_op))
			{
				//TODO figure out if that part is necessary what it does
				if(jump_syms.has(args[3]))
				{
					priscas::BW_32 addr = baseAddress.AsUInt32();
					priscas::BW_32 label_PC = static_cast<uint32_t>(jump_syms.lookup_from_sym(std::string(args[3].c_str())));
					imm = priscas::offset_to_address_br(addr, label_PC).AsUInt32();
				}

				else
				{
					imm = priscas::get_imm(args[3].c_str());
				}
			}

		}

		// Pass the values of rs, rt, rd to the processor's encoding function
		BW_32 inst = generic_mips32_encode(rs, rt, rd, f_code, imm, current_op);

		return std::shared_ptr<BW>(new BW_32(inst));
	}
	//TODO figure out if needs to be changed
	// Returns register number corresponding with argument if any
	// Returns -1 if invalid or out of range
	int get_reg_num(const char * reg_str)
	{
		std::vector<char> numbers;
		int len = strlen(reg_str);
		if(len <= 1) throw priscas::mt_bad_imm();
		if(reg_str[0] != '$') throw priscas::mt_parse_unexpected("$", reg_str);
		for(int i = 1; i < len; i++)
		{
			if(reg_str[i] >= '0' && reg_str[i] <= '9')
			{
				numbers.push_back(reg_str[i]);
			}

			else throw priscas::mt_bad_reg_format();
		}

		int num = -1;

		if(numbers.empty()) throw priscas::mt_bad_reg_format();
		else
		{
			char * num_str = new char[numbers.size()];

			int k = 0;
			for(std::vector<char>::iterator itr = numbers.begin(); itr < numbers.end(); itr++)
			{
				num_str[k] = *itr;
				k++;
			}
			num = atoi(num_str);
			delete[] num_str;
		}

		return num;
	}

	// Returns immediate value if valid
	int get_imm(const char * str)
	{
		return StrOp::StrToUInt32(UPString(str));
	}
}
