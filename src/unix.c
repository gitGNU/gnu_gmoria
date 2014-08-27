/* src/unix.c: UNIX dependent code.					-CJS-

   Copyright (c) 1989-91 James E. Wilson, Christopher J. Stuart

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


/* defines NULL */
#include <stdio.h>
/* defines CTRL */
#include <sys/ioctl.h>
/* defines TRUE and FALSE */
#include <curses.h>

#include "config.h"
#include "constant.h"
#include "types.h"


#include <signal.h>

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include <string.h>
#include <fcntl.h>

/* This must be included after fcntl.h, which has a prototype for `open'
   on some systems.  Otherwise, the `open' prototype conflicts with the
   `topen' declaration.  */
#include "externs.h"

#include <pwd.h>
#include <sys/errno.h>

struct passwd *getpwuid ();
struct passwd *getpwnam ();


/* Provides for a timeout on input. Does a non-blocking read, consuming the
   data if any, and then returns 1 if data was read, zero otherwise.

   Porting:

   In systems without the select call, but with a sleep for
   fractional numbers of seconds, one could sleep for the time
   and then check for input.

   In systems which can only sleep for whole number of seconds,
   you might sleep by writing a lot of nulls to the terminal, and
   waiting for them to drain, or you might hack a static
   accumulation of times to wait. When the accumulation reaches a
   certain point, sleep for a second. There would need to be a
   way of resetting the count, with a call made for commands like
   run or rest. */
int
check_input (microsec)
     int microsec;
{
  struct timeval tbuf;
  int ch;
  fd_set smask;

  /* Return true if a read on descriptor 1 will not block. */
  tbuf.tv_sec = 0;
  tbuf.tv_usec = microsec;
  FD_ZERO (&smask);
  FD_SET (fileno (stdin), &smask);
  if (select (1, &smask, (fd_set *) 0, (fd_set *) 0, &tbuf) == 1)
    {
      ch = getch ();
      /* check for EOF errors here, select sometimes works even when EOF */
      if (ch == -1)
	{
	  eof_flag++;
	  return 0;
	}
      return 1;
    }
  else
    return 0;
}

#if 0
/* This is not used, however, this should be compared against shell_out
   in io.c */

/* A command for the operating system. Standard library function
   'system' is unsafe, as it leaves various file descriptors
   open. This also is very careful with signals and interrupts,
   and does rudimentary job control, and puts the terminal back
   in a standard mode. */
int
system_cmd (p)
     char *p;
{
  int pgrp, pid, i, mask;
  union wait w;
  extern char *getenv ();

  mask = sigsetmask (~0);	/* No interrupts. */
  restore_term ();		/* Terminal in original state. */
  /* Are we in the control terminal group? */
  if (ioctl (0, TIOCGPGRP, (char *) &pgrp) < 0 || pgrp != getpgrp (0))
    pgrp = -1;
  pid = fork ();
  if (pid < 0)
    {
      sigsetmask (mask);
      moriaterm ();
      return -1;
    }
  if (pid == 0)
    {
      sigsetmask (0);		/* Interrupts on. */
      /* Transfer control terminal. */
      if (pgrp >= 0)
	{
	  i = getpid ();
	  ioctl (0, TIOCSPGRP, (char *) &i);
	  setpgrp (i, i);
	}
      for (i = 2; i < 30; i++)
	close (i);		/* Close all but standard in and out. */
      dup2 (1, 2);		/* Make standard error as standard out. */
      if (p == 0 || *p == 0)
	{
	  p = getenv ("SHELL");
	  if (p)
	    execl (p, p, 0);
	  execl ("/bin/sh", "sh", 0);
	}
      else
	execl ("/bin/sh", "sh", "-c", p, 0);
      _exit (1);
    }
  /* Wait for child termination. */
  for (;;)
    {
      i = wait3 (&w, WUNTRACED, (struct rusage *) 0);
      if (i == pid)
	{
	  if (WIFSTOPPED (w))
	    {
	      /* Stop outselves, if child stops. */
	      kill (getpid (), SIGSTOP);
	      /* Restore the control terminal, and restart subprocess. */
	      if (pgrp >= 0)
		ioctl (0, TIOCSPGRP, (char *) &pid);
	      killpg (pid, SIGCONT);
	    }
	  else
	    break;
	}
    }
  /* Get the control terminal back. */
  if (pgrp >= 0)
    ioctl (0, TIOCSPGRP, (char *) &pgrp);
  sigsetmask (mask);		/* Interrupts on. */
  moriaterm ();			/* Terminal in moria mode. */
  return 0;
}
#endif

/* Find a default user name from the system. */
void
user_name (buf, buflen)
     char *buf;
     size_t buflen;
{
  extern char *getlogin ();
  struct passwd *pwline;
  register char *p;

  p = getlogin ();
  if (p && p[0])
    {
      snprintf (buf, buflen, "%s", p);
    }
  else
    {
      pwline = getpwuid ((int) getuid ());
      if (pwline)
	snprintf (buf, buflen, "%s", pwline->pw_name);
    }
  if (!buf[0])
    snprintf (buf, buflen, "%s", "X");
}

/* expands a tilde at the beginning of a file name to a users home
   directory */
int
tilde (file, exp, explen)
     char *file, *exp;
     size_t explen;
{
  *exp = '\0';
  if (file)
    {
      if (*file == '~')
	{
	  char user[128];
	  struct passwd *pw = NULL;
	  int i = 0;

	  user[0] = '\0';
	  file++;
	  while (*file != '/' && i < sizeof (user))
	    user[i++] = *file++;
	  user[i] = '\0';
	  if (i == 0)
	    {
	      char *login = (char *) getlogin ();

	      if (login != NULL)
		snprintf (user, sizeof (user), "%s", login);
	      else if ((pw = getpwuid (getuid ())) == NULL)
		return 0;
	    }
	  if (pw == NULL && (pw = getpwnam (user)) == NULL)
	    return 0;
	  snprintf (exp, explen, "%s", pw->pw_dir);
	}
      size_t len = strlen (exp);
      strncat (exp, file, explen - len);
      return 1;
    }
  return 0;
}

/* undefine these so that tfopen and topen will work */
#undef fopen
#undef open

/* open a file just as does fopen, but allow a leading ~ to specify a home
   directory */
FILE *
tfopen (file, mode)
     char *file;
     char *mode;
{
  char buf[1024];
  extern int errno;

  if (tilde (file, buf, sizeof (buf)))
    return (fopen (buf, mode));
  errno = ENOENT;
  return NULL;
}

/* open a file just as does open, but expand a leading ~ into a home directory
   name */
int
topen (file, flags, mode)
     char *file;
     int flags, mode;
{
  char buf[1024];
  extern int errno;

  if (tilde (file, buf, sizeof (buf)))
    return (open (buf, flags, mode));
  errno = ENOENT;
  return -1;
}
