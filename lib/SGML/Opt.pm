##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: Opt.pm,v 1.3 1997/09/11 17:40:37 ehood Exp $ %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::Opt class.
##---------------------------------------------------------------------------##
##  Copyright (C) 1996,1997	Earl Hood, ehood@medusa.acs.uci.edu
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
##  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
##  USA
##---------------------------------------------------------------------------##

package SGML::Opt;

##------------------------------------------------------------------------
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
##	    AddOptions('opt1=s', "opt1 description",
##	               'opt2=s', "opt2 description");
##	    GetOptions();
##
##	    $opt1_string = $OptValues{'opt1'};
##	    # etc ...
##
##	The syntax of specifying command-line option type is the same
##	as document in the Getopt::Long module (this module inherits
##	from the Getopt::Long module).  All the command-line
##	option values will be stored in the %OptValues hash.  This
##	hash is automatically exported during the 'use' operation.
##	The hash is indexed by the name of the option.
##
##	The following options are predefined by this module:
##
##	    catalog		=> Catalog entity map files
##	    ignore		=> Parmater ents to set to "IGNORE"
##	    include		=> Parmater ents to set to "INCLUDE"
##
##	    debug|verbose	=> Debugging flag
##	    help		=> Help flag
##
##	The caller is responsible for acting upon any option defined
##	on the command-line.
##------------------------------------------------------------------------

use Exporter ();
use Getopt::Long;
@ISA = qw( Exporter GetOpt::Long );

@EXPORT = qw(
    &GetOptions
    &AddOptions
    &Usage
    %OptValues
    $Prog $ProgVersion
    $Debug $Help
    $Synopsis $Description $CopyYears
    @Catalogs
    @IncParmEnts
    @IgnParmEnts
);

$VERSION = "0.02";

use OSUtil;

##------------------------------------------------------------------------
BEGIN {
    ## Define default options
    %_options = (

	"catalog=s@"	=> "Entity mapping catalog",
	"ignore=s@"	=> qq(Set parameter entity to "IGNORE"),
	"include=s@"	=> qq(Set parameter entity to "INCLUDE"),

	"debug|verbose"	=> "Turn on debugging",
	"help"   	=> "Get help",

    );

    ## Init export variables
    %OptValues  = ();

    $Prog 	= $PROG;  # just copy from OSUtil

    $Debug	= 0;
    $Help	= 0;

    $Synopsis	= "$Prog [options]";
    $Description= "";
    $CopyYears	= "1997";

    ## Init private variables
    $_optspec_w	= 20;   	# Width for option spec for Usage
}

##------------------------------------------------------------------------
##	GetOptions takes 2 array references.  The first defines
##	any option specs, and the second a brief description of
##	the options.
##
sub GetOptions {
    AddOptions(@_);

    ## Explicitly call GetOpt's routine to do the actual parsing of @ARGV
    $retcode = Getopt::Long::GetOptions(\%OptValues, keys %_options);

    ## Set export variables
    @Catalogs	= @{$OptValues{"catalog"}};
    @IncParmEnts= @{$OptValues{"include"}};
    @IgnParmEnts= @{$OptValues{"ignore"}};

    $Debug	= $OptValues{"debug"}	     if $OptValues{"debug"};
    $Help	= $OptValues{"help"}	     if $OptValues{"help"};

    $retcode;
}

