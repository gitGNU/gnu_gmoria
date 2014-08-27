/* mcheck.c: consistency checker for the Moria creature definition compiler

   Copyright (C) 2005, 2010 Ben Asselstine
   Written by Ben Asselstine

   mc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   mc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with mc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "creature.h"
#include "xvasprintf.h"
#include "c-strcasestr.h"

static int 
move (char *flags)
{
  return lookup_flag ("move", flags);
}

static int
special (char *flags)
{
  return lookup_flag ("special", flags);
}

static int
treasure (char *flags)
{
  return lookup_flag ("treasure", flags);
}

static int
attacktype (char *flags)
{
  if (strchr (flags, ','))
    return -1;
  return lookup_flag ("attacktype", flags);
}

static int
attackdesc (char *flags)
{
  if (strchr (flags, ','))
    return -1;
  return lookup_flag ("attackdesc", flags);
}

static int
breath (char *flags)
{
  return lookup_flag ("breath", flags);
}

static int
spell (char *flags)
{
  return lookup_flag ("spell", flags);
}

static void
CErrMsg (creature_type *c, char *s)
{
  char *msg = xasprintf ("Consistency problem with '%s': %s", c->name, s);
  if (msg)
    {
      ErrMsg (msg);
      free (msg);
    }
  return;
}

static int
resist (char *flags)
{
  return lookup_flag ("resist", flags);
}

static int
defense (char *flags)
{
  return lookup_flag ("defense", flags);
}
/*
dragon: d, D
	never invisible, can't open doors, never phase, never eats others,
	never pick up objects, never multiply, carry objects/gold, breath
	weapons, cast spells, hurt by slay dragon, hurt by slay evil, can be
	slept, seen by infravision, young/mature 20% random movement
*/
static void
ConsistencyCheckDragon (creature_type *c)
{
  if ((c->cmove & special ("invisible")))
    CErrMsg (c, "dragons can't be invisible, yet this one is.");
  if ((c->cmove & special ("open_door")))
    CErrMsg (c, "dragons can't open doors, yet this one does.");
  if ((c->cmove & special ("phase")))
    CErrMsg (c, "dragons can't phase through rock, yet this one does.");
  if ((c->cmove & special ("eats_other")))
    CErrMsg (c, "dragons don't eat others, yet this one does.");
  if ((c->cmove & special ("picks_up")))
    CErrMsg (c, "dragons can't pick up things, yet this one does.");
  if ((c->cmove & special ("multiply")))
    CErrMsg (c, "dragons don't multiply, yet this one does.");
  if ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj")) == 0)
    CErrMsg (c, "dragons have treasure, yet this one doesn't.");
  if (((c->spells & (breath ("fire, acid, frost, light, gas"))) == 0) && 
      (c->spells & CS_FREQ))
    CErrMsg (c, "dragons can breathe, yet this one doesn't.");
  if ((c->spells & CS_SPELLS) == 0)
    CErrMsg (c, "dragons cast spells, yet this one doesn't.");
  if ((c->cdefense & (defense ("dragon"))) == 0)
    CErrMsg (c, "dragons can be slain easier with SD, yet this one can't.");
  if ((c->cdefense & (defense ("evil"))) == 0)
    CErrMsg (c, "dragons can be slain easier with SE, yet this one can't.");
  if ((c->cdefense & (defense ("no_sleep"))))
    CErrMsg (c, "dragons can be slept, yet this one can't be.");
  if (((c->cdefense & (defense ("infra"))) == 0) && 
      ((c->spells & (resist ("frost"))) == 0) && 
      ((c->cdefense & (defense ("fire"))) == 0))
    CErrMsg (c, "warm dragons can be seen with infravision, "
	     "yet this one can't.");
  if (((strcasestr (c->name, "Mature")) ||
      (strcasestr (c->name, "Young"))) &&
      (c->cmove & move ("random_20")) == 0)
    {
      CErrMsg (c, "Young and Mature dragons move randomly, "
	       "yet this one doesn't.");
    }
  return;
}

