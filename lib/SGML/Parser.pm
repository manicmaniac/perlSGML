##---------------------------------------------------------------------------##
##  File:
##      %Z% %Y% $Id: Parser.pm,v 1.1 1996/12/23 12:42:34 ehood Exp $  %Z%
##  Author:
##      Earl Hood			ehood@medusa.acs.uci.edu
##  Description:
##      This file defines the SGML::Parser class.
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

##########################################################################
##  Status of module:
##
##	o  Doctype declaration and subset not supported.
##      o  Marked sections not supported.
##      o  CDATA/RCDATA element content not supported.
##	o  Current supported features:
##	    -  Start tags (inluded attribute specification list)
##          -  End tags
##          -  Processing instructions
##          -  Comment declarations
##          -  PCDATA
##########################################################################

package SGML::Parser;

use Exporter ();
@ISA = qw( Exporter );
$VERSION = "0.01";
@EXPORT = ();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

use SGML::Syntax qw(:Delims);

##########################################################################

##**********************************************************************##
##	Class Variables
##**********************************************************************##

##  Class level callbacks
##
$CDataFunc	= undef;	# Cdata callback
$STagFunc	= undef;	# Start tag callback
$ETagFunc	= undef;	# End tag callback
$PIFunc		= undef;	# Processing instruction callback
$CommentFunc	= undef;	# Comment callback
	##
	## Each callback is invoked as follows:
        ##
        ##	&$CDataFunc($this, $cdata);
        ##	&$STagFunc($this, $gi, $attr_spec);
        ##	&$ETagFunc($this, $gi);
        ##	&PIFunc($this, $pidata);
        ##	&CommentFunc($this, \@comments);
        ##
        ## $this is a reference to the SGML::Parser object.
        ##
        ## Callbacks can also be registered for a particular instance.
        ## Any registered instance callbacks will be invoked instead
        ## of the class level callbacks.
        
##  Filehandle to send error messages        
##
$ErrHandle	= \*STDERR;

##  Error function callback.  $ErrHandle not used if defined
##
$ErrFunc	= undef;
	##
	## If defined, the error function is invoked as follows:
        ##	
        ##	&$ErrFunc($this, @error_text);
        ##
        ## @error_text signifies that the rest of the arguments
        ## are strings, when concatenated together, is the error
        ## message.  The line number and label of the input where
        ## error occured can be retrieved by the get_line_no and
        ## get_input_label methods of the passed in parser object.

##########################################################################

##**********************************************************************##
##	PUBLIC METHODS
##**********************************************************************##

##----------------------------------------------------------------------
##	new() constructor.
##
sub new {
    my $this = { };
    my $class = shift;
    
    $this->{_string} = undef;	# Input string
    $this->{_fh} = undef;	# Input file handle
    $this->{_filename} = '';	# Input filename of handle (for diagnostic
    				#     purposes)
    $this->{_buf} = '';		# Working buffer
                                
    ## Instance level callbacks; override class level                            
    $this->{CDataFunc}	= undef;	# Cdata callback
    $this->{STagFunc}	= undef;	# Start tag callback
    $this->{ETagFunc}	= undef;	# End tag callback
    $this->{PIFunc}	= undef;	# Processing instruction callback
    $this->{CommentFunc}= undef;	# Comment callback
    
    ## Instance level error handling; override class level
    $this->{ErrHandle}	= undef;	# Undefined - use class setting
    $this->{ErrFunc}	= undef;	# Undefined - use class setting
    
    bless $this, $class;
    $this;
}


