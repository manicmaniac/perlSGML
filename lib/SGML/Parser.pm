##---------------------------------------------------------------------------##
##  File:
##      %Z% $Id: Parser.pm,v 1.7 1997/02/07 20:04:39 ehood Exp $  %Z%
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
##	o  Current supported features:
##	    -  Start tags (inluded attribute specification list)
##          -  End tags
##          -  Processing instructions
##          -  Comment declarations
##          -  PCDATA
##	    -  Marked sections (w/parameter ent ref callback)
##	    -  CDATA/RCDATA elements (mode must be set via callbacks)
##########################################################################

package SGML::Parser;

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS 
	    $CDataFunc $CommentFunc $ETagFunc $IgnDataFunc $MSCloseFunc
	    $MSStartFunc $PERefFunc $PIFunc $STagFunc
	    $ErrHandle $ErrFunc
	    $ModePCData $ModeCData $ModeIgnore $ModeMSCData
	    );

use Exporter ();
@ISA = qw( Exporter );
$VERSION = "0.04";
@EXPORT = ();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

use SGML::Syntax qw(:Delims);
use SGML::Util;

##########################################################################

##**********************************************************************##
##	Class Variables
##**********************************************************************##

##  Class level callbacks
##
$CDataFunc	= undef;	# Cdata callback
$CommentFunc	= undef;	# Comment callback
$ETagFunc	= undef;	# End tag callback
$IgnDataFunc	= undef;	# Ignored data callback
$MSCloseFunc	= undef;	# Marked section end callback
$MSStartFunc	= undef;	# Marked section start callback
$PERefFunc	= undef;	# Parameter entity reference callback
$PIFunc		= undef;	# Processing instruction callback
$STagFunc	= undef;	# Start tag callback

	## Each callback is invoked as follows:
        ##
        ##        &$CDataFunc($this, $cdata);
        ##        &CommentFunc($this, \@comments);
        ##        &$ETagFunc($this, $gi);
        ##        &$IgnDataFunc($this, $data);
        ##        &$MSCloseFunc($this);
        ##        &$MSStartFunc($this, $status_keyword, $status_spec);
        ## $str = &PERefFunc($this, $entname);
        ##        &PIFunc($this, $pidata);
        ##        &$STagFunc($this, $gi, $attr_spec);
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

	## If defined, the error function is invoked as follows:
        ##	
        ##	&$ErrFunc($this, @error_text);
        ##
        ## @error_text signifies that the rest of the arguments
        ## are strings, when concatenated together, is the error
        ## message.  The line number and label of the input where
        ## error occured can be retrieved by the get_line_no and
        ## get_input_label methods of the passed in parser object.

