xquery version "1.0" encoding "UTF-8";

declare namespace xdb        = "http://exist-db.org/xquery/xmldb";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace app="http://kb.dk/this/app";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace ft="http://exist-db.org/xquery/lucene";

declare variable  $document := request:get-parameter("doc","");
declare variable  $frag     := request:get-parameter("id","");
declare variable  $work_id  := request:get-parameter("work_id","");
declare variable  $c        := request:get-parameter("c","texts");
declare variable  $o        := request:get-parameter("op","render");
declare variable  $status   := request:get-parameter("status","");
declare variable  $coll     := concat($c,'/');
declare variable  $op       := doc(concat("/db/letter_books/", $o,".xsl"));
declare variable  $file     := substring-after(concat($coll,$document),"/db");

declare option    exist:serialize "method=xml omit-xml-declaration=yes  media-type=text/html";

let $list := 
  if($frag and not($o = "facsimile" or $o = "form")) then
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document
    return $doc
  else
    for $doc in collection($coll)
    where util:document-name($doc)=$document
    return $doc

let $prev := 
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document 
    return $doc/preceding::t:div[1]/@xml:id

let $next := 
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document
    return $doc/following::t:div[1]/@xml:id

let $prev_encoded := 
    concat(replace(substring-before($file,'.xml'),'/','%2F'),'-',$prev)

let $next_encoded := 
    concat(replace(substring-before($file,'.xml'),'/','%2F'),'-',$next)

let $params := 
<parameters>
  <param name="uri_base" value="http://{request:get-header('HOST')}"/>
  <param name="hostname" value="{request:get-header('HOST')}"/>
  <param name="doc"      value="{$document}"/>
  <param name="id"       value="{$frag}"/>
  <param name="prev"     value="{$prev}"/>
  <param name="prev_encoded"
                         value="{$prev_encoded}"/>
  <param name="next"     value="{$next}"/>
  <param name="next_encoded"
                         value="{$next_encoded}"/>
  <param name="work_id"  value="{$work_id}"/>
  <param name="c"        value="{$c}"/>
  <param name="coll"     value="{$coll}"/>
  <param name="file"     value="{$file}"/>
  <param name="status"   value="{$status}"/>
</parameters>

for $doc in $list
return  transform:transform($doc,$op,$params)

