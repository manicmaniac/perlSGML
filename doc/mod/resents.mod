<!--	%Z% %Y% $Id: resents.mod,v 1.1 1996/10/05 15:20:25 ehood Exp $ %Z%
  -->
<hr>
<h2><a name="resolving">Resolving External Entities</a></h2>

<p>Defining the mapping between external entities to system files
may be done via the <a href="#-catalog"><code>-catalog</code></a>
command-line option.  The <em>catalog</em> provides you with the
capability of mapping public identifiers to system identifiers
(files) or to map entity names to system identifiers.
</p>

&catalog;

<dl>
<dt><strong>Note</strong></dt>
<dd><p>
The file specified by
<a href="#-catalog"><code>-catalog</code></a>
is read first before any files specified by SGML_CATALOG_FILES.
</p>
</dd>
</dl>
