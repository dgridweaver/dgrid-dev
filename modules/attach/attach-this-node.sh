#!/bin/bash

# THIS IS NOT FOR MANUAL USE

# thisscript is runned inside of dgridsys attach command

echo hostname=$HOSTNAME
echo "run(\$0)=$0"

if [ -f attach.vars ]; then
source ./attach.vars
fi

echo newnode_host=$newnode_host
echo newnode_path=$newnode_path

####
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`
####


# clear cache
../../main/modules-cache-clear

cd ../dgridsys/
export NODE_ID="${newnode_user}@${newnode_host}:$newnode_namesuffix"
export NODE_IDsuffix="$newnode_namesuffix"
echo "./dgridsys nodecfg addthis"
./dgridsys nodecfg addthis

echo "./dgridsys attach addthis-run-script ${_tmpdir_newnode}"
./dgridsys attach addthis-run-script ${_tmpdir_newnode}
#cd ../system/
#./system-runcleanenv attach addthis-run-script ${_tmpdir_newnode}
