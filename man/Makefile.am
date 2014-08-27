#  Copyright (C) 2014 Ben Asselstine
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

man_MANS = $(GAME_NAME).6

if WANT_UTILS
man_MANS += $(GAME_NAME)-mc.1 $(GAME_NAME)-tc.1 $(GAME_NAME)-rcc.1 
endif

EXTRA_DIST = $(man_MANS)
MAINTAINERCLEANFILES = $(man_MANS)
CLEANFILES = $(man_MANS)

mandeps = $(top_srcdir)/configure.ac

$(GAME_NAME).6: $(top_builddir)/src/$(GAME_NAME) $(mandeps)
	$(HELP2MAN) --name="turn-based action-strategy game" --section="6" --info-page="$(GAME_NAME)" $(top_builddir)/src/$(GAME_NAME) -o $@

$(GAME_NAME)-mc.1: $(top_builddir)/utils/mc/src/$(GAME_NAME)-mc $(mandeps)
	$(HELP2MAN) --name="monster compiler for gmoria" --section="1" --info-page="$(GAME_NAME)-mc" $(top_builddir)/utils/mc/src/$(GAME_NAME)-mc -o $@

$(GAME_NAME)-tc.1: $(top_builddir)/utils/tc/src/$(GAME_NAME)-tc $(mandeps)
	$(HELP2MAN) --name="treasure compiler for gmoria" --section="1" --info-page="$(GAME_NAME)-tc" $(top_builddir)/utils/tc/src/$(GAME_NAME)-tc -o $@

$(GAME_NAME)-rcc.1: $(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc $(mandeps)
	$(HELP2MAN) --name="race & class compiler for gmoria" --section="1" --info-page="$(GAME_NAME)-rcc" $(top_builddir)/utils/rcc/src/$(GAME_NAME)-rcc -o $@
