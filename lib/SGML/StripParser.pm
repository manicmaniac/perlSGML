##---------------------------------------------------------------------------##
##  File:
##      %Z% $Id: StripParser.pm,v 1.1 1997/09/11 17:40:56 ehood Exp $  %Z%
##  Author:
##      Earl Hood       ehood@medusa.acs.uci.edu
##  Description:
##      Class for stripping tags from SGML document instances.
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

package SGML::StripParser;

use SGML::Parser;
@ISA = qw( SGML::Parser );

use SGML::ISO8859 qw( &sgml2str );
use SGML::Util;

##**********************************************************************##
##	Public Methods
##**********************************************************************##

sub new {
    my $this = new SGML::Parser;
    my $class = shift;
    $this->{'_stripout'}{'_fh'}	   = \*STDOUT;
    $this->{'_stripout'}{'_html'}	   = 0;
    $this->{'_stripout'}{'_url'}	   = '';
    $this->{'_stripout'}{_charset} = '';
    $this->{'_stripout'}{_ignents} = {};
    $this->{'_stripout'}{_incents} = {};

    bless $this, $class;
    $this;
}

sub set_outhandle {
    my $this = shift;
    $this->{'_stripout'}{'_fh'} = shift;
}

sub set_html_mode {
    my $this = shift;
    $this->{'_stripout'}{'_html'} = shift;
}

sub set_charset {
    my $this = shift;
    $this->{'_stripout'}{_charset} = shift;
}

sub set_inc_parm_ents {
    my $this = shift;
    $this->{'_stripout'}{_incents}{@_} = ('INCLUDE') x scalar(@_);
}

sub set_ign_parm_ents {
    my $this = shift;
    $this->{'_stripout'}{_ignents}{@_} = ('IGNORE') x scalar(@_);
}

##**********************************************************************##
##	Redefined SGML::Parser Callback Methods
##**********************************************************************##

sub cdata {
    my $this = shift;
    print { $this->{'_stripout'}{'_fh'} } $_[0];
}

sub char_ref {
    my $this = shift;
    my $val = shift;
    my $str = '';

    if ($this->{'_stripout'}{'_charset'}) {
	$str = pack("C", int($val));
    } else {
	$str = defined($Entity{$val}) ? $Entity{$val} : "&#$val;";
    }

    print { $this->{'_stripout'}{'_fh'} } $str;
    '';
}

sub comment_decl { }

sub end_tag {
    my $this = shift;
    my $gi = lc shift;

    if ($this->{'_stripout'}{'_html'} and
	    $gi eq 'a' and
	    $this->{'_stripout'}{'_url'}) {

	print { $this->{'_stripout'}{'_fh'} }
	      ", <URL:$this->{'_stripout'}{'_url'}>, ";

	$this->{'_stripout'}{'_url'} = '';
    }
}

sub entity_ref {
    my $this = shift;
    my $name = shift;
    my $str  = '';

    if ($this->{'_stripout'}{'_charset'}) {
	$str = sgml2str("&$name;", $this->{'_stripout'}{'_charset'});
    } else {
	$str = defined($Entity{$name}) ? $Entity{$name} : "&$name;";
    }
    print { $this->{'_stripout'}{'_fh'} } $str;

    '';
}

sub ignored_data { }

sub marked_sect_close { }

sub marked_sect_open { }

sub parm_entity_ref {
    my $this = shift;
    my $name = shift;

    $this->{'_stripout'}{_ignents}{$name} ||
	$this->{'_stripout'}{_incents}{$name};
}

sub processing_inst { }

sub start_tag {
    my $this = shift;
    my $gi = lc shift;
    my $attr_spec = shift;

    if ($this->{'_stripout'}{'_html'} and $gi eq 'a') {
	my %attr = SGMLparse_attr_spec($attr_spec);
	if ($attr{'href'}) {
	    ($this->{'_stripout'}{'_url'} = $attr{'href'}) =~ s/#.*//;
	}
    }
}

##**********************************************************************##
##	BEGIN block of module
##**********************************************************************##

