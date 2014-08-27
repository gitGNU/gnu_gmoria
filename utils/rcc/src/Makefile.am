#  Copyright (C) 2014 Ben Asselstine
#  Written by Ben Asselstine
# 
#  rcc is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  rcc is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with rcc; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 

noinst_PROGRAMS = moria-rcc
moria_rcc_SOURCES=race-class.y symtab.c generic.h st.h opts.c opts.h rcc.c \
		 race-class.h

$(top_builddir)/lib/libgnu.la: 
	make -C $(top_srcdir)/lib

moria_rcc_LDADD=$(UTIL_LIBS) $(top_builddir)/lib/libgnu.la
AM_CPPFLAGS=-I$(top_builddir)/lib -I$(top_srcdir)/lib -I$(top_srcdir)/src
AM_CFLAGS = -DGAME_NAME=\"${GAME_NAME}\"
CLEANFILES=race-class.c
