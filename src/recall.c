/* src/recall.c: print out monster memory info			-CJS-

   Copyright (c) 1989-94 James E. Wilson, Christopher J. Stuart

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

#include <string.h>
static void roff ();

static char *desc_atype[] = {
  "do something undefined",
  "attack",
  "weaken",
  "confuse",
  "terrify",
  "shoot flames",
  "shoot acid",
  "freeze",
  "shoot lightning",
  "corrode",
  "blind",
  "paralyse",
  "steal money",
  "steal things",
  "poison",
  "reduce dexterity",
  "reduce constitution",
  "drain intelligence",
  "drain wisdom",
  "lower experience",
  "call for help",
  "disenchant",
  "eat your food",
  "absorb light",
  "absorb charges"
};
static char *desc_amethod[] = {
  "make an undefined advance",
  "hit",
  "bite",
  "claw",
  "sting",
  "touch",
  "kick",
  "gaze",
  "breathe",
  "spit",
  "wail",
  "embrace",
  "crawl on you",
  "release spores",
  "beg",
  "slime you",
  "crush",
  "trample",
  "drool",
  "insult"
};
static char *desc_howmuch[] = {
  " not at all",
  " a bit",
  "",
  " quite",
  " very",
  " most",
  " highly",
  " extremely"
};

static char *desc_move[] = {
  "move invisibly",
  "open doors",
  "pass through walls",
  "kill weaker creatures",
  "pick up objects",
  "breed explosively"
};
static char *desc_spell[] = {
  "teleport short distances",
  "teleport long distances",
  "teleport its prey",
  "cause light wounds",
  "cause serious wounds",
  "paralyse its prey",
  "induce blindness",
  "confuse",
  "terrify",
  "summon a monster",
  "summon the undead",
  "slow its prey",
  "drain mana",
  "unknown 1",
  "unknown 2"
};
static char *desc_breath[] = {
  "lightning",
  "poison gases",
  "acid",
  "frost",
  "fire"
};
static char *desc_weakness[] = {
  "frost",
  "fire",
  "poison",
  "acid",
  "bright light",
  "rock remover"
};

static vtype roffbuf;		/* Line buffer. */
static char *roffp;		/* Pointer into line buffer. */
static int roffpline;		/* Place to print line now being loaded. */

#define plural(c, ss, sp)	((c) == 1 ? ss : sp)

/* Number of kills needed for information. */

/* the higher the level of the monster, the fewer the kills you need */
#define knowarmor(l,d)		((d) > 304 / (4 + (l)))
/* the higher the level of the monster, the fewer the attacks you need,
   the more damage an attack does, the more attacks you need */
#define knowdamage(l,a,d)	((4 + (l))*(a) > 80 * (d))

/* Do we know anything about this monster? */
int
bool_roff_recall (mon_num)
     int mon_num;
{
  register recall_type *mp;
  register int i;

  if (wizard)
    return TRUE;
  mp = &c_recall[mon_num];
  if (mp->r_cmove || mp->r_cdefense || mp->r_kills || mp->r_spells
      || mp->r_deaths)
    return TRUE;
  for (i = 0; i < 4; i++)
    if (mp->r_attacks[i])
      return TRUE;
  return FALSE;
}