##------------------------------------------------------------------------
sub Usage {
    my($opt, $v, $o);
    my(@txt);
    my $fmt1 = "%${_optspec_w}s : %s\n";
    my $fmtn = "%${_optspec_w}s   %s\n";

    print STDOUT "Synopsis: $Synopsis\n";
    print STDOUT "Options:\n";
    foreach (sort keys %_options) {
	if (/([=:])(.)/) {
	    $opt = $`;  $o = $1;  $v = $2;

	    if      ($v eq 'i') {
		$v = '<int>';
	    } elsif ($v eq 's') {
		$v = '<str>';
	    } elsif ($v eq 'f') {
		$v = '<float>';
	    } else {
		$v = "<$v>";
	    }
	    if ($o eq ':') {
		$v = " [$v]";
	    } else {
		$v = " $v";
	    }

	} else {
	    $opt = $_;  $v = '';
	}
	@txt = split(/\n/, $_options{$_});
	print STDOUT sprintf($fmt1, "-$opt$v", shift(@txt));
	while (@txt) {
	    print STDOUT sprintf($fmtn, "", shift(@txt));
	}
    }
    if ($Description) {
	print STDOUT "Description:\n", $Description;
	print STDOUT <<"EndOfCopy";

  v$ProgVersion
  Copyright (C) $CopyYears  Earl Hood, ehood\@medusa.acs.uci.edu
  $Prog comes with ABSOLUTELY NO WARRANTY and $Prog may be
  copied only under the terms of the GNU General Public License
  (version 2, or later), which may be found in the distribution.
EndOfCopy

    }
}

##------------------------------------------------------------------------
##	AddOptions adds option specifications for command-line parsing.
##
sub AddOptions {
    my($spec, $desc);

    while (@_) {
	$spec = shift;
	$desc = shift;
	$_options{$spec} = $desc;
    }
}

##------------------------------------------------------------------------

1;

__END__

=head1 NAME

SGML::Opt - command-line option parsing for SGML::* programs

=head1 SYNOPSIS

  use SGML::Opt;

  AddOptions('opt1=s', "opt1 description",
             'opt2=s', "opt2 description");
  GetOptions();
  $opt1_string = $OptValues{'opt1'};

=head1 DESCRIPTION

B<SGML::Opt> provides common base for command-line option parsing
for SGML::* programs.

=head1 EXPORTED VARIABLES

=over 4

=item B<$Debug>

Flag if the B<-debug> or B<-verbose> option was specified.

=item B<$Description>

Variable that the application can define to give a brief description
of the application.  This is defines the description part of the
output generated by the B<Usage> function.

=item B<$Help>

Flag if the B<-help> option was specified.

=item B<$Prog>

Name of the program.

=item B<$Synopsis>

Variable that the application can define that represents the
synopsis output generated by the B<Usage> function.

=item B<@Catalogs>

List of SGML Open catalags specified by the B<-catalog> option.
Mulitple catalogs are specified by mulitple B<-catalog> options.

=item B<@IgnParmEnts>

List of parameter entities that should be defined to "C<IGNORE>" via
the B<-ignore> option.  Mulitple parameter entities are specified by
mulitple B<-ignore> options.

=item B<@IncParmEnts>

List of parameter entities that should be defined to "C<INCLUDE>" via
the B<-include> option.  Mulitple parameter entities are specified by
mulitple B<-include> options.

=item B<%OptValues>

Hash containing values of command-line options.  Keys are
the option name,

=back

=head1 EXPORTED FUNCTIONS

=head2 AddOptions()

B<AddOptions> takes a list of spec/description pairs.  The spec
is the option specification in the same format as the
B<Getopt::Long> module.  Descriptions are brief descriptions
of the associated option.  The descriptions are used by the
B<Usage> function.  Any specifications are added to the current
option specifications and will be used by the B<GetOptions>
function.

B<Parameters:>

=over 4

=item I<@>

List of spec/description pairs.

=back

=head2 GetOptions()

B<GetOptions> parses the command-line (C<@ARGV>).  A
list of spec/description pairs can be passed into
B<GetOptions> just like B<AddOptions>.

B<Parameters:>

=over 4

=item I<@> I<(optional)>

List of spec/description pairs.

=back

B<Return:>

=over 4

=item I<$>

1 on success, 0 on error.

=back

=head2 Usage()

B<Usage> prints out usage information to STDOUT.

=head1 SEE ALSO

Getopt::Long(3)

perl(1)

=head1 AUTHOR

Earl Hood, ehood@medusa.acs.uci.edu

=cut
