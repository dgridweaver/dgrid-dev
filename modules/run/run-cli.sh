#!/bin/bash


################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled run

echo 
echo "                  << run CLI util   >>"
echo 

#export MODINFO_dbg_run=4
