# 	%Z% %Y% $Id: Makefile,v 1.1 1996/09/30 16:37:22 ehood Exp $ %Z%
#

SGMLDOCS = \
    dtd2html.sgml \
    dtd_pl.sgml \
    dtddiff.sgml \
    dtdtree.sgml \
    dtdview.sgml \
    perlSGML.sgml \
    sgml_pl.sgml \
    stripsgml.sgml

HTMLDOCS = \
    dtd2html.html \
    dtd_pl.html \
    dtddiff.html \
    dtdtree.html \
    dtdview.html \
    perlSGML.html \
    sgml_pl.html \
    stripsgml.html

all:
	./sgml2html $(SGMLDOCS)
	chmod -R a+r,a+X .

dist:
	do ( \
	    cd html ; \
	    cp -p $(HTMLDOCS) $(dwrk)/src/perl/SGML/perlSGML/doc ; \
	) ;

clean: