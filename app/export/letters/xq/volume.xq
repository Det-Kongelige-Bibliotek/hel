xquery version "3.0" encoding "UTF-8";

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
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare variable  $document := request:get-parameter("doc","");
declare variable  $frag     := request:get-parameter("id","");
declare variable  $work_id  := request:get-parameter("work_id","");
declare variable  $c        := request:get-parameter("c","texts");
declare variable  $o        := request:get-parameter("op","render");
declare variable  $status   := request:get-parameter("status","");
declare variable  $app      := request:get-parameter("app","");
declare variable  $prefix   := request:get-parameter("prefix","");
declare variable  $coll     := concat($c,'/');
declare variable  $op       := doc(concat("/db/letter_books/", $o,".xsl"));
declare variable  $file     := concat("/",$coll,substring-before($document,"_"),"/",$document);

declare option exist:serialize "method=xml encoding=UTF-8 media-type=text/html";

(: 

A boolean query

"http://bifrost-test-01.kb.dk:8080/solr/blacklight-core/select?q=cat_ssi%3Aperson+AND+work_title_tesim%3Avictor&wt=xml&indent=true"

Look-up a given volume

"http://bifrost-test-01.kb.dk:8080/solr/blacklight-core/select?q=/letter_books/001541111/001541111_000.xml&wt=xml&indent=true"

:)

let $docs := 
   for $doc in collection($coll)
   where util:document-name($doc)=$document
   return $doc


for $doc in $docs[1]
return
<html>
  <body>
    <pre>file={$file}</pre>
    <pre>coll={$coll}</pre>
    <pre>doc={util:document-name($doc)}</pre>
    <h2>Tekst før brevene</h2>
    {
        for $div in $doc//t:div[not(@decls) and following::t:div[@decls]]
	return <p>{substring(string-join($div//text()," "),1,100)}</p>
    }
    <h2>Breve</h2>
    {
        for $div in $doc//node()[@decls]
	return 
	<p>
	{
		for $id in $div/@decls
		return
		  for $bibl in //t:bibl[@xml:id=$id]
                  return (
			"fra",
			<strong>{$bibl/t:respStmt[contains(t:resp,"sender")]/t:name}</strong>,
			"til",
			<strong>{$bibl/t:respStmt[contains(t:resp,"recipient")]/t:name}</strong>,
			for $d in $bibl/t:date[string()] return concat("(",$d,")")
	               )
	}
	<br/><small>{substring(string-join($div//text()," "),1,300)}</small>
	</p>
    }
    <h2>Tekst efter brevene</h2>
    {
        for $div in $doc//t:div[not(@decls) and not(following::t:div[@decls])]
	return <p>{substring(string-join($div//text()," "),1,100)}</p>
    }
  </body>
</html>