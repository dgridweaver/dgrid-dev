#!/bin/bash


################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled attach

if [ x$1 == x ]; then
echo "$0 <path-to-node> key1=val1 key2=val2"
echo "      <path-to-node> - username@hostname:suffix/path/to/node/install "
echo "      attach new node on host hostname, user username in directory <path>"
#echo "   attach newnode in same user on same host in directory <path>"

exit
fi

#export MODINFO_dbg_attach=4
#export MODINFO_dbg_dgridsys=4

attach_newnode_cli $*

