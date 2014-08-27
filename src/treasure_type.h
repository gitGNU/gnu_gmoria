/* src/treasure_type.h
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

#ifndef TREASURE_TYPE_H
#define TREASURE_TYPE_H
#include "primitives.h"

typedef struct treasure_type
{
  char *name;			/* Object name          */
  int32u flags;			/* Special flags        */
  int32u effect_idx;		/* Effect Index         */
  int8u tval;			/* Category number      */
  int8u tchar;			/* Character representation */
  int16 p1;			/* Misc. use variable   */
  int32 cost;			/* Cost of item         */
  int8u subval;			/* Sub-category number  */
  int8u number;			/* Number of items      */
  int16u weight;		/* Weight               */
  int16 tohit;			/* Plusses to hit       */
  int16 todam;			/* Plusses to damage    */
  int16 ac;			/* Normal AC            */
  int16 toac;			/* Plusses to AC        */
  int8u damage[2];		/* Damage when hits     */
  int8u level;			/* Level item first found */
  int32u spells[MAX_SPELLS];    /* magic book contains these spells */
} treasure_type;
#endif
