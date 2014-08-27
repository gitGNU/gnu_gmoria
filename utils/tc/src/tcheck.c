/* tcheck.c: consistency checker for the Moria treasure definition compiler

   Copyright (C) 2007, 2010, 2014 Ben Asselstine
   Written by Ben Asselstine

   This file is part of tc, the moria treasure compiler.

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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "treasure.h"
#include "xvasprintf.h"

static void
TErrMsg (treasure_type *t, char *s)
{
  char *msg = xasprintf ("Consistency problem with '%s': %s", t->name, s);
  if (msg)
    {
      ErrMsg (msg);
      free (msg);
    }
  return;
}

void
ConsistencyCheckTreasure (treasure_type *t, state_type *s)
{
  if (t->tval == TV_STAFF)
    {
      if (t->flags == 0)
	TErrMsg (t, "No `staff_casts' attribute specified");
    }
  else if (t->tval == TV_FOOD && s->mushroom_flag)
    {
      if (t->flags ==  0)
	TErrMsg (t, "No `eating_causes' attribute specified");
    }
  else if (t->tval == TV_WAND)
    {
      if (t->flags == 0)
	TErrMsg (t, "No `wand_casts' attribute specified");
    }
  else if (t->tval == TV_SCROLL)
    {
      if (t->flags == 0)
	TErrMsg (t, "No `scroll_casts' attribute specified");
    }
  else if (t->tval == TV_MAGIC_BOOK)
    {
      if (t->flags == 0)
	TErrMsg (t, "No `spell' attribute specified");
    }
  else if (t->tval == TV_PRAYER_BOOK)
    {
      if (t->flags == 0)
	TErrMsg (t, "No `prayer' attribute specified");
    }
  else if (t->tval == TV_GOLD)
    {
      if (t->cost <= 0)
	TErrMsg (t, "`cost' attribute must be greater than 0");
    }
  else if (t->tval == TV_FOOD)
    {
      if (t->p1 <= 0)
	TErrMsg (t, "`p1' attribute must be greater than 0");
    }

  if (t->tval == TV_NOTHING)
    {
      if (t->number > 0)
	TErrMsg (t, "`quantity' attribute must be precisely 0");
    }
  else
    {
      if (t->number <= 0)
	TErrMsg (t, "`quantity' attribute must be greater than 0");
    }

  if (t->tval == TV_SOFT_ARMOR || t->tval == TV_HARD_ARMOR ||
      t->tval == TV_BOOTS || t->tval == TV_GLOVES)
    {
      if (t->ac <= 0)
	TErrMsg (t, "`ac' attribute must be greater than 0");
    }
  switch (t->tval)
    {
    case TV_OPEN_DOOR:
    case TV_CLOSED_DOOR:
    case TV_SECRET_DOOR:
    case TV_UP_STAIR:
    case TV_DOWN_STAIR:
    case TV_STORE_DOOR:
    case TV_VIS_TRAP:
    case TV_INVIS_TRAP:
    case TV_RUBBLE:
    case TV_GOLD:
    case TV_NOTHING:
	{
	  if (t->weight > 0)
	    TErrMsg (t, "`weight' attribute must be precisely 0");
	  break;
	}
    default:
	{
	  if (t->weight <= 0)
	    TErrMsg (t, "`weight' attribute must be greater than 0");
	  break;
	}
    }
  switch (t->tval)
    {
    case TV_SWORD:
    case TV_HAFTED:
    case TV_POLEARM:
	{
	  if (t->damage[0] == 0 || t->damage[1] == 0)
	    TErrMsg (t, "`damage' attribute must be at least 1|1");
	}
      break;
    default:
      break;
    }
  //rings and potions don't necessarily need a particular effect
  //chests don't necessarily need a "contains"
  return;
}
