##---------------------------------------------------------------------------##
##  File:
##	%Z% $Id: ISO8859.pm,v 1.1 1997/09/11 17:40:56 ehood Exp $  %Z%
##  Author:
##      Earl Hood       ehood@medusa.acs.uci.edu
##  Description:
##	Module to deal with ISO-8859 data.
##---------------------------------------------------------------------------##
##    Copyright (C) 1997        Earl Hood, ehood@medusa.acs.uci.edu
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
##    02111-1307, USA
##---------------------------------------------------------------------------##

package SGML::ISO8859;

use Exporter;
@ISA = qw( Exporter );

@EXPORT_OK = qw(
    &str2sgml
    &sgml2str
);

##---------------------------------------------------------------------------
##      US-ASCII/Common characters
##---------------------------------------------------------------------------

%Char2Ent = (
  #--------------------------------------------------------------------------
  # Hex Code	Entity Ref	# ISO external entity and description
  #--------------------------------------------------------------------------
    0x26 =>	"amp",  	# ISOnum : Ampersand
    0x3C =>	"lt",   	# ISOnum : Less-than sign
    0x3E =>	"gt",   	# ISOnum : Greater-than sign

    0xA0 =>	"nbsp",  	# ISOnum : NO-BREAK SPACE
);

%Ent2Char = reverse %Char2Ent;

##---------------------------------------------------------------------------
##      Charset specification to mapping
##---------------------------------------------------------------------------

%CharsetSpec2Char2Ent = (
    'us-ascii'    =>	\%SGML::ISO8859::Char2Ent,
    'iso-8859-1'  =>	\%SGML::ISO8859::S1::Char2Ent,
    'iso-8859-2'  =>	\%SGML::ISO8859::S2::Char2Ent,
    'iso-8859-3'  =>	\%SGML::ISO8859::S3::Char2Ent,
    'iso-8859-4'  =>	\%SGML::ISO8859::S4::Char2Ent,
    'iso-8859-5'  =>	\%SGML::ISO8859::S5::Char2Ent,
    'iso-8859-6'  =>	\%SGML::ISO8859::S6::Char2Ent,
    'iso-8859-7'  =>	\%SGML::ISO8859::S7::Char2Ent,
    'iso-8859-8'  =>	\%SGML::ISO8859::S8::Char2Ent,
    'iso-8859-9'  =>	\%SGML::ISO8859::S9::Char2Ent,
    'iso-8859-10' =>	\%SGML::ISO8859::S10::Char2Ent,
);

%CharsetSpec2Ent2Char = (
    'us-ascii'    =>	\%SGML::ISO8859::Ent2Char,
    'iso-8859-1'  =>	\%SGML::ISO8859::S1::Ent2Char,
    'iso-8859-2'  =>	\%SGML::ISO8859::S2::Ent2Char,
    'iso-8859-3'  =>	\%SGML::ISO8859::S3::Ent2Char,
    'iso-8859-4'  =>	\%SGML::ISO8859::S4::Ent2Char,
    'iso-8859-5'  =>	\%SGML::ISO8859::S5::Ent2Char,
    'iso-8859-6'  =>	\%SGML::ISO8859::S6::Ent2Char,
    'iso-8859-7'  =>	\%SGML::ISO8859::S7::Ent2Char,
    'iso-8859-8'  =>	\%SGML::ISO8859::S8::Ent2Char,
    'iso-8859-9'  =>	\%SGML::ISO8859::S9::Ent2Char,
    'iso-8859-10' =>	\%SGML::ISO8859::S10::Ent2Char,
);

##---------------------------------------------------------------------------

###############################################################################
##	Routines
###############################################################################

##---------------------------------------------------------------------------##
##	str2sgml converts a string encoded by $charset to an sgml
##	string where special characters are converted to entity
##	references.
##
##	$return_data = SGML::ISO8859::str2sgml($data, $charset, $only8bit);
##
##	If $only8bit is non-zero, than only 8-bit characters are
##	translated.
##
sub str2sgml {
    my $data 	 =    shift;
    my $charset  = lc shift;
    my $only8bit =    shift;

    my($ret, $offset, $len) = ('', 0, 0);
    my($map);
    $charset =~ tr/_/-/;

    # Get mapping
    if ($charset =~ /iso-8859-(\d+)/) {
	$set = $1;
	require "SGML/ISO8859/S$set.pm";	# Load mapping
	$map = $CharsetSpec2Char2Ent{$charset};
    } else {
	$map = $CharsetSpec2Char2Ent{"us-ascii"};
    }

    # Convert string
    $len = length($data);
    while ($offset < $len) {
	$char = unpack("C", substr($data, $offset++, 1));
	if ($only8bit && $char < 0xA0) {
	    $ret .= pack("C", $char);
	} elsif ($map->{$char}) {
	    $ret .= join('', '&', $map->{$char}, ';');
	} elsif ($Char2Ent{$char}) {
	    $ret .= join('', '&', $Char2Ent{$char}, ';');
	}else {
	    $ret .= pack("C", $char);
	}
    }
    $ret;
}

