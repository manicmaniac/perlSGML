##---------------------------------------------------------------------------
##  File:
##	%Z% %Y% $Id: sgml.pl,v 1.1 1996/09/30 13:13:26 ehood Exp $ %Z%
##  Author:
##	Earl Hood, ehood@medusa.acs.uci.edu
##---------------------------------------------------------------------------
##  Copyright (C) 1994  Earl Hood, ehood@medusa.acs.uci.edu
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

package sgml;

$VERSION = '0.1.0';

##---------------------------------------------------------------------------
##	SGMLread_sgml() reads SGML markup.  The *array_r is the returned
##	array that contains tags separated from text.  I.e. read_sgml()
##	splits the markup tags from text.  Each array item is either a
##	markup tag or a text.  The order of tag/text items are the
##	order they appear in the text.
##
##	Argument descriptions:
##	    $handle :	Filehandle containing the SGML instance.
##	    *array_r :	Pointer to array variable to put splitted tag/text.
##
##	Usage:
##	    After read_sgml() is called, one only needs to 'shift' thru
##	    the items to read the SGML.  If the item begins with a
##	    '<' it is a tag, else it is text.
##
##	Notes:
##	    o	All comment declarations, '<!-- -->', are deleted.
##
##	Limitations:
##	    o	read_sgml() is not intended to parse a DTD, or an
##		SGML delcaration statement, '<SGML ...>'.  It is
##		designed to parse SGML instances.
##	    o	Marked sections are not recognized.
##	    o   Element with CDATA content can screw things up if they
##		contain '<' or '>' characters.
##	    o   Attributes with '<' or '>' characters will screw things
##		up.
##
sub main'SGMLread_sgml {
    local($handle, *array_r) = @_;
    local($d) = $/;
    local($txt, $tmp);

    $/ = 0777;		# Slurps entire file
    $tmp = <$handle>;

    ## Delete comment declarations ##
    while ($tmp =~ s/^([^<]*<)//) {
	$txt .= $1;
	if ($tmp =~ s/^!--//) {	# Check if comment declaration
	    chop $txt;
	    while (1) {			# Keep stripping until end of comment
		$tmp =~ s/^([^>]*>)//;
		last if $1 =~ /--\s*>$/ || !$tmp;
	    }
	} else {		# Else skip to next '>'
	    $tmp =~ s/^([^>]*>)//;  $txt .= $1;
	}
    }
    $txt .= $tmp;

    ## Split tags from text
    @array_r = grep($_ ne '', split(/(<[^>]*>)/, $txt));

    ## Restore slurp var
    $/ = $d;
}

1;
