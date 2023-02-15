#!/bin/bash

# THIS IS NOT FOR MANUAL USE

# thisscript is runned inside of dgridsys attach command

#$1 - path to grid

if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

install_path=$1

if [ x$install_path == x ]; then
echo "usage $0 <path>"
exit
fi

our_dir=`pwd`

# load variables from "server" node (node in wich attach cmd running)
source ./attach.vars

#install files copied from node
pushd $install_path > /dev/null
tar xf ${our_dir}/current_node.tar 
tar xf ${our_dir}/current_node_dgriddistr.tar
sh -x ./dgrid/modules/attach/attach-this-node.sh
popd

