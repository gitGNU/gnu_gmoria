/* src/treasure.c: dungeon object definitions

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
#include <stdio.h>

char *special_names[SN_ARRAY_SIZE] = {
  
  NULL,                   "(R)",                  "(RA)",
  "(RF)",                 "(RC)",                 "(RL)",
  "(HA)",                 "(DF)",                 "(SA)",
  "(SD)",                 "(SE)",                 "(SU)",
  "(FT)",                 "(FB)",                 "of Free Action",
  "of Slaying",           "of Clumsiness",        "of Weakness",
  "of Slow Descent",      "of Speed",             "of Stealth",
  "of Slowness",          "of Noise",             "of Great Mass",
  "of Intelligence",      "of Wisdom",            "of Infra-Vision",
  "of Might",             "of Lordliness",        "of the Magi",
  "of Beauty",            "of Seeing",            "of Regeneration",
  "of Stupidity",         "of Dullness",          "of Blindness",
  "of Timidness",         "of Teleportation",     "of Ugliness",
  "of Protection",        "of Irritation",        "of Vulnerability",
  "of Enveloping",        "of Fire",              "of Slay Evil",
  "of Dragon Slaying",    "(Empty)",              "(Locked)",
  "(Poison Needle)",      "(Gas Trap)",           "(Explosion Device)",
  "(Summoning Runes)",    "(Multiple Traps)",     "(Disarmed)",
  "(Unlocked)",           "of Slay Animal"
};

/* Pairing things down for THINK C.  */
#ifndef RSRC_PART2
int16 sorted_objects[MAX_DUNGEON_OBJ];

/* Identified objects flags					*/
int8u object_ident[OBJECT_IDENT_SIZE];
int16 t_level[MAX_OBJ_LEVEL + 1];
inven_type t_list[MAX_TALLOC];
inven_type inventory[INVEN_ARRAY_SIZE];
#endif

/* Treasure related values					*/
int16 inven_ctr = 0;		/* Total different obj's        */
int16 inven_weight = 0;		/* Cur carried weight   */
int16 equip_ctr = 0;		/* Cur equipment ctr    */
int16 tcptr;			/* Cur treasure heap ptr        */
