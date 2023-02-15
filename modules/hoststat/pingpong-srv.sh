#!/bin/bash

################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled hoststat
export MODINFO_dbg_hoststat=0



#mkdir -p "${GRIDBASEDIR}/not-in-vcs/"
#export LOGFILE="${GRIDBASEDIR}/not-in-vcs/misc.log"

#hoststat_scanhosts_cmd
hoststat_pingpongsrv_simple
