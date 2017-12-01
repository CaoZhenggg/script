#!/bin/bash

DATE=$(date +%Y%m%d-%H:%M:%S)


check() {
    if [ $USER != fxmss ];then
        printf "%s\n" '[ERROR] Please run this script by user fxmss!'
        exit 1
    fi
 
    if [ ! -f /home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt ];then
        printf "%s\n" '[ERROR] /home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt does not exist'
        exit 1
    else
        VERSION_NEW=$(cat /home/fxmss/tmp/fxmss_backend/VERSION_NEW.txt)
    fi

    if [ ! -f /home/fxmss/tmp/fxmss_frontend/FXMSS_V${VERSION_NEW}.frontend.tar.gz ];then
        printf "%s\n" "[ERROR] /home/fxmss/tmp/fxmss_frontend/FXMSS_V${VERSION_NEW}.frontend.tar.gz not exist"
        exit 1
    fi
}


stop_nginx() {
    /home/fxmss/nginx/sbin/nginx -s stop
    ps aux|grep nginx|grep -v grep >/dev/null
    if [ $? = 0 ];then
        killall nginx
    fi
}

backup() {
    if [ ! -d /home/fxmss/backup/fxmss_frontend ];then
        mkdir -p /home/fxmss/backup/fxmss_frontend
    fi
    
    cd /home/fxmss/nginx/frontend
    tar czf frontend.${DATE}.tar.gz audio js styles index.html favicon.ico --remove-files --force-local
    mv frontend.${DATE}.tar.gz /home/fxmss/backup/fxmss_frontend
}

deploy() {
    cd /home/fxmss/tmp/fxmss_frontend/
    tar zxf FXMSS_V${VERSION_NEW}.frontend.tar.gz -C /home/fxmss/nginx/frontend 
    rm -f FXMSS_V${VERSION_NEW}.frontend.tar.gz
}

start_nginx() {
    /home/fxmss/nginx/sbin/nginx

    ps aux|grep nginx|grep -v grep >/dev/null
    if [ $? != 0 ];then
        printf "%s\n" '[ERROR] nginx cannot startup, upgrade failed!'
        exit 1
    fi
}




main() {
    check
    stop_nginx
    
    if [ -d /home/fxmss/nginx/frontend ];then
        backup
    else
        mkdir -p /home/fxmss/nginx/frontend
    fi
    
    deploy
    start_nginx
}

main
