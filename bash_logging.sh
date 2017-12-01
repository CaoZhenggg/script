


func_logFormat() {
    local log_color=$1
    local log_level=$2
    local log_text=$3
    local date_format=$(date +"%Y-%m-%d %H:%M:%S %Z")

    local interactive_mode=off
    if [ $interactive_mode = off ];then
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

    printf "${log_color}[$(date_format)] [$log_level] ${log_text} ${LOG_COLOR_COLORLESS}\n"
}

# The following functions accept only one argument.
func_loggingInfo() { func_logFormat "$LOG_COLOR_INFO" 'INFO' "$1"; }
func_loggingSuccess() { func_logFormat "$LOG_COLOR_SUCCESS" 'SUCCESS' "$1"; }
func_loggingWarning() { func_logFormat "$LOG_COLOR_WARNING" 'WARNNING' "$1"; }
func_loggingError() { func_logFormat "$LOG_COLOR_ERROR" 'ERROR' "$1" ; }