/*
humanoid: h, H, k, n, o, p, P, T, U, y, Y
	can open doors, never eats others, all that carry treasure pick up obj,
	never multiply, h/U/Y and some people don't carry treasure,
	some cast spells, no breath weapons, all except some humans evil,
	hurt by slay evil, can be slept, seen by infravision, never random
	movement (except 0 level humans which are all 20% random)
	**harpies/nagas can't open doors, and move randomly
	**invisible humanoids can't be seen with infravision
	**frost-resistant humanoids can't be seen with infravision
	**the carry treasure must pick-up object rule is not applied

*/
static void
ConsistencyCheckHumanoid (creature_type *c)
{
  if (((c->cmove & special ("open_door")) == 0) && 
      (strchr ("hn", c->cchar) == NULL))
    CErrMsg (c, "humanoids (except for nagas and harpies) can open doors, "
	    "yet this one can't.");
  if ((c->cmove & special ("eats_other")))
    CErrMsg (c, "humanoids don't eat others, yet this one does.");
/*
  if (((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj"))) &&
      ((c->cmove & special ("picks_up")) == 0))
    CErrMsg (c, "humanoids that carry treasure also pick up objects, "
	    "yet this one doesn't.");
*/
  if ((c->cmove & special ("multiply")))
    CErrMsg (c, "humanoids don't multiply, yet this one does (har, har).");
  if (((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj"))) &&
      ((strchr("hUY", c->cchar))))
    CErrMsg (c, "harpies, umber hulks and yetis do not carry treasure, "
	    "yet this one does.");
  if (((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj"))) &&
      (c->cchar == 'p') && (c->level == 0) && (c->hd[0] == 1))
    CErrMsg (c, "lesser humanoids on the town level do not carry treasure, "
	    "yet this one does.");
  if (((c->spells & CS_SPELLS)) && (c->spells & CS_FREQ) &&
      ((strstr (c->name, "Priest") == 0) && (strstr (c->name, "Mage") == 0) &&
       (strstr (c->name, "Master") == 0) && (strstr (c->name, "Magic") == 0) &&
       (strstr (c->name, "Knight") == 0) && (strstr (c->name, "Nasty") == 0) && 
       (strstr (c->name, "Evil") == 0) && (strstr (c->name, "Sorcerer") == 0) &&
       (strstr (c->name, "Shaman") == 0) && 
       (strstr (c->name, "Necromancer") == 0)))
    CErrMsg (c, "only certain magic-related humanoids may cast spells, "
	     "and this one doesn't seem to be magic-related "
	     "yet it casts spells.");
  if ((c->spells & breath ("acid, fire, frost, gas, light")) && 
      (c->spells & CS_FREQ))
    CErrMsg (c, "humanoids don't breathe like dragons, yet this one does.");
  if ((c->cdefense & defense ("evil") == 0) &&
      ((strstr (c->name, "Blubbering") == 0) &&
       (strstr (c->name, "Mangy") == 0) &&
       (strstr (c->name, "Pitiful") == 0) &&
       (strstr (c->name, "Happy") == 0) &&
       (strstr (c->name, "Veteran") == 0) &&
       (strstr (c->name, "Warrior") == 0) &&
       (strstr (c->name, "Swordsman") == 0) &&
       (strstr (c->name, "Berzerker") == 0) &&
       (strstr (c->name, "Priest") == 0) &&
       (strstr (c->name, "Necromancer") == 0) &&
       (strstr (c->name, "Sorcerer") == 0) &&
       (strstr (c->name, "Mage") == 0) &&
       (strstr (c->name, "Magic") == 0)))
    CErrMsg (c, "only certain innocent humanoids are not evil, and this "
	    "one seems to be both innocent and evil.");
  if ((c->cdefense & (defense ("no_sleep"))) && (c->level < 50))
    CErrMsg (c, "humanoids can be slept (except for the most powerful), "
	     "yet this one can't be, and it's not so powerful.");
  if (((c->cdefense & (defense ("infra"))) == 0) && 
      ((c->cmove & special ("invisible")) == 0) &&
      ((c->spells & resist ("frost")) == 0))
    CErrMsg (c, "humanoids can be seen with infravision "
	    "(except humanoids who are invisible or frost-resistant), "
	    "yet this one can't.");
  if ((c->level == 0) && ((c->cmove & move ("random_20")) == 0) && (c->ac == 1))
    CErrMsg (c, "lesser humanoids that live in the town move randomly, "
	    "yet this one doesn't.");
  if ((c->level > 0) && (strchr ("hn", c->cchar) == NULL) && 
      ((c->cmove & move ("random_20, random_40, random_75"))))
    CErrMsg (c, "humanoids that live in the dungeon don't move randomly, "
	    "(except for harpies and nagas) yet this one does.");

  return;
}

/*
undead: G, L, M, s, V, W, Z
	only G invisible, all except s/Z open doors, only G/W phase,
	never eats others, only G picks up objects, never multiply,
	only s/Z do not carry objects/gold, some cast spells,
	no breath weapons, all evil except s/Z, hurt by slay evil,
	hurt by slay undead, can't be slept, never seen by infravision,
	G very random movement, W 20% random movement, others never random
	movement
	**Z isn't a kind of creature, but z is
	**Liches carry treasure
	**nether-creatures are also invisible
	**undead creatures who phase don't open doors
	**Spirit troll is a ghost and doesn't move randomly
	**the treasure rule isn't applied
*/
static void
ConsistencyCheckUndead (creature_type *c)
{
  if ((c->cchar != 'G') && (strstr (c->name, "Nether") == NULL) && 
      ((c->cmove & special ("invisible"))))
    CErrMsg (c, "undead creatures are not invisible "
	    "(except ghosts, and nether-creatures), "
	    "yet this one isn't a ghost nor a nether-creature and is invisble.");
  if ((strchr ("sz", c->cchar) == NULL) && 
      ((c->cmove & special ("phase"))==0) &&
      ((c->cmove & special ("open_door")) == 0))
    CErrMsg (c, "undead creatures open doors "
	    "(except for skeletons, zombies and those who phase through rock), "
	    "yet this creature doesn't, and isn't a skeleton, zombie, "
	    "nor is it capable of phasing.");
  if ((c->cchar != 'G') && ((c->cmove & special ("phase"))) && 
      (strstr (c->name, "Nether") == NULL))
    CErrMsg (c, "undead creatures are do not phase "
	    "(except for ghosts and nether-creatures), "
	    "yet this one is neither a ghost nor a nether-creature, "
	    "and can phase through rock.");
  if ((c->cmove & special ("eats_other")))
    CErrMsg (c, "undead don't eat others, yet this one does.");
  if ((c->cchar != 'G') && ((c->cmove & special ("picks_up"))))
    CErrMsg (c, "undead don't pick up objects (except ghosts), "
	    "yet this one isn't a ghost but does.");
  if ((c->cmove & special ("multiply")))
    CErrMsg (c, "undead don't multiply, yet this one does.");
/*
  if ((strchr ("sLz", c->cchar) == NULL) && 
      ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj"))))
    CErrMsg (c, "undead don't carry treasure "
	    "(except for skeletons, zombies, and liches), "
	    "yet this creature carries treasure.");
*/
  if ((c->spells & CS_SPELLS) && (c->spells & CS_FREQ) && 
      (strchr ("Msz", c->cchar)))
    CErrMsg (c, "undead creatures cast spells "
	    "(except for mummies, skeletons and zombies), "
	    "yet this creature can cast spells and "
	    "is a mummy, skeleton or zombie.");

  if ((c->spells & breath ("acid, fire, frost, gas, light")) && 
      (c->spells & CS_FREQ))
    CErrMsg (c, "undead creatures don't breathe like dragons, yet this one does.");
  if (((c->cdefense & (defense ("evil"))) == 0) && 
      (strchr ("sz", c->cchar) == NULL ))
    CErrMsg (c, "undead creatures are evil (except for skeletons and zombies), "
	    "yet this one isn't evil, and is not a skeleton or zombie.");
  if ((c->cdefense & (defense ("undead"))) == 0)
    CErrMsg (c, "undead creatures are hurt by slay-undead weapons, "
	    "yet this one isn't.");
  if ((c->cdefense & (defense ("no_sleep"))) == 0)
    CErrMsg (c, "undead creatures cannot be charmed or slept, "
	    "yet this one can.");
  if ((c->cdefense & defense ("infra")))
    CErrMsg (c, "undead creatures cannot be seen by infravision, "
	    "yet this one can.");
  if ((c->cchar == 'G') && (strcasestr (c->name, "Spirit Troll") == 0) &&
      (c->cmove & move ("random_20, random_40, random_75")) == 0)
    CErrMsg (c, "ghosts move randomly, except for spirit-trolls,"
	     "yet this one doesn't, and isn't a spirit-troll.");
  if ((c->cchar == 'W') && (c->cmove & move ("random_20")) == 0)
    CErrMsg (c, "wights move 20% randomly, yet this one doesn't.");
  if ((strchr ("GW", c->cchar) == NULL) && 
      (c->cmove & move ("random_20, random_40, random_75")))
    CErrMsg (c, "undead creatures do not move randomly "
	     "except for ghosts and wights, "
	     "yet this one moves randomly and is not a ghost or wight.");
  return;
}

/*
animal: a, A, b c, f, F, j, K, l, r, R, S, t, w
	only one of a/c invisible, can't open doors, never phase,
	only A eats others, never pick up objects, only a/b/F/l/r/w multiply,
	never carry objects or gold, never cast spells, some breath weapons,
	not evil, hurt by slay animal, can be slept, mammals seen by
	infravision, most have 20% random movement
	**everyone but ants and centipedes move randomly
*/
static void
ConsistencyCheckAnimal (creature_type *c)
{
  if ((strstr (c->name, "Clear") == NULL) && 
      ((c->cmove & special ("invisible"))))
    CErrMsg (c, "only \"Clear\" animals can be invisible.");
  if ((c->cmove & special ("open_door")))
    CErrMsg (c, "animals cannot open doors.");
  if ((c->cmove & special ("phase")))
    CErrMsg (c, "animals cannot phase through rock.");
  if ((c->cchar != 'A') && ((c->cmove & special ("eats_other"))))
    CErrMsg (c, "animals cannot eat others (except for ants).");
  if ((c->cmove & special ("picks_up")))
    CErrMsg (c, "animals cannot pick up objects.");
  if ((strchr ("abFlrw", c->cchar) == NULL) && 
      ((c->cmove & special ("multiply"))))
    CErrMsg (c, "animals cannot mulitply, "
	    "except for ants, bats, flies, louses, rodents and worms.");
      
  if ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj, "
			    "carry_small_obj, carry_obj, carry_gold")))
    CErrMsg (c, "animals cannot carry gold or objects.");
  if ((c->spells & CS_SPELLS) && (c->spells & CS_FREQ))
    CErrMsg (c, "animals cannot cast spells.");
  if ((c->spells & CS_BREATHE) && (c->spells & CS_FREQ) &&
      (strchr ("Fb", c->cchar) == NULL))
    CErrMsg (c, "animals cannot breathe attacks, "
	    "except for certain bats and flies.");
  if ((c->cdefense & defense ("evil")))
    CErrMsg (c, "animals are not evil.");
  if ((c->cdefense & defense ("animal")) == 0)
    CErrMsg (c, "animals are susceptible to slay-animal weapons, "
	    "yet this creature is not.");
  if ((c->cdefense & (defense ("no_sleep"))))
    CErrMsg (c, "animals can be charmed or slept, yet this animal cannot.");
  if ((strchr ("bjr", c->cchar) == NULL) && ((c->cmove & defense ("infra"))))
    CErrMsg (c, "only mammals may be seen with infravision.");
  if ((strchr ("ac", c->cchar) == NULL) && 
      ((c->cmove & move ("random_20, random_40, random_75")) == 0))
    CErrMsg (c, "animals move randomly "
	    "(except for ants and centipedes who sometimes move randomly), "
	    "and this animal doesn't move randomly "
	    "and is not an ant or a centipede.");
  return;
}

/*
demons: B, p(Evil Iggy), q
	always invisible, only B can phase, only B eats others, always pick up
	objects, never multiply, carry objects/gold, cast spells, only B
	breath weapon, all evil, hurt by slay evil, can not be slept, not seen
	by infravision, never random movement
	**quasits don't pick stuff up
	**quasits move randomly
*/
static void
ConsistencyCheckDemon (creature_type *c)
{
  if ((c->cmove & special ("invisible")) == 0)
    CErrMsg (c, "demons are invisible, and this one isn't.");
  if ((c->cmove & special ("phase")) && (c->cchar != 'B'))
    CErrMsg (c, "demons cannot phase (except for the Balrog), yet this one can "
	    "and it isn't the Balrog.");
  if ((c->cchar != 'B') && (c->cmove & special ("eats_other")))
    CErrMsg (c, "demons cannot eat others "
	    "(except for the Balrog), yet this one can "
	    "and it isn't the Balrog.");
  if (((c->cmove & special ("picks_up")) == 0) && (c->cchar != 'q'))
    CErrMsg (c, "demons always pick objects up (except for quasits), "
	    "yet this one does not, and is not a quasit.");
  if ((c->cmove & special ("multiply")))
    CErrMsg (c, "demons never multiply, "
	     "yet this one does and that's so badass.");
  if ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj, "
			    "carry_small_obj, carry_obj, carry_gold")) == 0)
    CErrMsg (c, "demons always carry gold or objects, and this one doesn't.");
  if (((c->spells & CS_SPELLS) == 0) || ((c->spells & CS_FREQ) == 0))
    CErrMsg (c, "demons cast spells, and this one doesn't.");
  if ((c->spells & CS_BREATHE) && (c->spells & CS_FREQ) && (c->cchar != 'B'))
    CErrMsg (c, "demons cannot breathe attacks, except for the Balrog, "
	    "yet this creature breathes attacks and is not the Balrog.");
  if ((c->cdefense & defense ("evil")) == 0)
    CErrMsg (c, "demons are always evil, yet this one isn't.");
  if ((c->cdefense & defense ("no_sleep")) == 0)
    CErrMsg (c, "demons can't be slept or charmed, yet this one can be.");
  if ((c->cdefense & defense ("infra")))
    CErrMsg (c, "demons can't be seen by infravision, yet this one can be.");
  if ((c->cmove & move ("random_20, random_40, random_75")) && 
      (c->cchar != 'q'))
    CErrMsg (c, "demons do not move randomly (except for quasits), "
	    "yet this one does, and is not a quasit.");
  return;
}

