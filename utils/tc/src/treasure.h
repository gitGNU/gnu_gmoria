/*
   Copyright (C) 2007, 2014 Ben Asselstine
   Written by Ben Asselstine
  
   tc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   tc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with tc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

#ifndef TC_CREATURE_H
#define TC_CREATURE_H 1

#include "primitives.h"

#include "player_constant.h"
#include "object_constant.h"
#include "treasure_type.h"

typedef struct 
{
  /* we need to keep track of stackability too. */
  int stackable;
  /* this item stacks with other objects of this kind/p1, plus this id too */
  int stackable_id;
  /* we need to keep track of horrible one-offs. */
  int unique_function;
  /* we need to keep track of objects that are only found in stores. */
  int store_only;
  /* we need to distinguish between mushrooms and other foods. */
  int mushroom_flag;
  /* we need to keep track of which stores carry this item (if any). */
  int buyable;
  /* we need to keep track of how frequently this item is up for sale */
  int buyable_freq[MAX_STORES];
}state_type;


#define STACK_NEVER          0x0000001
#define STACK_WITH_SAME_KIND 0x0000002
#define STACK_WITH_SAME_P1   0x0000004

#define UNIQ_CHEST_RUINED     0
#define UNIQ_WIZARD_OBJECT    1
#define UNIQ_SCARE_MONSTER    2
#define UNIQ_CREATED_BY_SPELL 3
#define UNIQ_INVENTORY_OBJECT 4

#define SOLD_IN_STORES 1

int tc_main (char *inputFilename);
unsigned int lookup_flag (char *kind, char *flags);
void ErrMsg (char *s);
#endif
