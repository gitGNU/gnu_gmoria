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

info_TEXINFOS = moria-mc.texi
moria_mc_TEXINFOS = usage package.texi

usage: ${top_builddir}/utils/mc/src/$(GAME_NAME)-mc
	@${top_builddir}/utils/mc/src/$(GAME_NAME)-mc --help > usage

# here we have an empty install-am rule, so that this info page won't get 
# installed.  meanwhile, we can still create a pdf or html pages.
#install-am:

AM_MAKEINFOFLAGS = --no-split
EXTRA_DIST = package.texi.in
CLEANFILES = usage moria-mc.info
