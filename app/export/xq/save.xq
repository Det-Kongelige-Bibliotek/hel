xquery version "1.0" encoding "UTF-8";

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

declare variable  $document := request:get-parameter("doc","");
declare variable  $frag     := request:get-parameter("id","");
declare variable  $work_id  := request:get-parameter("work_id","");
declare variable  $c        := request:get-parameter("c","texts");
declare variable  $o        := request:get-parameter("op","render");
declare variable  $coll     := concat($c,'/');



declare variable  $op       := doc(concat("/db/letter_books/", $o,".xsl"));


declare option    exist:serialize "method=xml media-type=text/xml";

(:xdb:store($pubroot,util:document-name($doc), $doc):)

let $person := 
  '{"firstName": "John W",
    "lastName": "Smith","isAlive": true,"age": 25,"height_cm": 167.6,"address": {"streetAddress": "21 2nd Street","city": "New York","state": "NY","postalCode": "10021-3100"},"phoneNumbers": [{"type": "home",                "number": "212 555-1234"            },            {                "type": "office",                "number": "646 555-4567"            }        ],        "children": [],        "spouse": null    }'

let $persdoc :=
    json:parse-json($person)

let $list := 
  if($frag and not($o = "facsimile")) then
    for $doc in collection($coll)//node()[ft:query(@xml:id,$frag)]
    where util:document-name($doc)=$document
    return $doc
  else
    for $doc in collection($coll)
    where util:document-name($doc)=$document
    return $doc

let $params := 
<parameters>
   <param name="uri_base" value="http://{request:get-header('HOST')}"/>
   <param name="doc"      value="{$document}"/>
   <param name="id"       value="{$frag}"/>
   <param name="work_id"  value="{$work_id}"/>
   <param name="c"        value="{$c}"/>
   <param name="coll"     value="{$coll}"/>
   <param name="submixion"     value="{$persdoc}"/>

</parameters>

let $trans_doc :=
for $doc in $list
return  transform:transform($doc,$op,$params)

(:$persdoc
$trans_doc :)

return
$params


(:
<json type="object">
    <pair name="firstName" type="string">John</pair>
    <pair name="lastName" type="string">Smith</pair>
    <pair name="isAlive" type="boolean">true</pair>
    <pair name="age" type="number">25</pair>
    <pair name="height_cm" type="number">167.6</pair>
    <pair name="address" type="object">
        <pair name="streetAddress" type="string">21 2nd Street</pair>
        <pair name="city" type="string">New York</pair>
        <pair name="state" type="string">NY</pair>
        <pair name="postalCode" type="string">10021-3100</pair>
    </pair>
    <pair name="phoneNumbers" type="array">
        <item type="object">
            <pair name="type" type="string">home</pair>
            <pair name="number" type="string">212 555-1234</pair>
        </item>
        <item type="object">
            <pair name="type" type="string">office</pair>
            <pair name="number" type="string">646 555-4567</pair>
        </item>
    </pair>
    <pair name="children" type="array"/>
    <pair name="spouse" type="null"/>
</json>
:)
