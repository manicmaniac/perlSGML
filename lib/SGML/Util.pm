##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: Util.pm,v 1.1 1996/12/17 12:50:10 ehood Exp $ %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::Util module.  Module contains
##	utility routines for SGML processing.
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

package SGML::Util;

use SGML::Syntax qw(:Delims);

## Derive from Exporter
use Exporter ();
@ISA = qw(Exporter);

@EXPORT = ();
@EXPORT_OK = ();
%EXPORT_TAGS = ();
$VERSION = "0.01";

##---------------------------------------------------------------------------##
##	SGMLparse_attr_spec parses an attribute specification list
##	into name/value pairs.
##
##	Parameters:
##	    $	: A scalar string representing the SGML attribute
##		  specificaion list.
##
##	Return:
##	    @	: An array of name value pairs.  The calling routine
##		  can assign the return value to a hash to allow
##		  easy access to attribute values.  The name/value
##		  pairs occur in the same order as listed in the
##		  specification list.
##
##	Notes:
##	    o   The stago, gi, and etago should NOT be in the
##		specification list string.
##
##	    o	All attribute names are converted to lowercase.
##
##	    o   Attribute values w/o a name are given a bogus name
##		of the reserved name indicator ('#' in the reference
##		concrete syntax) with a number appended (eg. "#4").
##		This is to handle the case when SHORTTAG is YES.
##
##	    o   Any non-whitespace character is treated as a name
##		character.  This allows the parsing of SGML-like
##		markup.  For example, the following will not generate
##		a complaint:
##
##			  % = 100
##			  width = 100%
##
sub SGMLparse_attr_spec {
    my $spec = shift;
    my $str, $var, $q;
    my (@ret) = ();
    my $n = 0;

    ## Remove beginning whitespace
    ($str = $spec) =~ s/^\s+//;

    LOOP: while (1) {

	## Check for name=value specification
	while ($str =~ /^([^=\s]+)\s*=\s*/) {
	    $var = lc $1;
	    $str = $';
	    if ($str =~ s/^([$quotes])//) {
		$q = $1;
		if (!($q eq $lit_ ? $str =~ s/^([^$lit]*)$lit//o :
				    $str =~ s/^([^$lita]*)$lita//o)) {
		    warn "Warning: Unclosed literal in: $spec\n";
		    push(@ret, $var, $str);
		    last LOOP;
		}
		$value = $1;
	    } else {
		if ($str =~ s/^(\S+)//) {
		    $value = $1;
		} else {
		    warn "Warning: No value after $var in: $spec\n";
		    last LOOP;
		}
	    }
	    $str =~ s/^\s+//;
	    push(@ret, $var, $value);
	}

	## Check if just value specified
	if ($str =~ s/^([$quotes])//) {		# Literal value
	    $q = $1;
	    if (!($q eq $lit_ ? $str =~ s/^([^$lit]*)$lit//o :
				$str =~ s/^([^$lita]*)$lita//o)) {
		warn "Warning: Unclosed literal in: $spec\n";
		push(@ret, $rni_ . $n++, $str);
		last LOOP;
	    }
	    push(@ret, $rni_ . $n++, $1);
	    next LOOP;
	}
	if ($str =~ s/^(\S+)\s*//o) {		# Name value
	    push(@ret, $rni_ . $n++, $1);
	    next LOOP;
	}

	## Probably should never get here
	if ($str =~ /\S/) {
	    warn "Warning: Illegal attribute specification syntax in: ",
		 "$spec\n";
	}
	last LOOP;
    }

    @ret;
}

##---------------------------------------------------------------------------##
1;
