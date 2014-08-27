/* src/creature_type.h
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

#ifndef CREATURE_TYPE_H
#define CREATURE_TYPE_H
#include "primitives.h"

typedef struct creature_type
{
  char *name;			/* Descrip of creature  */
  int32u cmove;			/* Bit field            */
  int32u spells;		/* Creature spells      */
  int16u cdefense;		/* Bit field            */
  int16u mexp;			/* Exp value for kill   */
  int8u sleep;			/* Inactive counter/10  */
  int8u aaf;			/* Area affect radius   */
  int8u ac;			/* AC                   */
  int8u speed;			/* Movement speed+10    */
  int8u cchar;			/* Character rep.       */
  int8u hd[2];			/* Creatures hit die    */
  int8u damage[4];		/* Type attack and damage */
  int8u level;			/* Level of creature    */
} creature_type;

typedef struct m_attack_type	/* Monster attack and damage types */
{
  int8u attack_type;
  int8u attack_desc;
  int8u attack_dice;
  int8u attack_sides;
} m_attack_type;

#endif
