##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: FSI.pm,v 1.1 1996/12/02 11:03:52 ehood Exp $ %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::FSI module.
##---------------------------------------------------------------------------##
##  Copyright (C) 1996  Earl Hood, ehood@medusa.acs.uci.edu
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
## 
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##  
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##---------------------------------------------------------------------------##
##  Usage:
##	The following is an example of how to use this module:
##
##	    use FileHandle;
##	    use SGML::FSI qw(OpenSysId);
##
##	    $fh = &OpenSysId($sysid, $base);
##	    # ...
##
##  Notes:
##	Currently, this module does not really support FSIs.  The
##	module exists to provide a stable(?) interface to resolving
##	sysids to perl filehandles.  Someday, FSI support will be
##	added as time permits and decent documentation exists.
##
##	The module's primary user will be the entity manager.
##
##	All sysids are treated as pathnames of files.
##---------------------------------------------------------------------------##

package SGML::FSI;

use Exporter ();
@ISA = qw( Exporter );

@EXPORT = qw( &OpenSysId );

$VERSION = "0.01";

use FileHandle;
use OSUtil;

BEGIN {

    ## Grab environment variables
    @SGML_SEARCH_PATH = split(/$PATHSEP/o, $ENV{SGML_SEARCH_PATH});
	# SGML_SEARCH_PATH defines a list of paths for searching
	# for relative file sysids.
}

##**********************************************************************##
##	PUBLIC ROUTINES
##**********************************************************************##

##----------------------------------------------------------------------
##	OpenSysId() returns a reference to a Perl filehandle for a
##	sysid.  undef is returned if sysid could not be opened.
##
sub OpenSysId {
    my($sysid, $base) = @_;

    return undef  unless $sysid =~ /\S/;

    ## Check if sysid an absolute pathname
    if (&OSUtil::is_absolute_path($sysid)) {
	return new FileHandle $sysid;
    }

    ## See if base can be used
    if ($base) {
	$sysid = $base . $DIRSEP . $sysid;
	return new FileHandle $sysid;
    }

    ## See if sysid in current directory
    if (-e $sysid) {
	return new FileHandle $sysid;
    }

    ## If reached here, got to search for sysid
    my $pathname;
    foreach (@SGML_SEARCH_PATH) {
	$pathname = $_ . $DIRSEP . $sysid;
	if (-e $pathname) {
	    return new FileHandle $pathname;
	}
    }

    undef;
}

##----------------------------------------------------------------------
1;
