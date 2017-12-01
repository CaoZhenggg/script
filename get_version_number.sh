#!/bin/bash
#author: Cao Zheng
#date: 2017/10/10

read -p "Please input path: " path
if [ ! -d $path ];then
    echo "[ERROR] $path doesn't exist!"
    bash $0
fi

ls $path|sort > list.txt

if [ -f tmpfile ];then
    rm -f tmpfile
fi

cat list.txt|while read line
do
    version=$(echo $line|grep -oP '\-[\d\.]+.*[\d\.]+.*')
    name=$(echo $line|sed "s#$version##")
    echo "$name $version $line" >> tmpfile
done

echo 'result:'
awk 'NR==FNR{a[$1]++;next}(a[$1]>1)&&(! b[$0]++)' tmpfile tmpfile|awk '{ print $3 }'

rm -f list.txt
rm -f tmpfile
