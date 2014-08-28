/* src/constant.h: global constants used by Moria

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

/*Note to the Wizard:					- RAK -	 */
/*	 Tweaking these constants can *GREATLY* change the game. */
/*	 Two years of constant tuning have generated these	 */
/*	 values.  Minor adjustments are encouraged, but you must */
/*	 be very careful not to unbalance the game.  Moria was	 */
/*	 meant to be challenging, not a give away.  Many	 */
/*	 adjustments can cause the game to act strangely, or even*/
/*	 cause errors.						 */

/*Addendum:							- JEW -
  I have greatly expanded the number of defined constants.  However, if
  you change anything below, without understanding EXACTLY how the game
  uses the number, the program may stop working correctly.  Modify the
  constants at your own risk. */

#ifndef CONSTANT_H
#define CONSTANT_H

/* Current version number of Moria				*/
#define CUR_VERSION_MAJ 5	/* version 5.7.2 */
#define CUR_VERSION_MIN 7
#define PATCH_LEVEL 2

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define MAX_UCHAR	255
#define MAX_SHORT	32767	/* maximum short/long signed ints */
#define MAX_LONG	0x7FFFFFFFL

/* Changing values below this line may be hazardous to your health! */

/* message line location */
#define MSG_LINE  0

/* number of messages to save in a buffer */
#define MAX_SAVE_MSG   22	/* How many messages to save -CJS- */

/* Dungeon size parameters					*/
#define MAX_HEIGHT  66		/* Multiple of 11; >= 22 */
#define MAX_WIDTH  198		/* Multiple of 33; >= 66 */
#define SCREEN_HEIGHT  22
#define SCREEN_WIDTH   66
#define QUART_HEIGHT (SCREEN_HEIGHT / 4)
#define QUART_WIDTH  (SCREEN_WIDTH / 4)

/* Dungeon generation values					*/
/* Note: The entire design of dungeon can be changed by only	 */
/*	 slight adjustments here.				 */
#define DUN_TUN_RND	  9	/* 1/Chance of Random direction          */
#define DUN_TUN_CHG	 70	/* Chance of changing direction (99 max) */
#define DUN_TUN_CON	 15	/* Chance of extra tunneling             */
#define DUN_ROO_MEA	 32	/* Mean of # of rooms, standard dev2     */
#define DUN_TUN_PEN	 25	/* % chance of room doors                */
#define DUN_TUN_JCT	 15	/* % chance of doors at tunnel junctions */
#define DUN_STR_DEN	 5	/* Density of streamers                  */
#define DUN_STR_RNG	 2	/* Width of streamers                    */
#define DUN_STR_MAG	 3	/* Number of magma streamers             */
#define DUN_STR_MC	 90	/* 1/x chance of treasure per magma      */
#define DUN_STR_QUA	 2	/* Number of quartz streamers            */
#define DUN_STR_QC	 40	/* 1/x chance of treasure per quartz     */
#define DUN_UNUSUAL	 300	/* Level/x chance of unusual room        */

/* Store constants						*/
//#define STORE_CHOICES	 26	/* NUMBER of items to choose stock from  */
#define STORE_MAX_INVEN	 18	/* Max diff objs in stock for auto buy   */
#define STORE_MIN_INVEN	 10	/* Min diff objs in stock for auto sell  */
#define STORE_TURN_AROUND 9	/* Amount of buying and selling normally */
#define COST_ADJ	 100	/* Adjust prices for buying and selling  */
#define SALES_TAX	 10	/* Auto-haggle penalty (percent)         */

/* Treasure constants						*/
#define INVEN_ARRAY_SIZE 34	/* Size of inventory array(Do not change) */
#define MAX_OBJ_LEVEL  50	/* Maximum level of magic in dungeon     */
#define OBJ_GREAT      12	/* 1/n Chance of item being a Great Item */

/* Creature generation constants */
/* with MAX_MALLOC 101, it is possible to get compacting monsters messages
   while breeding/cloning monsters */
