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
#ifndef __MIPS_H__
#define __MIPS_H__


/* A header for mips specifc details
 * such as register name mappings
 * and a jump list for functional routines
 *
 * Instruction Formats:
 * L - 8 opcode, 4 rd, 4 rs, 16 imm
 * R - 8 opcode, 4 rd, 4 rs, 4 rt, 12 x
 * I - 8 opcode, 8 x, 16 imm
 * D - 8 opcode, 4 rd, 20 x
 *
 *
 * wchen329
 */
#include <cstring>
#include <cstddef>
#include <memory>
#include "ISA.h"
#include "mt_exception.h"
#include "primitives.h"
#include "priscas_global.h"
#include "syms_table.h"
#include "ustrop.h"

namespace priscas
{

	// Friendly Register Names -> Numerical Assignments
	enum REGISTERS
	{
		$zero = 0,
		$g0 = 1,
		$g1 = 2,
		$g2 = 3,
		$g3 = 4,
		$g4 = 5,
		$g5 = 6,
		$g6 = 7,
		$g7 = 8,
		$g8 = 9,
		$g9 = 10,
		$g10 = 11,
		$g11 = 12,
		$g12 = 13,
		$g13 = 14,
		$g14 = 15,
		INVALID = -1
	};

	// instruction formats
	enum format
	{
		L, R, I, D	
	};

	// MIPS Processor Opcodes
	enum opcode
	{
	  ADD = 16,
    ADDI = 17,
    SUB = 18,
    SUBI = 19,
    MULTL = 20,
    MULTLI = 21,
    MULTH = 22,
    MULTHI = 23,
    LS = 32,
    LSI = 33,
    RS = 34,
    RSI = 35,
    ROR = 36,
    RORI = 37,
		BEQ = 49,
		BNEQ = 51,
		BLTZ = 53,
		BGTZ = 55,
		BLEZ = 57,
		BGEZ = 59,
		JMP = 61,
		JMPI = 63,
		PUSH = 64,
		POP = 66,
		LDI = 129,
		STI = 131,
		LDB = 133,
		STB = 135,
		SYS_RES = -1	// system reserved for shell interpreter
	};

	
	int friendly_to_numerical(const char *);

	// From a register specifier, i.e. %so get an integer representation
	int get_reg_num(const char *);

	// From a immediate string, get an immediate value.
	int get_imm(const char *);

	namespace ALU
	{
		enum ALUOp // TO-DO
		{
					ADD = 0,
					SUB = 1,
					SLL = 2,
					SRL = 3,
					OR = 4,
					AND = 5,
					XOR = 6
		};
	}

	// Format check functions
	/* Checks if an instruction is I formatted.
	 */
	bool l_inst(opcode operation);

	/* Checks if an instruction is R formatted.
	 */
	bool r_inst(opcode operation);

	/* Checks if an instruction is J formatted.
	 */
	bool i_inst(opcode operation);
	/*checks if instaruction is d formatted
	 */
	bool d_inst(opcode operation);
	/* Checks if an instruction performs
	 * memory access
	 */
	bool mem_inst(opcode operation);

	/* Checks if an instruction performs
	 * memory write
	 */
	bool mem_write_inst(opcode operation);

	/* Checks if an instruction performs
	 * memory read
	 */
	bool mem_read_inst(opcode operation);

	/* Checks if an instruction performs
	 * a register write
	 */
	bool reg_write_inst(opcode operation);

	/* Check if a special R-format
	 * shift instruction
	 */
	bool shift_inst(opcode operation);

	/* Check if a Jump or
	 * Branch Instruction
	 */
	bool jorb_inst(opcode operation);

	/* "Generic" MIPS-32 architecture
	 * encoding function asm -> binary
	 */
	BW_32 generic_mips32_encode(int rs, int rt, int rd, int funct, int imm_shamt_jaddr, opcode op);

	/* For calculating a label offset in branches
	 */
	BW_32 offset_to_address_br(BW_32 current, BW_32 target);

	/* MIPS_32 ISA
	 *
	 */
	class MIPS_32 : public ISA
	{
		
		public:
			virtual std::string get_reg_name(int id);
			virtual int get_reg_id(std::string& fr) { return friendly_to_numerical(fr.c_str()); }
			virtual ISA_Attrib::endian get_endian() { return ISA_Attrib::CPU_LITTLE_ENDIAN; }
			virtual mBW assemble(const Arg_Vec& args, const BW& baseAddress, syms_table& jump_syms) const;
		private:
			static const unsigned REG_COUNT = 16;
			static const unsigned PC_BIT_WIDTH = 32;
			static const unsigned UNIVERSAL_REG_BW = 32;
	};
}

#endif
