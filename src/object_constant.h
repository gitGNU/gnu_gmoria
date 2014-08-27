/* src/object_constant.h
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

#ifndef OBJECT_CONSTANT_H
#define OBJECT_CONSTANT_H

/* definitions for objects that can be worn */
#define TR_STATS	0x0000003FL	/* the stats must be the low 6 bits */
#define TR_STR		0x00000001L
#define TR_INT		0x00000002L
#define TR_WIS		0x00000004L
#define TR_DEX		0x00000008L
#define TR_CON		0x00000010L
#define TR_CHR		0x00000020L
#define TR_SEARCH	0x00000040L
#define TR_SLOW_DIGEST	0x00000080L
#define TR_STEALTH	0x00000100L
#define TR_AGGRAVATE	0x00000200L
#define TR_TELEPORT	0x00000400L
#define TR_REGEN	0x00000800L
#define TR_SPEED	0x00001000L

#define TR_EGO_WEAPON	0x0007E000L
#define TR_SLAY_DRAGON	0x00002000L
#define TR_SLAY_ANIMAL	0x00004000L
#define TR_SLAY_EVIL	0x00008000L
#define TR_SLAY_UNDEAD	0x00010000L
#define TR_FROST_BRAND	0x00020000L
#define TR_FLAME_TONGUE	0x00040000L

#define TR_RES_FIRE	0x00080000L
#define TR_RES_ACID	0x00100000L
#define TR_RES_COLD	0x00200000L
#define TR_SUST_STAT	0x00400000L
#define TR_FREE_ACT	0x00800000L
#define TR_SEE_INVIS	0x01000000L
#define TR_RES_LIGHT	0x02000000L
#define TR_FFALL	0x04000000L
#define TR_BLIND	0x08000000L
#define TR_TIMID	0x10000000L
#define TR_TUNNEL	0x20000000L
#define TR_INFRA	0x40000000L
#define TR_CURSED	0x80000000L

/* definitions for chests */
#define CH_LOCKED	0x00000001L
#define CH_TRAPPED	0x000001F0L
#define CH_LOSE_STR	0x00000010L
#define CH_POISON	0x00000020L
#define CH_PARALYSED	0x00000040L
#define CH_EXPLODE	0x00000080L
#define CH_SUMMON	0x00000100L

/* defines for treasure type values (tval) */
#define TV_NEVER	-1	/* used by find_range() for non-search */
#define TV_NOTHING	0
#define TV_MISC		1
#define TV_CHEST	2
/* min tval for wearable items, all items between TV_MIN_WEAR and TV_MAX_WEAR
   use the same flag bits, see the TR_* defines */
#define TV_MIN_WEAR	10
/* items tested for enchantments, i.e. the MAGIK inscription, see the
   enchanted() procedure */
#define TV_MIN_ENCHANT	10
#define TV_SLING_AMMO	10
#define TV_BOLT		11
#define TV_ARROW	12
#define TV_SPIKE	13
#define TV_LIGHT	15
#define TV_BOW		20
#define TV_HAFTED	21
#define TV_POLEARM	22
#define TV_SWORD	23
#define TV_DIGGING	25
#define TV_BOOTS	30
#define TV_GLOVES	31
#define TV_CLOAK	32
#define TV_HELM		33
#define TV_SHIELD	34
#define TV_HARD_ARMOR	35
#define TV_SOFT_ARMOR	36
/* max tval that uses the TR_* flags */
#define TV_MAX_ENCHANT	39
#define TV_AMULET	40
#define TV_RING		45
/* max tval for wearable items */
#define TV_MAX_WEAR	50
#define TV_STAFF	55
#define TV_WAND		65
#define TV_SCROLL	70
#define TV_POTION1	75
#define TV_POTION2	76
#define TV_FLASK	77
#define TV_FOOD 	80
#define TV_MAGIC_BOOK	90
#define TV_PRAYER_BOOK	91
/* objects with tval above this are never picked up by monsters */
#define TV_MAX_OBJECT	99
#define TV_GOLD		100
/* objects with higher tvals can not be picked up */
#define TV_MAX_PICK_UP	100
#define TV_INVIS_TRAP	101
/* objects between TV_MIN_VISIBLE and TV_MAX_VISIBLE are always visible,
   i.e. the cave fm flag is set when they are present */
