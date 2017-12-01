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
    for DIR in $RIGHT_DIR_RECURSIVE
    do
    {
        if [ ! -d  $SCRIPT_PATH/$LEFT_DIR/$DIR  ]; then
            if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
            fi
            find $SCRIPT_PATH/$RIGHT_DIR/$DIR -maxdepth 1 -type f | xargs -i cp {} $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
        else
            cd $SCRIPT_PATH/$RIGHT_DIR/$DIR
            FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
            
            for i in $FILES
            do
                ls $SCRIPT_PATH/$LEFT_DIR/$DIR/$i &> /dev/null
                if [ $? != 0 ]; then
                    if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                        mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                    fi
                    cp $SCRIPT_PATH/$RIGHT_DIR/$DIR/$i $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                else
                    RIGHT_FILE_MD5=$(md5sum $SCRIPT_PATH/$RIGHT_DIR/$DIR/$i | cut -d' ' -f1)
                    LEFT_FILE_MD5=$(md5sum $SCRIPT_PATH/$LEFT_DIR/$DIR/$i | cut -d' ' -f1)
                    if [ $RIGHT_FILE_MD5 != $LEFT_FILE_MD5 ]; then
                        if [ ! -d $SCRIPT_PATH/$TMP_DIR_TAR/$DIR ]; then
                            mkdir -p $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                        fi
                        cp $SCRIPT_PATH/$RIGHT_DIR/$DIR/$i $SCRIPT_PATH/$TMP_DIR_TAR/$DIR
                    fi
                fi
            done
        fi
    }&
    done
    wait
    
    for DIR in $LEFT_DIR_RECURSIVE
    do
    {
        if [ ! -d  $SCRIPT_PATH/$RIGHT_DIR/$DIR  ]; then
            echo "rm -rf $(ls $SCRIPT_PATH/$TMP_DIR_OLD)/$DIR" >> $SCRIPT_PATH/delete.txt
        else
            cd $SCRIPT_PATH/$LEFT_DIR/$DIR
            FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
            
            for file in $FILES
            do
                ls $SCRIPT_PATH/$RIGHT_DIR/$DIR/$file &> /dev/null
                if [ $? != 0 ]; then
                    echo "rm -f $(ls $SCRIPT_PATH/$TMP_DIR_OLD)/$DIR/$file" >> $SCRIPT_PATH/delete.txt
                fi
            done
        fi
    }&
    done
    wait
}

#顶级目录的比较
function rootDirCmp {
    cd  $SCRIPT_PATH/$RIGHT_DIR
    RIGHT_DIR_FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
    
    cd  $SCRIPT_PATH/$LEFT_DIR
    LEFT_DIR_FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")
    
    for file in $RIGHT_DIR_FILES
    do
    {
        if [ ! -f $SCRIPT_PATH/$LEFT_DIR/$file ]; then
            cp $SCRIPT_PATH/$RIGHT_DIR/$file $SCRIPT_PATH/$TMP_DIR_TAR
        else
            RIGHT_DIR_FILE_MD5=$(md5sum $SCRIPT_PATH/$RIGHT_DIR/$file | cut -d' ' -f1)
            LEFT_DIR_FILE_MD5=$(md5sum $SCRIPT_PATH/$LEFT_DIR/$file | cut -d' ' -f1)
            if [ $RIGHT_DIR_FILE_MD5 != $LEFT_DIR_FILE_MD5 ]; then
                cp $SCRIPT_PATH/$RIGHT_DIR/$file $SCRIPT_PATH/$TMP_DIR_TAR
            fi
        fi
    }&
    done
    wait

    for file in $LEFT_DIR_FILES
    do
    {
        if [ ! -f $SCRIPT_PATH/$RIGHT_DIR/$file ]; then
            echo "rm -f $(ls $SCRIPT_PATH/$TMP_DIR_OLD)/$file" >> $SCRIPT_PATH/delete.txt
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
    
    LEFT_DIR="$TMP_DIR_OLD/$(ls $TMP_DIR_OLD)"
    RIGHT_DIR="$TMP_DIR_NEW/$(ls $TMP_DIR_NEW)"
    
    #左右两侧递归目录列表(除了顶级目录)
    LEFT_DIR_RECURSIVE=$(find $LEFT_DIR -type d | grep -v ${LEFT_DIR}$ | sed "s#$LEFT_DIR/##")
    RIGHT_DIR_RECURSIVE=$(find $RIGHT_DIR -type d | grep -v ${RIGHT_DIR}$ | sed "s#$RIGHT_DIR/##")
    
    subDirCmp
    rootDirCmp

    #打包
    cd $SCRIPT_PATH/$TMP_DIR_TAR
    tar czf $INCRE_PACK_NAME $(ls)
    mv $INCRE_PACK_NAME $SCRIPT_PATH
    
    cd $SCRIPT_PATH
    
    echo "服务器上的增量应用目录中需要删除的文件："
    cat $SCRIPT_PATH/delete.txt
    
    rm -rf $TMP_DIR_OLD
    rm -rf $TMP_DIR_NEW
    rm -rf $TMP_DIR_TAR
    rm -f delete.txt
}

main
