/* UNIX Moria Version 5.x
   src/main.c: initialization, main() function and main loop
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


/* Original copyright message follows. */

/* Moria Version 4.8	COPYRIGHT (c) Robert Alan Koeneke		*/
/*									 */
/*	 I lovingly dedicate this game to hackers and adventurers	 */
/*	 everywhere...							 */
/*									 */
/*									 */
/*	 Designer and Programmer : Robert Alan Koeneke			 */
/*				   University of Oklahoma		 */
/*									 */
/*	 Assistant Programmers	 : Jimmey Wayne Todd			 */
/*				   University of Oklahoma		 */
/*									 */
/*				   Gary D. McAdoo			 */
/*				   University of Oklahoma		 */
/*									 */
/*	 UNIX Port		 : James E. Wilson			 */
/*				   UC Berkeley				 */
/*				   wilson@kithrup.com			 */
/*									 */
/*	 MSDOS Port		 : Don Kneller				 */
/*				   1349 - 10th ave			 */
/*				   San Francisco, CA 94122		 */
/*				   kneller@cgl.ucsf.EDU			 */
/*				   ...ucbvax!ucsfcgl!kneller		 */
/*				   kneller@ucsf-cgl.BITNET		 */
/*									 */
/*	 BRUCE Moria		 : Christopher Stuart			 */
/*				   Monash University			 */
/*				   Melbourne, Victoria, AUSTRALIA	 */
/*				   cjs@moncsbruce.oz			 */
/*									 */
/*       Amiga Port              : Corey Gehman                          */
/*                                 Clemson University                    */
/*                                 cg377170@eng.clemson.edu              */
/*									 */
/*	 Version 5.5		 : David Grabiner			 */
/*				   Harvard University			 */
/*				   grabiner@math.harvard.edu		 */
/*                                                                       */


#include "config.h"
#include "constant.h"
#include "types.h"
#include "externs.h"

#include <string.h>

#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>

#include <time.h>

long time ();
char *getenv ();

void perror ();

void exit ();


static void char_inven_init ();
static void init_m_level ();
static void init_t_level ();
#if (COST_ADJ != 100)
static void price_adjust ();
#endif

/* Initialize, restore, and get the ball rolling.	-RAK-	*/
int
main (argc, argv)
     int argc;
     char *argv[];
{
  int32u seed;
  int generate;
  int result;
  char *p;
  int new_game = FALSE;
  int force_rogue_like = FALSE;
  int force_keys_to = KEYBINDING_ORIGINAL + 1;

  /* default command set defined in config.h file */
  if (ROGUE_LIKE)
    keybinding = KEYBINDING_ROGUELIKE;
  else
    keybinding = KEYBINDING_ORIGINAL;

  if (0 != setuid (getuid ()))
    {
      perror ("Can't set permissions correctly!  Setuid call failed.\n");
      exit (0);
    }
  if (0 != setgid (getgid ()))
    {
      perror ("Can't set permissions correctly!  Setgid call failed.\n");
      exit (0);
    }


  seed = 0;			/* let wizard specify rng seed */
  int i = 0;
  for (i = 0; i < argc; i++)
    {
      if (strcmp (argv[i], "--help") == 0)
        strcpy(argv[i], "-?");
      else if (strcmp (argv[i], "--version") == 0)
        strcpy(argv[i], "-V");
    }
  /* check for user interface option */
  for (--argc, ++argv; argc > 0 && argv[0][0] == '-'; --argc, ++argv)
    switch (argv[0][1])
      {
      case 'N':
      case 'n':
	new_game = TRUE;
	break;
      case 'O':
      case 'o':
	/* rogue_like_commands may be set in get_char(), so delay this
	   until after read savefile if any */
	force_rogue_like = TRUE;
	force_keys_to = KEYBINDING_ORIGINAL + 1;
	break;
      case 'R':
      case 'r':
	force_rogue_like = TRUE;
	force_keys_to = KEYBINDING_ROGUELIKE + 1;
	break;
      case 'S':
        init_scorefile ();
        init_curses ();
        init_signals ();
	display_scores (TRUE);
	exit_game ();
      case 's':
        init_scorefile ();
        init_curses ();
        init_signals ();
	display_scores (FALSE);
	exit_game ();
      case 'W':
      case 'w':
	to_be_wizard = TRUE;

	if (isdigit ((int) argv[0][2]))
	  seed = atoi (&argv[0][2]);
	break;
      case 'V':
        printf ("%s\n", PACKAGE_STRING);
        printf ("License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.\n");
        printf ("This is free software: you are free to change and redistribute it.\n");
        printf ("This software comes with ABSOLUTELY NO WARRANTY.\n");
        exit (0);
        break;
      case '?':
	printf ("Usage: " GAME_NAME " [-norsSw] [savefile]\n");
        printf ("Play a turn-based action-strategy game.\n");
        printf ("\n");
        printf ("  -n             start a new character\n");
        printf ("  -o             play with original moria keybindings\n");
        printf ("  -r             play with roguelike keybindings\n");
        printf ("  -s             display the scores and exit\n");
        printf ("  -S             display the scores belonging to your user and exit\n");
        printf ("  -w[seed]       start in wizard mode with a seed for random number generation\n");
        printf ("  -?, --help     display this help and exit\n");
        printf ("  -V, --version  output version information and exit\n");
        printf ("\n");
        printf ("If not specified, the savefile is ~/.%s-save.\n", GAME_NAME);
        printf ("\n");
        printf ("For complete documentation, visit: <%s>\n", PACKAGE_URL);
        printf ("\n");
        printf ("Report bugs to %s.\n", PACKAGE_BUGREPORT);
        exit (0);
        break;
      default:
	printf ("Usage: " GAME_NAME " [-norsSw] [savefile]\n");
	exit_game ();
      }

  /* call this routine to grab a file pointer to the highscore file */
  /* and prepare things to relinquish setuid privileges */
  init_scorefile ();
  init_curses ();
  init_signals ();

  display_news();
  /* Some necessary initializations             */
  /* all made into constants or initialized in variables.c */

#if (COST_ADJ != 100)
  price_adjust ();
#endif

  /* Grab a random seed from the clock          */
  init_seeds (seed);

  /* Init monster and treasure levels for allocate */
  init_m_level ();
  init_t_level ();

  /* Init the store inventories                 */
  store_init ();
  /* Init default backpacks */
  fill_class_backpacks();

  /* Auto-restart of saved file */
  if (argv[0] != NULL)
    snprintf(savefile, sizeof (savefile), "%s", argv[0]);
  else if ((p = getenv ("MORIA_SAV")) != NULL)
    snprintf (savefile, sizeof (savefile), "%s", p);
  else if ((p = getenv ("HOME")) != NULL)
    snprintf (savefile, sizeof (savefile), "%s/%s", p, "." GAME_NAME "-save");
  else
    snprintf (savefile, sizeof (savefile), "%s", "." GAME_NAME "-save");

/* This restoration of a saved character may get ONLY the monster memory. In
   this case, get_char returns false. It may also resurrect a dead character
   (if you are the wizard). In this case, it returns true, but also sets the
   parameter "generate" to true, as it does not recover any cave details. */

  result = FALSE;
  if ((new_game == FALSE) && !access (savefile, 0) && get_char (&generate))
    result = TRUE;

  /* enter wizard mode before showing the character display, but must wait
     until after get_char in case it was just a resurrection */
  if (to_be_wizard)
    if (!enter_wiz_mode ())
      exit_game ();

  if (result)
    {
      change_name ();

      /* could be restoring a dead character after a signal or HANGUP */
      if (py.misc.chp < 0)
	death = TRUE;
    }
  else
    {				/* Create character      */
      create_character ();
      birth_date = time ((long *) 0);
      char_inven_init ();
      py.flags.food = 7500;
      py.flags.food_digested = 2;
      if (class[py.misc.pclass].spell == MAGE)
	{			/* Magic realm   */
	  clear_screen ();	/* makes spell list easier to read */
	  calc_spells (A_INT);
	  calc_mana (A_INT);
	}
      else if (class[py.misc.pclass].spell == PRIEST)
	{			/* Clerical realm */
	  calc_spells (A_WIS);
	  clear_screen ();	/* force out the 'learn prayer' message */
	  calc_mana (A_WIS);
	}
      /* prevent ^c quit from entering score into scoreboard,
         and prevent signal from creating panic save until this point,
         all info needed for save file is now valid */
      character_generated = 1;
      generate = TRUE;
    }

  if (force_rogue_like)
    {
      if (force_keys_to)
	keybinding = force_keys_to - 1;
    }

  magic_init ();

  /* Begin the game                             */
  clear_screen ();
  prt_stat_block ();
  if (generate)
    generate_cave ();

  /* Loop till dead, or exit                    */
  while (!death)
    {
      dungeon ();		/* Dungeon logic */

      /* check for eof here, see inkey() in io.c */
      /* eof can occur if the process gets a HANGUP signal */
      if (eof_flag)
	{
	  snprintf (died_from, sizeof (died_from), "%s", 
		    "(end of input: saved)");
	  if (!save_char ())
	    {
	      snprintf (died_from, sizeof (died_from), "%s", 
			"unexpected eof");
	    }
	  /* should not reach here, by if we do, this guarantees exit */
	  death = TRUE;
	}

      if (!death)
	generate_cave ();	/* New level     */
    }

  exit_game ();			/* Character gets buried. */
  /* should never reach here, but just in case */
  return (0);
}