/* Print out what we have discovered about this monster. */
int
roff_recall (mon_num)
     int mon_num;
{
  char *p, *q;
  int8u *pu;
  vtype temp;
  register recall_type *mp;
  register creature_type *cp;
  register int i, k;
  register int32u j;
  int32 templong;
  int mspeed;
  int32u rcmove, rspells;
  int16u rcdefense;
  recall_type save_mem;
  memset (&save_mem, 0, sizeof (save_mem));

  mp = &c_recall[mon_num];
  cp = &c_list[mon_num];
  if (wizard)
    {
      save_mem = *mp;
      mp->r_kills = MAX_SHORT;
      mp->r_wake = mp->r_ignore = MAX_UCHAR;
      j = (((cp->cmove & CM_4D2_OBJ) != 0) * 8) +
	(((cp->cmove & CM_2D2_OBJ) != 0) * 4) +
	(((cp->cmove & CM_1D2_OBJ) != 0) * 2) +
	((cp->cmove & CM_90_RANDOM) != 0) + ((cp->cmove & CM_60_RANDOM) != 0);
      mp->r_cmove = (cp->cmove & ~CM_TREASURE) | (j << CM_TR_SHIFT);
      mp->r_cdefense = cp->cdefense;
      if (cp->spells & CS_FREQ)
	mp->r_spells = cp->spells | CS_FREQ;
      else
	mp->r_spells = cp->spells;
      j = 0;
      pu = cp->damage;
      while (*pu != 0 && j < 4)
	{
	  mp->r_attacks[(int) j] = MAX_UCHAR;
	  j++;
	  pu++;
	}
      /* A little hack to enable the display of info for Quylthulgs.  */
      if (mp->r_cmove & CM_ONLY_MAGIC)
	mp->r_attacks[0] = MAX_UCHAR;
    }
  roffpline = 0;
  roffp = roffbuf;
  rspells = mp->r_spells & cp->spells & ~CS_FREQ;
  /* the CM_WIN property is always known, set it if a win monster */
  rcmove = mp->r_cmove | (CM_WIN & cp->cmove);
  rcdefense = mp->r_cdefense & cp->cdefense;
  snprintf (temp, sizeof (temp), "The %s:\n", cp->name);
  roff (temp);
  /* Conflict history. */
  if (mp->r_deaths)
    {
      snprintf (temp, sizeof (temp),
		"%d of the contributors to your monster memory %s",
		mp->r_deaths, plural (mp->r_deaths, "has", "have"));
      roff (temp);
      roff (" been killed by this creature, and ");
      if (mp->r_kills == 0)
	roff ("it is not ever known to have been defeated.");
      else
	{
	  snprintf (temp, sizeof (temp),
		    "at least %d of the beasts %s been exterminated.",
		    mp->r_kills, plural (mp->r_kills, "has", "have"));
	  roff (temp);
	}
    }
  else if (mp->r_kills)
    {
      snprintf (temp, sizeof (temp),
		"At least %d of these creatures %s",
		mp->r_kills, plural (mp->r_kills, "has", "have"));
      roff (temp);
      roff (" been killed by contributors to your monster memory.");
    }
  else
    roff ("No known battles to the death are recalled.");
  /* Immediately obvious. */
  k = FALSE;
  if (cp->level == 0)
    {
      roff (" It lives in the town");
      k = TRUE;
    }
  else if (mp->r_kills)
    {
      /* The Balrog is a level 100 monster, but appears at 50 feet.  */
      i = cp->level;
      if (i > WIN_MON_APPEAR)
	i = WIN_MON_APPEAR;
      snprintf (temp, sizeof (temp),
		" It is normally found at depths of %d feet", i * 50);
      roff (temp);
      k = TRUE;
    }
  /* the c_list speed value is 10 greater, so that it can be a int8u */
  mspeed = cp->speed - 10;
  if (rcmove & CM_ALL_MV_FLAGS)
    {
      if (k)
	roff (", and");
      else
	{
	  roff (" It");
	  k = TRUE;
	}
      roff (" moves");
      if (rcmove & CM_RANDOM_MOVE)
	{
	  roff (desc_howmuch[(int) ((rcmove & CM_RANDOM_MOVE) >> 3)]);
	  roff (" erratically");
	}
      if (mspeed == 1)
	roff (" at normal speed");
      else
	{
	  if (rcmove & CM_RANDOM_MOVE)
	    roff (", and");
	  if (mspeed <= 0)
	    {
	      if (mspeed == -1)
		roff (" very");
	      else if (mspeed < -1)
		roff (" incredibly");
	      roff (" slowly");
	    }
	  else
	    {
	      if (mspeed == 3)
		roff (" very");
	      else if (mspeed > 3)
		roff (" unbelievably");
	      roff (" quickly");
	    }
	}
    }
  if (rcmove & CM_ATTACK_ONLY)
    {
      if (k)
	roff (", but");
      else
	{
	  roff (" It");
	  k = TRUE;
	}
      roff (" does not deign to chase intruders");
    }
  if (rcmove & CM_ONLY_MAGIC)
    {
      if (k)
	roff (", but");
      else
	{
	  roff (" It");
	  k = TRUE;
	}
      roff (" always moves and attacks by using magic");
    }
  if (k)
    roff (".");
  /* Kill it once to know experience, and quality (evil, undead, monsterous).
     The quality of being a dragon is obvious. */
  if (mp->r_kills)
    {
      roff (" A kill of this");
      if (cp->cdefense & CD_ANIMAL)
	roff (" natural");
      if (cp->cdefense & CD_EVIL)
	roff (" evil");
      if (cp->cdefense & CD_UNDEAD)
	roff (" undead");

      /* calculate the integer exp part, can be larger than 64K when first
         level character looks at Balrog info, so must store in long */
      templong = (long) cp->mexp * cp->level / py.misc.lev;
      /* calculate the fractional exp part scaled by 100,
         must use long arithmetic to avoid overflow */
      j = (((long) cp->mexp * cp->level % py.misc.lev) * (long) 1000 /
	   py.misc.lev + 5) / 10;

      snprintf (temp, sizeof (temp),
		" creature is worth %ld.%02ld point%s", templong,
		j, (templong == 1 && j == 0 ? "" : "s"));
      roff (temp);

      if (py.misc.lev / 10 == 1)
	p = "th";
      else
	{
	  i = py.misc.lev % 10;
	  if (i == 1)
	    p = "st";
	  else if (i == 2)
	    p = "nd";
	  else if (i == 3)
	    p = "rd";
	  else
	    p = "th";
	}
      i = py.misc.lev;
      if (i == 8 || i == 11 || i == 18)
	q = "n";
      else
	q = "";
      snprintf (temp, sizeof (temp),
		" for a%s %d%s level character.", q, i, p);
      roff (temp);
    }
  /* Spells known, if have been used against us.
     Breath weapons or resistance might be known only because we cast spells 
     at it. */
  k = TRUE;
  j = rspells;
  for (i = 0; j & CS_BREATHE; i++)
    {
      if (j & (CS_BR_LIGHT << i))
	{
	  j &= ~(CS_BR_LIGHT << i);
	  if (k)
	    {
	      if (mp->r_spells & CS_FREQ)
		roff (" It can breathe ");
	      else
		roff (" It is resistant to ");
	      k = FALSE;
	    }
	  else if (j & CS_BREATHE)
	    roff (", ");
	  else
	    roff (" and ");
	  roff (desc_breath[i]);
	}
    }
  k = TRUE;
  for (i = 0; j & CS_SPELLS; i++)
    {
      if (j & (CS_TEL_SHORT << i))
	{
	  j &= ~(CS_TEL_SHORT << i);
	  if (k)
	    {
	      if (rspells & CS_BREATHE)
		roff (", and is also");
	      else
		roff (" It is");
	      roff (" magical, casting spells which ");
	      k = FALSE;
	    }
	  else if (j & CS_SPELLS)
	    roff (", ");
	  else
	    roff (" or ");
	  roff (desc_spell[i]);
	}
    }
  if (rspells & (CS_BREATHE | CS_SPELLS))
    {
      if ((mp->r_spells & CS_FREQ) > 5)
	{			/* Could offset by level */
	  snprintf (temp, sizeof (temp), "; 1 time in %ld",
		    cp->spells & CS_FREQ);
	  roff (temp);
	}
      roff (".");
    }
  /* Do we know how hard they are to kill? Armor class, hit die. */
  if (knowarmor (cp->level, mp->r_kills))
    {
      snprintf (temp, sizeof (temp), " It has an armor rating of %d", cp->ac);
      roff (temp);
      snprintf (temp, sizeof (temp),
		" and a%s life rating of %dd%d.",
		((cp->cdefense & CD_MAX_HP) ? " maximized" : ""),
		cp->hd[0], cp->hd[1]);
      roff (temp);
    }
  /* Do we know how clever they are? Special abilities. */
  k = TRUE;
  j = rcmove;
  for (i = 0; j & CM_SPECIAL; i++)
    {
      if (j & (CM_INVISIBLE << i))
	{
	  j &= ~(CM_INVISIBLE << i);
	  if (k)
	    {
	      roff (" It can ");
	      k = FALSE;
	    }
	  else if (j & CM_SPECIAL)
	    roff (", ");
	  else
	    roff (" and ");
	  roff (desc_move[i]);
	}
    }
  if (!k)
    roff (".");
  /* Do we know its special weaknesses? Most cdefense flags. */
  k = TRUE;
  j = rcdefense;
  for (i = 0; j & CD_WEAKNESS; i++)
    {
      if (j & (CD_FROST << i))
	{
	  j &= ~(CD_FROST << i);
	  if (k)
	    {
	      roff (" It is susceptible to ");
	      k = FALSE;
	    }
	  else if (j & CD_WEAKNESS)
	    roff (", ");
	  else
	    roff (" and ");
	  roff (desc_weakness[i]);
	}
    }
  if (!k)
    roff (".");
  if (rcdefense & CD_INFRA)
    roff (" It is warm blooded");
  if (rcdefense & CD_NO_SLEEP)
    {
      if (rcdefense & CD_INFRA)
	roff (", and");
      else
	roff (" It");
      roff (" cannot be charmed or slept");
    }
  if (rcdefense & (CD_NO_SLEEP | CD_INFRA))
    roff (".");
  /* Do we know how aware it is? */
  if (((mp->r_wake * mp->r_wake) > cp->sleep) || mp->r_ignore == MAX_UCHAR ||
      (cp->sleep == 0 && mp->r_kills >= 10))
    {
      roff (" It ");
      if (cp->sleep > 200)
	roff ("prefers to ignore");
      else if (cp->sleep > 95)
	roff ("pays very little attention to");
      else if (cp->sleep > 75)
	roff ("pays little attention to");
      else if (cp->sleep > 45)
	roff ("tends to overlook");
      else if (cp->sleep > 25)
	roff ("takes quite a while to see");
      else if (cp->sleep > 10)
	roff ("takes a while to see");
      else if (cp->sleep > 5)
	roff ("is fairly observant of");
      else if (cp->sleep > 3)
	roff ("is observant of");
      else if (cp->sleep > 1)
	roff ("is very observant of");
      else if (cp->sleep != 0)
	roff ("is vigilant for");
      else
	roff ("is ever vigilant for");
      snprintf (temp, sizeof (temp),
		" intruders, which it may notice from %d feet.",
		10 * cp->aaf);
      roff (temp);
    }
  /* Do we know what it might carry? */
  if (rcmove & (CM_CARRY_OBJ | CM_CARRY_GOLD))
    {
      roff (" It may");
      j = (rcmove & CM_TREASURE) >> CM_TR_SHIFT;
      if (j == 1)
	{
	  if ((cp->cmove & CM_TREASURE) == CM_60_RANDOM)
	    roff (" sometimes");
	  else
	    roff (" often");
	}
      else if ((j == 2) && ((cp->cmove & CM_TREASURE) ==
			    (CM_60_RANDOM | CM_90_RANDOM)))
	roff (" often");
      roff (" carry");
      if (rcmove & CM_SMALL_OBJ)
	p = " small objects";
      else
	p = " objects";
      if (j == 1)
	{
	  if (rcmove & CM_SMALL_OBJ)
	    p = " a small object";
	  else
	    p = " an object";
	}
      else if (j == 2)
	roff (" one or two");
      else
	{
	  snprintf (temp, sizeof (temp), " up to %ld", j);
	  roff (temp);
	}
      if (rcmove & CM_CARRY_OBJ)
	{
	  roff (p);
	  if (rcmove & CM_CARRY_GOLD)
	    {
	      roff (" or treasure");
	      if (j > 1)
		roff ("s");
	    }
	  roff (".");
	}
      else if (j != 1)
	roff (" treasures.");
      else
	roff (" treasure.");
    }

  /* We know about attacks it has used on us, and maybe the damage they do. */
  /* k is the total number of known attacks, used for punctuation */
  k = 0;
  for (j = 0; j < 4; j++)
    if (mp->r_attacks[(int) j])
      k++;
  pu = cp->damage;
  /* j counts the attacks as printed, used for punctuation */
  j = 0;
  for (i = 0; *pu != 0 && i < 4; pu++, i++)
    {
      int att_type, att_how, d1, d2;

      /* don't print out unknown attacks */
      if (!mp->r_attacks[i])
	continue;

      att_type = monster_attacks[*pu].attack_type;
      att_how = monster_attacks[*pu].attack_desc;
      d1 = monster_attacks[*pu].attack_dice;
      d2 = monster_attacks[*pu].attack_sides;

      j++;
      if (j == 1)
	roff (" It can ");
      else if (j == k)
	roff (", and ");
      else
	roff (", ");

      if (att_how > 19)
	att_how = 0;
      roff (desc_amethod[att_how]);
      if (att_type != 1 || (d1 > 0 && d2 > 0))
	{
	  roff (" to ");
	  if (att_type > 24)
	    att_type = 0;
	  roff (desc_atype[att_type]);
	  if (d1 && d2)
	    {
	      if (knowdamage (cp->level, mp->r_attacks[i], d1 * d2))
		{
		  if (att_type == 19)	/* Loss of experience */
		    roff (" by");
		  else
		    roff (" with damage");
		  snprintf (temp, sizeof (temp), " %dd%d", d1, d2);
		  roff (temp);
		}
	    }
	}
    }
  if (j)
    roff (".");
  else if (k > 0 && mp->r_attacks[0] >= 10)
    roff (" It has no physical attacks.");
  else
    roff (" Nothing is known about its attack.");
  /* Always know the win creature. */
  if (cp->cmove & CM_WIN)
    roff (" Killing one of these wins the game!");
  roff ("\n");
  prt ("--pause--", roffpline, 0);
  if (wizard)
    *mp = save_mem;
  return inkey ();
}

/* Print out strings, filling up lines as we go. */
static void
roff (p)
     register char *p;
{
  register char *q, *r;

  while (*p)
    {
      *roffp = *p;
      if (*p == '\n' || roffp >= roffbuf + sizeof (roffbuf) - 1)
	{
	  q = roffp;
	  if (*p != '\n')
	    while (*q != ' ')
	      q--;
	  *q = 0;
	  prt (roffbuf, roffpline, 0);
	  roffpline++;
	  r = roffbuf;
	  while (q < roffp)
	    {
	      q++;
	      *r = *q;
	      r++;
	    }
	  roffp = r;
	}
      else
	roffp++;
      p++;
    }
}
