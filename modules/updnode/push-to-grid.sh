#!/bin/bash


################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled updnode

#echo 
#echo "                  << updnode CLI util   >>"
#echo 

echo "push updates to active grid nodes"
#export MODINFO_dbg_hoststat=6
export MODINFO_dbg_updnode=6
updnode_push_to_grid_cmd $*
