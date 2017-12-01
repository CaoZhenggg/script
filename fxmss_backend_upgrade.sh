#!/bin/bash
#Author: CaoZheng
#Date: 2017/08/10
#-------------------------------------------------------#
#Modify: logical optimization
#Date: 2017/08/29
#Author: CaoZheng
#-------------------------------------------------------#

source /etc/profile
source ~/.bash_profile

DATE=$(date +%Y%m%d-%H:%M:%S)

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


if [ -d /home/fxmss/fxmss-dp-fms ];then
    GENDBPASS_JAR=$(ls /home/fxmss/fxmss-dp-fms/lib/|grep fxmss-s-basic)
    DBPASSWORD=$(java -jar /home/fxmss/fxmss-dp-fms/lib/$GENDBPASS_JAR fxmss|grep -v successful)
elif [ -d /home/fxmss/fxmss-dp-job ];then
    GENDBPASS_JAR=$(ls /home/fxmss/fxmss-dp-job/lib/|grep fxmss-s-basic)
    DBPASSWORD=$(java -jar /home/fxmss/fxmss-dp-job/lib/$GENDBPASS_JAR fxmss|grep -v successful)
fi



check() {
    if [ ! -f /home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt ];then
        log_error "/home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt does not exist!"
        exit 1
    else
        VERSION_NEW=$(cat /home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt)
    fi  
    
    if [ ! -f /home/fxmss/tmp/fxmss_backend/FXMSS_V${VERSION_NEW}.fms.tar.gz ];then
        log_error "/home/fxmss/tmp/fxmss_backend/FXMSS_V${VERSION_NEW}.fms.tar.gz does not exist!"
        exit 1
    fi

    if [ ! -f /home/fxmss/tmp/fxmss_backend/FXMSS_V${VERSION_NEW}.job.tar.gz ];then
        log_error "/home/fxmss/tmp/fxmss_backend/FXMSS_V${VERSION_NEW}.job.tar.gz does not exist!"
        exit 1
    fi
}

stop_apps() {
    log_info "Stoping fms..."
    cd /home/fxmss/fxmss-dp-fms/bin
    bash shutdown.sh &> /dev/null
    sleep 2
    ps aux|grep fms|grep -v grep >/dev/null
    if [ $? = 0 ];then
        kill -9 $(ps aux|grep fms|grep -v grep|awk '{ print $2 }')
    else
        log_success "fms has been stoped."
    fi

    log_info "Stoping job..."   
    cd /home/fxmss/fxmss-dp-job/bin
    bash shutdown.sh &> /dev/null
    sleep 2
    ps aux|grep job|grep -v grep >/dev/null
    if [ $? = 0 ];then
        kill -9 $(ps aux|grep job|grep -v grep|awk '{ print $2 }')
    else
        log_success "job has been stoped."
    fi
}

backup() {
    log_info "Backup..."
    
    if [ ! -d /home/fxmss/backup/fxmss_backend/ ];then
        mkdir -p /home/fxmss/backup/fxmss_backend/
    fi

    cd /home/fxmss
    tar czf fxmss-dp-fms-${DATE}.tar.gz fxmss-dp-fms --remove-files --force-local
    mv fxmss-dp-fms-${DATE}.tar.gz /home/fxmss/backup/fxmss_backend/
    
    tar czf fxmss-dp-job-${DATE}.tar.gz fxmss-dp-job --remove-files --force-local
    mv fxmss-dp-job-${DATE}.tar.gz /home/fxmss/backup/fxmss_backend/

    if [ $? != 0 ];then
        log_error "Backup Failed!"
    else
        log_success "backup has been done."
    fi
}

deploy() {
    log_info "Deploying..."

    # unarchive fms
    cd /home/fxmss/tmp/fxmss_backend
    tar zxf FXMSS_V${VERSION_NEW}.fms.tar.gz -C /home/fxmss
    
    cd /home/fxmss/backup/fxmss_backend
    tar zxf fxmss-dp-fms-${DATE}.tar.gz --force-local
    cp -r fxmss-dp-fms/logs /home/fxmss/fxmss-dp-fms
    rm -rf fxmss-dp-fms
 
    # unarchive job
    cd /home/fxmss/tmp/fxmss_backend
    tar zxf FXMSS_V${VERSION_NEW}.job.tar.gz -C /home/fxmss
    
    cd /home/fxmss/backup/fxmss_backend
    tar zxf fxmss-dp-job-${DATE}.tar.gz --force-local
    cp -r fxmss-dp-job/logs /home/fxmss/fxmss-dp-job
    rm -rf fxmss-dp-job

    # make some change to application's configure file
    case $HOSTNAME in
        DWCJAPP03)
            sed -i 's/LOCALHOST/DWCJAPP03/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/FMSHOST/DWCJAPP04/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/JOBHOST1/DWCJAPP03/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/JOBHOST2/DWCJAPP04/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            
            sed -i 's/LOCALHOST/DWCJAPP03/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/JOBHOST/DWCJAPP04/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/FMSHOST1/DWCJAPP03/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/FMSHOST2/DWCJAPP04/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml

            sed -i "s#FXMSSDBPASS#$DBPASSWORD#" /home/fxmss/fxmss-dp-fms/conf/cwap-context-ext.properties
            sed -i "s#FXMSSDBPASS#$DBPASSWORD#" /home/fxmss/fxmss-dp-job/conf/cwap-context-ext.properties
        ;;
        DWCJAPP04)
            sed -i 's/LOCALHOST/DWCJAPP04/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/FMSHOST/DWCJAPP03/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/JOBHOST1/DWCJAPP03/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            sed -i 's/JOBHOST2/DWCJAPP04/' /home/fxmss/fxmss-dp-fms/conf/ehcache-setting.xml
            
            sed -i 's/LOCALHOST/DWCJAPP04/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/JOBHOST/DWCJAPP03/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/FMSHOST1/DWCJAPP03/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml
            sed -i 's/FMSHOST2/DWCJAPP04/' /home/fxmss/fxmss-dp-job/conf/ehcache-setting.xml

            sed -i "s#FXMSSDBPASS#$DBPASSWORD#" /home/fxmss/fxmss-dp-fms/conf/cwap-context-ext.properties
            sed -i "s#FXMSSDBPASS#$DBPASSWORD#" /home/fxmss/fxmss-dp-job/conf/cwap-context-ext.properties
        ;;
    esac
   


    # start fms and job
    cd /home/fxmss/fxmss-dp-fms/bin
    bash startup.sh &> /dev/null 
    if [ $? != 0 ];then
        log_error "starting fms failed!"
        exit 1
    fi

    cd /home/fxmss/fxmss-dp-job/bin
    bash startup.sh &> /dev/null
    if [ $? != 0 ];then
        log_error "starting job failed!"
        exit 1
    fi

    log_success "deployment has been done."
}




main() {
    check
    stop_apps
    backup    
    deploy
}

main
