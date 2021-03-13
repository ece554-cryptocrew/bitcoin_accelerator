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
#include "mmem.h"

namespace priscas
{
	byte_8b& mmem::operator[](ptrdiff_t ind)
	{
		return data[ind];
	}

	const byte_8b& mmem::operator[](ptrdiff_t ind) const
	{
		return data[ind];
	}

	mmem::mmem() :
		data(nullptr),
		size(0)
	{
	}

	mmem::mmem(size_t size)
	{

		this -> data = new byte_8b[size];
		this -> size = size;
	}

	mmem::mmem(const mmem & m)
	{
		// disabled, see interface declaration, may enable later
	}
	
	mmem mmem::operator=(const mmem & m)
	{
		// disabled, see interface declaration, may enable later
		return m;
	}

	void mmem::resize(size_t size)
	{
		delete[] this->data;
		this->data = new byte_8b[size];
		this->size = size;
	}

	mmem::~mmem()
	{
		delete this->data;
	}

	void mmem::save(ptrdiff_t begin, ptrdiff_t end, FILE* f)
	{
		// Dump the rest of the memory array

		uint64_t count = 0;
		uint64_t offset = 0;

		while(count < (end-begin))
		{
			offset = (begin + count) % size;
			fwrite(this->data + offset, sizeof(byte_8b), 1, f);
			++count;
		}
	}

	void mmem::restore(ptrdiff_t begin, FILE* f)
	{
		// Load the rest of the memory array
		uint64_t read_count = 0;
		uint64_t offset = 0;
		do
		{
			uint64_t where = (begin + offset) % size;
			fread(this->data + where, sizeof(byte_8b), 1, f);
		}
		while(read_count);
	}

	void mmem::reset()
	{
		// Memset Entire Memory region to zero
		memset(data, 0, size);
	}
}