/* Init players with some belongings			-RAK-	*/
static void
char_inven_init ()
{
  register int i, j;
  inven_type inven_init;

  /* this is needed for bash to work right, it can't hurt anyway */
  for (i = 0; i < INVEN_ARRAY_SIZE; i++)
    invcopy (&inventory[i], OBJ_NOTHING);

  for (i = 0; i < 5; i++)
    {
      j = player_init[py.misc.pclass][i];
      invcopy (&inven_init, j);
      /* this makes it known2 and known1 */
      store_bought (&inven_init);
      /* must set this bit to display tohit/todam for stiletto */
      if (inven_init.tval == TV_SWORD)
	inven_init.ident |= ID_SHOW_HITDAM;
      inven_carry (&inven_init);
    }

  /* wierd place for it, but why not? */
  for (i = 0; i < MAX_SPELLS; i++)
    {
      spell_status[i].learned = 0;
      spell_status[i].worked = 0;
      spell_status[i].forgotten = 0;
      spell_status[i].unused = 0;
    }

  for (i = 0; i < MAX_SPELLS; i++)
    spell_order[i] = MAX_SPELLS;
}


/* Initializes M_LEVEL array for use with PLACE_MONSTER	-RAK-	*/
static void
init_m_level ()
{
  register int i, k;

  for (i = 0; i <= MAX_MONS_LEVEL; i++)
    m_level[i] = 0;

  k = MAX_CREATURES - WIN_MON_TOT;
  for (i = 0; i < k; i++)
    m_level[c_list[i].level]++;

  for (i = 1; i <= MAX_MONS_LEVEL; i++)
    m_level[i] += m_level[i - 1];
}


/* Initializes T_LEVEL array for use with PLACE_OBJECT	-RAK-	*/
static void
init_t_level ()
{
  register int i, l;
  int tmp[MAX_OBJ_LEVEL + 1];

  for (i = 0; i <= MAX_OBJ_LEVEL; i++)
    t_level[i] = 0;
  for (i = 0; i < MAX_DUNGEON_OBJ; i++)
    t_level[object_list[i].level]++;
  for (i = 1; i <= MAX_OBJ_LEVEL; i++)
    t_level[i] += t_level[i - 1];

  /* now produce an array with object indexes sorted by level, by using
     the info in t_level, this is an O(n) sort! */
  /* this is not a stable sort, but that does not matter */
  for (i = 0; i <= MAX_OBJ_LEVEL; i++)
    tmp[i] = 1;
  for (i = 0; i < MAX_DUNGEON_OBJ; i++)
    {
      l = object_list[i].level;
      sorted_objects[t_level[l] - tmp[l]] = i;
      tmp[l]++;
    }
}


#if (COST_ADJ != 100)
/* Adjust prices of objects				-RAK-	*/
static void
price_adjust ()
{
  register int i;

  /* round half-way cases up */
  for (i = 0; i < MAX_OBJECTS; i++)
    object_list[i].cost = ((object_list[i].cost * COST_ADJ) + 50) / 100;
}
#endif
