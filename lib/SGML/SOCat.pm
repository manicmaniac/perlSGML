##---------------------------------------------------------------------------##
##  File:
##      %Z% $Id: SOCat.pm,v 1.9 1997/08/27 21:01:22 ehood Exp $  %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::SOCat class.  POD documentation
##	at the end of this file.
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
##  You should have received a copy of the GNU General Public
##  License along with this program; if not, write to the Free
##  Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
##  MA  02111-1307, USA.
##---------------------------------------------------------------------------##

package SGML::SOCat;

use vars qw(@ISA @EXPORT $VERSION
	    $MaxErrs
	    $com $lit $lit_ $lita $lita_ $quotes
	    $_hcnt %_name_sysid_entries %_scalar_entries
	    %Entries);

use Exporter ();
@ISA = qw( Exporter );

@EXPORT = ();
$VERSION = "0.02";

$MaxErrs= 10;		# Max number of errors before aborting

$com	= q/--/;	# Comment delimiter
$lit	= q/"/;		# Literal delimiter
$lit_	= q/"/;
$lita	= q/'/;		# Literal (alternate) delimiter
$lita_	= q/'/;
$quotes	= q/"'/;	# All literal delimiters

$_hcnt	= 0;		# Filehandle count

%_name_sysid_entries = (

    'DELEGATE'	=> { argc => 2, argt => [1,0] },
    'DOCTYPE' 	=> { argc => 2, argt => [0,0] },
    'DTDDECL'	=> { argc => 2, argt => [1,0] },
    'ENTITY%' 	=> { argc => 2, argt => [0,0] },
    'ENTITY'  	=> { argc => 2, argt => [0,0] },
    'LINKTYPE'	=> { argc => 2, argt => [0,0] },
    'NOTATION'	=> { argc => 2, argt => [0,0] },
    'PUBLIC'  	=> { argc => 2, argt => [1,0] },
    'SYSTEM'	=> { argc => 2, argt => [0,0] },

);
%_scalar_entries = (

    'DOCUMENT'	=> { argc => 1, argt => [0] },
    'SGMLDECL'	=> { argc => 1, argt => [0] },

);
%Entries	= (		# Legal catalog entries
    %_name_sysid_entries,
    %_scalar_entries,

    'BASE'     	=> { argc => 1, argt => [0] },
    'CATALOG' 	=> { argc => 1, argt => [0] },
    'OVERRIDE'	=> { argc => 1, argt => [0] },

);

##**********************************************************************##
##	PUBLIC METHODS
##**********************************************************************##

##----------------------------------------------------------------------
##	new() constructor.
##
sub new {
    my $this = { };
    my $class = shift;
    my $file = shift;

    bless $this, $class;
    $this->_reset();

    my $stat = 1;
    if (ref($file)) {	# if reference, assume reference to filehandle
	my $name = shift;
	$stat = $this->read_handle($file, $name);
    } elsif (defined($file)) {
	$stat = $this->read_file($file);
    }

    $stat ? $this : undef;
}

##----------------------------------------------------------------------
##	read_file() reads the catalog designated by the filename
##	passed in.  A 1 is returned on success, and a 0 on failure.
##
sub read_file {
    my $this = shift;
    my $fname = shift;
    my $handle = "CAT" . $_hcnt++;

    if (open($handle, $fname)) {
	$this->read_handle(\*$handle, $fname);
    } else {
	$this->_errMsg(qq{Unable to open "$fname"});
    }
}

