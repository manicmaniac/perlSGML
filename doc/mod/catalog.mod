<!--	%Z% %Y% $Id: catalog.mod,v 1.1 1996/09/30 16:38:41 ehood Exp $ %Z%
  -->
<hr>
<h2><a name="resolving">Resolving External Entities</a></h2>

<p>Defining the mapping between external entities to system files
may be done via that <a href="#-catalog"><code>-catalog</code></a>
command-line option.  The <em>catalog</em>, provides you with the
capability of mapping public identifiers to system identifiers
(files) or to map entity names to system identifiers.
</p>

<h3>Catalog Syntax</h3>

<p>The syntax of a catalog is a subset of SGML catalogs
(as defined in
<cite>SGML Open Draft Technical Resolution 9401:1994</cite>).
</p>

<p>A catalog contains a sequence of the following types of entries:
</p>

<dl>
<dt><code>PUBLIC</code> <var>public_id</var> <var>system_id</var></dt>
<dd><p>This maps <var>public_id</var> to <var>system_id</var>.
</p>
</dd>
<dt><code>ENTITY</code> <var>name</var> <var>system_id</var></dt>
<dd><p>This maps a general entity whose name is <var>name</var> to
<var>system_id</var>.
</p>
</dd>
<dt><code>ENTITY %</code><var>name</var> <var>system_id</var></dt>
<dd><p>This maps a parameter entity whose name is <var>name</var> to
<var>system_id</var>.
</p>
</dd>
</dl>

<h4>Syntax Notes</h4>

<ul>
<li><p>A <var>system_id</var> string cannot contain any spaces.  The
<var>system_id</var> is treated as pathname of file. </p>
</li>
<li><p>Any line in a catalog file that does not follow the previously
mentioned entries is ignored.</p>
</li>
<li><p>In case of duplicate entries, the first entry defined is used.
</ul>

<p>Example catalog file:</p>
<pre>
        -- ISO public identifiers --
PUBLIC "ISO 8879-1986//ENTITIES General Technical//EN"            iso-tech.ent
PUBLIC "ISO 8879-1986//ENTITIES Publishing//EN"                   iso-pub.ent
PUBLIC "ISO 8879-1986//ENTITIES Numeric and Special Graphic//EN"  iso-num.ent
PUBLIC "ISO 8879-1986//ENTITIES Greek Letters//EN"                iso-grk1.ent
PUBLIC "ISO 8879-1986//ENTITIES Diacritical Marks//EN"            iso-dia.ent
PUBLIC "ISO 8879-1986//ENTITIES Added Latin 1//EN"                iso-lat1.ent
PUBLIC "ISO 8879-1986//ENTITIES Greek Symbols//EN"                iso-grk3.ent 
PUBLIC "ISO 8879-1986//ENTITIES Added Latin 2//EN"                ISOlat2
PUBLIC "ISO 8879-1986//ENTITIES Added Math Symbols: Ordinary//EN" ISOamso

        -- HTML public identifiers and entities --
PUBLIC "-//IETF//DTD HTML//EN"                                    html.dtd
PUBLIC "ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML"          ISOlat1.ent
ENTITY "%html-0"                                                  html-0.dtd
ENTITY "%html-1"                                                  html-1.dtd

</pre>

<h3>Environment Variables</h3>

<p>The following
envariables (ie. environment variables) are supported:
</p>

<dl>
<dt>P_SGML_PATH</dt>
<dd><p>This is a colon (semi-colon for MSDOS users)
separated list of paths for finding catalog files
or system identifiers.  For example, if a system identifier is not
an absolute pathname, then the paths listed in P_SGML_PATH are used to
find the file.
</p>
</dd>
<dt>SGML_CATALOG_FILES</dt>
<dd><p>This envariable is a colon (semi-colon for MSDOS users)
separated list of catalog files to read.
The file specified by
<a href="#-catalog"><code>-catalog</code></a>
is read first before any files specified by SGML_CATALOG_FILES.  If
a file in the list is not an absolute path, then file is searched in
the paths listed in the P_SGML_PATH and SGML_SEARCH_PATH.
</p>
</dd>
<dt>SGML_SEARCH_PATH</dt>
<dd><p>This is a colon (semi-colon for MSDOS users)
separated list of paths for finding catalog files
or system identifiers.  This envariable serves the same function as
P_SGML_PATH.  If both are defined, paths listed in P_SGML_PATH are
searched first before any paths in SGML_SEARCH_PATH.</p>
</dd>
</dl>
<p>The use of P_SGML_PATH is for compatibility with earlier versions.
SGML_CATALOG_FILES and SGML_SEARCH_PATH
are supported for compatibility with James Clark's <code>nsgmls(1)</code>.
</p>
<dl>
<dt><strong>Note</strong></dt>
<dd>When searching for a file via the P_SGML_PATH and/or SGML_SEARCH_PATH,
if the file is not found in any of the paths, then the current working
directory is searched.
</dd>
</dl>

