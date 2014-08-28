/* src/magic.c: code for mage spells

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

/* Throw a magic spell					-RAK-	*/
void
cast ()
{
  int i, j, item_val, dir;
  int choice, chance, result;
  register struct flags *f_ptr;
  register struct misc *p_ptr;
  register inven_type *i_ptr;
  register spell_type *m_ptr;

  free_turn_flag = TRUE;
  if (py.flags.blind > 0)
    msg_print ("You can't see to read your spell book!");
  else if (no_light ())
    msg_print ("You have no light to read by.");
  else if (py.flags.confused > 0)
    msg_print ("You are too confused.");
  else if (class[py.misc.pclass].spell != MAGE)
    msg_print ("You can't cast spells!");
  else if (!find_range (TV_MAGIC_BOOK, TV_NEVER, &i, &j))
    msg_print ("But you are not carrying any spell-books!");
  else if (get_item (&item_val, "Use which spell-book?", i, j, NULL, NULL))
    {
      result = cast_spell ("Cast which spell?", item_val, &choice, &chance);
      if (result < 0)
	msg_print ("You don't know any spells in that book.");
      else if (result > 0)
	{
	  m_ptr = &magic_spell[py.misc.pclass][choice];
	  free_turn_flag = FALSE;

	  if (randint (100) < chance)
	    msg_print ("You failed to get the spell off!");
	  else
	    {
	      /* Spells.  */
	      switch (choice + 1)
		{
		case 1:
		  if (get_dir (NULL, &dir))
		    fire_bolt (GF_MAGIC_MISSILE, dir, char_row, char_col,
			       damroll (2, 6), spell_names[0]);
		  break;
		case 2:
		  detect_monsters ();
		  break;
		case 3:
		  teleport (10);
		  break;
		case 4:
		  light_area (char_row, char_col);
		  break;
		case 5:
		  hp_player (damroll (4, 4));
		  break;
		case 6:
		  detect_sdoor ();
		  detect_trap ();
		  break;
		case 7:
		  if (get_dir (NULL, &dir))
		    fire_ball (GF_POISON_GAS, dir, char_row, char_col, 12,
			       spell_names[6]);
		  break;
		case 8:
		  if (get_dir (NULL, &dir))
		    confuse_monster (dir, char_row, char_col);
		  break;
		case 9:
		  if (get_dir (NULL, &dir))
		    fire_bolt (GF_LIGHTNING, dir, char_row, char_col,
			       damroll (4, 8), spell_names[8]);
		  break;
		case 10:
		  td_destroy ();
		  break;
		case 11:
		  if (get_dir (NULL, &dir))
		    sleep_monster (dir, char_row, char_col);
		  break;
		case 12:
		  cure_poison ();
		  break;
		case 13:
		  teleport ((int) (py.misc.lev * 5));
		  break;
		case 14:
		  for (i = 22; i < INVEN_ARRAY_SIZE; i++)
		    {
		      i_ptr = &inventory[i];
		      i_ptr->flags = (i_ptr->flags & ~TR_CURSED);
		    }
		  break;
		case 15:
		  if (get_dir (NULL, &dir))
		    fire_bolt (GF_FROST, dir, char_row, char_col,
			       damroll (6, 8), spell_names[14]);
		  break;
		case 16:
		  if (get_dir (NULL, &dir))
		    wall_to_mud (dir, char_row, char_col);
		  break;
		case 17:
		  create_food ();
		  break;
		case 18:
		  recharge (20);
		  break;
		case 19:
		  sleep_monsters1 (char_row, char_col);
		  break;
		case 20:
		  if (get_dir (NULL, &dir))
		    poly_monster (dir, char_row, char_col);
		  break;
		case 21:
		  ident_spell ();
		  break;
		case 22:
		  sleep_monsters2 ();
		  break;
		case 23:
		  if (get_dir (NULL, &dir))
		    fire_bolt (GF_FIRE, dir, char_row, char_col,
			       damroll (9, 8), spell_names[22]);
		  break;
		case 24:
		  if (get_dir (NULL, &dir))
		    speed_monster (dir, char_row, char_col, -1);
		  break;
		case 25:
		  if (get_dir (NULL, &dir))
		    fire_ball (GF_FROST, dir, char_row, char_col, 48,
			       spell_names[24]);
		  break;
		case 26:
		  recharge (60);
		  break;
		case 27:
		  if (get_dir (NULL, &dir))
		    teleport_monster (dir, char_row, char_col);
		  break;
		case 28:
		  f_ptr = &py.flags;
		  f_ptr->fast += randint (20) + py.misc.lev;
		  break;
		case 29:
		  if (get_dir (NULL, &dir))
		    fire_ball (GF_FIRE, dir, char_row, char_col, 72,
			       spell_names[28]);
		  break;
                case 30:
                  resist_poison_gas();
		case 31:
		  destroy_area (char_row, char_col);
		  break;
		case 32:
		  genocide ();
		  break;
		default:
		  break;
		}
	      /* End of spells.                              */
	      if (!free_turn_flag)
		{
		  p_ptr = &py.misc;
                  if (spell_status[choice].worked == 0)
                    {
		      p_ptr->exp += m_ptr->sexp << 2;
                      spell_status[choice].worked = 1;
		      prt_experience ();
                    }
		}
	    }
	  p_ptr = &py.misc;
	  if (!free_turn_flag)
	    {
	      if (m_ptr->smana > p_ptr->cmana)
		{
		  msg_print ("You faint from the effort!");
		  py.flags.paralysis =
		    randint ((int) (5 * (m_ptr->smana - p_ptr->cmana)));
		  p_ptr->cmana = 0;
		  p_ptr->cmana_frac = 0;
		  if (randint (3) == 1)
		    {
		      msg_print ("You have damaged your health!");
		      dec_stat (A_CON);
		    }
		}
	      else
		p_ptr->cmana -= m_ptr->smana;
	      prt_cmana ();
	    }
	}
    }
}
