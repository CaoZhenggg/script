#!/bin/bash
#Author: Zheng Cao
#Date: 07/04/2017

env_check(){
	if [ "$HOSTNAME" != "DWCJAPP01" -a  "$HOSTNAME" != "DWCJAPP02" -a "$HOSTNAME" != "DWCJAPP03" -a "$HOSTNAME" != "DWCJAPP04" ];then		
	    printf "%s\n" 'This script can running in DWCJAPP01 and DWCJAPP02 only!'
		exit 1
	fi
	
    if [ $(whoami) != "fxmss" ];then
        printf "%s\n" 'Please run this script by user fxmss!'
        exit 1
    fi
	
	if [ ! -f packages/jdk-7u79-linux-x64.tar.gz ];then
        printf "%s\n" 'There is no jdk-7u79-linux-x64.tar.gz in packages directory!'
	    exit 1
    fi
}

install_jdk(){
    tar zxf packages/jdk-7u79-linux-x64.tar.gz -C /home/fxmss
    echo "export JAVA_HOME=/home/fxmss/jdk1.7.0_7" >> ~/.bash_profile
	echo "export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib" >> ~/.bash_profile
    echo "export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH" >> ~/.bash_profile
	source ~/.bash_profile
	
	java -version &> /dev/null
	if [ $? != 0 ];then
	    printf "%s\n" 'Error: java environment variables are not right!'
		exit 1
	fi
}




main(){
    env_check
    install_jdk
}

main