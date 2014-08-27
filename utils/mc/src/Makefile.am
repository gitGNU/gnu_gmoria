#  Copyright (C) 2005, 2010 Ben Asselstine
#  Written by Ben Asselstine
# 
#  mc is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  mc is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with mc; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 

noinst_PROGRAMS = moria-mc
moria_mc_SOURCES=creature.y symtab.c generic.h st.h opts.c opts.h mc.c \
		 creature.h mcheck.c mcheck.h

$(top_builddir)/lib/libgnu.la: 
	make -C $(top_srcdir)/lib

moria_mc_LDADD=$(UTIL_LIBS) $(top_builddir)/lib/libgnu.la
AM_CPPFLAGS=-I$(top_builddir)/lib -I$(top_srcdir)/lib -I$(top_srcdir)/src
AM_CFLAGS = -DGAME_NAME=\"${GAME_NAME}\"
CLEANFILES=creature.c
