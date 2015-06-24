
# The TEI file store

## Introduction

This directory contains what is needed for storing and accessing ADL stuff in
an eXist DB 

## The stuff

* [adder.xsl](../transforms/adder.xsl) generates a SOLR add document making an
  index for text searching in ADL
* [present.xq](./present.xq) is retrieving piece of XML from the store given
  the name of the file and the xml:id of the fragment. Call it like this
  http://example.org/adl/present.xq?doc=file.xml&id=xml-frag-id
