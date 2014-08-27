/* src/signals.c: signal handlers

   Copyright (c) 1989-94 James E. Wilson, Christopher J. Stuart

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

/* This signal package was brought to you by		-JEW-  */
/* Completely rewritten by				-CJS- */

/* To find out what system we're on.  */

#include <stdio.h>

#include "config.h"
#include "constant.h"

#include <sys/types.h>
#include <unistd.h>

#define MSIGNAL signal


/* must include before externs.h, because that uses SIGTSTP */
#include <signal.h>

#include "types.h"
#include "externs.h"

#include <string.h>

void exit ();
unsigned sleep ();

static int error_sig = -1;
static int signal_count = 0;

static int
signal_handler (sig)
     int sig;
{

  if (error_sig >= 0)		/* Ignore all second signals. */
    {
      if (++signal_count > 10)	/* Be safe. We will die if persistent enough. */
	MSIGNAL (sig, SIG_DFL);
      return 0;
    }
  error_sig = sig;

  /* Allow player to think twice. Wizard may force a core dump. */
  if (sig == SIGINT || sig == SIGQUIT)
    {
      if (death)
	MSIGNAL (sig, SIG_IGN);	/* Can't quit after death. */
      else if (!character_saved && character_generated)
	{
	  if (!get_check ("Really commit *Suicide*?"))
	    {
	      if (turn > 0)
		disturb (1, 0);
	      erase_line (0, 0);
	      put_qio ();
	      error_sig = -1;
	      MSIGNAL (sig, signal_handler);	/* Have to restore handler. */
	      /* in case control-c typed during msg_print */
	      if (wait_for_more)
		put_buffer (" -more-", MSG_LINE, 0);
	      put_qio ();
	      return 0;		/* OK. We don't quit. */
	    }
	  snprintf (died_from, sizeof (died_from), "%s", "Interrupting");
	}
      else
	snprintf (died_from, sizeof (died_from), "%s", "Abortion");
      prt ("Interrupt!", 0, 0);
      death = TRUE;
      exit_game ();
    }
  /* Die. */
  prt
    ("OH NO!!!!!!  A gruesome software bug LEAPS out at you. There is NO defense!",
     23, 0);
  if (!death && !character_saved && character_generated)
    {
      panic_save = 1;
      prt ("Your guardian angel is trying to save you.", 0, 0);
      snprintf (died_from, sizeof (died_from), "(panic save %d)", sig);
      if (!save_char ())
	{
	  snprintf (died_from, sizeof (died_from), "%s", "software bug");
	  death = TRUE;
	  turn = -1;
	}
    }
  else
    {
      death = TRUE;
      _save_char (savefile);	/* Quietly save the memory anyway. */
    }
  restore_term ();
  /* always generate a core dump */
  MSIGNAL (sig, SIG_DFL);
  kill (getpid (), sig);
  sleep (5);
  exit (1);
}


void
nosignals ()
{
#ifdef SIGTSTP
  MSIGNAL (SIGTSTP, SIG_IGN);
#endif
  if (error_sig < 0)
    error_sig = 0;
}

void
signals ()
{
#ifdef SIGTSTP
  MSIGNAL (SIGTSTP, suspend);
#endif
  if (error_sig == 0)
    error_sig = -1;
}


void
init_signals ()
{
  MSIGNAL (SIGINT, signal_handler);

  MSIGNAL (SIGINT, signal_handler);
  MSIGNAL (SIGFPE, signal_handler);

  /* Ignore HANGUP, and let the EOF code take care of this case. */
  MSIGNAL (SIGHUP, SIG_IGN);
  MSIGNAL (SIGQUIT, signal_handler);
  MSIGNAL (SIGILL, signal_handler);
  MSIGNAL (SIGTRAP, signal_handler);
  MSIGNAL (SIGIOT, signal_handler);
#ifdef SIGEMT			/* in BSD systems */
  MSIGNAL (SIGEMT, signal_handler);
#endif
#ifdef SIGDANGER		/* in SYSV systems */
  MSIGNAL (SIGDANGER, signal_handler);
#endif
  MSIGNAL (SIGKILL, signal_handler);
  MSIGNAL (SIGBUS, signal_handler);
  MSIGNAL (SIGSEGV, signal_handler);
#ifdef SIGSYS
  MSIGNAL (SIGSYS, signal_handler);
#endif
  MSIGNAL (SIGTERM, signal_handler);
  MSIGNAL (SIGPIPE, signal_handler);
#ifdef SIGXCPU			/* BSD */
  MSIGNAL (SIGXCPU, signal_handler);
#endif
#ifdef SIGPWR			/* SYSV */
  MSIGNAL (SIGPWR, signal_handler);
#endif
}

void
ignore_signals ()
{
  MSIGNAL (SIGINT, SIG_IGN);
#ifdef SIGQUIT
  MSIGNAL (SIGQUIT, SIG_IGN);
#endif
}

void
default_signals ()
{
  MSIGNAL (SIGINT, SIG_DFL);
#ifdef SIGQUIT
  MSIGNAL (SIGQUIT, SIG_DFL);
#endif
}

void
restore_signals ()
{
  MSIGNAL (SIGINT, signal_handler);
#ifdef SIGQUIT
  MSIGNAL (SIGQUIT, signal_handler);
#endif
}
