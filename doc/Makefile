# 	%Z% %Y% $Id: Makefile,v 1.3 1996/10/07 10:12:41 ehood Exp $ %Z%
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
	/bin/csh -f sgml2html $(SGMLDOCS)
	chmod -R a+r,a+X .

dist:
	( \
	    cd html ; \
	    cp -p $(HTMLDOCS) $(dwrk)/src/perl/SGML/perlSGML/doc ; \
	) ;

clean:
