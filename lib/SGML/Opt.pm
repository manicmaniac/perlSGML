##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: Opt.pm,v 1.1 1996/11/14 14:47:42 ehood Exp $ %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::Opt class.
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

package SGML::Opt;

##------------------------------------------------------------------------
##
##	The SGML::Opt module is for programs built using the
##	SGML Perl modules.  This package is designed to provide a
##	common interface to parsing the command-line.  The package
##	already includes common options for SGML::* based programs.
##	Each program can specify there own additional arguments that
##	should be parsed.
##
##	Usage:
##	    use SGML::Opt;
##
##	    &GetOptions( [
##	        'opt1=s',
##	        'opt2=s',
##	    ] );
##
##	    $opt1_string = $OptValues{opt1};
##	    @catfiles = @{$OptValues{catalog}};
##	    # etc ...
##
##	The syntax of specifying command-line option type is the same
##	as document in the Getopt::Long module.  All the command-line
##	option values will be stored in the %OptValues hash.  This
##	hash is automatically exported during the 'use' operation.
##	The hash is indexed by the name of the option.
##
##------------------------------------------------------------------------

use Exporter ();
use Getopt::Long;
@ISA = qw(Exporter GetOpt::Long);

@EXPORT = qw(GetOptions %OptValues);

$VERSION = "0.01";

##------------------------------------------------------------------------
BEGIN {
    ## Define default options
    %_options = ();
    @_options{
	"catalog=s@",		# Catalog files to read
	"debug|verbose",	# Set debuging
	"help",			# Print help message
	"ignore=s@",		# Set parm ents to "INCLUDE"
	"include=s@",		# Set parm ents to "IGNORE"
    };

    ## Init hash that will hold option values
    %OptValues = ();
}

##------------------------------------------------------------------------
##	GetOptions takes an array reference as an argument.  The array
##	contains caller defined option specifications.
##
sub GetOptions {
    my $array_r = shift;

    if (ref($array_r) eq 'ARRAY') {
    	@_options{@$array_r};
    } elsif (ref($array_r) eq 'HASH') {
    	foreach (keys %$array_r) {
	    $_options{$_};
	}
    }

    ## Explicitly call GetOpt's routine to do the actual parsing of @ARGV
    &GetOpt::Long::GetOptions(\%OptValues, keys %_options);
}

##------------------------------------------------------------------------
1;
