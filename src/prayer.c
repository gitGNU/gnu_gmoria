/* src/prayer.c: code for priest spells

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
#include "externs.h"

#include <stdio.h>

/* Pray like HELL.					-RAK-	*/
void
pray ()
{
  int i, j, item_val, dir;
  int choice, chance, result;
  register spell_type *s_ptr;
  register struct misc *m_ptr;
  register struct flags *f_ptr;
  register inven_type *i_ptr;

  free_turn_flag = TRUE;
  if (py.flags.blind > 0)
    msg_print ("You can't see to read your prayer!");
  else if (no_light ())
    msg_print ("You have no light to read by.");
  else if (py.flags.confused > 0)
    msg_print ("You are too confused.");
  else if (class[py.misc.pclass].spell != PRIEST)
    msg_print ("Pray hard enough and your prayers may be answered.");
  else if (inven_ctr == 0)
    msg_print ("But you are not carrying anything!");
  else if (!find_range (TV_PRAYER_BOOK, TV_NEVER, &i, &j))
    msg_print ("You are not carrying any Holy Books!");
  else if (get_item (&item_val, "Use which Holy Book?", i, j, NULL, NULL))
    {
      result =
	cast_spell ("Recite which prayer?", item_val, &choice, &chance);
      if (result < 0)
	msg_print ("You don't know any prayers in that book.");
      else if (result > 0)
	{
	  s_ptr = &magic_spell[py.misc.pclass][choice];
	  free_turn_flag = FALSE;

	  if (randint (100) < chance)
	    msg_print ("You lost your concentration!");
	  else
	    {
	      /* Prayers.                                       */
	      switch (choice + 1)
		{
		case 1:
		  detect_evil ();
		  break;
		case 2:
		  hp_player (damroll (3, 3));
		  break;
		case 3:
		  bless (randint (12) + 12);
		  break;
		case 4:
		  remove_fear ();
		  break;
		case 5:
		  light_area (char_row, char_col);
		  break;
		case 6:
		  detect_trap ();
		  break;
		case 7:
		  detect_sdoor ();
		  break;
		case 8:
		  slow_poison ();
		  break;
		case 9:
		  if (get_dir (NULL, &dir))
		    confuse_monster (dir, char_row, char_col);
		  break;
		case 10:
		  teleport ((int) (py.misc.lev * 3));
		  break;
		case 11:
		  hp_player (damroll (4, 4));
		  break;
		case 12:
		  bless (randint (24) + 24);
		  break;
		case 13:
		  sleep_monsters1 (char_row, char_col);
		  break;
		case 14:
		  create_food ();
		  break;
		case 15:
		  for (i = 0; i < INVEN_ARRAY_SIZE; i++)
		    {
		      i_ptr = &inventory[i];
		      /* only clear flag for items that are wielded or worn */
		      if (i_ptr->tval >= TV_MIN_WEAR
			  && i_ptr->tval <= TV_MAX_WEAR)
			i_ptr->flags &= ~TR_CURSED;
		    }
		  break;
		case 16:
		  f_ptr = &py.flags;
		  f_ptr->resist_heat += randint (10) + 10;
		  f_ptr->resist_cold += randint (10) + 10;
		  break;
		case 17:
		  cure_poison ();
		  break;
		case 18:
		  if (get_dir (NULL, &dir))
		    fire_ball (GF_HOLY_ORB, dir, char_row, char_col,
			       (int) (damroll (3, 6) + py.misc.lev),
			       "Black Sphere");
		  break;
		case 19:
		  hp_player (damroll (8, 4));
		  break;
		case 20:
		  detect_inv2 (randint (24) + 24);
		  break;
		case 21:
		  protect_evil ();
		  break;
		case 22:
		  earthquake ();
		  break;
		case 23:
		  map_area ();
		  break;
		case 24:
		  hp_player (damroll (16, 4));
		  break;
		case 25:
		  turn_undead ();
		  break;
		case 26:
		  bless (randint (48) + 48);
		  break;
		case 27:
		  dispel_creature (CD_UNDEAD, (int) (3 * py.misc.lev));
		  break;
		case 28:
		  hp_player (200);
		  break;
		case 29:
		  dispel_creature (CD_EVIL, (int) (3 * py.misc.lev));
		  break;
                case 30:
                  resist_poison_gas();
		case 31:
		  warding_glyph ();
		  break;
		case 32:
		  remove_fear ();
		  cure_poison ();
		  hp_player (1000);
		  for (i = A_STR; i <= A_CHR; i++)
		    res_stat (i);
		  dispel_creature (CD_EVIL, (int) (4 * py.misc.lev));
		  turn_undead ();
		  if (py.flags.invuln < 3)
		    py.flags.invuln = 3;
		  else
		    py.flags.invuln++;
		  break;
		default:
		  break;
		}
	      /* End of prayers.                                */
	      if (!free_turn_flag)
		{
		  m_ptr = &py.misc;
                  if (spell_status[choice].worked == 0)
                    {
		      m_ptr->exp += s_ptr->sexp << 2;
		      prt_experience ();
                      spell_status[choice].worked = 1;
                    }
		}
	    }
	  m_ptr = &py.misc;
	  if (!free_turn_flag)
	    {
	      if (s_ptr->smana > m_ptr->cmana)
		{
		  msg_print ("You faint from fatigue!");
		  py.flags.paralysis =
		    randint ((int) (5 * (s_ptr->smana - m_ptr->cmana)));
		  m_ptr->cmana = 0;
		  m_ptr->cmana_frac = 0;
		  if (randint (3) == 1)
		    {
		      msg_print ("You have damaged your health!");
		      dec_stat (A_CON);
		    }
		}
	      else
		m_ptr->cmana -= s_ptr->smana;
	      prt_cmana ();
	    }
	}
    }
}
