#!/bin/bash
# Author: Zheng Cao
# Date: 2017/06/27
#-------------------------------------------------------#
#Modify: add special case handling
#Date: 2017/09/05
#Author: CaoZheng
#-------------------------------------------------------#

compare_url="$1"
base_url="$2"
tmp_dir="/tmp/jenkins/difference/$(openssl rand -hex 5)"

if [ -e "$tmp_dir" ];then
    mv $tmp_dir ${tmp_dir}.backup
    rm -rf $tmp_dir/*
else
    mkdir $tmp_dir -p
fi

svn diff --summarize $compare_url $base_url > $tmp_dir/svn.txt

awk '$1=="A" { print $2 }' $tmp_dir/svn.txt|egrep -v "\/\." > $tmp_dir/A.list
awk '$1=="M" { print $2 }' $tmp_dir/svn.txt|egrep -v "\/\." > $tmp_dir/M.list
awk '$1=="MM" { print $2 }' $tmp_dir/svn.txt|egrep -v "\/\." >> $tmp_dir/M.list
awk '$1=="D" { print $2 }' $tmp_dir/svn.txt|egrep -v "\/\." > $tmp_dir/D.list
awk '$1!="A" && $1!="M" && $1!="MM" && $1!="D" { print $0 }' $tmp_dir/svn.txt|egrep -v "\/\." > $tmp_dir/SPECIAL.list

cat $tmp_dir/M.list|while read i
do
    FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
    if [ "$FileType" = "file" ];then
        echo $i >> $tmp_dir/final_list.txt
    fi
done

cat $tmp_dir/D.list|while read i
do
    FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
    if [ "$FileType" = "file" ];then
        echo $i >> $tmp_dir/final_list.txt
    elif [ "$FileType" = "directory" ]; then
        echo $i >> $tmp_dir/D.dir.txt
    else 
        echo "[ERROR] Unknow file type!"
        rm -rf $tmp_dir
        exit 1
    fi
done        


sed s#$compare_url#$base_url# $tmp_dir/A.list > $tmp_dir/A.list.tmp
cat $tmp_dir/A.list.tmp|while read i
do
    FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
    if [ "$FileType" = "file" ];then
        origin_url=$(echo $i|sed s#$base_url#$compare_url#)
        echo $origin_url >> $tmp_dir/final_list.txt
    elif [ "$FileType" = "directory" ]; then
        origin_url=$(echo $i|sed s#$base_url#$compare_url#)
        echo $origin_url >> $tmp_dir/A.dir.txt
    else
        echo "[ERROR] Unknow file type!"
        rm -rf $tmp_dir
        exit 1
    fi
done


# dir process
# two file: MD.dir.txt, A.dir.txt
if [ -f "$tmp_dir/D.dir.txt" ];then
    cat $tmp_dir/D.dir.txt|while read i
    do
        grep $i $tmp_dir/final_list.txt
        if [ $? != 0 ];then
            svn ls --recursive $i|grep -v '.*/$'|sed  "s#^#${i}\/#"|egrep -v "\/\." >> $tmp_dir/final_list.txt
        fi
    done
fi

if [ -f "$tmp_dir/A.dir.txt" ];then
    cat $tmp_dir/A.dir.txt|while read i
    do
        grep $i $tmp_dir/final_list.txt
            if [ $? != 0 ];then
            trunk_url=$(echo $i|sed s#$compare_url#$base_url#)
            svn ls --recursive $trunk_url|grep -v '.*/$'|sed  "s#^#${compare_url}\/#"|egrep -v "\/\." >> $tmp_dir/final_list.txt
            fi
    done
fi



if [ -s $tmp_dir/SPECIAL.list ];then
    echo "[WARNING] Special circumsstance"
    echo "------------------------------------------------------"
    cat $tmp_dir/SPECIAL.list
    echo "------------------------------------------------------";echo;echo                   
fi

cat $tmp_dir/final_list.txt

# remove tmp_dir
rm $tmp_dir -rf
