/* src/player_constant.h

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

#ifndef PLAYER_CONSTANT_H
#define PLAYER_CONSTANT_H
/* Player constants						*/
#define USE_DEVICE	  3	/* x> Harder devices x< Easier devices   */
#define PLAYER_FOOD_FULL 10000	/* Getting full                          */
#define PLAYER_FOOD_MAX	 15000	/* Maximum food value, beyond is wasted  */
#define PLAYER_FOOD_FAINT  300	/* Character begins fainting             */
#define PLAYER_FOOD_WEAK  1000	/* Warn player that he is getting very low */
#define PLAYER_FOOD_ALERT 2000	/* Warn player that he is getting low    */
#define PLAYER_REGEN_FAINT    33	/* Regen factor*2^16 when fainting    */
#define PLAYER_REGEN_WEAK     98	/* Regen factor*2^16 when weak        */
#define PLAYER_REGEN_NORMAL  197	/* Regen factor*2^16 when full        */
#define PLAYER_REGEN_HPBASE  1442	/* Min amount hp regen*2^16           */
#define PLAYER_REGEN_MNBASE  524	/* Min amount mana regen*2^16         */
#define PLAYER_WEIGHT_CAP 130	/* "#"*(1/10 pounds) per strength point  */
#define PLAYER_EXIT_PAUSE 2	/* Pause time before player can re-roll  */


/* Base to hit constants					*/
#define BTH_PLUS_ADJ	 3	/* Adjust BTH per plus-to-hit     */

/* magic numbers for players inventory array */
#define INVEN_WIELD 22		/* must be first item in equipment list */
#define INVEN_HEAD  23
#define INVEN_NECK  24
#define INVEN_BODY  25
#define INVEN_ARM   26
#define INVEN_HANDS 27
#define INVEN_RIGHT 28
#define INVEN_LEFT  29
#define INVEN_FEET  30
#define INVEN_OUTER 31
#define INVEN_LIGHT 32
#define INVEN_AUX   33

/* Attribute indexes -CJS- */

#define A_STR 0
#define A_INT 1
#define A_WIS 2
#define A_DEX 3
#define A_CON 4
#define A_CHR 5

/* definitions for the player's status field */
#define PY_HUNGRY	0x00000001L
#define PY_WEAK		0x00000002L
#define PY_BLIND	0x00000004L
#define PY_CONFUSED	0x00000008L
#define PY_FEAR		0x00000010L
#define PY_POISONED	0x00000020L
#define PY_FAST		0x00000040L
#define PY_SLOW		0x00000080L
#define PY_SEARCH	0x00000100L
#define PY_REST		0x00000200L
#define PY_STUDY	0x00000400L

#define PY_INVULN	0x00001000L
#define PY_HERO		0x00002000L
#define PY_SHERO	0x00004000L
#define PY_BLESSED	0x00008000L
#define PY_DET_INV	0x00010000L
#define PY_TIM_INFRA	0x00020000L
#define PY_SPEED	0x00040000L
#define PY_STR_WGT	0x00080000L
#define PY_PARALYSED	0x00100000L
#define PY_REPEAT	0x00200000L
#define PY_ARMOR	0x00400000L

#define PY_STATS	0x3F000000L
#define PY_STR		0x01000000L	/* these 6 stat flags must be adjacent */
#define PY_INT		0x02000000L
#define PY_WIS		0x04000000L
#define PY_DEX		0x08000000L
#define PY_CON		0x10000000L
#define PY_CHR		0x20000000L

#define PY_HP		0x40000000L
#define PY_MANA		0x80000000L

#endif
