#!/bin/bash


################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
_dir0=`dirname $_file0`
cd ${_dir0}

. ./libdgrid.sh
################## [END] dgrid header1 ################ 

