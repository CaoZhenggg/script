#!/bin/bash
source /etc/profile

check() {
    if [ ! -d fxmss-dp-fms/target/fxmss-dp-fms-1.0.0 ];then
        printf "%s\n" '==============================='
        printf "%s\n" 'fms directory does not exist!!!'
        printf "%s\n" '==============================='
        exit 1
    fi

    if [ ! -d fxmss-dp-job/target/fxmss-dp-job-1.0.0 ];then
        printf "%s\n" '==============================='
        printf "%s\n" 'job directory does not exist!!!'
        printf "%s\n" '==============================='
        exit 1
    fi
}

clean() {
    ssh fxmss@172.17.192.217 'rm /home/fxmss/tmp/fxmss-dp-fms-1.0.0 -rf'
    ssh fxmss@172.17.192.217 'rm /home/fxmss/tmp/fxmss-dp-job-1.0.0 -rf'
    
    ssh fxmss@172.17.192.217 'ls /home/fxmss/tmp/fxmss-dp-fms-1.0.0' &> /dev/null
    if [ $? = 0 ];then
        printf "%s\n" '============================================'
        printf "%s\n" 'remote host tmp directory was not cleaned !'
        printf "%s\n" '============================================'
        exit 1
    fi

    ssh fxmss@172.17.192.217 'ls /home/fxmss/tmp/fxmss-dp-job-1.0.0' &> /dev/null
    if [ $? = 0 ];then
        printf "%s\n" '============================================'
        printf "%s\n" 'remote host tmp directory was not cleaned !'
        printf "%s\n" '============================================'
        exit 1
    fi
    
    rm FXMSS_V1.0.0.0.fms.tar.gz -f
    rm FXMSS_V1.0.0.0.job.tar.gz -f
}

tar_package() {
    tar zcf FXMSS_V1.0.0.0.fms.tar.gz fxmss-dp-fms/target/fxmss-dp-fms-1.0.0
    tar zcf FXMSS_V1.0.0.0.job.tar.gz fxmss-dp-job/target/fxmss-dp-job-1.0.0
}

ssh_copy() {
    scp -r fxmss-dp-fms/target/fxmss-dp-fms-1.0.0 fxmss@172.17.192.217:/home/fxmss/tmp
    scp -r fxmss-dp-job/target/fxmss-dp-job-1.0.0 fxmss@172.17.192.217:/home/fxmss/tmp
}

deploy() {
    ssh fxmss@172.17.192.217 'bash /home/fxmss/scripts/fxmss_backend_upgrade.sh &> /home/fxmss/scripts/log/fxmss_backend_upgrade.log'
}

print_log() {
    scp fxmss@172.17.192.217:/home/fxmss/scripts/log/fxmss_backend_upgrade.log .
    printf "%s\n" '============================================'
    printf "%s\n" '               Deploy Log                   '
    printf "%s\n" '============================================'
    cat ./fxmss_backend_upgrade.log
    rm ./fxmss_backend_upgrade.log -f
    printf "%s\n" '============================================'
}




main() {
    check
    clean
#    tar_package
    ssh_copy
    deploy
}

main