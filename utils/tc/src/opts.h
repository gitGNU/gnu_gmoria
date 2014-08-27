/*
   Copyright (C) 2007, 2010 Ben Asselstine
   Written by Ben Asselstine
  
   tc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   tc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with tc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

#ifndef TC_OPTS_H
#define TC_OPTS_H

#include <stdio.h>
struct tc_arguments_t
{
  int debug;
  char *infile;
  FILE *outfile;
  int consistency_check;
  int sort;
  int only_generate_constants;
};
struct arguments_t 
{
  struct tc_arguments_t tc;
};

void parse_opts(int argc, char **argv, struct arguments_t *arguments);

#define DEFAULT_SORT_VALUE "1"

extern struct arguments_t arguments;
#endif
