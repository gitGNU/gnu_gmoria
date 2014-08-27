#  Copyright (C) 2014 Ben Asselstine
#  Written by Ben Asselstine
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Library General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
bin_PROGRAMS = moria
moria_SOURCES = monsters_tables.c monsters_constant.h  treasure_tables.c treasure_constant.h constant.h tables.c create.c creature.c death.c desc.c dungeon.c eat.c externs.h files.c generate.c help.c io.c magic.c main.c misc1.c misc2.c misc3.c misc4.c monsters.c moria1.c moria2.c moria3.c moria4.c player.c potions.c prayer.c recall.c rnd.c save.c scrolls.c sets.c signals.c spells.c staffs.c store1.c store2.c treasure.c types.h unix.c variable.c wands.c wizard.c creature_constant.h primitives.h object_constant.h treasure_type.h player_constant.h creature_type.h race_class_types.h race_class_constant.h race_class_tables.c

if WANT_UTILS

treasure_constant.h: $(top_srcdir)/data/items.inf $(top_builddir)/utils/tc/src/$(GAME_NAME)-tc
	$(top_builddir)/utils/tc/src/$(GAME_NAME)-tc --constants $(top_srcdir)/data/items.inf > treasure_constant.h

treasure_tables.c: $(top_srcdir)/data/items.inf $(top_builddir)/utils/tc/src/$(GAME_NAME)-tc
	$(top_builddir)/utils/tc/src/$(GAME_NAME)-tc $(top_srcdir)/data/items.inf > treasure_tables.c

monsters_constant.h: $(top_srcdir)/data/mon.inf $(top_builddir)/utils/mc/src/$(GAME_NAME)-mc
	$(top_builddir)/utils/mc/src/$(GAME_NAME)-mc --constants $(top_srcdir)/data/mon.inf > monsters_constant.h

monsters_tables.c: $(top_srcdir)/data/mon.inf $(top_builddir)/utils/mc/src/$(GAME_NAME)-mc
	$(top_builddir)/utils/mc/src/$(GAME_NAME)-mc $(top_srcdir)/data/mon.inf > monsters_tables.c

race_class_constant.h: $(top_srcdir)/data/race-class.inf $(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc
	$(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc --constants $(top_srcdir)/data/race-class.inf > race_class_constant.h

race_class_tables.c: $(top_srcdir)/data/race-class.inf $(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc
	$(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc $(top_srcdir)/data/race-class.inf > race_class_tables.c

CLEANFILES=monsters_tables.c monsters_constant.h \
	   treasure_tables.c treasure_constant.h \
	   race_class_tables.c race_class_constant.h
endif

moria_LDADD = $(GAME_LIBS)
AM_CFLAGS = -DSYSCONFDIR=\"${sysconfdir}\" -DPKGDATADIR=\"${pkgdatadir}\" -DLOCALSTATEDIR=\"${localstatedir}\" -DGAME_NAME=\"${GAME_NAME}\"
BUILT_SOURCES=monsters_tables.c monsters_constant.h \
	      treasure_tables.c treasure_constant.h \
	      race_class_tables.c race_class_constant.h