#define MAX_MALLOC	  125	/* Max that can be allocated            */
#define MAX_MALLOC_CHANCE 160	/* 1/x chance of new monster each round  */
#define MAX_MONS_LEVEL	   40	/* Maximum level of creatures            */
#define MAX_SIGHT	   20	/* Maximum dis a creature can be seen    */
#define MAX_SPELL_DIS	   20	/* Maximum dis creat. spell can be cast  */
#define MAX_MON_MULT	   75	/* Maximum reproductions on a level      */
#define MON_MULT_ADJ	    7	/* High value slows multiplication       */
#define MON_NASTY	   50	/* 1/x chance of high level creat         */
#define MIN_MALLOC_LEVEL   14	/* Minimum number of monsters/level      */
#define MIN_MALLOC_TD	    4	/* Number of people on town level (day)  */
#define MIN_MALLOC_TN	    8	/* Number of people on town level (night) */
#define WIN_MON_TOT	    2	/* Total number of "win" creatures       */
#define WIN_MON_APPEAR	   50	/* Level where winning creatures begin   */
#define MON_SUMMON_ADJ	    2	/* Adjust level of summoned creatures    */
#define MON_DRAIN_LIFE	    2	/* Percent of player exp drained per hit */
#define MIN_MONIX	    2	/* Minimum index in m_list (1 = py, 0 = no mon) */

/* with MAX_TALLOC 150, it is possible to get compacting objects during
   level generation, although it is extremely rare */
#define MAX_TALLOC     175	/* Max objects per level                 */
#define MIN_TRIX	1	/* Minimum t_list index used              */
#define TREAS_ROOM_ALLOC  7	/* Amount of objects for rooms           */
#define TREAS_ANY_ALLOC	  2	/* Amount of objects for corridors       */
#define TREAS_GOLD_ALLOC  2	/* Amount of gold (and gems)             */

/* Magic Treasure Generation constants				*/
/* Note: Number of special objects, and degree of enchantments	 */
/*	 can be adjusted here.					 */
#define OBJ_STD_ADJ	 125	/* Adjust STD per level * 100            */
#define OBJ_STD_MIN	 7	/* Minimum STD                           */
#define OBJ_TOWN_LEVEL	 7	/* Town object generation level          */
#define OBJ_BASE_MAGIC	 15	/* Base amount of magic                  */
#define OBJ_BASE_MAX	 70	/* Max amount of magic                   */
#define OBJ_DIV_SPECIAL	 6	/* magic_chance/#  special magic        */
#define OBJ_DIV_CURSED	 13	/* 10*magic_chance/#  cursed items         */

#define SCARE_MONSTER	99

#include "race_class_constant.h"
#include "player_constant.h"
/* some systems have a non-ANSI definition of this, so undef it first */
#undef CTRL
#define CTRL(x)		(x & 0x1F)
#define DELETE		0x7f
#define ESCAPE	      '\033'	/* ESCAPE character -CJS-  */


/* Fval definitions: these describe the various types of dungeon floors and
   walls, if numbers above 15 are ever used, then the test against
   MIN_CAVE_WALL will have to be changed, also the save routines will have
   to be changed. */
#define NULL_WALL	0
#define DARK_FLOOR	1
#define LIGHT_FLOOR	2
#define MAX_CAVE_ROOM	2
#define CORR_FLOOR	3
#define BLOCKED_FLOOR	4	/* a corridor space with cl/st/se door or rubble */
#define MAX_CAVE_FLOOR	4

#define MAX_OPEN_SPACE  3
#define MIN_CLOSED_SPACE 4

#define TMP1_WALL	8
#define TMP2_WALL	9

#define MIN_CAVE_WALL	12
#define GRANITE_WALL	12
#define MAGMA_WALL	13
#define QUARTZ_WALL	14
#define BOUNDARY_WALL	15

#define MAX_DEFAULT_PACK_ITEMS 5

/* Column for stats    */
#define STAT_COLUMN	0

/* Class spell types */
#define NONE	0
#define MAGE	1
#define PRIEST	2


/* definitions for the psuedo-normal distribution generation */
#define NORMAL_TABLE_SIZE	256
#define NORMAL_TABLE_SD		64	/* the standard deviation for the table */

#include "creature_constant.h"

#include "object_constant.h"

/* spell types used by get_flags(), breathe(), fire_bolt() and fire_ball() */
#define GF_MAGIC_MISSILE 0
#define GF_LIGHTNING	1
#define GF_POISON_GAS	2
#define GF_ACID		3
#define GF_FROST	4
#define GF_FIRE		5
#define GF_HOLY_ORB	6

/* Number of entries allowed in the scorefile.  */
#define SCOREFILE_SIZE	1000


#define KEYBINDING_ORIGINAL 0
#define KEYBINDING_ROGUELIKE 1

/* This sets the default user interface.  */
/* To use the original key bindings (keypad for movement) set ROGUE_LIKE
   to FALSE; to use the rogue-like key bindings (vi style movement)
   set ROGUE_LIKE to TRUE.  */
/* If you change this, you only need to recompile main.c.  */
#define ROGUE_LIKE FALSE

//#define STORE_CHOICES 26 /* NUMBER of items to choose stock from  */

#include "treasure_constant.h"
#include "monsters_constant.h"

#endif
