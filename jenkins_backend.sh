#!/bin/bash
#Author: CaoZheng
#Date: 2017/06/22
#-------------------------------------------------------#
#Modify: logical optimization
#Date: 2017/08/29
#Author: CaoZheng
#-------------------------------------------------------#

source /etc/profile
source ~/.bash_profile

WORKPATH=$(pwd)
TMPPATH=/tmp/$(openssl rand -hex 5)

mkdir $TMPPATH 

USER[0]=1796    #曹政
USER[1]=1460    #刘陈伟
USER[2]=1494    #白帆
USER[3]=1522    #蒋志芳
USER[4]=1870    #白祥旭
USER[5]=1751    #胖媚月
USER[6]=1732    #季英财
USER[7]=1750    #于彬
USER[8]=1995    #李鹏

INTERACTIVE_MODE=off

if [ $INTERACTIVE_MODE = off ];then
    LOG_DEFAULT_COLOR=""
    LOG_INFO_COLOR=""
    LOG_SUCCESS_COLOR=""
    LOG_WARN_COLOR=""
    LOG_ERROR_COLOR=""
else
    LOG_DEFAULT_COLOR=$(tput sgr 0)
    LOG_INFO_COLOR=$(tput sgr 0)
    LOG_SUCCESS_COLOR=$(tput setaf 2)
    LOG_WARN_COLOR=$(tput setaf 3)
    LOG_ERROR_COLOR=$(tput setaf 1)
fi

color_log() {
    local log_text=$1
    local log_level=$2
    local log_color=$3
    
    printf "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [$log_level] ${log_text} ${LOG_DEFAULT_COLOR}\n"
}

log_info() { color_log "$1" "INFO" "$LOG_INFO_COLOR"; }
log_success() { color_log "$1" "SUCCESS" "$LOG_SUCCESS_COLOR"; }
log_warning() { color_log "$1" "WARNNING" "$LOG_WARN_COLOR"; }
log_error() { color_log "$1" "ERROR" "$LOG_ERROR_COLOR"; }

error_exit() {
    rm -rf $TMPPATH
    
    #send error massage to USER
    encoding=GBK
    msg=$(echo  "场务监测系统ST后端部署失败！ 时间：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins" | iconv -t $encoding)
    
    for user in ${USER[@]}
    do
        curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1796&msg=$msg" &>/dev/null
    done
    
    exit 1
}

check() {
    MAVEN_VERSION_fms=$(cat /home/ci/.jenkins/jobs/FXMSS_Backend_Upgrade\(ST\)/workspace/fxmss-dp-fms/pom.xml|grep -A 1 '<artifactId>fxmss-dp-fms</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')
    MAVEN_VERSION_job=$(cat /home/ci/.jenkins/jobs/FXMSS_Backend_Upgrade\(ST\)/workspace/fxmss-dp-job/pom.xml |grep -A 1 '<artifactId>fxmss-dp-job</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')
    if [ $MAVEN_VERSION_fms != $MAVEN_VERSION_job ];then
        log_error "MAVEN_VERSION_fms is not equal MAVEN_VERSION_job, please check pom.xml!"
        error_exit
    else
        VERSION=$MAVEN_VERSION_fms
    fi

    if [ ! -d $WORKPATH/fxmss-dp-fms/target/fxmss-dp-fms-$VERSION ];then
        log_error "fxmss-dp-fms-$VERSION directory does not exist at host jenkins!"
        error_exit
    fi

    if [ ! -d $WORKPATH/fxmss-dp-job/target/fxmss-dp-job-$VERSION ];then
        log_error "fxmss-dp-job-$VERSION directory does not exist at host jenkins!"
        error_exit
    fi
}

archive() {
    if [ ! -d ~/Deliverable/fxmss_backend ];then
        mkdir ~/Deliverable/fxmss_backend -p
    fi

    #fms
    cd $WORKPATH/fxmss-dp-fms/target/
    cp -r fxmss-dp-fms-${VERSION} $TMPPATH/fxmss-dp-fms
    
    cd $TMPPATH
    tar zcf FXMSS_V${VERSION}.fms.tar.gz fxmss-dp-fms
    mv FXMSS_V${VERSION}.fms.tar.gz ~/Deliverable/fxmss_backend    

    #job
    cd $WORKPATH/fxmss-dp-job/target/
    cp -r fxmss-dp-job-${VERSION} $TMPPATH/fxmss-dp-job
    
    cd $TMPPATH
    tar zcf FXMSS_V${VERSION}.job.tar.gz fxmss-dp-job
    mv FXMSS_V${VERSION}.job.tar.gz ~/Deliverable/fxmss_backend 
}

