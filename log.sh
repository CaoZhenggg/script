#!/bin/bash
#Author: Zheng Cao
#Date: 07/04/2017


# Determines if print colors or not
if [ $(tty -s) ];then
    readonly INTERACTIVE_MODE="off"
else
    readonly INTERACTIVE_MODE="on"
fi

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
