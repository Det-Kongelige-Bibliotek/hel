#!/usr/bin/sh

PROJ="$HOME/projects"
ADDER="$PROJ/valhal/app/export/transforms/adder.xsl"
USAGE="Usage: generate_seed_docs.sh -s source -d destination -t work or author"

while getopts "s:d:t:" flag
do
  case $flag in
    s) SOURCE=$OPTARG; export SOURCE ;;
    d) DEST=$OPTARG;   export DEST ;;
    t) TYPE=$OPTARG;   export TYPE ;;
  esac
done

if [ ! -d "$SOURCE" ];then 
    echo "Source directory doesn't exist: $SOURCE"
    echo $USAGE
    exit 1
fi

if [ ! -d "$DEST" ]; then
    mkdir -p "$DEST"
fi

FILES=$SOURCE/*.xml
if [ "$TYPE" == "work" ]; then
    CAT="cat"
elif [ "$TYPE" == "portrait" ];then
    CAT="category"
else
    echo "Invalid category: $TYPE"
    echo $USAGE
    exit 1
fi

for f in $FILES 
do
  echo "processing $f"
  ID=$(basename -s .xml $f)
  xsltproc --stringparam file $ID --stringparam $CAT $TYPE -o $DEST/$ID.xml $ADDER $f
done
