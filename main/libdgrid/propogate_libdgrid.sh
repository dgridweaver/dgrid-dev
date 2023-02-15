#!/bin/bash

export DGRID_mode_distrubution_enable=1

################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
_dir0=`dirname $_file0`
cd ${_dir0}

. ./libdgrid.sh
################## [END] dgrid header1 ################ 
cd ${DGRIDDISTDIRrel}

( ls -1 ./modules/*/libdgrid.sh ; 
ls -1 ./init/libdgrid.sh ./main/libdgrid.sh ) | while read -r i; do
echo "cp ./main/libdgrid/libdgrid.sh $i"
done
