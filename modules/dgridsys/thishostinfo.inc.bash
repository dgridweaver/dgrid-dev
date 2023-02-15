#!/bin/bash

this_hostinfo()
{
#HOST_dnsname

#if [ -x"$HOST_id" == x ]; then
#HOST_id=
#fi

host_cfg_dir=$nodecfg_path/$HOST_id/
#if [ -x"$HOST_dnsname" == x ]; then
#HOST_dnsname=`hostname`
#fi
HOST_hostname=`hostname`
HOST_hostid=`hostid`
HOST_uuid=`uuidgen`
}

this_node_idsuffix()
{
#echo -n "home1"
echo -n "one"
}

this_nodeinfo()
{
#local NODE_HOST
NODE_UUID=`uuidgen`
##NODE_ID=stas@sh21:home1
NODE_IDsuffix=`this_node_idsuffix`
#if [ -n "$HOST_dnsname" ]; then
#NODE_HOST=${HOST_dnsname%%.*}
#HOSTid=${HOST_dnsname%%.*}
#fi

if [ -n $DGRIDBASEDIR ]; then
NODE_INSTPATH=$DGRIDBASEDIR
fi
NODE_USER=$USER
}

