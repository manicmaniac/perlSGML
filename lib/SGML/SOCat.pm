##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: SOCat.pm,v 1.1 1996/11/13 15:29:08 ehood Exp $ %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SOCat class.
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

package SOCat;

use Exporter ();
@EXPORT = ();
$VERSION = 0.01;

BEGIN {

    @SGML_SEARCH_PATH = ();	# List of paths to find sysids
    $MaxErrs	= 10;		# Max number of errors before aborting

    $com	= q/--/;	# Comment delimiter
    $lit	= q/"/;		# Literal delimiter
    $lit_	= q/"/;
    $lita	= q/'/;		# Literal (alternate) delimiter
    $lita_	= q/'/;
    $quotes	= q/"'/;	# All literal delimiters

    $_hcnt	= 0;		# Filehandle count

    %_name_sysid_entries = (
	'PUBLIC'  	=> 2,
	'ENTITY'  	=> 2,
	'ENTITY%' 	=> 2,
	'DOCTYPE' 	=> 2,
	'LINKTYPE'	=> 2,
	'NOTATION'	=> 2,
	'SYSTEM'	=> 2,
	'DELEGATE'	=> 2,
    );
    %_scalar_entries = (
	'SGMLDECL'	=> 1,
	'DOCUMENT'	=> 1,
	'BASE'     	=> 1,
    );

    %Entries	= (		# Legal catalog entries
	%_name_sysid_entries,
	%_scalar_entries,
	'CATALOG' 	=> 1,
	'OVERRIDE'	=> 1,
    );

}

##**********************************************************************##
##	PUBLIC METHODS
##**********************************************************************##

##----------------------------------------------------------------------
##	new() constructor.
##
sub new {
    my $this = { };
    my $class = shift;
    bless $this, $class;
    $this->_reset();
    $this;
}

##----------------------------------------------------------------------
sub read_file {
    my $this = shift;
    my $fname = shift;
    my $handle = "CAT" . $_hcnt++;

    if (open($handle, $fname)) {
	$this->read_handle(\*$handle, $fname);
    } else {
	$this->_errMsg("Unable to open $fname");
    }
}

##----------------------------------------------------------------------
sub read_handle {
    my $this  = shift;
    my ($fh, $fname) = @_;

    ## Push file data onto stack
    push(@{$this->{_File}}, { _FH => $fh,
			      _filename => $fname,
			      _buf => undef,
			      _line_num => 0,
			      _override => 0,
			      _errcnt => 0,
			      _peek => [ ],
			    } );

    ## We use an eval block to capture die's
    eval {
	my $token, $islit, $i, $tmp, $override;
	my @args;
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
	    for ($i = 0; $i < $Entries{$token}; $i++) {
		if (!defined($tmp = ($this->_get_next_token())[0])) {
		    $this->_errMsg("Unexpected EOF");
		    last ENTRY;
		}
		push(@args, $tmp);
	    }

	    ## Store entry information
	    $override = $fref->{_override};
	    SW: {
		if (defined($_name_sysid_entries{$token})) {
		    $tmp = ($args[0] =~ '%') ? 'ENTITY%' : $token;
		    $this->{$tmp}{$args[0]} = {
			sysid => $args[1],
			override => $override,
		    }  unless defined($this->{$tmp}{$args[0]});
		    last SW;
		}
		if (defined($_scalar_entries{$token})) {
		    $this->{$token} = $args[0]
			unless defined $this->{$token};
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