##  Some constants
$ModePCData	= 1;
$ModeCData	= 2;
$ModeIgnore	= 3;
$ModeMSCData	= 4;

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
    
    ## Private variables

    $this->{_string} = undef;	# Input string
    $this->{_fh} = undef;	# Input file handle
    $this->{_filename} = '';	# Input filename of handle (for diagnostic
    				#     purposes)
    $this->{_buf} = '';		# Working buffer
    $this->{_open_ms} = 0;	# Number of open marked sections
    $this->{_abort} = 0;	# Abort flag

    ## Instance level callbacks; override class level                            
    $this->{CDataFunc}	= undef;	# Cdata callback
    $this->{CommentFunc}= undef;	# Comment callback
    $this->{ETagFunc}	= undef;	# End tag callback
    $this->{IgnDataFunc}= undef;	# Ignored data callback
    $this->{MSCloseFunc}= undef;	# Marked section end callback
    $this->{MSStartFunc}= undef;	# Marked section start callback
    $this->{PERefFunc}	= undef;	# Parameter entity reference callback
    $this->{PIFunc}	= undef;	# Processing instruction callback
    $this->{STagFunc}	= undef;	# Start tag callback

    ## Instance level error handling; override class level
    $this->{ErrHandle}	= undef;	# Undefined - use class setting
    $this->{ErrFunc}	= undef;	# Undefined - use class setting
    
    ## Other instance stuff
    $this->{mode} = $ModePCData;	# Parsing mode
                                
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
    
  # Eval code to capture die's
  eval {

    my($before, $after, $type, $tmp);
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
        
	#--------------------------------------------------------------
        # Check for markup.  Choose match that occurs earliest in
        # string.  This stuff adds more time to parsing, but supports
        # arbitrary values of the delimiters. (Size of delimiter
        # check needs to be added)
	#--------------------------------------------------------------
        
        ($before, $after, $type, $m1) = (undef,'','','');

	# Pcdata mode checks
	if ($this->{mode} == $ModePCData) {

	    if ($buf =~ /$mdo/o) {			# Markup declaration
		if (!defined($before) or length($before) > length($`)) {
		    $before = $`;  $after = $';
		    if ($after =~ s/^$comm//o) {	# Comment declaration
			$type = $comm_;
		    } elsif ($after =~ s/^$dso//o) {    # Marked section
			$type = $dso_;
		    } else {			    	# Unsupported
			$this->_errMsg("Unsupported markup declaration");
			($before, $after, $type) = (undef,'','');
		    }
		}
	    }
	    if ($buf =~ /$stago([$namestart])/o) {	# Start tag
		if (!defined($before) or length($before) > length($`)) {
		    $before = $`;  $m1 = $1;  $after = $';
		    $type = $stago_;
		}
	    }
	    if ($buf =~ /$pio/o) {			# Processing inst
		if (!defined($before) or length($before) > length($`)) {
		    $before = $`;  $after = $';
		    $type = $pio_;
		}
	    }
	} # End if in pcdata mode

	# Check if pcdata or in a cdata element
	if ($this->{mode} == $ModePCData or
	    $this->{mode} == $ModeCData) {

	    if ($buf =~ /$etago([$namestart])/o) {	# End tag
		if (!defined($before) or length($before) > length($`)) {
		    $before = $`;  $m1 = $1;  $after = $';
		    $type = $etago_;
		}
	    }
	}

	# Check if regardless
	if ($buf =~ /$msc$mdc/o) {			# Marked section close
            if (!defined($before) or length($before) > length($`)) {
	        $before = $`;  $after = $';
	        $type = $msc_;
            }
	}

	#--------------------------------------------------------------
	# Now, check what the type is an process accordingly.
	#--------------------------------------------------------------
        
        ## Invoke cdata callback if any before text
	if ($before ne '') {
	    $this->{mode} == $ModeIgnore ?
		$this->_invoke_cb('IgnDataFunc', $before) :
		$this->_invoke_cb('CDataFunc', $before);
	}

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
            if ($buf =~ s/^([$namechars]*)//o) {
	        $gi .= $1;
	    }
        
            # Get attribute specification list and tagc
            $attr = '';
            STAG: while (1) {
                if ($buf =~ /$tagc/o) {
                    $attr .= $`;  $buf = $';
                    if (!&SGMLopen_lit($attr)) {
                        last STAG;
                    } else {
			$attr .= $tagc_;
			next;
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
        
        ## Marked section start
        if ($type eq $dso_) {
	    $buf = $after;
	    $tmp = '';

            # Read up to dso
            MSO: while (1) {
                if ($buf =~ /$dso/o) {
            	    $tmp .= $`;  $buf = $';
                    last MSO;
                }
                $tmp .= $buf;
                if (!defined($buf = $this->_get_line())) {
                    $this->_errMsg("Unexpected EOF for marked section start");
                }
            }

	    if ($tmp =~ /$pero($namechars)/o) {
		$keyword = $this->_invoke_cb('PERefFunc', $1);
	    } else {
		($keyword = $tmp) =~ s/\s//g;
	    }
	    $keyword = uc $keyword;
	    $this->_invoke_cb('MSStartFunc', $keyword, $tmp);

	    if ($keyword eq "IGNORE") {
		$this->{mode} = $ModeIgnore;
	    } elsif ($keyword eq "RCDATA" or
		     $keyword eq "CDATA") {
		$this->{mode} = $ModeCData;
	    } else {
		$this->{_open_ms}++;
	    }

	    next LOOP;
	}

        ## Marked section end
        if ($type eq $msc_) {
	    $buf = $after;
	    if ($this->{_open_ms} == 0) {
		$this->_errMsg("Mark section close w/o a mark section start");
	    } else {
		$this->{_open_ms}--;
	    }
	    if ($this->{mode} == $ModeIgnore or
		$this->{mode} == $ModeCData) {
		$this->{mode} = $ModePCData;
	    }
	    $this->_invoke_cb('MSCloseFunc');
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
            
            my(@comms) = ();
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

	    next LOOP;
        }
    
    	## If not markup, invoke cdata callback
	$this->{mode} == $ModeIgnore ?
	    $this->_invoke_cb('IgnDataFunc', $buf) :
	    $this->_invoke_cb('CDataFunc', $buf);
        $buf = '';
    }

  }; # End eval

    # Return buffer.  May contain data if parsing was aborted, otherwise
    # should be undef.
    $buf;
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

##----------------------------------------------------------------------
##	set_abort_flag() is used by callback routines to instruct
##	parser to abort parsing.
##
sub set_abort_flag {
    my $this = shift;
    $this->{_abort} = 1;
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

	if ($this->{_abort}) {
	    $this->{_abort} = 0;
	    die;	# Captured by eval
	}
    }
}

##----------------------------------------------------------------------
##	_get_line() retrieves the next line from input.  undef is
##	returned if end of input is reached.
##
sub _get_line {
    my $this = shift;
    my $ret = undef;
    my($sref, $fh);
    
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
1;