##----------------------------------------------------------------------
##	parse_data() parses an SGML instance specified by either a
##	reference to a filehandle or a reference to a scalar string.
##      If a scalar string, the input will get modified.  Therefore,
##      the callar may need to make a copy before calling parse_data
##      if the original input is needed afterwards.
##
##	The routine calls registered callback for the various events
##	that can occur.  It is up to the callbacks to make sense of
##      the data.
##
##	Example usage:
##
##	    $parser->parse_data(\*FILE, "file.sgm", $init_buffer_txt,
##				$line_no_start);
##
##	Only the first argument is required.  The other are optional.
##        
sub parse_data {
    my $this = shift;		# Self reference
    my $in = shift;		# Input (filehandle or a string reference)
    $this->{_label} = shift;	# Input label (Optional)
    my $buf = shift || '';	# Initial buffer (Optional)
    $this->{_ln} = shift || 0;	# Starting line number (Optional).
    
    my $before, $after, $type, $tmp;
    my $m1;
    
    ## Set values for subsequent calls to _get_line()
    if (ref($in) eq 'SCALAR') {
        $this->{_string} = $in;
        $this->{_fh} = undef;
    } else {
        $this->{_string} = undef;
        $this->{_fh} = $in;
    }

    ## Parse input
    LOOP: while (defined($buf)) {
    
    	# Fill working buffer if empty
    	if ($buf eq '') {
            last LOOP  unless defined($buf = $this->_get_line());
        }
        
        # Check for markup.  Choose match that occurs earliest in
        # string.  This stuff adds more time to parsing, but supports
        # arbitrary values of the delimiters. (Size of delimiter
        # check needs to be added)
        
        ($before, $after, $type, $m1) = (undef,'','','');
        if ($buf =~ /$mdo/o) {			# Markup declaration
            if (!defined($before) or length($before) > length($`)) {
	        $before = $`;  $after = $';
                if ($after =~ s/^$comm//o) {	    # Comment declaration
                    $type = $comm_;
                } else {			    # Unsupported
                    $this->_errMsg("Unsupported markup declaration");
	            ($before, $after, $type) = (undef,'','');
                }
            }
        }
        if ($buf =~ /$etago([$namestart])/o) {	# End tag
            if (!defined($before) or length($before) > length($`)) {
                $before = $`;  $m1 = $1;  $after = $';
                $type = $etago_;
            }
        }
        if ($buf =~ /$stago([$namestart])/o) {	# Start tag
            if (!defined($before) or length($before) > length($`)) {
	        $before = $`;  $m1 = $1;  $after = $';
	        $type = $stago_;
            }
        }
        if ($buf =~ /$pio/o) {			# Processing instruction
            if (!defined($before) or length($before) > length($`)) {
	        $before = $`;  $after = $';
	        $type = $pio_;
            }
        }
        
        ## Invoke cdata callback if any before text
        $this->_invoke_cb('CDataFunc', $before)
            unless $before eq '';

        ## End tag
        if ($type eq $etago_) {
	    $gi = $m1;
	    $buf = $after;
    
    	    # Get rest of generic identifier
            if ($buf =~ s/^([$namechars]*)\s*//o) {
	        $gi .= $1;
	    }
        
            # Read up to tagc
            ETAG: while (1) {
                if ($buf =~ /$tagc/o) {
            	    $buf = $';
                    last ETAG;
                }
                if (!defined($buf = $this->_get_line())) {
                    $this->_errMsg("Unexpected EOF; end tag not closed");
                }
            }
            $this->_invoke_cb('ETagFunc', $gi);
            next LOOP;
        }
        
        ## Start tag
        if ($type eq $stago_) {
	    $gi = $m1;
	    $buf = $after;
    
    	    # Get rest of generic identifier
            if ($buf =~ s/^([$namechars]*)\s*//o) {
	        $gi .= $1;
	    }
        
            # Get attribute specification list and tagc
            $attr = '';
            STAG: while (1) {
                if ($buf =~ /$tagc/o) {
                    $attr = $`;  $tmp = $';
                    if (!_open_lit($attr)) {
	                $buf = $tmp;
                        last STAG;
                    }
                }
                if (!defined($tmp = $this->_get_line())) {
                    $this->_errMsg("Unexpected EOF; start tag not finished");
                    $buf = undef;
                    last STAG;
                }
                $buf .= $tmp;
            }
            $this->_invoke_cb('STagFunc', $gi, $attr);
            next LOOP;
        }
        
        ## Processing instruction
        if ($type eq $pio_) {
	    $buf = $after;
            $tmp = '';
        
            # Read up to tagc
            PI: while (1) {
                if ($buf =~ /$pic/o) {
            	    $tmp .= $`;  $buf = $';
                    last PI;
                }
                $tmp .= $buf;
                if (!defined($buf = $this->_get_line())) {
                    $this->_errMsg("Unexpected EOF; PI not closed");
                }
            }
            $this->_invoke_cb('PIFunc', $tmp);
            next LOOP;
        }
        
        ## Comment declaration
        if ($type eq $comm_) {
            $buf = $after;
            
            my @comms;
            # Outer loop for comment declaration as a whole
            COMDCL: while (1) {
            	$tmp = '';
                
                # Inner loop for each comment block in declaration
                COMM: while (1) {
                    if ($buf =~ /$comm/o) {
            	        $tmp .= $`;  $buf = $';
                        last COMM;
                    }
                    $tmp .= $buf;
                    if (!defined($buf = $this->_get_line())) {
                        $this->_errMsg("Unexpected EOF; Comment not closed");
                        last COMM;
                    }
                }
                # Push comment block on list
                push(@comms, $tmp);
                last COMM  unless defined($buf);
                
                # Check for declaration close or another comment block
                while ($buf !~ /\S/) {
                    if (!defined($buf = $this->_get_line())) {
                        $this->_errMsg("Unexpected EOF; Comment declaration ",
                        	       "not closed");
                        last COMDCL;
                    }
                }
                if ($buf =~ s/^\s*$comm//o) {
                    next COMDCL;
                } elsif ($buf =~ s/^\s*$mdc//o) {
                    last COMDCL;
                } else {	# punt
                    $this->_errMsg("Invalid cdata outside of comment");
                    next COMDCL;
                }
            }
            $this->_invoke_cb('CommentFunc', \@comms);
        }
    
    	## If not markup, invoke cdata callback
        $this->_invoke_cb('CDataFunc', $buf);
        $buf = '';
    }
}

##----------------------------------------------------------------------
##	get_line_no() retrieves the current line number of the input.
##	Method useful in callback routines.
##
sub get_line_no {
    my $this = shift;
    $this->{_ln};
}

##----------------------------------------------------------------------
##	get_input_label() retrieves the label given to the input being
##	parsed.  Label is defined when the parse_data method is called.
##	Method useful in callback routines.
##
sub get_input_label {
    my $this = shift;
    $this->{_label};
}

##########################################################################

##**********************************************************************##
##	PRIVATE METHODS
##**********************************************************************##

sub _invoke_cb {
    my $this = shift;
    my $func = shift;
    
    if (defined(&{$rout = $this->{$func}}) ||
        defined(&{$rout = $$func})) {
        
	&$rout($this, @_);
    }
}

##----------------------------------------------------------------------
##	_get_line() retrieves the next line from input.  undef is
##	returned if end of input is reached.
##
sub _get_line {
    my $this = shift;
    my $ret = undef;
    my $sref, $fh;
    
    if (defined($fh = $this->{_fh})) {
        $ret = <$fh>;
        
    } elsif (defined($sref = $this->{_string})) {
    
        if ($$sref =~ s%(.*?${/})%%o) {
            $ret = $1;
        } elsif ($$sref ne '') {
            $ret = $$sref;
            $this->{_string} = undef;
        }
    }
    if (defined($ret)) {
    	if (defined($fh)) {
	    $this->{_ln} = $.;
        } else {
	    $this->{_ln}++;
        }
    }
    $ret;
}

##----------------------------------------------------------------------
##	_errMsg() prints an error message.
##
sub _errMsg {
    my $this = shift;
    
    if (defined($this->{ErrFunc}) || defined($ErrFunc)) {
    	$this->_invoke_cb('ErrFunc', @_);
        
    } else {
        my $fh = $this->{ErrHandle} || $ErrHandle;
        
        if (defined($fh)) {
	    my $label = $this->{_label};
	    my $line = $this->{_ln};
            
            print $fh (ref($this), ":$label:Line $line:", @_, "\n");
        }
    }
}

##**********************************************************************##
##	PRIVATE PACKAGE ROUTINES
##**********************************************************************##

##----------------------------------------------------------------------
##	_open_lit() returns true if string has a literal that is not
##	closed.  Else it returns false.
##
sub _open_lit {
    my $str = $_[0];
    my($q, $after);

    while ($str =~ /([$quotes])/o) {
	$q = $1;
	$after = $';
	if (($q eq $lit_ ? ($after =~ /($lit)/o) :
			   ($after =~ /($lita)/o)) ) {
	    $str = $';
	} else {
	    return 1;
	}
    }
    0;
}

##----------------------------------------------------------------------
1;

