#!/usr/bin/bash
FILES=adl2/authors/*.xml
CAT=portrait



for f in $FILES 
do
  echo "processing $f"
  ID=$(basename -s .xml $f)
  xsltproc --stringparam file $ID --stringparam category $CAT -o seed_docs/$ID.xml ./RubymineProjects/valhal/app/export/transforms/adder.xsl $f
done