##----------------------------------------------------------------------
##	read_handle() reads the catalog designated by the filehandle
##	passed in.  A 1 is returned on success, and a 0 on failure.
##	A reference to a filehandle should passed in to avoid problems
##	with package scoping.
##
sub read_handle {
    my $this  = shift;
    my ($fh, $fname) = @_;

    ## Push file data onto stack
    push(@{$this->{_File}}, { _FH => $fh,
			      _filename => $fname,
			      _buf => undef,
			      _line_num => 0,
			      _override => 0,
			      _base => '',
			      _errcnt => 0,
			      _peek => [ ],
			    } );

    ## We use an eval block to capture die's
    eval {
	my($token, $islit, $i, $tmp, $override, $base);
	my(@args);
	my $fref = $this->{_File}[$#{$this->{_File}}];

	ENTRY: while (1) {

	    ## Get next entry token
	    ($token, $islit) = $this->_get_next_token();
	    last ENTRY  unless defined($token);

	    ## Check if literal
	    if ($islit) {
		$this->_errMsg("Line ", $fref->{_line_num},
			       ": Spurious literal '$token'");
		next ENTRY;
	    }

	    ## Check if entry is recognized
	    $token =~ tr/a-z/A-Z/;
	    if (!$Entries{$token}) {
		$this->_errMsg("Line ", $fref->{_line_num},
			       ": Unrecognized entry '$token'");
		
		## Skip passed any arguments to unrecognized entry
		while (1) {
		    ($token, $islit) = $this->_get_next_token(1);
		    last ENTRY  unless defined($token);
		    last  	unless $islit;
		    $this->_get_next_token();
		}
		next ENTRY;
	    }

	    ## Have known entry ##

	    ## Get arguments for entry
	    @args = ();
	    for ($i = 0; $i < $Entries{$token}{argc}; $i++) {
		if (!defined($tmp = ($this->_get_next_token())[0])) {
		    $this->_errMsg("Unexpected EOF");
		    last ENTRY;
		}
		## Compress whitespace if required
		if ($Entries{$token}{argt}[$i]) {
		    $tmp =~ s/\s+/ /g;
		}
		push(@args, $tmp);
	    }

	    ## Store entry information
	    $override = $fref->{_override};
	    $base = $fref->{_base};
	    SW: {
		if (defined($_name_sysid_entries{$token})) {
		    $tmp = ($args[0] =~ '%') ? 'ENTITY%' : $token;

		    # Only store entry if not already defined
		    if (!defined($this->{$tmp}{$args[0]})) {
			$this->{$tmp}{$args[0]} = {
			    sysid => $args[1],
			    override => $override,
			    base => $base,
			};

			# Check if DELEGATE and store size of pubid
			# prefix
			if ($tmp eq 'DELEGATE') {
			    push(@{$this->{_DelSizes}{length($args[0])}},
				 $args[0]);
			}
		    }
		    last SW;
		}
		if (defined($_scalar_entries{$token})) {
		    $this->{$token} = {
			sysid => $args[0],
			base => $base,
		    } unless defined $this->{$token};
		    last SW;
		}
		if ($token eq 'BASE') {
		    $fref->{_base} = $args[0];
		    last SW;
		}
		if ($token eq 'OVERRIDE') {
		    $fref->{_override} = ($args[0] =~ /yes/i) ? 1 : 0;
		    last SW;
		}
		if ($token eq 'CATALOG') {
		    $this->read_file($args[0]);
		    last SW;
		}
		$this->_errMsg("Internal Error\n");

	    } # End SW

	} # End ENTRY

    }; # End eval

    if ($@) { warn $@; }

    ## Pop file data off stack
    pop(@{$this->{_File}});

    ## Return status
    $@ ? 0 : 1;
}

##----------------------------------------------------------------------
##	get_public() retrieves the sysid public identifier.
##
##	Usage:
##
##	Scalar context:  Check if pubid has an entry
##	    if ($cat->get_public($pubid)) {
##		...
##	    }
##	Array context:  Retrieve sysid of pubid
##	    ($sysid, $base, $override) = $cat->get_public($pubid);
##
sub get_public {
    my $this = shift;
    my $pubid = shift;
    $pubid =~ s/\s+/ /g;

    wantarray
    ? 
	($this->{PUBLIC}{$pubid}{sysid},
	 $this->{PUBLIC}{$pubid}{base},
	 $this->{PUBLIC}{$pubid}{override})
    :
	defined($this->{PUBLIC}{$pubid});
}

##----------------------------------------------------------------------
##	get_gen_ent() retrieves the sysid general entity name.
##
##	Usage:
##	Scalar context:  Check if general entity name has an entry
##	    if ($cat->get_gen_ent($name)) {
##		...
##	    }
##	Array context:  Retrieve sysid of general entity
##	    ($sysid, $base, $override) = $cat->get_gen_ent($name);
##
sub get_gen_ent {
    my $this = shift;
    my $name = shift;

    wantarray ?
	($this->{ENTITY}{$name}{sysid},
	 $this->{ENTITY}{$name}{base},
	 $this->{ENTITY}{$name}{override})
    :
	defined($this->{ENTITY}{$name});
}

##----------------------------------------------------------------------
##	get_parm_ent() retrieves the sysid for parameter entity name.
##
##	Usage:
##	Scalar context:  Check if parameter entity name has an entry
##	    if ($cat->get_parm_ent($name)) {
##		...
##	    }
##	Array context:  Retrieve sysid of parameter entity
##	    ($sysid, $base, $override) = $cat->get_parm_ent($name);
##
sub get_parm_ent {
    my $this = shift;
    my $name = shift;

    wantarray
    ?
	($this->{'ENTITY%'}{$name}{sysid},
	 $this->{'ENTITY%'}{$name}{base},
	 $this->{'ENTITY%'}{$name}{override})
    :
	defined($this->{'ENTITY%'}{$name});
}

##----------------------------------------------------------------------
##	get_doctype() retrieves the sysid for the entity denoted
##	by document type name.
##
##	Usage:
##	Scalar context:  Check if doctype has an entry
##	    if ($cat->get_doctype($name)) {
##		...
##	    }
##	Array context:  Retrieve sysid of doctype external subset
##	    ($sysid, $base, $override) = $cat->get_doctype($name);
##
sub get_doctype {
    my $this = shift;
    my $name = shift;

    wantarray
    ?
	($this->{DOCTYPE}{$name}{sysid},
	 $this->{DOCTYPE}{$name}{base},
	 $this->{DOCTYPE}{$name}{override})
    :
	defined($this->{DOCTYPE}{$name});
}

##----------------------------------------------------------------------
##	get_linktype() retrieves the sysid for the entity denoted
##	by link type name.
##
##	Usage:
##	Scalar context:  Check if linktype name has an entry
##	    if ($cat->get_linktype($name)) {
##		...
##	    }
##	Array context:  Retrieve sysid of linktype nsmr
##	    ($sysid, $base, $override) = $cat->get_linktype($name);
##
sub get_linktype {
    my $this = shift;
    my $name = shift;

    wantarray
    ?
	($this->{LINKTYPE}{$name}{sysid},
	 $this->{LINKTYPE}{$name}{base},
	 $this->{LINKTYPE}{$name}{override})
    :
	defined($this->{LINKTYPE}{$name});
}

##----------------------------------------------------------------------
##	get_notation() retrieves the sysid for the entity denoted
##	by notation name.
##
##	Usage:
##	Scalar context:  Check if notation has an entry
##	    if ($cat->get_notation($name)) {
##		...
##	    }
##	Array context:  Retrieve sysid of notation
##	    ($sysid, $base, $override) = $cat->get_notation($name);
##
sub get_notation {
    my $this = shift;
    my $name = shift;

    wantarray ?
	($this->{NOTATION}{$name}{sysid},
	 $this->{NOTATION}{$name}{base},
	 $this->{NOTATION}{$name}{override})
    :
	defined($this->{NOTATION}{$name});
}

##----------------------------------------------------------------------
##	get_system() retrieves the sysid for the entity denoted
##	by a system id.
##
##	Usage:
##	Scalar context:  Check if sysid has an entry
##	    if ($cat->get_system($esysid)) {
##		...
##	    }
##	Array context:  Retrieve sysid of a sysid
##	    ($sysid, $base, $override) = $cat->get_system($esysid);
##
sub get_system {
    my $this = shift;
    my $sysid = shift;

    wantarray
    ?
	($this->{SYSTEM}{$sysid}{sysid},
	 $this->{SYSTEM}{$sysid}{base},
	 $this->{SYSTEM}{$sysid}{override})
    :
	defined($this->{SYSTEM}{$sysid});
}

##----------------------------------------------------------------------
##	get_sgmldecl() retrieves the sysid for the SGML declaration.
##
##	Usage:
##	Scalar context:  Check if sgmldecl entry defined
##	    if ($cat->get_sgmldecl()) {
##		...
##	    }
##	Array context:  Retrieve sysid of sgmldecl
##	    ($sysid, $base) = $cat->get_sgmldecl();
##
sub get_sgmldecl {
    my $this = shift;

    wantarray
    ?
	($this->{SGMLDECL}{sysid},
	 $this->{SGMLDECL}{base})
    :
	defined($this->{SGMLDECL});
}

##----------------------------------------------------------------------
##	get_dtddecl() retrieves the sysid for the SGML declaration
##	associated with a doctype external subset pubid.
##
##	Usage:
##	Scalar context:  Check if dtddecl defined
##	    if ($cat->get_dtddecl($pubid)) {
##		...
##	    }
##	Array context:  Retrieve sysid of dtddecl
##	    ($sysid, $base) = $cat->get_dtddecl($pubid);
##
sub get_dtddecl {
    my $this = shift;
    my $pubid = shift;
    $pubid =~ s/\s+/ /g;

    wantarray
    ?
	($this->{DTDDECL}{$pubid}{sysid},
	 $this->{DTDDECL}{$pubid}{base})
    :
	defined($this->{DTDDECL}{$pubid});
}

##----------------------------------------------------------------------
##	get_document() retrieves the sysid for the document entity.
##
##	Usage:
##	Scalar context:  Check if document entity defined
##	    if ($cat->get_document()) {
##		...
##	    }
##	Array context:  Retrieve sysid of document entity
##	    ($sysid, $base) = $cat->get_document();
##
sub get_document {
    my $this = shift;

    wantarray
    ?
	($this->{DOCUMENT}{sysid},
	 $this->{DOCUMENT}{base})
    :
	($this->{DOCUMENT});
}

##----------------------------------------------------------------------
##	get_delegate() checks a pubid to see if a pubid-prefix has
##	been defined that matches the pubid.  If so, then a sysid of
##	a catalog is returned.  The catalog should be used to resolve
##	pubids that match the prefix.
##
##	Usage:
##	Scalar context:  Check if pubid has a prefix entry
##	    if ($cat->get_delegate($pubid)) {
##		...
##	    }
##	Array context:  Retrieve sysid of catalog for pubid
##	    ($sysid, $base) = $cat->get_delegate($pubid);
##
sub get_delegate {
    my $this = shift;
    my $in_pubid = shift;
    my($len, @pubpres);
    my $pubpre = '';

    $in_pubid =~ s/\s+/ /g;

    ## Sort prefixes by size with largest first
    @pubpres = sort { $b <=> $a } keys %{$this->{_DelSizes}};

    ## Check if there is a pubid prefix for in_pubid
    OUTER: foreach $len (@pubpres) {
	INNER: foreach (@{$this->{_DelSizes}{$len}}) {
	    if ($in_pubid =~ /^$_/) {
		$pubpre = $_;
		last OUTER;
	    }
	}
    }
    wantarray
    ?
	($pubpre ? ($this->{DELEGATE}{$pubpre}{sysid},
		    $this->{DELEGATE}{$pubpre}{base}) : ())
    :
	$pubpre ? 1 : 0;
}

##**********************************************************************##
##	PRIVATE METHODS
##**********************************************************************##

##----------------------------------------------------------------------
##	_reset() initializes the data structures for SOCat.
##
sub _reset {
    my $this = shift;

    $this->{_File} = [ ];
}

##----------------------------------------------------------------------
##	_errMsg() prints a formatted error message.  The passed
##	in message is prefixed by the class name and the filename
##	of the file at the top of the stack.
##
sub _errMsg {
    my $this = shift;
    my $fref = $this->{_File}[$#{$this->{_File}}];
    my $prfx = join('', ref($this), ":", $fref->{_filename}, ":");

    ## Output message
    warn $prfx, @_, "\n";

    ## Check if error count over maximum
    my $errcnt = ++$fref->{_errcnt};
    if ($errcnt >= $MaxErrs) {
	die $prfx, "Parsing aborted; too many errors ($errcnt)\n";
    }
}

##----------------------------------------------------------------------
##	_get_next_token() grabs the next token from the file at
##	top of the stack.  If a non-zero argument is passed in,
##	the function will return next token but keep it in the
##	input.  This allows one to peek at the next token.
##
sub _get_next_token {
    my $this = shift;
    my $peeking = shift;

    my $token = undef;
    my $islit = 0;
    my $fref = $this->{_File}[$#{$this->{_File}}];

    ## Check if token cached from previous peek
    if (@{$fref->{_peek}}) {
	($token, $islit) = @{$fref->{_peek}};
	$fref->{_peek} = [ ]  unless $peeking;
    }
    return ($token, $islit)  if defined($token);

    ## Do some aliasing to make things easier
    local(*buf) 	= \$fref->{_buf};
    local(*fh)   	= \$fref->{_FH};
    local(*line_num) 	= \$fref->{_line_num};

    ## Get next token from filehandle
    GETTOKEN: while (1) {

	## Load buffer if empty
	while (!$buf or $buf !~ /\S/) {
	    last GETTOKEN  unless $buf = <$fh>;
	    $line_num = $.;
	}

	## Remove any leading spaces from buffer
	$buf =~ s/^\s+//;

	## Check for comment
	if ($buf =~ s/^$com//o) {
	    while (1) {
		if ($buf =~ /$com/o) {
		    $buf = $';
		    last;
		}
		if (not $buf = <$fh>) {
		    $this->_errMsg("Line $.: ",
				   "Unclosed comment at EOF ",
				   "(comment start: line $line_num)");
		    last GETTOKEN;
		}
	    }
	    $line_num = $.;
	    next GETTOKEN;
	}

	##  Literal Token
	if ($buf =~ s/^([$quotes])//o) {
	    my $q = $1;
	    $islit = 1;
	    $token = '';

	    while (1) {
		if (($q eq $lit_) ? ($buf =~ /$lit/o) :
				    ($buf =~ /$lita/o)) {
		    $token .= $`;
		    $buf = $';
		    last;
		}
		$token .= $buf;
		if (not $buf = <$fh>) {
		    $this->_errMsg("Line $.: ",
				   "Unclosed literal at EOF ",
				   "(literal start: line $line_num)");
		    $line_num = $.;
		    last GETTOKEN;
		}
	    }
	    last GETTOKEN;

	} 

	# Name token
	$buf =~ s/(\S+)\s*//;
	$token = $1;
	last GETTOKEN;
    }

    ## Save token if peeking
    @{$fref->{_peek}} = ($token, $islit)  if $peeking;

    ## Return token
    ($token, $islit);
}

##----------------------------------------------------------------------
1;

__END__

=head1 NAME

SGML::SOCat - SGML Open Catalog parser

=head1 SYNOPSIS

  use SGML::SOCat;
  $soc = new SGML::SOCat "catalog";
  $soc = new SGML::SOCat \*FILEHANDLE;

or

  use SGML::SOCat;
  $soc = new SGML::SOCat;
  $soc->read_file("catalog");
  $soc->read_handle(\*FILEHADNLE);

=head1 DESCRIPTION

B<SGML::SOCat> is an SGML Open Catalog (as defined by
I<SGML Open Technical Resolution 9401:1995> and extensions
defined in I<SP>).  B<SGML::SOCat> is designed to be used
by an entity manager (like B<SGML::EntMan>) for resolving
external entities.

=head1 OBJECT METHODS

Some methods of B<SGML::SOCat> may return the following
information: I<base system identifier in effect> and/or
I<override flag>.  Example:
 
    ($sysid, $base, $override) = $soc->get_public($pubid);

The I<base system identifier in effect> is the base system
identifier to use if the system identifier is relative.
 
The I<override flag> states that the system identifier defined
in the catalog should override the explicit system identifier
specified in a document.

The following methods are defined:

=over 4

=item $soc->B<read_file>($file)

B<read_file> reads the catalog designated by the filename
passed in.  A 1 is returned on success, and a 0 on failure.

=item $soc->B<read_handle>(\*FILEHANDLE, $name)

B<read_handle> reads the catalog designated by the filehandle
passed in.  A 1 is returned on success, and a 0 on failure.
A reference to a filehandle should passed in to avoid problems
with package scoping.

The second argument is optional.  If specified, it is used
as the name of the filehandle for error messages.

=item $soc->B<get_public>($pubid)

B<get_public> retrieves the sysid public identifier.
In a scalar context, 1 is returned if public identifier has
a mapping to a system identifier, else 0 is returned.  For
example:

    if ($soc->get_public($pubid)) {
	...
    }

In an list context, a list of values are returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_public($pubid);

=item $soc->B<get_gen_ent>($gen_entity_name)

B<get_gen_ent> retrieves the sysid for a I<general entity name>.
In a scalar context, the method returns 1 if there is a catalog
entry for the general entity name, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_gen_ent($name);

=item $soc->B<get_parm_ent>($parm_entity_name)

B<get_parm_ent> retrieves the sysid for a I<parameter entity name>.
In a scalar context, the method returns 1 if there is a catalog
entry for the parameter entity name, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_parm_ent($name);

=item $soc->B<get_doctype>($doc_type_name)

B<get_doctype> retrieves the sysid for the entity denoted
by a I<document type name>.
In a scalar context, the method returns 1 if there is a catalog
entry for the document type name, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_doctype($name);

=item $soc->B<get_linktype>($link_type_name)

B<get_linktype> retrieves the sysid for the entity denoted
by a I<link type name>.
In a scalar context, the method returns 1 if there is a catalog
entry for the link type name, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_linktype($name);

=item $soc->B<get_system>($sysid)

B<get_system> retrieves the sysid for the entity denoted
by a I<system identifier>.
In a scalar context, the method returns 1 if there is a catalog
entry for the system identifier, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier>, I<base system identifier in effect>,
and I<override flag>.  Example:

    ($sysid, $base, $override) = $soc->get_system($sysid);

=item $soc->B<get_sgmldecl>()

B<get_doctype> retrieves the sysid for the SGML declaration.
In a scalar context, the method returns 1 if there is a catalog
entry for the SGML declaration, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier> and I<base system identifier in effect>.
Example:

    ($sysid, $base) = $soc->get_sgmldecl();

=item $soc->B<get_dtddecl>($pubid)

B<get_dtddecl> retrieves the sysid for for the SGML declaration
associated with a doctype external subset I<public indentifier>.
In a scalar context, the method returns 1 if there is a catalog
entry for the public indentifier, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier> and I<base system identifier in effect>.
Example:

    ($sysid, $base) = $soc->get_dtddecl($pubid);


=item $soc->B<get_document>()

B<get_document> retrieves the sysid for the document entity.
In a scalar context, the method returns 1 if there is a catalog
entry for the document entity, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier> and I<base system identifier in effect>.
Example:

    ($sysid, $base) = $soc->get_document();

=item $soc->B<get_delegate>($pubid)

B<get_delegate> checks a public identifier to see if a pubid-prefix
has been defined that matches the public identifier.  If so, then a
system identifier of a catalog is returned.  The catalog should be
used to resolve pubids that match the prefix.

In a scalar context, the method returns 1 if there is a delegate
entry for the public identifier, else 0 is returned.  In
a list context, the following list is returned:
I<system identifier> and  I<base system identifier in effect>.
The system identifier is for a catalog that should be used to
resolve the public identifier.
Example:

    ($sysid, $base) = $soc->get_delegate($pubid);

Since B<SGML::SOCat> does not automatically open the returned
catalog to resolve the public identifier, the caller must perform
that function.  For example:

    ($catalog, $base) = $soc->get_delegate($pubid);
    ## Ignore $base for this example
    $soc_del = new SGML::SOCat $catalog;
    ($sysid, $base) = $soc_del->get_delegate($pubid);

See L<SGML::EntMan> for external entity resolution that
automatically handles delegations.

=back

=head1 NOTES

=over 4

=item *

The total maximun number of errors allowed while parsing is
set by the C<$SGML::SOCat::MaxErrs> variable.  The default value
is 10.

=item *

If an error occurs during the instantiation of an B<SGML::SOCat>
object (via the B<new> class method), C<undef> is returned.

=back

=head1 SEE ALSO

SGML::EntMan(3)

perl(1)

=head1 AUTHOR

Earl Hood, ehood@medusa.acs.uci.edu

=cut
