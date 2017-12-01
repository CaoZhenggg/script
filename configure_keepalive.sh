#!/bin/bash
#Author: Zheng Cao
#Date: 07/04/2017

# These two variable has 5 strings!
DWCJAPP01="fxmss 199.31.224.7 eth0 MASTER 60"
DWCJAPP02="fxmss 199.31.224.107 eth0 BACKUP 59"

env_check(){
	if [ $HOSTNAME != "DWCJAPP01" -a $HOSTNAME != "DWCJAPP02" ];then
	    printf "%s\n" 'This script can running in DWCJAPP01 and DWCJAPP02 only!'
		exit 1
	fi
	
    if [ $(whoami) != "root" ];then
        printf "%s\n" 'Please run this script by user root!'
        exit 1
    fi
	
	if [ ! -z $(rpm -qa keepalived) ];then
        KL_version=$(rpm -qa keepalived|awk -F '-' '{ print $2 }')
        if [ $KL_version != "1.2.24" ];then
            printf "%s\n" 'keepalived version is not 1.2.24!'
	        exit 1
	    fi
	else
	    printf "%s\n" 'Error: keepalived-1.2.24 was not installed!'
	    exit 1
	fi

    if [ $(echo $DWCJAPP01|awk '{ print NF }') != 5 ];then
        printf "%s\n" 'variable DWCJAPP01 was broken!'
	    exit 1
    elif [ $(echo $DWCJAPP01|awk '{ print NF }') != 5 ];then
        printf "%s\n" 'variable DWCJAPP02 was broken!'
	    exit 1
    fi
	
	if [ ! -f conf/keepalived.conf ];then
        printf "%s\n" 'Error: there is no keepalived.conf in conf directory!'
        exit 1
    fi	
}

configure_keepalived(){
    mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
	cp conf/keepalived.conf /etc/keepalived/
	chown root. /etc/keepalived/keepalived.conf
	chmod 644 /etc/keepalived/keepalived.conf
	
    case $HOSTNAME in
        DWCJAPP01)
	        username=$(echo $DWCJAPP01|awk '{ print $1 }')
            vip=$(echo $DWCJAPP01|awk '{ print $2 }')
            ifname=$(echo $DWCJAPP01|awk '{ print $3 }')
            mode=$(echo $DWCJAPP01|awk '{ print $4 }')
            routeid=$(echo $DWCJAPP01|awk '{ print $5 }')
            sed -i "s/\[MODE\]/$mode/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[USER\]/$username/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[VIP\]/$vip/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[IFNAME\]/$ifname/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[ROUTEID\]/$routeid/g" /etc/keepalived/keepalived.conf 
	    ;;
	    DWCJAPP02)
		    username=$(echo $DWCJAPP02|awk '{ print $1 }')
            vip=$(echo $DWCJAPP02|awk '{ print $2 }')
            ifname=$(echo $DWCJAPP02|awk '{ print $3 }')
            mode=$(echo $DWCJAPP02|awk '{ print $4 }')
            routeid=$(echo $DWCJAPP02|awk '{ print $5 }')
            sed -i "s/\[MODE\]/$mode/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[USER\]/$username/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[VIP\]/$vip/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[IFNAME\]/$ifname/g" /etc/keepalived/keepalived.conf 
            sed -i "s/\[ROUTEID\]/$routeid/g" /etc/keepalived/keepalived.conf
        ;;
    esac
}	




main(){
    env_check
	configure_keepalived
}

main