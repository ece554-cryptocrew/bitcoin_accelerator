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
			fr_name[1] == 'g' ?
				!strcmp("$g0", fr_name) ? $g0 :
				!strcmp("$g1", fr_name) ? $g1 :
				!strcmp("$g2", fr_name) ? $g2 :
				!strcmp("$g3", fr_name) ? $g3 :
				!strcmp("$g4", fr_name) ? $g4 :
				!strcmp("$g5", fr_name) ? $g5 :
				!strcmp("$g6", fr_name) ? $g6 :
				!strcmp("$g7", fr_name) ? $g7 :
				!strcmp("$g8", fr_name) ? $g8 :
				!strcmp("$g9", fr_name) ? $g9 :
				!strcmp("$g10", fr_name) ? $g10 :
				!strcmp("$g11", fr_name) ? $g11 :
				!strcmp("$g12", fr_name) ? $g12 :
			  !strcmp("$g13", fr_name) ? $g13 :
				!strcmp("$g14", fr_name) ? $g14 : INVALID	
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
			id == 1 ? "$g0" :
			id == 2 ? "$g1" :
			id == 3 ? "$g2" :
			id == 4 ? "$g3" :
			id == 5 ? "$g4" :
			id == 6 ? "$g5" :
			id == 7 ? "$g6" :
			id == 8 ? "$g7" :
			id == 9 ? "$g8" :
			id == 10 ? "$g9" :
			id == 11 ? "$g10" :
			id == 12 ? "$g11" :
			id == 13 ? "$g12" :
			id == 14 ? "$g13" :
			id == 15 ? "$g14" : "";
  
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
			operation == STI ? true:
			operation == LDI ? true:
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
			operation == BGEZ ? true:
			operation == BLEZ ? true:
			operation == BEQ ? true :
			operation == BNEQ ? true:
			operation == BLTZ ? true:
		 	operation == BGTZ ? true:
			operation == JMP ? true:
			operation == JMPI ? true:
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
			(operation == STI || operation == STB)? 
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
			(mem_read_inst(operation)) || (l_inst(operation) && operation != STB) || (r_inst(operation)) || operation == LDI || operation == POP;
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
		// first check jump
		bool is_jump = 
      operation == JMP ? true :
			operation == JMPI ? true :
			false;


		bool is_branch =
			operation == BEQ ? true :
			operation == BNEQ ? true :
			operation == BLTZ ? true :
			operation == BGTZ ? true :
			operation == BLEZ ? true :
		 	operation == BGEZ ? true :
			false;

		return is_jump || is_branch;
	}
	

  BW_32 generic_mips32_encode(int rs, int rt, int rd, int imm, opcode op)
	{
		BW_32 w = 0;

		if(l_inst(op))
		{
			w = (w.AsUInt32() | (imm & ((1 << 16) - 1)));
			w = (w.AsUInt32() | ((rs & ((1 << 4) - 1) ) << 16 ));
			w = (w.AsUInt32() | ((rd & ((1 << 4) - 1) ) << 20 ));
			w = (w.AsUInt32() | ((op & ((1 << 8) - 1) ) << 24 ));
		}

		if(r_inst(op))
		{
			w = (w.AsUInt32() | ((rt & ((1 << 4) - 1) ) << 12 ));
			w = (w.AsUInt32() | ((rs & ((1 << 4) - 1) ) << 16 ));
			w = (w.AsUInt32() | ((rd & ((1 << 4) - 1) ) << 20 ));
			w = (w.AsUInt32() | ((op & ((1 << 8) - 1) ) << 24 ));
		}

		if(i_inst(op))
		{

			w = (w.AsUInt32() | (imm & ((1 << 16) - 1)));
			w = (w.AsUInt32() | ((op & ((1 << 8) - 1) ) << 24 ));
		}

		if(d_inst(op)) // unsure about the rs|rd
		{
			w = (w.AsUInt32() | (((rs|rd) & ((1 << 16) - 1) ) << 20 ));
			w = (w.AsUInt32() | ((op & ((1 << 8) - 1) ) << 24 ));
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
		
		if("ADDI" == args[0]) { current_op = priscas::ADDI;}
		else if("SUBI" == args[0]) { current_op = priscas::SUBI;}
		else if("MULTLI" == args[0]) { current_op = priscas::MULTLI;}
		else if("MULTHI" == args[0]) { current_op = priscas::MULTHI; }
		else if("LSI" == args[0]) { current_op = priscas::LSI; }
		else if("RSI" == args[0]) { current_op = priscas::RSI; }
		else if("RORI" == args[0]) { current_op = priscas::RORI; }
		else if("LDB" == args[0]) { current_op = priscas::LDB; }
		else if("STB" == args[0]) { current_op = priscas::STB; }
		else if("ADD" == args[0]) { current_op = priscas::ADD; }	
		else if("SUB" == args[0]) { current_op = priscas::SUB; }	
		else if("MULTL" == args[0]) { current_op = priscas::MULTL; }	
		else if("MULTH" ==  args[0]) { current_op = priscas::MULTH; }
		else if("LS" == args[0]) { current_op = priscas::LS; }
		else if("RS" == args[0]) { current_op = priscas::RS; }
		else if("ROR" == args[0]) { current_op = priscas::ROR; }
		else if("BEQ" == args[0]) { current_op = priscas::BEQ; }
		else if("BNEQ" == args[0]) { current_op = priscas::BNEQ; }
		else if("BLTZ" == args[0]) { current_op = priscas::BLTZ; }
		else if("BGTZ" == args[0]) { current_op = priscas::BGTZ; }
		else if("BLEZ" == args[0]) { current_op = priscas::BLEZ; }
		else if("BGEZ" == args[0]) { current_op = priscas::BGEZ; }	
		else if("JMP" == args[0]) { current_op = priscas::JMP;}
		else if("JMPI" == args[0]) { current_op = priscas::JMPI; }	
		else if("LDI" == args[0]) { current_op = priscas::LDI; }
		else if("STI" == args[0]) { current_op = priscas::STI; }
		else if("PUSH" == args[0]) { current_op = priscas::PUSH;}
		else if("POP" == args[0]) { current_op = priscas::POP;}	
		else
		{
			throw mt_bad_mnemonic();
		}

		// Check for insufficient arguments
		if(args.size() >= 1)
		{
			if	(
					(l_inst(current_op) && args.size() != 4) ||
					(r_inst(current_op) && args.size() != 4) ||
					(i_inst(current_op) && args.size() != 2) ||
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
					imm = (label_PC.AsUInt32());
				}

				else
				{
						imm = priscas::get_imm(args[1].c_str());
				}
			}
			
      else if(d_inst(current_op))
			{
				if((rd = priscas::friendly_to_numerical(args[1].c_str())) <= priscas::INVALID)
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
    
						
			//else if(r_inst(current_op))
			//{
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

*/
        
      else if(r_inst(current_op))
      {
        // later, MUST check for branches
				if((rs = priscas::friendly_to_numerical(args[2].c_str())) <= priscas::INVALID)
					rs = priscas::get_reg_num(args[2].c_str());
	
			}

			else if(i_inst(current_op)) //To handle LDI STI will need to code up encoding special
			{
				if((rd = priscas::friendly_to_numerical(args[2].c_str()))<= priscas::INVALID)
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
		BW_32 inst = generic_mips32_encode(rs, rt, rd, imm, current_op);

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
