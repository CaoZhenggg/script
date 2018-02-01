#!/bin/bash
#Author: CaoZheng
#注意：
#  1.需要检查file目录是否存在，里面有四个脚本，数据库部署时用到。
#    这四个脚本暂时不存放到svn，所以每次脚本执行必须要检查文件存不存在！！
#   md5码如下：
#   e2ff5e8cf18e6a83ebad7fc3d87e6f0d  rebuild_rollback.sql
#   2c9d5f7951c83b7996e35d9a20d75393  rebuild_update.sql
#   7d68ab4d5fd8c69d1a318599a0336b1b  rollback.sh
#   e90520fb132c8cb112cee8cd67cc0cb6  update.sh

DB_URL_OLD=$1
DB_URL_NEW=$2

ARCHIVE_TYPE=$3      #后端应用是增量（根据代码差异清单）还是全量
SVN_URL_BACKEND=$4

START_REVISION=$5
END_REVISION=$6

# 初始化操作
function init
{
    JENKINS_ITEM_NAME=fxmss_get_deliverable
    JENKINS_ITEM_NAME_ESCAPE=fxmss_get_deliverable

    SVN_USER=liuchenwei
    SVN_PASSWORD=liuchenwei

    BUILD_NUMBER=$(curl http://localhost:8080/job/$JENKINS_ITEM_NAME_ESCAPE/lastBuild/buildNumber)

    WORK_PATH=$(pwd)
    SCRIPT_PATH=$(cd $(dirname $0); pwd)
    TMP_DIR00=/tmp/$(openssl rand -hex 5)       #拉取svn上数据库文件的临时目录
    TMP_DIR01=/tmp/$(openssl rand -hex 5)       #存放数据库增量文件的临时目录
    TMP_DIR02=/tmp/$(openssl rand -hex 5)       # 生成应用增量包的临时目录

    # 助讯通ID
    USER[1]=1460    #*陈伟
    USER[0]=1796    #曹政
    USER[2]=1494    #*帆

    # 创建临时文件
    mkdir $TMP_DIR00
    mkdir $TMP_DIR01
    mkdir $TMP_DIR02
}

# 格式化日志
function log_format
{
    local log_color=$1
    local log_level=$2
    local log_text=$3
    local date_format=$(date +"%Y-%m-%d %H:%M:%S %Z")

    local interactive_mode=off
    if [ $interactive_mode = off ]; then
        LOG_COLOR_COLORLESS=""
        LOG_COLOR_INFO=""
        LOG_COLOR_SUCCESS=""
        LOG_COLOR_WARNING=""
        LOG_COLOR_ERROR=""
    else
        LOG_COLOR_COLORLESS=$(tput sgr 0)
        LOG_COLOR_INFO=$(tput sgr 0)
        LOG_COLOR_SUCCESS=$(tput setaf 2)
        LOG_COLOR_WARNING=$(tput setaf 3)
        LOG_COLOR_ERROR=$(tput setaf 1)
    fi

    printf "${log_color}[$date_format] [$log_level] $log_text $LOG_COLOR_COLORLESS\n"
}

function logging_info { log_format "$LOG_COLOR_INFO" 'INFO' "$1"; }
function logging_success { log_format "$LOG_COLOR_SUCCESS" 'SUCCESS' "$1"; }
function logging_warning { log_format "$LOG_COLOR_WARNING" 'WARNNING' "$1"; }
function logging_error { log_format "$LOG_COLOR_ERROR" 'ERROR' "$1" ; }

function clean
{
    rm -rf $TMP_DIR00
    rm -rf $TMP_DIR01
    rm -rf $TMP_DIR02
}

# 助讯通消息
function zxt_msg
{
    encoding=GBK

    if [ $1 == error ]; then
        msg=$(echo  "Event：场务监测打包生成发布物失败！ Log：http://172.17.192.170:8080/view/FXMSS/job/$JENKINS_ITEM_NAME/${BUILD_NUMBER}/console Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins: 请运维攻城狮尽快解决，谢谢！" | iconv -t $encoding)

        for user in ${USER[@]}
        do
            curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1460&msg=$msg" &>/dev/null
        done

        clean && exit 1
    fi

    if [ $1 == ok ]; then
        msg00=$(echo  "Event：场务监测打包发生成布物成功！ Log：http://172.17.192.170:8080/view/FXMSS/job/$JENKINS_ITEM_NAME/${BUILD_NUMBER}/console Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins: 小case！" | iconv -t $encoding)

        msg01=$(echo  "应用发布物下载：ftp://172.17.192.170/pub/fxmss_package/CFETS3-FXMSS_V${VERSION}-QDM.tgz MD5码：$(md5sum /var/ftp/pub/fxmss_package/CFETS3-FXMSS_V${VERSION}-QDM.tgz | awk '{ print $1 }')" | iconv -t $encoding)

        msg02=$(echo  "数据库发布物下载：ftp://172.17.192.170/pub/fxmss_package/CFETS3-FXMSS_V${VERSION}-QDM.zip MD5码：$(md5sum /var/ftp/pub/fxmss_package/CFETS3-FXMSS_V${VERSION}-QDM.zip | awk '{ print $1 }')" | iconv -t $encoding)

        for user in ${USER[@]}
        do
            curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1460&msg=$msg00" &>/dev/null
            curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1460&msg=$msg01" &>/dev/null
            curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1460&msg=$msg02" &>/dev/null
        done

        clean && exit 0
    fi
}

function check
{
    svn info $SVN_URL_BACKEND &> /dev/null
    if [ $? != 0 ]; then
        logging_error "svn_url_backend is not valid!"
        zxt_msg "error"
    fi

    svn info $DB_URL_OLD &> /dev/null
    if [ $? != 0 ]; then
        logging_error "database_path_old is not valid!"
        zxt_msg "error"
    fi

    svn info $DB_URL_NEW &> /dev/null
    if [ $? != 0 ]; then
        logging_error "database_path_new is not valid!"
        zxt_msg "error"
    fi

    #检查磁盘空间是否有500M可用
    DISK_SIZE=$(df -k | grep '/home/ci$' | awk '{ print $3 }')
    if [ $DISK_SIZE -lt 512000 ]; then
        logging_error "/home/ci space is less than 500M!!!"
        zxt_msg "error"
    fi

    #检查svn上fms和job的pom.xml文件中应用的版本是否一致
    MAVEN_VERSION_fms="$(cat /home/ci/.jenkins/jobs/$JENKINS_ITEM_NAME_ESCAPE/workspace/fxmss-dp-fms/pom.xml|grep -A 1 '<artifactId>fxmss-dp-fms</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')"
    MAVEN_VERSION_job="$(cat /home/ci/.jenkins/jobs/$JENKINS_ITEM_NAME_ESCAPE/workspace/fxmss-dp-job/pom.xml |grep -A 1 '<artifactId>fxmss-dp-job</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')"

    if [ $MAVEN_VERSION_fms != $MAVEN_VERSION_job ]; then
        logging_error "MAVEN_VERSION_fms is not equal MAVEN_VERSION_job, please check file pom.xml on svn!"
        zxt_msg "error"
    else
        VERSION=$MAVEN_VERSION_fms
    fi

    if [ ! -d $SCRIPT_PATH/file ]; then
        logging_error "$SCRIPT_PATH/file directory does not exist!"
        zxt_msg "error"
    fi

    #这个目录里有四个脚本，数据库部署需要用到
    if [ ! -d $SCRIPT_PATH/file ]; then
        logging_error "$SCRIPT_PATH/file directory does not exist!"
        zxt_msg "error"
    fi

    if [ ! -f $SCRIPT_PATH/file/rebuild_rollback.sql ]; then
        logging_error "$SCRIPT_PATH/file/rebuild_rollback.sql does not exist!"
        zxt_msg "error"
    fi

    if [ ! -f $SCRIPT_PATH/file/rebuild_update.sql ]; then
        logging_error "$SCRIPT_PATH/file/rebuild_update.sql does not exist!"
        zxt_msg "error"
    fi

    if [ ! -f $SCRIPT_PATH/file/rollback.sh ]; then
        logging_error "$SCRIPT_PATH/file/rollback.sh does not exist!"
        zxt_msg "error"
    fi

    if [ ! -f $SCRIPT_PATH/file/update.sh ]; then
        logging_error "$SCRIPT_PATH/file/update.sh does not exist!"
        zxt_msg "error"
    fi

    local rebuild_rollback_md5=$(md5sum $SCRIPT_PATH/file/rebuild_rollback.sql | awk '{ print $1 }')
    if [ $rebuild_rollback_md5 != e2ff5e8cf18e6a83ebad7fc3d87e6f0d ]; then
        logging_error " md5 of file $SCRIPT_PATH/file/rebuild_rollback.sql was changed!!!"
        zxt_msg "error"
    fi

    local rebuild_update_md5=$(md5sum $SCRIPT_PATH/file/rebuild_update.sql | awk '{ print $1 }')
    if [ $rebuild_update_md5 != 2c9d5f7951c83b7996e35d9a20d75393 ]; then
        logging_error " md5 of file $SCRIPT_PATH/file/rebuild_update.sql was changed!!!"
        zxt_msg "error"
    fi

    local rollback_md5=$(md5sum $SCRIPT_PATH/file/rollback.sh | awk '{ print $1 }')
    if [ $rollback_md5 != 7d68ab4d5fd8c69d12318599a0336b1b ]; then
        logging_error " md5 of file $SCRIPT_PATH/file/rebuild_update.sql was changed!!!"
        zxt_msg "error"
    fi

    local update_md5=$(md5sum $SCRIPT_PATH/file/update.sh | awk '{ print $1 }')
    if [ $update_md5 != e90520fb132c8cb112cee8cd67cc0cb6 ]; then
        logging_error " md5 of file $SCRIPT_PATH/file/update.sh was changed!!!"
        zxt_msg "error"
    fi

    #ftp目录, 产物就放到该目录供下载
    if [ -d /var/ftp/pub/fxmss_package ]; then
        rm -rf /var/ftp/pub/fxmss_package/*
    else
        mkdir /var/ftp/pub/fxmss_package/ -p
    fi
}

function archive_frontend
{
    cd $WORK_PATH/frontend
    mkdir frontend
    cp -r audio js styles data favicon.ico index.html frontend/
    find frontend/ -type d -name '.svn' | xargs -i rm -rf {}
    tar zcf /var/ftp/pub/fxmss_package/FXMSS_V${VERSION}.frontend.tgz frontend --remove-files
}

#获取两个版本的数据库目录01_FXMSS/01_scripts下除了00_init目录以外的所有差异文件
function db_cmp
{
    DB_VERSION_OLD=$(echo $DB_URL_OLD | cut -d '/' -f 8 | grep -oP '\d(\.\d)+')
    DB_VERSION_NEW=$(echo $DB_URL_NEW | cut -d '/' -f 8 | grep -oP '\d(\.\d)+')

    #从svn拉取两个版本的数据库文件
    mkdir $TMP_DIR00/$DB_VERSION_OLD
    cd $TMP_DIR00/$DB_VERSION_OLD
    svn co $DB_URL_OLD
    find . -type d -name '.svn' | xargs -i rm -rf {}

    mkdir $TMP_DIR00/$DB_VERSION_NEW
    cd $TMP_DIR00/$DB_VERSION_NEW
    svn co $DB_URL_NEW
    find . -type d -name '.svn' | xargs -i rm -rf {}

    CMP_DIR_BASE=$TMP_DIR00/$DB_VERSION_OLD/01_FXMSS/01_scripts
    CMP_DIR=$TMP_DIR00/$DB_VERSION_NEW/01_FXMSS/01_scripts
    CMP_DIR_dirs=$(find $CMP_DIR -type d | grep -v ${CMP_DIR}$ | grep -v '00_init' | sed "s#$CMP_DIR/##")       #所有子目录的列表，不包括CMP_DIR目录下的一级目录

    for DIR in $CMP_DIR_dirs
    do
    {
        if [ ! -d  $CMP_DIR_BASE/$DIR  ]; then
            if [ ! -d $TMP_DIR01/$DIR ]; then
                mkdir -p $TMP_DIR01/$DIR
            fi
            find $CMP_DIR/$DIR -maxdepth 1 -type f | xargs -i cp {} $TMP_DIR01/$DIR
        else
            cd $CMP_DIR/$DIR
            FILES=$(find . -maxdepth 1 -type f | sed "s#^\./##")

            for i in $FILES
            do
                ls $CMP_DIR_BASE/$DIR/$i &> /dev/null
                if [ $? != 0 ]; then
                    if [ ! -d $TMP_DIR01/$DIR ]; then
                        mkdir -p $TMP_DIR01/$DIR
                    fi
                    cp $CMP_DIR/$DIR/$i $TMP_DIR01/$DIR
                else
                    RIGHT_FILE_MD5=$(md5sum $CMP_DIR/$DIR/$i | cut -d' ' -f1)
                    LEFT_FILE_MD5=$(md5sum $CMP_DIR_BASE/$DIR/$i | cut -d' ' -f1)
                    if [ $RIGHT_FILE_MD5 != $LEFT_FILE_MD5 ]; then
                        if [ ! -d $TMP_DIR01/$DIR ]; then
                            mkdir -p $TMP_DIR01/$DIR
                        fi
                        cp $CMP_DIR/$DIR/$i $TMP_DIR01/$DIR
                    fi
                fi
            done
        fi
    }&
    done
    wait
}

function archive_database
{
    #database
    cd $TMP_DIR01
    mkdir 01_FXMSS
    mv $(ls | grep -v 01_FXMSS) 01_FXMSS/

    # 02_update目录中要排除其它版本的目录
    cd $TMP_DIR00/$DB_VERSION_NEW/01_FXMSS/02_update
    ls | egrep -v "$DB_VERSION_NEW|02_update" | xargs -i rm -rf {}

    cp -r $TMP_DIR00/$DB_VERSION_NEW/01_FXMSS/02_update $TMP_DIR01/01_FXMSS/
    cp $TMP_DIR00/$DB_VERSION_NEW/01_FXMSS/build-01_FXMSS.sql $TMP_DIR01/01_FXMSS/
    cp $TMP_DIR00/$DB_VERSION_NEW/01_FXMSS/rollback-01_FXMSS.sql $TMP_DIR01/01_FXMSS/

    #检查build-01_FXMSS.sql调用的脚本路径是否正确
    cat $TMP_DIR01/01_FXMSS/build-01_FXMSS.sql | egrep -v 'prompt|^$' | egrep -v '^@./01_FXMSS' &> /dev/null
    if [ $? == 0 ]; then
        logging_error "Wrong path of files called by build-01_FXMSS.sql, please check!"
        clean && exit 1
    fi

    #检查build-01_FXMSS.sql中调用的脚本数目和发布物中的sql文件数是否一致
    local file_nums=$(find $TMP_DIR01/01_FXMSS/ -type f -name "*\.sql" | egrep -v "rollback-01_FXMSS.sql|build-01_FXMSS.sql" | wc -l)
    local invoke_nums=$(cat $TMP_DIR01/01_FXMSS/build-01_FXMSS.sql | egrep '^@' | wc -l)
    if [ $file_nums != $invoke_nums ]; then
        logging_error "Wrong number of files called by build-01_FXMSS.sql, please check!"
        clean && exit 1
    fi

    #copy本脚本同级目录下的file目录中的脚本
    cd $TMP_DIR01
    cp $SCRIPT_PATH/file/rebuild_rollback.sql .
    cp $SCRIPT_PATH/file/rebuild_update.sql .
    cp $SCRIPT_PATH/file/rollback.sh .
    cp $SCRIPT_PATH/file/update.sh .

    find . -type d -name '.svn' | xargs -i rm -rf {}
    zip -r CFETS3-FXMSS_V${VERSION}-QDM.zip ./*
    mv CFETS3-FXMSS_V${VERSION}-QDM.zip /var/ftp/pub/fxmss_package/
}

function maven_compile
{
    #models="fxmss-s-config fxmss-s-basic fxmss-s-imt fxmss-u-api fxmss-u-ams fxmss-u-dps fxmss-u-dqs fxmss-u-jss fxmss-u-rss fxmss-dp-fms fxmss-dp-job"
    local models='fxmss-p-parent'
    for model in $models
    do
        cd $WORK_PATH/$model
        mvn clean install -DskipTests

        if [ $? != 0 ]; then
          echo ''
          logging_error "Compile ERROR!!!!!!!!!!!!"
          echo ''

          zxt_msg "error"
        fi

        cd ..
    done
}

function archive_fms_full
{
    cd $WORK_PATH/fxmss-dp-fms/target/
    mv fxmss-dp-fms-${VERSION} fxmss-dp-fms
    find fxmss-dp-fms/ -type d -name '.svn' | xargs -i rm -rf {}
    tar zcf /var/ftp/pub/fxmss_package/FXMSS_V${VERSION}.fms.tgz fxmss-dp-fms --remove-files
}

function archive_fms_incre
{
    #增量jar包
    local modules="fxmss-u-dps fxmss-u-ams fxmss-s-imt fxmss-s-config fxmss-s-basic fxmss-u-dqs fxmss-dp-fms"

    for module in $modules
    do
        cat $TMP_DIR02/fxmss_backend_diff_list.txt | grep /$module/ &> /dev/null
        if [ $? == 0 ]; then
            echo $module >> $TMP_DIR02/fms.txt
        fi
    done

    local incre_module_list=$(cat $TMP_DIR02/fms.txt | tr '\n' '|' | sed 's#|$##')
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/target/fxmss-dp-fms-$MAVEN_VERSION_fms/lib/
    ls | egrep -v "$incre_module_list" | xargs -i rm -rf {}

    #保留fxmss-dp-fms/src/main/conf目录下的所有文件
    local incre_conf_list=$(cat $TMP_DIR02/fxmss_backend_diff_list.txt | grep fxmss-dp-fms/src/main/conf | awk -F/ '{ print $NF}' | tr '\n' '|' | sed 's#|$##')
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/target/fxmss-dp-fms-$MAVEN_VERSION_fms/conf
    ls | egrep -v "$incre_file_list" | xargs -i rm -rf {}

    #保留fxmss-dp-fms/src/main/web目录下的所有文件
    local incre_web_list=$(cat $TMP_DIR02/fxmss_backend_diff_list.txt | grep fxmss-dp-fms/src/main/web | awk -F'/web/' '{ print $2 }' | tr '\n' '|' | sed 's#|$##')
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/target/fxmss-dp-fms-$MAVEN_VERSION_fms/web
    find . -type f | sed "s#^./##" | egrep -v "$incre_web_list" | xargs -i rm -rf {}

    #bin目录，启动脚本是自动生成的，所以差异清单中没有
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/target/fxmss-dp-fms-$MAVEN_VERSION_fms/bin
    ls | egrep -v 'version|startup.sh' | xargs -i rm -rf {}

    #archive
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/target/fxmss-dp-fms-$MAVEN_VERSION_fms
    tar czf /var/ftp/pub/fxmss_package/FXMSS_V${MAVEN_VERSION_fms}.fms.tgz bin/ conf/ lib/ web/
}

function archive_job_full
{
    cd $WORK_PATH/fxmss-dp-job/target/
    mv fxmss-dp-job-${VERSION} fxmss-dp-job
    find fxmss-dp-job/ -type d -name '.svn' | xargs -i rm -rf {}
    tar zcf /var/ftp/pub/fxmss_package/FXMSS_V${VERSION}.job.tgz fxmss-dp-job --remove-files
}

function archive_job_incre
{
    #增量jar包
    local modules="fxmss-u-jss fxmss-u-api fxmss-s-imt fxmss-s-config fxmss-s-basic fxmss-s-rss fxmss-dp-job"

    for module in $modules
    do
        cat $TMP_DIR02/fxmss_backend_diff_list.txt | grep /$module/ &> /dev/null
        if [ $? == 0 ]; then
            echo $module >> $TMP_DIR02/job.txt
        fi
    done


    local incre_module_list=$(cat $TMP_DIR02/job.txt | tr '\n' '|' | sed 's#|$##')
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-job/target/fxmss-dp-job-$MAVEN_VERSION_job/lib/
    ls | egrep -v "$incre_module_list" | xargs -i rm -rf {}

    #保留fxmss-dp-job/src/main/conf目录下的所有文件
    local incre_conf_list=$(cat $TMP_DIR02/fxmss_backend_diff_list.txt | grep fxmss-dp-job/src/main/conf | awk -F/ '{ print $NF}' | tr '\n' '|' | sed 's#|$##')
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-job/target/fxmss-dp-job-$MAVEN_VERSION_job/conf
    ls | egrep -v "$incre_file_list" | xargs -i rm -rf {}

    #bin目录，启动脚本是自动生成的，所以差异清单中没有
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-job/target/fxmss-dp-job-$MAVEN_VERSION_job/bin
    ls | egrep -v 'version|startup.sh' | xargs -i rm -rf {}

    #archive
    cd $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-job/target/fxmss-dp-job-$MAVEN_VERSION_job
    tar czf /var/ftp/pub/fxmss_package/FXMSS_V${MAVEN_VERSION_job}.job.tgz bin/ conf/ lib/
}

function app_archive
{
    if [ x$ARCHIVE_TYPE == xfull ]; then
        maven_compile
        archive_fms_full
        archive_job_full
    elif [ x$ARCHIVE_TYPE == xincre ]; then
        #获取差异清单
        svn diff --username $SVN_USER --password $SVN_PASSWORD -r $START_REVISION:$END_REVISION --summarize $SVN_URL_BACKEND | egrep -v "\/\." | awk '{ print $2 }' > $TMP_DIR02/fxmss_backend_diff_list.txt

        cd $TMP_DIR02
        svn co $SVN_URL_BACKEND &> /dev/null

        #app version check
        MAVEN_VERSION_fms=$(cat $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-fms/pom.xml|grep -A 1 '<artifactId>fxmss-dp-fms</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')
        MAVEN_VERSION_job=$(cat $TMP_DIR02/25_FXMSS_Backend/fxmss-dp-job/pom.xml |grep -A 1 '<artifactId>fxmss-dp-job</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')

        if [ $MAVEN_VERSION_fms != $MAVEN_VERSION_job ];then
            logging_error "MAVEN_VERSION_fms is not equal MAVEN_VERSION_job, please check pom.xml!"
            zxt_msg "error"
        fi

        cd $TMP_DIR02/25_FXMSS_Backend/fxmss-p-parent
        mvn clean install -DskipTests
        if [ $? != 0 ]; then
            echo ''
            logging_error "compile error!"
            echo ''
            zxt_msg "error"
        fi

        archive_fms_incre
        archive_job_incre
    fi

    #将fms、job、前端压缩包再次打包压缩为交付物
    cd /var/ftp/pub/fxmss_package/
    tar czf CFETS3-FXMSS_V${VERSION}-QDM.tgz FXMSS_V${VERSION}.fms.tgz FXMSS_V${VERSION}.job.tgz FXMSS_V${VERSION}.frontend.tgz --remove-files
}




function main
{
    init
    check
    archive_frontend
    db_cmp
    archive_database
    app_archive
    zxt_msg "ok"
}

main
