#!/bin/bash
#Author: CaoZheng
#Date: 2017/05/25


Script_Path=$(dirname $0)
Temp_Path=/tmp/$(openssl rand -hex 5)

mkdir $Temp_Path


compare_url="$1"
base_url="$2"

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
            echo "================="
            echo "Unknow file type!"
            echo "================="
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
            echo "================="
            echo "Unknow file type!"
            echo "================="
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
    
    echo "[INFO] Done."; echo
}

archive_jar() {
    mkdir $Temp_Path/jar_war

    Project_List=$(cat $Temp_Path/final_list.txt|grep /src/|sed 's#/src.*##'|sort|uniq -c|grep -v pom.xml|awk '{ print $2 }')
    for i in $Project_List
    do  
        local BaseName=$(basename $i)

        cd $Temp_Path
        echo "[INFO] Checkout $i"   
        svn checkout $i &> /dev/null
        if [ $? != 0 ];then
            echo "[ERROR] Checkout $BaseName failed"
            rm -rf $Temp_Path
            exit 1
        fi

        echo "[INFO] Compile $BaseName"    
        cd $BaseName
        mvn clean install -DskipTests &> /dev/null
        if [ $? != 0 ];then
            echo "[ERROR] Compile $(basename $i) failed"
            rm -rf $Temp_Path
            exit 1
        else 
            echo "[INFO] Done."
        fi
        cd target
        ls|egrep "*.jar|*.war"|xargs -i mv {} $Temp_Path/jar_war
        echo
    done

    echo "[INFO] Last step: archive"
    cd $Temp_Path/jar_war
    local FILES=$(ls |egrep "*.jar|*.war")
    tar czf jar_war.tar.gz $FILES --remove-files
    
    if [ ! -d ~/Deliverable/jar_tar ];then
        mkdir -p ~/Deliverable/jar_tar
    else
        rm -rf ~/Deliverable/jar_tar/*
    fi

    mv jar_war.tar.gz ~/Deliverable/jar_tar
    if [ $? = 0 ];then
        echo "[INFO] Done."
        echo "[INFO] Target path: /home/ci/Deliverable/jar_tar/jar_war.tar.gz"
    fi
}

clean() {
    cd; rm -rf $Temp_Path
}




main() {
    get_diff_txt
    archive_jar
    clean
}

main