BEGIN {

    %Entity = (
    #-----------------------------
    # Numeric and Special Graphic
    #-----------------------------
    #   Entity      ASCII substitution
    #   ----------  ------------------
	"half", 	"1/2",	# fraction one-half
	"frac12",	"1/2",
	"189",  	"1/2",
	"frac14",	"1/4",	# fraction one-quarter
	"188",  	"1/4",
	"frac34",	"3/4",	# fraction three-quarters
	"190",  	"3/4",
	"frac18",	"1/8",	# fraction one-eighth
	"frac38",	"3/8",	# fraction three-eighths
	"frac58",	"5/8",	# fraction five-eighths
	"frac78",	"7/8",	# fraction seven-eighths
	"sup1", 	"[1]",	# superscript one
	"185",  	"[1]",
	"sup2", 	"[2]",	# superscript two
	"178",  	"[2]",
	"sup3", 	"[3]",	# superscript three
	"179",  	"[3]",
	"plus", 	"+",	# plus sign
	"plusmn",	"+/-",	# plus-or-minus sign
	"lt",   	"<",	# less-than sign
	"equals",	"=",	# equals sign
	"gt",   	">",	# greater-than sign
	"divide",	"/",	# divide sign
	"times",	"*",	# times sign
	"curren",	"\$",	# general currency sign
	"164",  	"\$",
	"pound",	"L",	# pound sign
	"163",  	"L",
	"dollar",	"\$",	# dollar sign
	"cent", 	"c",	# cent sign
	"162",  	"c",
	"yen",  	"Y",	# yen sign
	"165",  	"Y",
	"num",  	"",	# number sign
	"percent",	"%", 	# percent sign
	"amp",  	"&",	# ampersand
	"ast",  	"*",	# asterisk
	"commat",	"@",	# commercial at
	"lsqb", 	"[",	# left square bracket
	"bsol", 	"\\",	# reverse solidus
	"rsqb", 	"]",	# right square bracket
	"lcub", 	"{",	# left curly bracket
	"verbar",	"|",	# vertical bar
	"rcub", 	"}",	# right curly bracket
	"copy", 	"(C)",	# copyright sign
	"169",  	"(C)",
	"reg",  	"(R)",	# registered sign
	"174",  	"(R)",
	"trade",	"(TM)",	# tradmark
	"brvbar",	"|",	# broken vertical bar
	"166",  	"|",
	"excl", 	"!",	# exclamation mark
	"quot", 	'"',	# quotation mark
	"apos", 	"'",	# apostrophe
	"lpar", 	"(",	# left parenthesis
	"rpar", 	")",	# right parenthesis
	"comma",	",",	# comma
	"lowbar",	"_",	# low line
	"hyphen",	"-",	# hyphen
	"period",	".",	# full stop, period
	"sol",  	"/",	# solidus
	"colon",	":",	# colon
	"semi", 	";",	# semicolon
	"quest",	"?",	# question mark
	"laquo",	"<<",	# angle quotation mark, left
	"171",  	"<<",
	"raquo",	">>",	# angle quotation mark, right
	"187",  	">>",
	"lsquo",	"'",	# single quotation mark, left
	"rsquo",	"'",	# single quotation mark, right
	"ldquo",	'"',	# double quotation mark, left
	"rdquo",	'"',	# double quotation mark, right
	"nbsp", 	" ",	# no break (required) space
	"160",  	" ",
	"shy",  	"-",	# soft hyphen
	"173",  	"-",

    #---------------
    # Added Latin 1
    #---------------
    #   Entity      ASCII substitution
    #   ----------  ------------------
	"aacute",	"a",	# small a, acute accent
	"225",  	"a",
	"Aacute",	"A",	# capital A, acute accent
	"193",  	"A",
	"acirc",	"a",	# small a, circumflex accent
	"226",  	"a",
	"Acirc",	"A",	# capital A, circumflex accent
	"194",  	"A",
	"agrave",	"a",	# small a, grave accent
	"224",  	"a",
	"Agrave",	"A",	# capital A, grave accent
	"192",  	"A",
	"aring",	"a",	# small a, ring
	"229",  	"a",
	"Aring",	"A",	# capital A, ring
	"197",  	"A",
	"atilde",	"a",	# small a, tilde
	"227",  	"a",
	"Atilde",	"A",	# capital A, tilde
	"195",  	"A",
	"auml", 	"a",	# small a, dieresis or umlaut mark
	"228",  	"a",
	"Auml", 	"A",	# capital A, dieresis or umlaut mark
	"196",  	"A",
	"aelig",	"ae",	# small ae diphthong (ligature)
	"230",  	"ae",
	"AElig",	"AE",	# capital AE diphthong (ligature)
	"198",  	"AE",
	"ccedil",	"c",	# small c, cedilla
	"231",  	"c",
	"Ccedil",	"C",	# capital C, cedilla
	"199",  	"C",
	"eth",  	"d",	# small eth, Icelandic
	"240",  	"d",
	"ETH",  	"d",	# capital Eth, Icelandic
	"208",  	"d",
	"eacute",	"e",	# small e, acute accent
	"233",  	"e",
	"Eacute",	"E",	# capital E, acute accent
	"201",  	"E",
	"ecirc",	"e",	# small e, circumflex accent
	"234",  	"e",
	"Ecirc",	"E",	# capital E, circumflex accent
	"202",  	"E",
	"egrave",	"e",	# small e, grave accent
	"232",  	"e",
	"Egrave",	"E",	# capital E, grave accent
	"200",  	"E",
	"euml", 	"e",	# small e, dieresis or umlaut mark
	"235",  	"e",
	"Euml", 	"E",	# capital E, dieresis or umlaut mark
	"203",  	"E",
	"iacute",	"i",	# small i, acute accent
	"237",  	"i",
	"Iacute",	"I",	# capital I, acute accent
	"205",  	"I",
	"icirc",	"i",	# small i, circumflex accent
	"238",  	"i",
	"Icirc",	"I",	# capital I, circumflex accent
	"206",  	"I",
	"igrave",	"i",	# small i, grave accent
	"236",  	"i",
	"Igrave",	"I",	# capital I, grave accent
	"204",  	"I",
	"iuml", 	"i",	# small i, dieresis or umlaut mark
	"239",  	"i",
	"Iuml", 	"I",	# capital I, dieresis or umlaut mark
	"207",  	"I",
	"ntilde",	"n",	# small n, tilde
	"241",  	"n",
	"Ntilde",	"N",	# capital N, tilde
	"209",  	"N",
	"oacute",	"o",	# small o, acute accent
	"243",  	"o",
	"Oacute",	"O",	# capital O, acute accent
	"211",  	"O",
	"ocirc",	"o",	# small o, circumflex accent
	"244",  	"o",
	"Ocirc",	"O",	# capital O, circumflex accent
	"212",  	"O",
	"ograve",	"o",	# small o, grave accent
	"242",  	"o",
	"Ograve",	"O",	# capital O, grave accent
	"210",  	"O",
	"oslash",	"o",	# small o, slash
	"248",  	"o",
	"Oslash",	"O",	# capital O, slash
	"216",  	"O",
	"otilde",	"o",	# small o, tilde
	"245",  	"o",
	"Otilde",	"O",	# capital O, tilde
	"213",  	"O",
	"ouml", 	"o",	# small o, dieresis or umlaut mark
	"246",  	"o",
	"Ouml", 	"O",	# capital O, dieresis or umlaut mark
	"214",  	"O",
	"szlig",	"s",	# small sharp s, German (sz ligature)
	"223",  	"s",
	"thorn",	"p",	# small thorn, Icelandic
	"254",  	"p",
	"THORN",	"P",	# capital THORN, Icelandic
	"222",  	"P",
	"uacute",	"u",	# small u, acute accent
	"250",  	"u",
	"Uacute",	"U",	# capital U, acute accent
	"218",  	"U",
	"ucirc",	"u",	# small u, circumflex accent
	"251",  	"u",
	"Ucirc",	"U",	# capital U, circumflex accent
	"219",  	"U",
	"ugrave",	"u",	# small u, grave accent
	"249",  	"u",
	"Ugrave",	"U",	# capital U, grave accent
	"217",  	"U",
	"uuml", 	"u",	# small u, dieresis or umlaut mark
	"252",  	"u",
	"Uuml", 	"U",	# capital U, dieresis or umlaut mark
	"220",  	"U",
	"yacute",	"y",	# small y, acute accent
	"253",  	"y",
	"Yacute",	"Y",	# capital Y, acute accent
	"221",  	"Y",
	"yuml", 	"y",	# small y, dieresis or umlaut mark
	"255",  	"y",
    );

}