/*
quylthulg: Q
	in a class by itself, almost exactly the same as demon except not
	evil and does not carry objects/gold, should be in class other
	**always moves via magic.
*/
static void
ConsistencyCheckQuylthulg (creature_type *c)
{
  if ((c->cmove & special ("invisible")) == 0)
    CErrMsg (c, "quylthulgs are invisible, and this one isn't.");
  if (c->cmove & special ("phase"))
    CErrMsg (c, "quylthulgs cannot phase, yet this one can.");
  if (c->cmove & special ("eats_other"))
    CErrMsg (c, "quylthulgs do not eat others, yet this one can.");
  if ((c->cmove & special ("picks_up")))
    CErrMsg (c, "quylthulgs do not pick objects up, yet this one does.");
  if ((c->cmove & special ("multiply")))
    CErrMsg (c, "quylthulgs never multiply, yet this one does.");
  if ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj, "
			    "carry_small_obj, carry_obj, carry_gold")))
    CErrMsg (c, "quylthulgs never carry gold or objects, and this one does.");
  if (((c->spells & CS_SPELLS) == 0) || ((c->spells & CS_FREQ) == 0))
    CErrMsg (c, "quylthulgs cast spells, and this one doesn't.");
  if ((c->spells & CS_BREATHE) && (c->spells & CS_FREQ))
    CErrMsg (c, "quylthulgs cannot breathe attacks, "
	    "yet this creature breathes attacks.");
  if ((c->cdefense & defense ("evil")))
    CErrMsg (c, "quylthulgs are not evil, yet this one is.");
  if ((c->cdefense & defense ("no_sleep")) == 0)
    CErrMsg (c, "quylthulgs can't be slept or charmed, yet this one can be.");
  if ((c->cdefense & defense ("infra")))
    CErrMsg (c, "quylthulgs can't be seen by infravision, "
	     "yet this one can be.");
  if (c->cmove & move ("random_20, random_40, random_75"))
    CErrMsg (c, "quylthulgs do not move randomly, yet this one does.");
  if (c->cmove & move ("magic_only") == 0)
    CErrMsg (c, "quylthulgs move via magic, yet this one does not.");
  return;
}

