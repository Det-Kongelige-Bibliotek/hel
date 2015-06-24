xquery version "1.0" encoding "UTF-8";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace app="http://kb.dk/this/app";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace ft="http://exist-db.org/xquery/lucene";

declare option exist:serialize "method=xml media-type=text/html"; 
declare variable $document := request:get-parameter("doc", "");
declare variable $fragment := request:get-parameter("id", "");


let $list := 
  if($fragment) then
    for $doc in collection("/db/adl/texts")//node()[ft:query(@xml:id,$fragment)]
    where util:document-name($doc)=$document
    return $doc
  else
    for $doc in collection("/db/adl/texts")
    where util:document-name($doc)=$document
    return $doc

let $params := 
<parameters>
   <param name="hostname" value="{request:get-header('HOST')}"/>
   <param name="doc" value="{$document}"/>
   <param name="id" value="{$fragment}"/>
</parameters>

for $doc in $list
return transform:transform($doc,doc("/db/adl/render.xsl"),$params)
 
