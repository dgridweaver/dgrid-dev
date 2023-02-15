#!/bin/bash


################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled monitdg

echo 
echo "                  << monitdg CLI util   >>"
echo 
#export MODINFO_dbg_monitdg=4
echo ----------------------------------

#cfgstack_load_byid "etc/monitdg.conf" ${THIS_NODEID}
cfgstack_cfg_thisnode "etc/monitdg.conf"
#cfgstack_cfg trace UNKNOWN "/etc/monitdg.conf" $THIS_NODEID


set |grep -i ^monitdg |grep -v "()"

################
echo
echo ----------------------------------
monitdg_output_monit_cfgfile
echo ----------------------------------
monitdg_status_service_monitdg
echo ----------------------------------


