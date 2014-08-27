/* generic.h: useful generic union type, used here and there
 *
 * Copyright (c) 1989 by Joseph Hall.
 * All rights reserved except as stated below.
 *
 * Jim Wilson and any other holders of copyright on substantial portions
 * of Moria are granted rights to use, modify, and distribute this program
 * as they see fit, so long as the terms of its use, modification and/or
 * distribution are no less restrictive than those applying to Moria,
 * version 5.0 or later, itself, and so long as this use is related to
 * the further development of Moria.
 *
 * Anyone having any other use in mind for this code should contact the
 * author at 4116 Brewster Dr., Raleigh NC 27606 (jnh@ecemwl.ncsu.edu).
 *
   Copyright (C) 2005, 2010 Ben Asselstine
   Written by Ben Asselstine
  
   mc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   mc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with mc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */

#ifndef _GENERIC_H_
#define _GENERIC_H_

typedef union {
	int	i;
	long	l;
	float	f;
	double	d;
	char	c;
	char	*s;
	char	**s_A;
	char	*v;
	} generic_t, *generic_Pt;

#define GEN_TYPE_NONE 0
#define GEN_TYPE_INT 1
#define GEN_TYPE_LONG 2
#define GEN_TYPE_FLOAT 3
#define GEN_TYPE_DOUBLE 4
#define GEN_TYPE_CHAR 5
#define GEN_TYPE_STRING 6
#define GEN_TYPE_STRING_A 7
#define GEN_TYPE_VOID_PTR 8

#endif /* _GENERIC_H_ */
