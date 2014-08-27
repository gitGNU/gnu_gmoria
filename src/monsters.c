/* src/monsters.c: monster definitions

   Copyright (c) 1989-94 James E. Wilson, Robert A. Koeneke

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Library General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "config.h"
#include "constant.h"
#include "types.h"

monster_type m_list[MAX_MALLOC];
int16 m_level[MAX_MONS_LEVEL + 1];

/* Blank monster values	*/
monster_type blank_monster = { 0, 0, 0, 0, 0, 0, 0, FALSE, 0, FALSE };
int16 mfptr;			/* Cur free monster ptr */
int16 mon_tot_mult;		/* # of repro's of creature     */