##---------------------------------------------------------------------------##
##	sgml2str converts a string with sdata entity references to the
##	raw character values denoted by a character set.
##
##	$return_data = SGML::ISO8859::sgml2str($data, $charset);
##
sub sgml2str {
    my $data 	 =    shift;
    my $charset  = lc shift;

    my($map);
    $charset =~ tr/_/-/;

    # Get mapping
    if ($charset =~ /iso-8859-(\d+)/) {
	$set = $1;
	require "SGML/ISO8859/S$set.pm";	# Load mapping
	$map = $CharsetSpec2Ent2Char{$charset};
    } else {
	$map = $CharsetSpec2Ent2Char{"us-ascii"};
    }

    $data =~ s/\&([\w\.\-]+);
	      /defined($map->{$1}) ? sprintf("%c", $map->{$1}) :
		   defined($Ent2Char{$1}) ? sprintf("%c", $Ent2Char{$1}) :
		   "&$1;"
	      /gex;
    $data;
}

##---------------------------------------------------------------------------##
1;

__END__

=head1 NAME

SGML::ISO8859 - routines for handling ISO 8859 character sets

=head1 SYNOPSIS

  use SGML::ISO8859;

  $sgml_str = SGML::ISO8859::str2sgml($data, $charset);
  $data     = SGML::ISO8859::sgml2str($sgml_str, $charset);

=head1 DESCRIPTION

B<SGML::ISO8859> contains routines for handling ISO 8859 character
data for SGML related processing.  The routines defined in the
module can be specified during the B<use> operator to import the
routines into the current name space.  For example:

    use SGML::ISO8859 qw( &str2sgml &sgml2str );

B<SGML::ISO8859> supports the following character sets:
B<us-ascii>,
B<iso-8859-1> (Latin-1),
B<iso-8859-2> (Latin-2),
B<iso-8859-3> (Latin-3),
B<iso-8859-4> (Latin-4),
B<iso-8859-5> (Cyrillic),
B<iso-8859-6> (Arabic),
B<iso-8859-7> (Greek),
B<iso-8859-8> (Hebrew),
B<iso-8859-9> (Latin-5),
B<iso-8859-10> (Latin-6).

The following routines are available in B<SGML::ISO8859>:

=head2 str2sgml

    $sgml_str =
    str2sgml(
	$data,
	$charset
    );

B<str2sgml> converts a string so any special characters are
converted to the appropriate entity references.  The characters
'E<lt>', 'E<gt>', and 'E<amp>' will be converted also.

B<Parameters:>

=over 4

=item I<$data>

The scalar string to convert.

=item I<$charset>

The character set of the string.

=back

B<Return:>

=over 4

=item I<$sgml_str>

String with all special characters translated to entity references.

=back

=head2 sgml2str

    $data =
    sgml2str(
	$sgml_str,
	$charset
    );

B<sgml2str> converts a string containing special character
entity references into a "raw" string.

B<Parameters:>

=over 4

=item I<$sgml_str>

The scalar string to convert.

=item I<$charset>

The character set to convert string to.

=back

B<Return:>

=over 4

=item I<$data>

The "raw" string.

=back

=head1 NOTES

=over 4

=item *

The mappings that B<SGML::ISO8859> uses for conversion are
defined by the B<SGML::ISO8859::S#> modules, where B<#> is
the character set number.

=item *

The following character sets,
B<iso-8859-6> (Arabic) and
B<iso-8859-8> (Hebrew),
do not have any official ISO SGML character entity sets.
B<SGML::ISO8859> uses an unoffical set.  To see the mappings
defined, see the B<SGML::ISO8859::S6> and B<SGML::ISO8859::S8>
modules.

=back

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Earl Hood, ehood@medusa.acs.uci.edu

=cut
