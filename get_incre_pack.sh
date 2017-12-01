#!/bin/bash
#Author: CaoZheng
#Date: 2017/11/20
#Function: 自动生成增量包
#          第一个参数：上一个全量版本的包，tar.gz格式
#          第二个参数：待制作增量包的全量包，tar.gz格式
#          第三个参数：生成的增量包名字，压缩方式为 tar.gz

SCRIPT_PATH=$(cd $(dirname $0); pwd)

PACK_OLD=$1
PACK_NEW=$2
INCRE_PACK_NAME=$3    #增量包压缩格式为tar.gz

TMP_DIR_OLD=$(openssl rand -hex 5)    #增量包的解压目录
TMP_DIR_NEW=$(openssl rand -hex 5)    #待制作增量包的全量包解压目录
TMP_DIR_TAR=$(openssl rand -hex 5)    #存放增量文件的目录

#子目录的比较
function subDirCmp {
    for DIR in $TMP_DIR_NEW_RECURSIVE
    do
    {
        if [ ! -d  $SCRIPT_PATH/$TMP_DIR_OLD/$DIR  ]; then
            if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
            fi
            find $SCRIPT_PATH/$TMP_DIR_NEW/$DIR -maxdepth 1 -type f | xargs -i cp {} $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
        else
            cd $SCRIPT_PATH/$TMP_DIR_NEW/$DIR
            FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
            
            for i in $FILES
            do
                ls $SCRIPT_PATH/$TMP_DIR_OLD/$DIR/$i &> /dev/null
                if [ $? != 0 ]; then
                    if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                        mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                    fi
                    cp $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$i $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                else
                    RIGHT_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$i | cut -d' ' -f1)
                    LEFT_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_OLD/$DIR/$i | cut -d' ' -f1)
                    if [ $RIGHT_FILE_MD5 != $LEFT_FILE_MD5 ]; then
                        if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                            mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                        fi
                        cp $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$i $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                    fi
                fi
            done
        fi
    }&
    done
    wait
    
    for DIR in $TMP_DIR_OLD_RECURSIVE
    do
    {
        if [ ! -d  $SCRIPT_PATH/$TMP_DIR_NEW/$DIR  ]; then
            echo "rm -rf $DIR" >> $SCRIPT_PATH/delete.txt
        else
            cd $SCRIPT_PATH/$TMP_DIR_OLD/$DIR
            FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
            
            for file in $FILES
            do
                ls $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$file &> /dev/null
                if [ $? != 0 ]; then
                    echo "rm -f $DIR/$file" >> $SCRIPT_PATH/delete.txt
                else
                    RIGHT_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$file | cut -d' ' -f1)
                    LEFT_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_NEW/$DIR/$file | cut -d' ' -f1)
                    if [ $RIGHT_FILE_MD5 != $LEFT_FILE_MD5 ]; then
                        echo "rm -f $DIR/$file" >> $SCRIPT_PATH/delete.txt
                    fi
                fi
            done
        fi
    }&
    done
    wait
}

#顶级目录的比较
function rootDirCmp {
    cd  $SCRIPT_PATH/$TMP_DIR_NEW
    TMP_DIR_NEW_FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
    
    cd  $SCRIPT_PATH/$TMP_DIR_OLD
    TMP_DIR_OLD_FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
    
    for i in $TMP_DIR_NEW_FILES
    do
    {
        if [ ! -f $SCRIPT_PATH/$TMP_DIR_OLD/$i ]; then
            cp $SCRIPT_PATH/$TMP_DIR_NEW/$i $SCRIPT_PATH/$TMP_DIR_TAR
        else
            TMP_DIR_NEW_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_NEW/$i | cut -d' ' -f1)
            TMP_DIR_OLD_FILE_MD5=$(md5sum $SCRIPT_PATH/$TMP_DIR_OLD/$i | cut -d' ' -f1)
            if [ $TMP_DIR_NEW_FILE_MD5 != $TMP_DIR_OLD_FILE_MD5 ]; then
                cp $SCRIPT_PATH/$TMP_DIR_NEW/$i $SCRIPT_PATH/$TMP_DIR_TAR
            fi
        fi
    }&
    done
    wait

    for file in $TMP_DIR_OLD_FILES
    do
    {
        if [ ! -f $SCRIPT_PATH/$TMP_DIR_NEW/$file ]; then
            echo "rm -f $file" >> $SCRIPT_PATH/delete.txt
        fi
    }&
    done
    wait
}


function main {
    mkdir $TMP_DIR_OLD
    mkdir $TMP_DIR_NEW
    mkdir $TMP_DIR_TAR
    
    tar zxf $PACK_OLD -C $TMP_DIR_OLD
    tar zxf $PACK_NEW -C $TMP_DIR_NEW

    #左右两侧所有目录及其子目录列表
    TMP_DIR_OLD_RECURSIVE=$(find $TMP_DIR_OLD -type d | grep -v ${TMP_DIR_OLD}$ | sed "s#$TMP_DIR_OLD/##")
    TMP_DIR_NEW_RECURSIVE=$(find $TMP_DIR_NEW -type d | grep -v ${TMP_DIR_NEW}$ | sed "s#$TMP_DIR_NEW/##")
    
    subDirCmp
    rootDirCmp

    #打包
    cd $SCRIPT_PATH/$TMP_DIR_TAR
    tar czf $INCRE_PACK_NAME $(ls)
    mv $INCRE_PACK_NAME $SCRIPT_PATH
    
    cd $SCRIPT_PATH
    
    echo "服务器上的增量应用目录中需要删除的文件："
    cat delete.txt
    
    rm -rf $TMP_DIR_OLD
    rm -rf $TMP_DIR_NEW
    rm -rf $TMP_DIR_TAR
    rm -f delete.txt
}

main
