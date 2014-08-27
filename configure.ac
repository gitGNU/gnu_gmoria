#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

dnl Copyright (C) 2014 Ben Asselstine
dnl This program is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 3 of the License, or
dnl (at your option) any later version.
dnl 
dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl GNU Library General Public License for more details.
dnl 
dnl You should have received a copy of the GNU General Public License
dnl along with this program; if not, write to the Free Software
dnl Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

AC_PREREQ(2.59)
AC_INIT([gmoria],[5.7.1],[gmoria@nym.hush.com], [], [http://sv.nongnu.org/p/gmoria/])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([src/main.c])
AM_INIT_AUTOMAKE
AM_CONFIG_HEADER(config.h)
AC_CONFIG_MACRO_DIR([m4])

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_MKDIR_P
AC_PROG_YACC

# Checks for header files.
AC_HEADER_STDC

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T

gl_EARLY
gl_INIT
AM_CONDITIONAL([GL_GENERATE_ARGZ_H], [test "x" = x])

AC_CHECK_LIB(curses,initscr,GAME_LIBS="$GAME_LIBS -lcurses",[echo "To build this software, you must install the curses development package."; exit 1])
AC_SUBST(GAME_LIBS)

AC_CHECK_LIB([m],[main],UTIL_LIBS="$UTIL_LIBS -lm",[echo "To build this software, you must have the math library."; exit 1])
AC_SUBST(UTIL_LIBS)


# even though the package name is umoria, we want to call it moria in various
# places
GAME_NAME="moria"
AC_SUBST(GAME_NAME)

# Checks for library functions.

# GNU help2man creates man pages from --help output; in many cases, this
# is sufficient, and obviates the need to maintain man pages separately.
# However, this means invoking executables, which we generally cannot do
# when cross-compiling, so we test to avoid that (the variable
# "cross_compiling" is set by AC_PROG_CC).
if test $cross_compiling = no; then
  AM_MISSING_PROG(HELP2MAN, help2man)
else
  HELP2MAN=:
fi

AC_ARG_ENABLE(utils,
              [  --enable-utils  compile monster and treasure compilers (default=yes)],
              use_utils="$enableval", use_utils="yes")
AM_CONDITIONAL([WANT_UTILS],[test "x$YACC" != "x"])
if test "x$YACC" != "x"; then
  AM_CONDITIONAL([WANT_UTILS],[test $use_utils = "yes"])
else
        echo yacc not present.  not compiling the utilities.
fi

AC_CONFIG_FILES([Makefile 
                 lib/Makefile
                 utils/Makefile
                 utils/mc/Makefile
                 utils/mc/src/Makefile
                 utils/mc/doc/Makefile
                 utils/mc/doc/package.texi
                 utils/tc/Makefile
                 utils/tc/src/Makefile
                 utils/tc/doc/Makefile
                 utils/tc/doc/package.texi
                 utils/rcc/Makefile
                 utils/rcc/src/Makefile
                 utils/rcc/doc/Makefile
                 utils/rcc/doc/package.texi
                 src/Makefile
                 data/Makefile
                 doc/Makefile
                 man/Makefile
		 ])
AC_OUTPUT
