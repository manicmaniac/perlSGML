##	%Z% %Y% $Id: Makefile,v 1.1 1996/09/30 13:34:51 ehood Exp $ %Z%

SCRIPTS = \
    dtd2html \
    dtddiff \
    dtdtree \
    dtdview \
    install.me \
    stripsgml \
    # End of list

all:
	chmod a+x $(SCRIPTS)
	chmod -R a+r,a+X .
