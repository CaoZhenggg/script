#!/bin/bash
#Author: Zheng Cao
#Date: 07/04/2017

env_check(){
    if [ $HOSTNAME != "DWCJAPP01" -a $HOSTNAME != "DWCJAPP02" ];then
	    printf "%s\n" 'This script can running in DWCJAPP01 and DWCJAPP02 only!'
		exit 1
	fi
	
    if [ $(whoami) != "fxmss" ];then
        printf "%s\n" 'Please run this script by user fxmss!'
        exit 1
    fi

    if [ ! -f packages/pcre-8.31.tar.bz2 ];then
        printf "%s\n" 'Error: there is no pcre-8.31.tar.bz2 in packages directory!'
        exit 1
    fi
	
	if [ ! -f packages/nginx-1.10.2.tar.gz ];then
        printf "%s\n" 'Error: there is no nginx-1.10.2.tar.gz in packages directory!'
        exit 1
    fi
	
	if [ ! -f conf/nginx.conf ];then
	    printf "%s\n" 'Error: there is no nginx config file in conf directory!'
		exit 1
	fi
}

install_nginx(){
	    cd packages
		tar -xjf packages/pcre-8.31.tar.bz2
        tar -xzf packages/nginx-1.10.2.tar.gz 
        cd ./nginx-1.10.2
        
		./configure --prefix=/home/fxmss/nginx --with-pcre=../pcre-8.31		
		if [ $? = 0 ];then 
		    make
		else
            echo "Error: configure"
            exit 1			
		fi
		
		if [ $? = 0 ];then 
		    make install
	    else
		    echo "Error: make"
			exit 1
		fi
        
		if [ $? = 0 ];then 
		    mv 
            cp conf/nginx.conf /home/fxmss/nginx/conf
            chmod +x /home/fxmss/nginx/sbin/nginx	
	    else
			echo "Error: make install"
			exit 1
		fi
        
        # clean directory
	    rm -rf packages/nginx-1.10.2
        rm -rf packages/pcre-8.31			
}




main(){
    env_check
    install_nginx    
}

main