/*
other: C, e, E, g, i, J, m, O, X, $, ','
	some can be invisible, never open doors, only X phase,
	only C/E/i/O eats others, only C/E/i/O pick up objects, only
	O/',' multiply, only C/i/O carry objects/gold, $ carries only
	gold, no breath weapons, not evil (all brainless
	creatures), not hurt by any special weapon, can't be slept,
	never seen with infravision, brainless creatures,
	some drain mana/exp/etc., fire/air elementals (includes invisible
	stalker) move quickly, golems are animated and should never move
	randomly, the rest never move or move slowly/randomly if they do
	**$ carries objects, "only gold" isn't represented.
	**not checking fire/air elemental speed as it's not very regular
	**eyes can be seen with infravision
	**stationary creatures do not move randomly
	**earth based creatures can phase
	**fire based creatures can be seen with infravision
	**xorn picks up objects too
	**xorn moves at normal speed and not randomly
	**eyes and icky-things CAN be slept
	**Earth and Air elementals/spirits CAN open doors
	**Oozes may sometimes open doors

*/
static void
ConsistencyCheckOther (creature_type *c)
{
  if (((c->cmove & special ("invisible"))) &&
    ((strcasestr (c->name, "Air ") == 0) &&
     (strcasestr (c->name, "Invisible") == 0) &&
     (strcasestr (c->name, "Clear") == 0) &&
     (strcasestr (c->name, "Crystal") == 0)))
    CErrMsg (c, "only certain transparent brainless creatures are invisible, "
	    "and this one doesn't seem to be transparent, "
	    "yet it is designated as invisible.");
  if ((c->cmove & special ("open_door")) && 
      (strcasestr (c->name, "Air ") == 0) &&
      (strcasestr (c->name, "Invisible ") == 0) &&
      (strcasestr (c->name, "Earth ") == 0) &&
      (strcasestr (c->name, "Ooze") == 0) &&
      (strcasestr (c->name, "Xorn") == 0))
    CErrMsg (c, "brainless creatures can't open doors, "
	    "except for air and earth elementals, xorns or oozes, "
	    "yet this one does, "
	    "and it isn't an air or earth elemental, nor a xorn, "
	    "nor an ooze.");
  if ((c->cmove & special ("phase")) && (c->cchar != 'X') && 
      (strcasestr (c->name, "Earth") == 0))
    CErrMsg (c, "brainless creatures can't phase through rock except for Xorn, "
	    "and earth-based spirits, yet this one does, "
	    "and it's neither a Xorn nor an earth-based spirit.");
  if ((c->cmove & special ("eats_other")) && 
      (strchr ("CEiO", c->cchar) == NULL))
    CErrMsg (c, "brainless creatures don't generally eat others "
	    "(except for cubes, elementals, icky-things and oozes), "
	    "yet this one does "
	    "and it's not a cube, elemental, icky-thing or ooze.");
  if ((c->cmove & special ("picks_up")) && 
      (strchr ("CEiOX", c->cchar) == NULL))
    CErrMsg (c, "brainless creatures don't generally pick up objects "
	    "(except for cubes, elementals, icky-things, oozes and xorns), "
	    "yet this one does "
	    "and it's not a cube, elemental, icky-thing, ooze or xorn.");
  if ((c->cmove & special ("multiply")) && (strchr (",O", c->cchar)) == NULL)
    CErrMsg (c, "brainless creatures never multiply "
	    "(except for oozes and mushroom patches), "
	    "yet this one does "
	    "and it's not an ooze or a mushroom patch.");
  if ((c->cmove & treasure ("has_random_60, has_random_90, "
			    "has_1d2_obj, has_2d2_obj, has_4d2_obj, "
			    "carry_small_obj, carry_obj, carry_gold")) &&
      (strchr ("CiO$", c->cchar) == NULL))
    CErrMsg (c, "brainless creatures generally don't carry treasure "
	    "(except for cubes, icky-things and oozes), "
	    "yet this one does "
	    "and it's not a cube, icky-thing or ooze.");
  if ((c->spells & breath ("acid, fire, frost, gas, light")) && 
      (c->spells & CS_FREQ))
    CErrMsg (c, "brainless creatures don't breathe like dragons, "
	    "yet this one does.");
  if ((c->cdefense & defense ("evil")))
    CErrMsg (c, "brainless creatures are not evil, yet this one is.");
  if ((c->cdefense & defense ("dragon, animal, undead")))
    CErrMsg (c, "brainless creatures are not susceptible to special weapons, "
	    "(like SA, SD, SU), yet this one is.");
  if (((c->cdefense & (defense ("no_sleep"))) == 0) && 
      (strchr ("eiX", c->cchar) == NULL))
    CErrMsg (c, "brainless creatures can't be slept except eyes, icky-things, "
	    "and xorns, "
	    "yet this one can be, and it's not an eye, icky-thing or xorn.");
  if ((c->cdefense & defense ("infra")) && (c->cchar != 'e') && 
      (c->spells & resist ("fire")) == 0)
    CErrMsg (c, "brainless creatures cannot be seen by infravision "
	    "(except for eyes, and fire-based brainless creatures), "
	    "yet this one can and it's not an eye, "
	    "or a fire-based brainless creature.");
  if (((c->spells & spell ("drain_mana")) == 0) && (c->cchar == 'e'))
    CErrMsg (c, "eyes always drain mana, yet this one doesn't.");
  if ((c->cchar == 'g') && 
      ((c->cmove & move ("random_20, random_40, random_75"))))
    CErrMsg (c, "golems don't move randomly, yet this one does.");
  if (strchr ("CeiJmO$,", c->cchar))
    {
      if ((c->cmove & move ("attack_only")))
	{
	  if ((c->cmove & move ("random_20, random_40, random_75")))
	    CErrMsg (c, "stationary brainless creatures do not move randomly, "
		    "yet this one does.");
	}
      else
	{
	  if (!((c->speed < 11) || ((c->cmove & 
		move ("random_20, random_40, random_75")))))
	    CErrMsg (c, "brainless creatures either move slowly or randomly, "
		    "except for golems, elementals and xorns, "
		    "yet this one moves quickly or not randomly "
		    "and it's not a golem, elemental or xorn.");
	}
    }
  return;
}

void
ConsistencyCheckCreature (creature_type *c)
{
  if (strchr ("dD", c->cchar))
    ConsistencyCheckDragon (c);
  if (strchr ("hHknopPTUyY", c->cchar))
    ConsistencyCheckHumanoid (c);
  if (strchr ("GLMsVWz", c->cchar))
    ConsistencyCheckUndead (c);
  if (strchr ("aAbcfFjKlrRStw", c->cchar))
    ConsistencyCheckAnimal (c);
  if ((strchr ("Bq", c->cchar)) || (strcmp(c->name,"Evil Iggy")==0))
    ConsistencyCheckDemon (c);
  if (c->cchar == 'Q')
    ConsistencyCheckQuylthulg (c);
  if (strchr ("CeEgiJmOX$,", c->cchar))
    ConsistencyCheckOther (c);
  return;
}
