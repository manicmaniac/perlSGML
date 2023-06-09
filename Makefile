##	%Z% $Id: Makefile,v 1.3 1997/09/18 14:52:07 ehood Exp $  %Z%

###########################################
# MAKEFILE VARIABLES
###########################################

# Standard variables
CC          	= gcc
C++         	= g++
AR          	= ar
RANLIB      	= ranlib
CDEBUG      	= -g
C++DEBUG    	= -g
DEBUG       	= -DDEBUG
TOUCH       	= touch
MAKE        	= make
MAKEDEPEND  	= makedepend
PERL        	= perl
DEFINES		= $(DEBUG)
CHMOD		= /bin/chmod
RM          	= /bin/rm
MV		= /bin/mv
CP		= /bin/cp
TAR		= tar
GZIP		= gzip
ZIP		= zip

SAPPHIRE	= -I/usr/sapphire
X11INCDIR	= -I/usr/openwin/include
X11LIBDIR	= -L/usr/openwin/lib
MOTIFINCDIR	= -I/usr/dt/share/include
MOTIFLIBDIR	= -L/usr/dt/lib

###########################################

PROGS		= \
		  dtd2html \
		  dtddiff \
		  dtdtree \
		  dtdview \
		  stripsgml \
		  # End of list

SUBDIRS		= \
		  doc \
		  # End of subdirs

default: progs make_subdirs

depend:

install:
	$(PERL) install.me

progs:
	$(CHMOD) a+x $(PROGS)

clean:
	$(RM) -f $(OBJS) $(LIB)

make_subdirs:
	@for i in $(SUBDIRS) ; \
	   do( \
	      cd $$i ; echo ; \
	      echo "---====== <$$i> ======---"; \
	      $(MAKE) ; \
	      echo "---====== </$$i> ======---"; \
	     ); \
	done

clean_subdirs:
	@for i in $(SUBDIRS) ; \
	   do( \
	      cd $$i ; echo ; \
	      echo "---====== <$$i> ======---"; \
	      $(MAKE) clean ; \
	      echo "---====== </$$i> ======---"; \
	     ); \
	done


depend_subdirs:
	@for i in $(SUBDIRS) ; \
	   do( \
	      cd $$i ; echo ; \
	      echo "---====== <$$i> ======---"; \
	      $(RM) -f ./local_depend ; \
	      $(TOUCH) ./local_depend ; \
	      $(MAKE) depend ; \
	      echo "---====== </$$i> ======---"; \
	     ); \
	done

depend_local:
	@echo "Remaking include file dependencies..." \\c
	@$(RM) -f ./local_depend
	@$(TOUCH) ./local_depend
	@$(MAKEDEPEND) -flocal_depend -- $(INCDIRS) -- $(SRCS)
	@$(RM) -f local_depend.bak
	@echo "done."


############################################################
# Now include all the local file dependencies generated by
# makedepend
# include ./local_depend
