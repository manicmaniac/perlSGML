# 	%Z% %Y% $Id: Makefile,v 1.4 1997/09/12 20:14:16 ehood Exp $ %Z%
#

SGMLDOCS = \
    SGML::DTD.sgml \
    SGML::EntMan.sgml \
    SGML::FSI.sgml \
    SGML::ISO8859.sgml \
    SGML::Opt.sgml \
    SGML::Parser.sgml \
    SGML::SOCat.sgml \
    SGML::StripParser.sgml \
    SGML::Util.sgml \
    dtd2html.sgml \
    dtd_pl.sgml \
    dtddiff.sgml \
    dtdtree.sgml \
    dtdview.sgml \
    perlSGML.sgml \
    sgml_pl.sgml \
    stripsgml.sgml

HTMLDOCS = \
    SGML::DTD.html \
    SGML::EntMan.html \
    SGML::FSI.html \
    SGML::ISO8859.html \
    SGML::Opt.html \
    SGML::Parser.html \
    SGML::SOCat.html \
    SGML::StripParser.html \
    SGML::Util.html \
    dtd2html.html \
    dtd_pl.html \
    dtddiff.html \
    dtdtree.html \
    dtdview.html \
    perlSGML.html \
    sgml_pl.html \
    stripsgml.html

PERLMODS = \
    ../lib/SGML/DTD.pm \
    ../lib/SGML/EntMan.pm \
    ../lib/SGML/FSI.pm \
    ../lib/SGML/ISO8859.pm \
    ../lib/SGML/Opt.pm \
    ../lib/SGML/Parser.pm \
    ../lib/SGML/SOCat.pm \
    ../lib/SGML/StripParser.pm \
    ../lib/SGML/Syntax.pm \
    ../lib/SGML/Util.pm

all:
	/bin/csh -f sgml2html $(SGMLDOCS)
	chmod -R a+r,a+X .

check:
	@for i in $(SGMLDOCS) ; \
	   do( \
	      nsgmls -s $$i ; \
	     ); \
	done

dist:
	( \
	    cd html ; \
	    cp -p $(HTMLDOCS) $(dwrk)/src/perl/SGML/perlSGML/doc ; \
	) ;

clean:
