#!/bin/bash
#Author: CaoZheng
#Date: 2017/07/25


Script_Path=$(dirname $0)
Temp_Path=/tmp/$(openssl rand -hex 5)

mkdir $Temp_Path
mkdir $Temp_Path/class_tar

compare_url="$1"
base_url="$2"
build_files="$3"



get_diff_txt() {
    echo "[INFO] Get difference list... " 
    svn diff --summarize $compare_url $base_url > $Temp_Path/svn.txt

    awk '$1=="A" { print $2 }' $Temp_Path/svn.txt|egrep -v "\/\." > $Temp_Path/A.list
    awk '$1=="M" { print $2 }' $Temp_Path/svn.txt|egrep -v "\/\." > $Temp_Path/M.list
    awk '$1=="MM" { print $2 }' $Temp_Path/svn.txt|egrep -v "\/\." >> $Temp_Path/M.list
    awk '$1=="D" { print $2 }' $Temp_Path/svn.txt|egrep -v "\/\." > $Temp_Path/D.list


    cat $Temp_Path/M.list|while read i
    do
        FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
        if [ "$FileType" = "file" ];then
            echo $i >> $Temp_Path/final_list.txt
        fi
    done

    cat $Temp_Path/D.list|while read i
    do
        FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
        if [ "$FileType" = "file" ];then
            echo $i >> $Temp_Path/final_list.txt
        elif [ "$FileType" = "directory" ]; then
            echo $i >> $Temp_Path/D.dir.txt
        else 
            echo "[ERROR] Unknow file type!"
            rm -rf $Temp_Path
            exit 1
        fi
    done        


    sed s#$compare_url#$base_url# $Temp_Path/A.list > $Temp_Path/A.list.tmp
    cat $Temp_Path/A.list.tmp|while read i
    do
        FileType=$(svn info "$i"|grep 'Node Kind'|awk '{ print $3 }')
        if [ "$FileType" = "file" ];then
            origin_url=$(echo $i|sed s#$base_url#$compare_url#)
            echo $origin_url >> $Temp_Path/final_list.txt
        elif [ "$FileType" = "directory" ]; then
            origin_url=$(echo $i|sed s#$base_url#$compare_url#)
            echo $origin_url >> $Temp_Path/A.dir.txt
        else
            echo "[ERROR] Unknow file type!"
            rm -rf $Temp_Path
            exit 1
        fi
    done


    if [ -f "$Temp_Path/D.dir.txt" ];then
        cat $Temp_Path/D.dir.txt|while read i
        do
            grep $i $Temp_Path/final_list.txt &> /dev/null
            if [ $? != 0 ];then
                svn ls --recursive $i|grep -v '.*/$'|sed  "s#^#${i}\/#"|egrep -v "\/\." >> $Temp_Path/final_list.txt
            fi
        done
    fi

    if [ -f "$Temp_Path/A.dir.txt" ];then
        cat $Temp_Path/A.dir.txt|while read i
        do
            grep $i $Temp_Path/final_list.txt &> /dev/null
                if [ $? != 0 ];then
                trunk_url=$(echo $i|sed s#$compare_url#$base_url#)
                svn ls --recursive $trunk_url|grep -v '.*/$'|sed  "s#^#${compare_url}\/#"|egrep -v "\/\." >> $Temp_Path/final_list.txt
                fi
        done
    fi
    
    [ $? = 0 ] && echo "[INFO] Done."; echo
}

archive() {
    cat $Temp_Path/final_list.txt|egrep ".*\.java" > $Temp_Path/Java_File_List.txt
    cat $Temp_Path/final_list.txt|egrep -v ".*\.java" > $Temp_Path/Other_File_List.txt
    
    #Java_File_List.txt process
    Project_List=$(cat $Temp_Path/Java_File_List.txt|grep /src/|sed 's#/src.*##'|sort|uniq -c|grep -v pom.xml|awk '{ print $2 }')
    for i in $Project_List
    do  
        BaseName=$(basename $i)

        cd $Temp_Path
        echo "[INFO] Checkout $i"   
        svn checkout $i &> /dev/null
        if [ $? != 0 ];then
            echo "[ERROR] Checkout $BaseName failed"
            rm -rf $Temp_Path
            exit 1
        fi

        cd $BaseName
        if [ ! -f $build_file ];then
            echo "[ERROR] Please input exact ant build filename(s), $build_file does not exist"
            rm -rf $Temp_Path
            exit 1
        fi   

        build_file_list=$(echo $build_files|tr ',' ' ')
        for build_file in $build_file_list
        do
            if [ ! -f $build_file ];then
                echo "[ERROR] $build_file does not exist"
                rm -rf $Temp_Path
                exit 1
            fi
            echo "[INFO] Build file: $build_file"
            echo "[INFO] Building..."
            ant -buildfile $build_file &> /dev/null
            if [ $? != 0 ];then
                echo "[ERROR] Compile failed"
                rm -rf $Temp_Path
                exit 1
            else 
                echo "[INFO] Done."; echo
            fi
        done
    done   
    
    cd $Temp_Path
    java_file_list=$(cat Java_File_List.txt)
    for i in $java_file_list;
    do
       Class_File=$(basename $i|sed 's/java/class/')
       find  -type f -name $Class_File|xargs -i cp {} $Temp_Path/class_tar
    done   
 
 
    #Other_File_List.txt process 
    cd $Temp_Path/class_tar
    cat $Temp_Path/Other_File_List.txt|while read i
    do
        echo "[INFO] wget $i --user=liuchenwei --password=liuchenwei"
        wget $i  --user=liuchenwei --password=liuchenwei &>/dev/null
        if [ $? != 0 ];then
            echo "[ERROR] $i cannot download from svn server"
            rm -rf $Temp_Path
            exit 1
        elif [ -f $(basename $i) ];then
            echo "[INFO] Done."
            echo
        fi  
    done 
 
 
    #Archive        
    echo "[INFO] Last step: archive"
    cd $Temp_Path/class_tar
 
    FILES=$(ls)
    
    tar czf class.tar.gz $FILES --remove-files
    
    if [ ! -d ~/Deliverable/class_tar ];then
        mkdir -p ~/Deliverable/class_tar
    else
       rm -rf ~/Deliverable/class_tar/*
    fi

    mv class.tar.gz ~/Deliverable/class_tar
    if [ $? = 0 ];then
       echo "[INFO] Done."
       echo "[INFO] Target path: /home/ci/Deliverable/class_tar/class.tar.gz"
    fi
}

clean() {
    cd; rm -rf $Temp_Path
}




main() {
    get_diff_txt
    archive
    clean
}

main