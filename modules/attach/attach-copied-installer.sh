#!/bin/bash

# THIS IS NOT FOR MANUAL USE

# thisscript is runned inside of dgridsys attach command

#$1 - path to grid

if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

#install_path=$1

if [ ! x$1 == xATTACH-RUN ]; then
echo "usage $0 ATTACH-RUN"
exit
fi

#if [ x$install_path == x ]; then
#echo "usage $0 <path>"
#exit
#fi

our_dir=`pwd`

# load variables from "server" node (node in wich attach cmd running)
if [ ! -f ./attach.vars ]; then
echo -n `basename $0` :
echo "attach.vars not found"
exit
fi
source ./attach.vars


if [ -z "$NODE_INSTPATH" ]; then
  echo -n `basename $0` :
  echo "NODE_INSTPATH must be set"
  exit
fi

if [ -e "$NODE_INSTPATH/dgrid" ]; then
  echo -n `basename $0` :
  echo "$NODE_INSTPATH (NODE_INSTPATH/dgrid) exists, abort "
  exit
fi

echo INIT_get_host_ids_outdir=$INIT_get_host_ids_outdir

#install files copied from node
pushd $NODE_INSTPATH > /dev/null
tar xf ${our_dir}/current_node.tar 
#tar xf ${our_dir}/current_node_dgriddistr.tar
#sh -x ./dgrid/modules/attach/attach-this-node.sh
#exit
bash -l ./dgrid/init/init attach-this-node
popd