##---------------------------------------------------------------------------##
1;

__END__

=head1 NAME

SGML::StripParser - strip tags from an SGML instance

=head1 SYNOPSIS

  use SGML::StripParser;
  $parser = new SGML::StripParser;
  $parser->parse_data(\*STDIN);

=head1 DESCRIPTION

B<SGML::StripParser> strips SGML tags from document instances
and translates entity references for special characters and
character references to ASCII (or the character set specified by the
B<set_charset> method).  The B<parse_data> method is used to specify
the input filehandle of the SGML document instance.  By default,
output will go to STDOUT, but the output filehandle can be changed
by the B<set_outhandle> method.

=head1 CLASS METHODS

The following class methods are defined:

=head2 B<new> SGML::StripParser

Instantiate a new B<SGML::StripParser> object.

=head1 OBJECT METHODS

The following methods are defined:

=head2 B<parse_data>(\*I<FILEHANDLE>)

Process the document instance specified by I<FILEHANDLE>.

=head2 B<parse_data>(\*I<FILEHANDLE>)

Process the document instance specified by I<FILEHANDLE>.

=head2 B<set_outhandle>(\*I<FILEHANDLE>)

Set the output filehandle to I<FILEHANDLE>.

=head2 B<set_html_mode>(I<$boolean>)

If I<$boolean> is a true value, anchor URLs in HTML documents
will be included in the output.

=head2 B<set_charset>(I<$charset>)

Use I<$charset> as the character set to use while processing.
By default, ASCII is assumed, so entity references for special
characters and character references are mapped to ASCII text.
B<set_charset> allows the entity references and character references
to interpreted under a different character set.  Only the ISO-8859
character sets (1-10) are supported.

=head2 B<set_inc_parm_ents>(I<@names>)

Set the list of parameter entities in I<@names> to "C<INCLUDE>".
This method may be useful for instances that have marked sections
with parameter entity references for the status keyword.

=head2 B<set_ign_parm_ents>(I<@names>)

Set the list of parameter entities in I<@names> to "C<IGNORE>".
This method may be useful for instances that have marked sections
with parameter entity references for the status keyword.

=head1 NOTES

=over 4

=item *

B<SGML::StripParser> is derived from the B<SGML::Parser> class.
Hence, it has the same parsing capbilities and limitation of the
B<SGML::Parser> class.

=back

=head1 SEE ALSO

SGML::ISO8859(3), SGML::Parser(3)

perl(1)

=head1 AUTHOR

Earl Hood, ehood@medusa.acs.uci.edu

=cut
