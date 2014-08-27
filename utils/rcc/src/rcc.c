/*
   Copyright (C) 2014 Ben Asselstine
   Written by Ben Asselstine
  
   rcc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   rcc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with rcc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

#include <stdlib.h>
#include "race-class.h"
#include "opts.h"

struct arguments_t arguments;

int
main (int argc, char **argv)
{
  int retval;
  parse_opts (argc, argv, &arguments);  //from opts.c
  retval = rcc_main (arguments.rcc.infile); //from race-class.y
  exit (retval);
}
