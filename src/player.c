/* src/player.c: player specific variable definitions

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
#include <stdlib.h>
#include "constant.h"
#include "types.h"
#include "externs.h"

/* Player record for most player related info */
player_type py;
/* player location in dungeon */
int16 char_row;
int16 char_col;
/* calculated base hp values for player at each level, store them so that
   drain life + restore life does not affect hit points */
int16u player_hp[MAX_PLAYER_LEVEL];

int32u spell_order[MAX_SPELLS];
spell_status_type spell_status[MAX_SPELLS];

/* Each type of character starts out with a few provisions.	*/
/* Note that the entries refer to elements of the object_list[] array*/
/* 344 = Food Ration, 365 = Wooden Torch, 123 = Cloak, 318 = Beginners-Majik,
   103 = Soft Leather Armor, 30 = Stiletto, 322 = Beginners Handbook 
   see fill_class_backpacks */
int16u player_init[MAX_CLASS][MAX_DEFAULT_PACK_ITEMS];

int 
get_store_item_index (int tval, int subval)
{
  int i;
  for (i = MAX_DUNGEON_OBJ; i < OBJ_OPEN_DOOR; i++)
    {
      if (object_list[i].tval == tval && object_list[i].subval == subval)
        return i;
    }
  return -1;
}

int
get_dungeon_item_index (int tval, int subval)
{
  int i;
  for (i = 0; i < MAX_DUNGEON_OBJ; i++)
    {
      if (object_list[i].tval == tval && object_list[i].subval == subval)
        return i;
    }
  return -1;
}

void
fill_class_backpacks ()
{
  int i;
  for (i = 0; i < MAX_CLASS; i++)
    {
      player_init[i][0] = get_store_item_index(TV_FOOD, 90);
      if (player_init[i][0] == 65535)
        {
          restore_term();
          fprintf (stderr, "Error! "
                   "Can't find a TV_FOOD item of subval 90 (%s) in stores.\n",
                   "e.g. a ration of food");
          exit(1);
        }
      player_init[i][1] = get_store_item_index(TV_LIGHT, 192);
      if (player_init[i][1] == 65535)
        {
          restore_term();
          fprintf (stderr, "Error! "
                   "Can't find a TV_LIGHT item of subval 192 (%s) in stores.\n",
                   "e.g. wooden torches");
          exit(1);
        }
      player_init[i][2] = get_dungeon_item_index(TV_CLOAK, 1);
      if (player_init[i][2] == 65535)
        {
          restore_term();
          fprintf (stderr, "Error! "
                   "Can't find a TV_CLOAK item of subval 1 (%s) in list %s.\n",
                   "e.g. just a standard old cloak", "of dungeon items");
          exit(1);
        }
      player_init[i][3] = get_dungeon_item_index(TV_SWORD, 3);
      if (player_init[i][3] == 65535)
        {
          restore_term();
          fprintf (stderr, "Error! "
                   "Can't find a TV_SWORD item of subval 3 (%s) in list %s.\n",
                   "e.g. a stiletto dagger", "of dungeon items");
          exit(1);
        }
      if (class[i].spell == NONE)
        {
          player_init[i][4] = get_dungeon_item_index(TV_SOFT_ARMOR, 2);
          if (player_init[i][4] == 65535)
            {
              restore_term();
              fprintf (stderr, "Error! "
                       "Can't find a TV_SOFT_ARMOR item of subval 2 (%s) %s.\n",
                       "e.g. soft leather armor", "in list of dungeon items");
              exit(1);
            }
        }
      else if (class[i].spell == MAGE)
        {
          player_init[i][4] = get_dungeon_item_index(TV_MAGIC_BOOK, 64);
          if (player_init[i][4] == 65535)
            {
              restore_term();
              fprintf (stderr, "Error! "
                       "Can't find a TV_MAGIC_BOOK item of subval 64 (%s)%s.\n",
                       "e.g. 1st magic book", " in list of dungeon items");
              exit(1);
            }
        }
      else if (class[i].spell == PRIEST)
        {
          player_init[i][4] = 322;
          player_init[i][4] = get_dungeon_item_index(TV_PRAYER_BOOK, 64);
          if (player_init[i][4] == 65535)
            {
              fprintf (stderr, "Error! Can't"
                       " find a TV_PRAYER_BOOK item of subval 64 (%s)%s.\n",
                       "e.g. 1st prayer book", " in list of dungeon items");
              exit(1);
            }
        }
    }
}
