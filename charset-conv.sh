#!/bin/bash

dirname=$1
fromCharset=$2
toCharset=$3
usageSample="Usage: ./charset-conv.sh 'home/zapdos/sample' ISO-8859-1 UTF-8"
if [ "$dirname" == "" ] ; then
    echo "Info: missing file directory"
    echo $usageSample
    exit -1
fi 

if [ "$fromCharset" == ""] ; then 
    echo "Info: missing current files charset"
    echo $usageSample
    exit -1
fi

if [ "$toCharset" == "" ] ; then
    echo "Info: missing new files charset"
    echo $usageSample
    exit -1
fi

arr=($dirname/*)
for file in "${arr[@]}"; do
        iconv -f $fromCharset -t $toCharset//TRANSLIT "$file" -o "$file.$toCharset"
        rm -rf "$file"
        mv "$file.$toCharset" "$file"
        file -i "$file"
done

exit 0