#  Copyright (C) 2014 Ben Asselstine
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

staticdatadir = ${pkgdatadir}
staticdata_DATA = news origcmds.hlp owizcmds.hlp roglcmds.hlp rwizcmds.hlp version.hlp welcome.hlp

dynamicdatadir = ${localstatedir}
dynamicdata_DATA = $(GAME_NAME)-scores

EXTRA_DIST = ${staticdata_DATA} ${dynamicdata_DATA} \
	     items.inf mon.inf race-class.inf README

install-data-hook:
	@MKDIR_P@ $(DESTDIR)/${localstatedir}
	touch $(DESTDIR)/${localstatedir}/$(GAME_NAME)-scores
	chmod 0666 $(DESTDIR)/${localstatedir}/$(GAME_NAME)-scores
