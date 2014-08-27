/*
   Copyright (C) 2005, 2010, 2014 Ben Asselstine
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

#include <config.h>
#include <stdlib.h>
#define _GL_GETOPT_H
#include "argp.h"
#include <string.h>
#include "config.h"
#include "opts.h"
#include "xvasprintf.h"

const char *argp_program_version = PACKAGE_NAME " mc " PACKAGE_VERSION;
const char *argp_program_bug_address = PACKAGE_BUGREPORT; 

static char doc[] = "Generate %s's monsters_tables.c from FILE.\vBy default the monsters_tables.c file goes to the standard output unless the -o option is used.";

static char args_doc[] = "FILE";

static struct argp_option options[] = 
{
    {"outfile", 'o', "FILE", 0, "put generated code into FILE", 1},
    {"consistency-check", 'c', 0, 0, "check for consistency errors", 1},
    {"debug", 'd', 0, OPTION_HIDDEN, "show extra debugging information", 1},
    {"constants", 'C', 0, 0, "generate constants instead of tables.", 1},

{ 0 }
};

static error_t 
parse_opt (int key, char *arg, struct argp_state *state) 
{
  struct arguments_t *arguments = state->input;

  switch (key) 
    { 
    case 'C':
      arguments->mc.only_generate_constants = 1;
      break;
    case 'o':
	{
	  FILE *fileptr;
	  if (strcmp (arg, "-") == 0)
	    arguments->mc.outfile = stdout;
	  else
	    {
	      fileptr = fopen (arg, "w");
	      if (!fileptr)
		{
		  argp_error (state, "cannot open '%s' for reading (%m)", arg);
		  return EINVAL;
		}
	      arguments->mc.outfile = fileptr;
	    }
	  break;
	}
    case 'c':
	{
	  arguments->mc.consistency_check = 1;
	  break;
	}
    case 'd':
	{
	  arguments->mc.debug = 1;
	  break;
	}
    case ARGP_KEY_INIT:
      arguments->mc.outfile = stdout;
      break;
    case ARGP_KEY_ARG:
      arguments->mc.infile = arg;
      break;
    case ARGP_KEY_NO_ARGS:
      argp_error (state, "You must supply a FILE to compile.");
      break;
    case ARGP_KEY_END:
      break;
    default:
      return ARGP_ERR_UNKNOWN;
    }
  return 0;
}

static char *
help_filter (int key, const char *text, void *input)
{
  if (key == ARGP_KEY_HELP_PRE_DOC)
    return xasprintf (text, PACKAGE_NAME);
  else if (key == ARGP_KEY_HELP_EXTRA)
    return xasprintf("For complete documentation, visit: <%s>\n", PACKAGE_URL);
  return (char *) text;
}

static struct argp argp = { options, parse_opt, args_doc, doc, 0, 
                            help_filter };

void 
parse_opts(int argc, char **argv, struct arguments_t *arguments)
{
  int retval;
  setenv ("ARGP_HELP_FMT", "no-dup-args-note", 1);
  retval = argp_parse (&argp, argc, argv, 0, 0, arguments); 
  if (retval < 0)
    {
      argv[1] = "--help";
      retval = argp_parse (&argp, 2, argv, 0, 0, arguments); 
      //doesn't get here.
    }
  return;
}
