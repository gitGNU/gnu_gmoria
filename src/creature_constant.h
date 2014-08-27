/* src/creature_constant.h
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

#ifndef CREATURE_CONSTANT_H
#define CREATURE_CONSTANT_H


/* definitions for creatures, cmove field */
#define CM_ALL_MV_FLAGS	0x0000003FL
#define CM_ATTACK_ONLY	0x00000001L
#define CM_MOVE_NORMAL	0x00000002L
/* For Quylthulgs, which have no physical movement.  */
#define CM_ONLY_MAGIC	0x00000004L

#define CM_RANDOM_MOVE	0x00000038L
#define CM_20_RANDOM	0x00000008L
#define CM_40_RANDOM	0x00000010L
#define CM_75_RANDOM	0x00000020L

#define CM_SPECIAL	0x003F0000L
#define CM_INVISIBLE	0x00010000L
#define CM_OPEN_DOOR	0x00020000L
#define CM_PHASE	0x00040000L
#define CM_EATS_OTHER	0x00080000L
#define CM_PICKS_UP	0x00100000L
#define CM_MULTIPLY	0x00200000L

#define CM_SMALL_OBJ	0x00800000L
#define CM_CARRY_OBJ	0x01000000L
#define CM_CARRY_GOLD	0x02000000L
#define CM_TREASURE	0x7C000000L
#define CM_TR_SHIFT	26	/* used for recall of treasure */
#define CM_60_RANDOM	0x04000000L
#define CM_90_RANDOM	0x08000000L
#define CM_1D2_OBJ	0x10000000L
#define CM_2D2_OBJ	0x20000000L
#define CM_4D2_OBJ	0x40000000L
#define CM_WIN		0x80000000L

/* creature spell definitions */
#define CS_FREQ		0x0000000FL
#define CS_SPELLS	0x0001FFF0L
#define CS_TEL_SHORT	0x00000010L
#define CS_TEL_LONG	0x00000020L
#define CS_TEL_TO	0x00000040L
#define CS_LGHT_WND	0x00000080L
#define CS_SER_WND	0x00000100L
#define CS_HOLD_PER	0x00000200L
#define CS_BLIND	0x00000400L
#define CS_CONFUSE	0x00000800L
#define CS_FEAR		0x00001000L
#define CS_SUMMON_MON	0x00002000L
#define CS_SUMMON_UND	0x00004000L
#define CS_SLOW_PER	0x00008000L
#define CS_DRAIN_MANA	0x00010000L

#define CS_BREATHE	0x00F80000L	/* may also just indicate resistance */
#define CS_BR_LIGHT	0x00080000L	/* if no spell frequency set */
#define CS_BR_GAS	0x00100000L
#define CS_BR_ACID	0x00200000L
#define CS_BR_FROST	0x00400000L
#define CS_BR_FIRE	0x00800000L

/* creature defense flags */
#define CD_DRAGON	0x0001
#define CD_ANIMAL	0x0002
#define CD_EVIL		0x0004
#define CD_UNDEAD	0x0008
#define CD_WEAKNESS	0x03F0
#define CD_FROST	0x0010
#define CD_FIRE		0x0020
#define CD_POISON	0x0040
#define CD_ACID		0x0080
#define CD_LIGHT	0x0100
#define CD_STONE	0x0200

#define CD_NO_SLEEP	0x1000
#define CD_INFRA	0x2000
#define CD_MAX_HP	0x4000
#endif