#define TV_MIN_VISIBLE	102
#define TV_VIS_TRAP	102
#define TV_RUBBLE	103
/* following objects are never deleted when trying to create another one
   during level generation */
#define TV_MIN_DOORS	104
#define TV_OPEN_DOOR	104
#define TV_CLOSED_DOOR	105
#define TV_UP_STAIR	107
#define TV_DOWN_STAIR	108
#define TV_SECRET_DOOR	109
#define TV_STORE_DOOR	110
#define TV_MAX_VISIBLE	110

#define MAX_STORES	 6	/* Number of different stores            */
#define STORE_INVEN_MAX	 24	/* Max number of discrete objs in inven  */

/* id's used for object description, stored in object_ident */
#define OD_TRIED	0x1
#define OD_KNOWN1	0x2

/* id's used for item description, stored in i_ptr->ident */
#define ID_MAGIK	0x1
#define ID_DAMD		0x2
#define ID_EMPTY	0x4
#define ID_KNOWN2	0x8
#define ID_STOREBOUGHT	0x10
#define ID_SHOW_HITDAM	0x20
#define ID_NOSHOW_P1	0x40
#define ID_SHOW_P1	0x80

/* indexes into the special name table */
#define SN_NULL			0
#define SN_R			1
#define SN_RA			2
#define SN_RF			3
#define SN_RC			4
#define SN_RL			5
#define SN_HA			6
#define SN_DF			7
#define SN_SA			8
#define SN_SD			9
#define SN_SE			10
#define SN_SU			11
#define SN_FT			12
#define SN_FB			13
#define SN_FREE_ACTION		14
#define SN_SLAYING		15
#define SN_CLUMSINESS		16
#define SN_WEAKNESS		17
#define SN_SLOW_DESCENT		18
#define SN_SPEED		19
#define SN_STEALTH		20
#define SN_SLOWNESS		21
#define SN_NOISE		22
#define SN_GREAT_MASS		23
#define SN_INTELLIGENCE		24
#define SN_WISDOM		25
#define SN_INFRAVISION		26
#define SN_MIGHT		27
#define SN_LORDLINESS		28
#define SN_MAGI			29
#define SN_BEAUTY		30
#define SN_SEEING		31
#define SN_REGENERATION		32
#define SN_STUPIDITY		33
#define SN_DULLNESS		34
#define SN_BLINDNESS		35
#define SN_TIMIDNESS		36
#define SN_TELEPORTATION	37
#define SN_UGLINESS		38
#define SN_PROTECTION		39
#define SN_IRRITATION		40
#define SN_VULNERABILITY	41
#define SN_ENVELOPING		42
#define SN_FIRE			43
#define SN_SLAY_EVIL		44
#define SN_DRAGON_SLAYING	45
#define SN_EMPTY		46
#define SN_LOCKED		47
#define SN_POISON_NEEDLE	48
#define SN_GAS_TRAP		49
#define SN_EXPLOSION_DEVICE	50
#define SN_SUMMONING_RUNES	51
#define SN_MULTIPLE_TRAPS	52
#define SN_DISARMED		53
#define SN_UNLOCKED		54
#define SN_SLAY_ANIMAL		55
#define SN_ARRAY_SIZE		56	/* must be at end of this list */

/* Constants describing limits of certain objects		*/
#define OBJ_LAMP_MAX	15000	/* Maximum amount that lamp can be filled */
#define OBJ_BOLT_RANGE	 18	/* Maximum range of bolts and balls      */
#define OBJ_RUNE_PROT	 3000	/* Rune of protection resistance         */

#define MAX_SPELLS       31     /* This many spells in the game            */
#endif
