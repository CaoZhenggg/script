#!/bin/bash
NLS_LANG=AMERICAN_AMERICA.AL32UTF8
import NLS_LANG

if [ ! -d ./log ]; then
      mkdir log
fi

debug(){
        echo $*
        echo $* >> ./log/db_Import.log
}

debug "Task Begin--Import."
debug "Now begin to import data from database, please waiting ..."
debug "";


debug "Begin to import FXMSS data from FXMSS, please waiting ..."
imp fxmss/fxmss@fxmss file=fxmss.dmp tables=ABNML_QT_MNTR,ABNML_TRDNG_MNTR,AFTR_DAY_MKT_TRD_ANAlyze,AFTR_DAY_TRD_ANAlyze,ALRT_EV_STAT,AUTH,AUTH_PCKG_INFO,BST_QUOTE_INFO,CCY_CNTRL_PRTY,CSWAP_QT_MKT_TRD,DL_INTRVL_INFO,FX_DL_LOG,FX_DL_LOG_INFO,FX_MKT_ORDR_DPTH_DATA,FX_MKT_ORDR_DPTH_ORG,FX_MKT_TRD,INSTN_TRD_ANALYZE,MKT_HLDY,MKT_OPNG_AND_CLSNG,ORG_BSC_INFO,PARAM_STNG,QUOTE_ANLY,RVRS_BHVR_MNTR,RVRS_VOL_RATIO,TRD_ANLY_DTL_INFO,TRD_sUPer_restricted_INFO,USR_AUTH_INFO,USR_INFO,USR_OPRTN_INFO,USR_TKN,WARNINg_EV_DL,STNDRD_MKT_ORDR_DPTH_DATA ignore=y log=log/db_Import.log;

debug "End to import FXMSS data from FXMSS, please continue ..."

debug "";
debug "Now end to import data from database, database import successfully.";
debug "";
debug "Task End--Import.";
debug "INFO: --Database Import terminated successfully."