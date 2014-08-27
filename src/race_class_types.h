/* src/race_class_type.h

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

#ifndef RACE_CLASS_TYPE_H
#define RACE_CLASS_TYPE_H
#include "primitives.h"
typedef struct spell_type
{				/* spell name is stored in spell_names[] array at index [0][i], [1][i] if priest */
  int8u slevel;
  int8u smana;
  int8u sfail;
  int8u sexp;			/* 1/4 of exp gained for learning spell */
} spell_type;

typedef struct race_type
{
  char *trace;			/* Type of race                 */
  int16 str_adj;		/* adjustments                  */
  int16 int_adj;
  int16 wis_adj;
  int16 dex_adj;
  int16 con_adj;
  int16 chr_adj;
  int16 b_age;			/* Base age of character         */
  int8u m_age;			/* Maximum age of character      */
  int8u m_b_ht;			/* base height for males          */
  int8u m_m_ht;			/* mod height for males           */
  int8u m_b_wt;			/* base weight for males          */
  int8u m_m_wt;			/* mod weight for males           */
  int8u f_b_ht;			/* base height females            */
  int8u f_m_ht;			/* mod height for females */
  int8u f_b_wt;			/* base weight for female */
  int8u f_m_wt;			/* mod weight for females */
  int16 b_dis;			/* base chance to disarm         */
  int16 srh;			/* base chance for search        */
  int16 stl;			/* Stealth of character          */
  int16 fos;			/* frequency of auto search      */
  int16 bth;			/* adj base chance to hit        */
  int16 bthb;			/* adj base to hit with bows     */
  int16 bsav;			/* Race base for saving throw    */
  int8u bhitdie;		/* Base hit points for race      */
  int8u infra;			/* See infra-red                 */
  int8u b_exp;			/* Base experience factor        */
  int32u rtclass;		/* Bit field for class types     */
} race_type;

typedef struct class_type
{
  char *title;			/* type of class                */
  int8u adj_hd;			/* Adjust hit points            */
  int8u mdis;			/* mod disarming traps          */
  int8u msrh;			/* modifier to searching        */
  int8u mstl;			/* modifier to stealth          */
  int8u mfos;			/* modifier to freq-of-search   */
  int8u mbth;			/* modifier to base to hit      */
  int8u mbthb;			/* modifier to base to hit - bows */
  int8u msav;			/* Class modifier to save       */
  int16 madj_str;		/* Class modifier for strength  */
  int16 madj_int;		/* Class modifier for intelligence */
  int16 madj_wis;		/* Class modifier for wisdom    */
  int16 madj_dex;		/* Class modifier for dexterity */
  int16 madj_con;		/* Class modifier for constitution */
  int16 madj_chr;		/* Class modifier for charisma  */
  int8u spell;			/* class use mage spells        */
  int8u m_exp;			/* Class experience factor      */
  int8u first_spell_lev;	/* First level where class can use spells. */
} class_type;

typedef struct background_type
{
  char *info;			/* History information          */
  int8u roll;			/* Die roll needed for history  */
  int8u chart;			/* Table number                 */
  int8u next;			/* Pointer to next table        */
  int8u bonus;			/* Bonus to the Social Class+50 */
} background_type;

typedef struct owner_type
{
  char *owner_name;
  int16 max_cost;
  int8u max_inflate;
  int8u min_inflate;
  int8u haggle_per;
  int8u owner_race;
  int8u insult_max;
  int8u pstore; /*  # of Store 0 is '1'*/
} owner_type;

/* class level adjustment constants */
#define CLA_BTH		0
#define CLA_BTHB	1
#define CLA_DEVICE	2
#define CLA_DISARM	3
#define CLA_SAVE	4
/* this depends on the fact that CLA_SAVE values are all the same, if not,
   then should add a separate column for this */
#define CLA_MISC_HIT	4
#define MAX_LEV_ADJ	5

#endif
