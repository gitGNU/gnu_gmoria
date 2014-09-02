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

info_TEXINFOS = moria-rcc.texi
moria_rcc_TEXINFOS = usage package.texi

usage: ${top_builddir}/utils/rcc/src/$(GAME_NAME)-rcc
	@${top_builddir}/utils/rcc/src/$(GAME_NAME)-rcc --help > usage

# here we have an empty install-am rule, so that this info page won't get 
# installed.  meanwhile, we can still create a pdf or html pages.
#install-am:

AM_MAKEINFOFLAGS = --no-split --no-headers
EXTRA_DIST = package.texi.in
CLEANFILES = usage moria-rcc.info
