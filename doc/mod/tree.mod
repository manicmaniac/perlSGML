<!--	%Z% %Y% $Id: tree.mod,v 1.2 1996/10/06 18:47:13 ehood Exp $ %Z%
  -->

<p>The tree shows the overall content hierarchy for an element.
Content hierarchies of descendents will also be shown.  Elements that
exist at a higher (or equal) level, or if the maximum depth has been
reached, are pruned.  The string "<code>...</code>" is appended to an
element if it has been pruned due to pre-existance at a higher (or
equal) level.  The content of the pruned element can be determined
by searching for the complete tree of the element (ie. elements w/o
"<code>...</code>").  Elements pruned because maximum depth has been
reached will not have "<code>...</code>" appended.

</p>

<p>Example:
</p>

<pre>
     |__section+)
         |_(effect?, ...
         |__title, ...
         |__toc?, ...
         |__epc-fig*,
         |   |_(effect?, ...
         |   |__figure,
         |   |   |_(effect?, ...
         |   |   |__title, ...
         |   |   |__graphic+, ...
         |   |   |__assoc-text?)
</pre>

<dl>
<dt><strong>Note</strong></dt>
<dd><p>Pruning must be done to avoid a combinatorical explosion.
It is common for DTD's to define content hierarchies of infinite
depth.  Even with a predefined maximum depth, the generated tree
can become very large.
</p>
</dd>
</dl>

<p>Since the tree outputed is static, the inclusion and exclusion sets
of elements are treated specially. Inclusion and exclusion elements
inherited from ancestors are not propagated down to determine
what elements are printed, but special markup is presented at a
given element if there exists inclusion and exclusion elements from
ancestors. The reason inclusions and exclusions are not propagated down
is because of the pruning done. Since an element may occur in multiple
contexts -- and have different ancestoral inclusions and exclusions in
effect -- an element without "<code>...</code>" may be the only place
of reference to see the content hierarchy of the element.

</p>

<p>Example:</p>

<pre>
    D1
     |  {+} idx needbegin needend newline
     | 
     |_(head,
     |   | {A+} idx needbegin needend newline
     |   |  {-} needbegin needend
     |   | 
     |   |_(((#PCDATA |
     |   |____((acro |
     |   |       | {A+} idx needbegin needend newline
     |   |       | {A-} needbegin needend
     |   |       | 
     |   |       |_(((#PCDATA |
     |   |       |____((super | ...
     |   |       |______sub)))*)) ...
</pre>

<p>Ignoring the lines starting with {}'s, one gets the content
hierachy of an element as defined by the DTD without concern of where
it may occur in the overall structure. The {} lines give additional
information regarding the element with respect to its existance
within a specific context. For example, when an <code>ACRO</code> element occurs
within <code>D1</code>,<code>HEAD</code>, along with its normal
content, it can contain <code>IDX</code> and <code>NEWLINE</code>
elements due to inclusions from ancestors. However, it cannot contain
<code>NEEDBEGIN</code> and <code>NEEDEND</code> regardless of its defined
content since an ancestor(s) excludes them.

</p>

<dl>
<dt><strong>Note</strong></dt>
<dd>Exclusions override inclusions. If an element occurs in an
inclusion set and an exclusion set, the exclusion takes
precedence. Therefore, in the above example, <code>needbegin</code>, 
<code>needend</code> are excluded from <code>acro</code>.</dd>
</dl>
<p>Explanation of {}'s keys:
</p>
<dl>
<dt><code>{+}</code></dt>
<dd>The list of inclusion elements defined by the current element.
Since this is part of the content model of the element, the
inclusion subelements are printed as part of the content
hierarchy of the current element after the base content model.
Subelements that are inclusions will have <code>{+}</code> appended
to the subelement entry.
</dd>
<dt><code>{A+}</code></dt>
<dd>The list of inclusion elements due to ancestors. This is listed
as reference to determine the content of an element within a
given context. None of the ancestoral inclusion elements are
printed as part of the content hierarchy of the element. 
</dd>
<dt><code>{-}</code></dt>
<dd>The list of exclusion elements defined by the current
element. Since this is part of the content model of the
element, any subelement in the content model that would be
excluded will have <code>{-}</code> appended to the subelement
listing.
</dd>
<dt><code>{A-}</code></dt>
<dd>The list of exclusion elements due to ancestors. This is listed
as reference to determine the content of an element within a
given context. None of the ancestoral exclusion elements
have any effect on the printing of the content hierarchy of
the current element.
</dd>
</dl>