send_deliverable() {
    ssh fxmss@172.17.192.216 'ls /home/fxmss/tmp/fxmss_backend' &> /dev/null
    if [ $? != 0 ];then
        ssh fxmss@172.17.192.216 'mkdir -p /home/fxmss/tmp/fxmss_backend'
    fi
    
    ssh fxmss@172.17.192.217 'ls /home/fxmss/tmp/fxmss_backend' &> /dev/null
    if [ $? != 0 ];then
        ssh fxmss@172.17.192.217 'mkdir -p /home/fxmss/tmp/fxmss_backend'
    fi

    scp ~/Deliverable/fxmss_backend/FXMSS_V${VERSION}.fms.tar.gz fxmss@172.17.192.216:/home/fxmss/tmp/fxmss_backend
    scp ~/Deliverable/fxmss_backend/FXMSS_V${VERSION}.job.tar.gz fxmss@172.17.192.216:/home/fxmss/tmp/fxmss_backend

    scp ~/Deliverable/fxmss_backend/FXMSS_V${VERSION}.fms.tar.gz fxmss@172.17.192.217:/home/fxmss/tmp/fxmss_backend
    scp ~/Deliverable/fxmss_backend/FXMSS_V${VERSION}.job.tar.gz fxmss@172.17.192.217:/home/fxmss/tmp/fxmss_backend
    
    #send VERSION file to remote
    echo $VERSION > $TMPPATH/VERSION.txt
    scp $TMPPATH/VERSION.txt fxmss@172.17.192.216:/home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt
    scp $TMPPATH/VERSION.txt fxmss@172.17.192.217:/home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt
    
    #send deploy script to remote
    scp ~/common-scripts/remote-scripts/fxmss_backend_upgrade.sh fxmss@172.17.192.216:/home/fxmss/scripts/
    scp ~/common-scripts/remote-scripts/fxmss_backend_upgrade.sh fxmss@172.17.192.217:/home/fxmss/scripts/
}

deploy() {
    ssh fxmss@172.17.192.216 'bash /home/fxmss/scripts/fxmss_backend_upgrade.sh &> /home/fxmss/scripts/log/fxmss_backend_upgrade.log'
    ssh fxmss@172.17.192.217 'bash /home/fxmss/scripts/fxmss_backend_upgrade.sh &> /home/fxmss/scripts/log/fxmss_backend_upgrade.log'
}

print_log() {
    scp fxmss@172.17.192.216:/home/fxmss/scripts/log/fxmss_backend_upgrade.log $TMPPATH/fxmss_backend-216.log
    echo '-------------------------------------------------------------------------------------'
    echo '@              journal of fxmss_backend_upgrade.sh from 172.17.192.216              @'
    echo '-------------------------------------------------------------------------------------'
    cat $TMPPATH/fxmss_backend-216.log
    echo '-------------------------------------------------------------------------------------';echo
    
    scp fxmss@172.17.192.217:/home/fxmss/scripts/log/fxmss_backend_upgrade.log $TMPPATH/fxmss_backend-217.log
    echo '-------------------------------------------------------------------------------------'
    echo '@              journal of fxmss_backend_upgrade.sh from 172.17.192.217              @'
    echo '-------------------------------------------------------------------------------------'
    cat $TMPPATH/fxmss_backend-217.log
    echo '-------------------------------------------------------------------------------------';echo
}

deploy_check() {
    sleep 10
    
    RETVAL=0
    
    echo '-------------------------------------------------------------------------------------'
    echo '@                            Deploy status checking                                 @'
    echo '-------------------------------------------------------------------------------------'

    ssh fxmss@172.17.192.216 '/usr/sbin/lsof -i:18084' &> /dev/null
    if [ $? = 0 ];then
        log_success "18084 port is listening on 172.17.192.216"
    else
        RETVAL=$?
        log_error "18084 port is not listening at host 172.17.192.216" 
    fi
    
    ssh fxmss@172.17.192.217 '/usr/sbin/lsof -i:18084' &> /dev/null
    if [ $? = 0 ];then
        log_success "18084 port is listening on 172.17.192.217"
    else
        RETVAL=$?
        log_error "18084 port is not listening at host 172.17.192.217" 
    fi
    
    ssh fxmss@172.17.192.216 '/opt/jdk1.7.0_79/bin/jps|grep fms' &> /dev/null
    if [ $? = 0 ];then
        log_success "fms is running at 172.17.192.216" 
    else
        RETVAL=$?
        log_error "fms is not running at 172.17.192.216" 
    fi
    
    ssh fxmss@172.17.192.217 '/opt/jdk1.7.0_79/bin/jps|grep fms' &> /dev/null
    if [ $? = 0 ];then
        log_success "fms is running at 172.17.192.217"
    else
        RETVAL=$?
        log_error "fms application not started at host 172.17.192.217" 
    fi
    
    ssh fxmss@172.17.192.216 '/opt/jdk1.7.0_79/bin/jps|grep job' &> /dev/null
    if [ $? = 0 ];then
        log_success "job is running at 172.17.192.216"
    else
        RETVAL=$?
        log_error "job application not started at host 172.17.192.216" 
    fi
    
    ssh fxmss@172.17.192.217 '/opt/jdk1.7.0_79/bin/jps|grep job' &> /dev/null
    if [ $? = 0 ];then
        log_success "job is running at 172.17.192.217"
    else
        RETVAL=$?
        log_error "job application not started at host 172.17.192.217" 
    fi

    echo '-------------------------------------------------------------------------------------';echo
}

message() {
    if [ $RETVAL != 0 ];then
        encoding=GBK
        msg=$(echo -e "Event：场务监测ST后端部署失败！ Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins"|iconv -t $encoding)
    else
        encoding=GBK
        msg=$(echo -e "Event：场务监测ST后端部署成功！ Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins"|iconv -t $encoding)
    fi
    
    for user in ${USER[@]}
    do
        curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1796&msg=$msg" &>/dev/null
    done
}




main() {
    check
    archive
    send_deliverable
    deploy
    print_log
    deploy_check
    message
    rm -rf $TMPPATH
}

main