#!/bin/bash

export DGRID_mode_distrubution_enable=1

################## dgrid header1 ################
if [ x$ORIGDIR == x ]; then
  export ORIGDIR=$(pwd)
fi

_file0=$(readlink -f $0)
cd $(dirname $_file0)

. ./libdgrid.sh

################## [END] dgrid header1 ################

################## initgrid.sh header  ################
initgrid_BASEDIR=$(dirname $_file0)
initgrid_BASEDIR_DGRID=$DGRIDDISTDIR
################## [END] initgrid.sh header1 ################

source $initgrid_BASEDIR/install_profile.conf
#MODINFO_modpath_initgrid

#######################################################

echo
echo "                  << initgrid util   >>"
echo
#export MODINFO_dbg_init=4

initgrid_install_dgrid $*
