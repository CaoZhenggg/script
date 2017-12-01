#!/bin/bash
source /etc/profile
source ~/.bash_profile

WORKPATH=$(pwd)
TMPPATH=/tmp/$(openssl rand -hex 5)
mkdir $TMPPATH

USER[0]=1796    #曹政
USER[1]=1460    #刘成伟
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
    msg=$(echo  "场务监测系统ST前端部署失败！ 时间：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins" | iconv -t $encoding)
    
    for user in ${USER[@]}
    do
        curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1796&msg=$msg" &>/dev/null
    done
    
    exit 1
}

svn_check() {
    MAVEN_VERSION_fms=$(cat /home/ci/.jenkins/jobs/FXMSS_Backend_Upgrade\(ST\)/workspace/fxmss-dp-fms/pom.xml |grep -A 1 '<artifactId>fxmss-dp-fms</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')
    MAVEN_VERSION_job=$(cat /home/ci/.jenkins/jobs/FXMSS_Backend_Upgrade\(ST\)/workspace/fxmss-dp-job/pom.xml |grep -A 1 '<artifactId>fxmss-dp-job</artifactId>'|grep version|sed -e 's/<version>//' -e 's/<\/version>//' -e 's/^[ \t ]//')
    if [ $MAVEN_VERSION_fms != $MAVEN_VERSION_job ];then
        log_error "MAVEN_VERSION_fms is not equal MAVEN_VERSION_job, please check pom.xml!"
        error_exit        
    else
        VERSION=$MAVEN_VERSION_fms
    fi

    
    if [ ! -d $WORKPATH/dist/js ];then
        log_error "$WORKPATH/dist/js directory does not exist!"
        error_exit
    fi

    if [ ! -d $WORKPATH/dist/audio ];then
        log_error "$WORKPATH/dist/audio directory does not exist!"
        error_exit
    fi

    if [ ! -d $WORKPATH/dist/styles ];then
        log_error "$WORKPATH/dist/styles directory does not exist!"
        error_exit
    fi

    if [ ! -f $WORKPATH/dist/index.html ];then
        log_error "$WORKPATH/dist/index.html does not exist!"
        error_exit
    fi

    if [ ! -f $WORKPATH/dist/favicon.ico ];then
        log_error "$WORKPATH/dist/favicon.ico does not exist!"
        error_exit
    fi
}

archive() {
    cp -r $WORKPATH/dist $TMPPATH
    cd $TMPPATH/dist
    
    find . -type d -name .svn|xargs -i rm -rf {}
    tar zcf FXMSS_V${VERSION}.frontend.tar.gz js styles audio index.html favicon.ico

    if [ ! -d ~/Deliverable/fxmss_frontend ];then
        mkdir -p ~/Deliverable/fxmss_frontend 
    fi

    mv FXMSS_V${VERSION}.frontend.tar.gz ~/Deliverable/fxmss_frontend
}

send_deliverable() {
    ssh fxmss@172.17.192.217 'ls /home/fxmss/tmp/fxmss_frontend' &>/dev/null
    if [ $? != 0 ];then
        ssh fxmss@172.17.192.217 'mkdir -p /home/fxmss/tmp/fxmss_frontend'
    fi

    ssh fxmss@172.17.192.216 'ls /home/fxmss/tmp/fxmss_frontend' &>/dev/null
    if [ $? != 0 ];then
        ssh fxmss@172.17.192.216 'mkdir -p /home/fxmss/tmp/fxmss_frontend'
    fi    
    
    scp ~/Deliverable/fxmss_frontend/FXMSS_V${VERSION}.frontend.tar.gz fxmss@172.17.192.216:/home/fxmss/tmp/fxmss_frontend
    scp ~/Deliverable/fxmss_frontend/FXMSS_V${VERSION}.frontend.tar.gz fxmss@172.17.192.217:/home/fxmss/tmp/fxmss_frontend
}


remote_deploy() {
    scp /home/ci/common-scripts/remote-scripts/fxmss_frontend_upgrade.sh fxmss@172.17.192.216:/home/fxmss/scripts/fxmss_frontend_upgrade.sh &> /dev/null
    scp /home/ci/common-scripts/remote-scripts/fxmss_frontend_upgrade.sh fxmss@172.17.192.217:/home/fxmss/scripts/fxmss_frontend_upgrade.sh &> /dev/null
    
    ssh fxmss@172.17.192.216 'bash /home/fxmss/scripts/fxmss_frontend_upgrade.sh &> /home/fxmss/scripts/log/fxmss_frontend_upgrade.log'
    ssh fxmss@172.17.192.217 'bash /home/fxmss/scripts/fxmss_frontend_upgrade.sh &> /home/fxmss/scripts/log/fxmss_frontend_upgrade.log'
}

message() {  
    if [ $? = 0 ];then
        encoding=GBK
        msg=$(echo -e "Event：场务监测ST前端部署成功！  Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins"|iconv -t $encoding)
    else
        encoding=GBK
        msg=$(echo -e "Event：场务监测ST前端部署失败！  Date：$(date +%Y/%m/%d-%H:%M:%S)    --Jenkins"|iconv -t $encoding)
    fi

    for user in ${USER[@]}
    do
        curl "http://200.31.147.138:6680/post.sdk?recv=${user}&send=1796&msg=$msg" &> /dev/null
    done
}

print_log() {
    scp fxmss@172.17.192.216:/home/fxmss/scripts/log/fxmss_frontend_upgrade.log ${TMPPATH}/frontend_216.log
    printf "%s\n" '-------------------------------------------------------------------------------------'
    printf "%s\n" '@                                216 Log                                            @'
    printf "%s\n" '-------------------------------------------------------------------------------------'
    cat ${TMPPATH}/frontend_216.log
    printf "%s\n" '-------------------------------------------------------------------------------------';echo

    scp fxmss@172.17.192.217:/home/fxmss/scripts/log/fxmss_frontend_upgrade.log ${TMPPATH}/frontend_217.log
    printf "%s\n" '-------------------------------------------------------------------------------------'
    printf "%s\n" '@                                217 Log                                            @'
    printf "%s\n" '-------------------------------------------------------------------------------------'
    cat ${TMPPATH}/frontend_217.log
    printf "%s\n" '-------------------------------------------------------------------------------------'
}




main() {
    svn_check
    archive
    send_deliverable
    remote_deploy
    message
    print_log
    rm -rf $TMPPATH
}

main