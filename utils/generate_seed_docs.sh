#!/usr/bin/bash
FILES=adl2/texts/*.xml
CAT=work



for f in $FILES 
do
  echo "processing $f"
  ID=$(basename -s .xml $f)
  xsltproc --stringparam file $ID --stringparam cat $CAT -o seed_docs/$ID.xml ./RubymineProjects/valhal/app/export/transforms/adder.xsl $f
done
