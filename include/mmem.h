//////////////////////////////////////////////////////////////////////////////
//
//    PRISCAS - Computer architecture simulator
//    Copyright (C) 2019 Winor Chen
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
#ifndef __MMEM_H__
#define __MMEM_H__
#include <cstring>
#include "priscas_global.h"
#include "primitives.h"

namespace priscas
{
	// Main memory
	class mmem
	{
		public:
			size_t get_size(){return size;}		// returns size;
			byte_8b * begin() {return data;}	// get beginning address of data range
			mmem();
			mmem(size_t);
			byte_8b& operator[](ptrdiff_t ind);
			const byte_8b& operator[](ptrdiff_t ind) const;
			void save(ptrdiff_t begin, ptrdiff_t end, FILE*);
			void restore(ptrdiff_t begin, FILE*);
			void resize(size_t size);
			void reset();
			~mmem();
		private:
			mmem operator=(const mmem &);		// copy assignment, disabled
			mmem(const mmem &);					// copy constructor, disabled
			byte_8b * data;					// the actual data of memory
			size_t size;					// size of memory space in bytes

			void alloc(size_t bytes);
			void dealloc();
	};

}

#endif
