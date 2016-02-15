xquery version "3.0" encoding "UTF-8";

import module namespace json="http://xqilla.sourceforge.net/lib/xqjson";

declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xdb="http://exist-db.org/xquery/xmldb";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace app="http://kb.dk/this/app";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace local="http://kb.dk/this/app";
declare namespace uuid="java:java.util.UUID";

declare variable  $document := request:get-parameter("doc","");
declare variable  $frag     := request:get-parameter("id","");
declare variable  $work_id  := request:get-parameter("work_id","");
declare variable  $c        := request:get-parameter("c","texts");
declare variable  $o        := request:get-parameter("op","solrize");
declare variable  $op       := doc(concat("/db/letter_books/", $o,".xsl"));
declare variable  $status   := request:get-parameter("status","");
(: The posted content should actually live in a param with the same name :)

declare variable  $content  := request:get-parameter("content","");
declare variable  $coll     := concat($c,'/');
declare variable  $file     := substring-after(concat($coll,$document),"/db");

declare option    exist:serialize "method=xml media-type=text/xml";

declare function local:enter-location-data(

)

declare function local:enter-person-data(
  $frag as xs:string,
  $role as xs:string,
  $doc as node(),
  $json as node()) as node()*
{
  let $letter := $doc//node()[@xml:id=$frag]
  let $resp   := $doc//t:bibl[@xml:id = $letter/@decls]
                      /t:respStmt[t:resp = $role ]

  let $respid_id := 
    if($resp/@xml:id) then
      $resp/@xml:id
    else
      let $mid := concat("idm",util:uuid())
      let $u   := update insert attribute xml:id {$mid} into $resp
      return $mid

  let $cleanup :=
  for $n in $resp//t:name
  return update delete $n

  let $tasks := 
  for $person in $json//pair[@name=$role]/item[@type='object']
    let $person_id := $person//pair[@name="xml_id"]
    let $name := 
    <t:name>   
      <t:surname>{$person//pair[@name="family_name"]/text()}</t:surname>,
      <t:forename>{$person//pair[@name="given_name"]/text()}</t:forename>
    </t:name>
    let $full_name := concat(
      $person//pair[@name="family_name"]/text(),
      ", ",
      $person//pair[@name="given_name"]/text())
    let $all :=
      if($person_id) then
	let $s    := $letter//t:persName[$person_id=@xml:id]
	let $pref := concat('#person',$person_id)
	let $ppid := concat('person',$person_id)
	let $up1  := update insert attribute key {$full_name} into $s
	let $up2  := update insert attribute sameAs {$pref}   into $s
	let $up5  := update insert $name into $resp      
	let $r    := $resp/t:name[last()]
	let $up3  := update insert attribute xml:id {$ppid} into $r
	return $up1 and $up2 and $up3
      else
	update insert $name into $resp     
 
     return $all

  return ()

};



let $prev := 
  if($frag) then
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document 
    return $doc/preceding::t:div[1]/@xml:id
  else
    ""

let $next := 
  if($frag) then
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document
    return $doc/following::t:div[1]/@xml:id
  else
    ""

let $prev_encoded := 
  if($frag) then
    concat(replace(substring-before($file,'.xml'),'/','%2F'),'-',$prev)
  else
    ""
let $next_encoded := 
  if($frag) then
    concat(replace(substring-before($file,'.xml'),'/','%2F'),'-',$next)
  else
    ""

let $data := json:parse-json($content)

let $doc := 
for $tei in collection($coll)
where util:document-name($tei)=$document
return $tei

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

let $d := local:enter-person-data($frag,"sender",$doc,$data)
let $e := local:enter-person-data($frag,"recipient",$doc,$data)
let $trans_doc := transform:transform($doc,$op,$params)

return
$trans_doc

