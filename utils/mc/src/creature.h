/*
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

#ifndef MC_CREATURE_H
#define MC_CREATURE_H 1
/*
#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

typedef unsigned long  int32u;
typedef long           int32;
typedef unsigned short int16u;
typedef short          int16;
typedef unsigned char  int8u;

#define CM_TREASURE 0x7C000000L
#define CM_ALL_MV_FLAGS 0x0000003F
#define CM_SPECIAL 0x003F0000L
#define CM_WIN 0x80000000L
#define CS_SPELLS 0x0001FFF0L
#define CS_FREQ 0x0000000FL
#define CS_BREATHE 0x00F80000L

typedef struct creature_type
{
  int idx;
  char *name;
  int32u cmove;
  int32u spells;
  int16u cdefense;
  int16u mexp;
  int8u sleep;
  int8u aaf; 
  int8u ac;  
  int8u speed;
  int8u cchar;
  int8u hd[2];
  int8u damage[4];
  int8u level; 
} creature_type;

typedef struct 
{
  int8u attack_type;
  int8u attack_desc;
  int8u attack_dice;
  int8u attack_sides;
} attack_t;
*/

#include "creature_constant.h"
#include "creature_type.h"

int mc_main (char *inputFilename);
unsigned int lookup_flag (char *kind, char *flags);
void ErrMsg (char *s);
#endif
