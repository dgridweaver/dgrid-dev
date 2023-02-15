#!/bin/bash

if [ x$MODINFO_loaded_updnode == "x" ]; then
export MODINFO_loaded_updnode="Y"
else
return
fi

#MODINFO_dbg_updnode=0
#MODINFO_enable_updnode=

updthis_env_start()
{
#cfgstack_cfg load UNKNOWN "/etc/updnode.conf" $THIS_NODEID
cfgstack_load_byid etc/updnode.conf $THIS_NODEID

export UPDTHIS_UPD_NODEID=$UPDNODE_uplink_nodeid
#echo "export UPDTHIS_UPD_NODEID=\"$UPDNODE_uplink_nodeid\""

if [ x$UPDNODE_uplink_nodeid == "x" ]; then
 echo -n
else
 nodecfg_nodeid_load $UPDNODE_uplink_nodeid
 if [ "x$?" == "x0" ]; then
  echo -n
  echo CONNECT_dnsname=$CONNECT_dnsname
  echo NODE_INSTPATH=$NODE_INSTPATH
  UPDNODE_uplink_repo="ssh://$CONNECT_dnsname//$NODE_INSTPATH"
 else
  echo "error: UPDNODE_uplink_node set incorerectly" 1>&2
  return
 fi
fi



if [ x$UPDNODE_uplink_repo == "x" ]; then
echo -n
 UPDTHIS_repo_cfg=$UPDNODE_repo_cfg
 UPDTHIS_repo_dist=$UPDNODE_repo_dist
else

 if [ "x$UPDNODE_repo_cfg" == "x" ]; then
 UPDTHIS_repo_cfg=$UPDNODE_uplink_repo
 else
 UPDTHIS_repo_cfg=$UPDNODE_repo_cfg
 fi

 if [ "x$UPDNODE_repo_dist" == "x" ]; then
 UPDTHIS_repo_dist="${UPDNODE_uplink_repo}/dgrid"
 else
 UPDTHIS_repo_dist=$UPDNODE_repo_dist
 fi

fi
}

updthis_print_module_info()
{
echo "updinst01: mod info, called updthis_print_module_info"

}

updthis_printcfg()
{
( set -o posix ; set )|grep ^UPDTHIS
}

updthis_dist_upd()
{
local code cmdl_nodeid msg
local nodeid=$1

echo ; updthis_showcfg ; echo ; #echo nodeid=$nodeid

if [ -z "$nodeid" ]; then
cmdl_nodeid=0
nodeid=$UPDTHIS_UPD_NODEID
msg="Use UPDTHIS_UPD_NODEID : $nodeid";
else
msg="Use cmd line nodeid : $nodeid";
cmdl_nodeid=1
fi

nodecfg_nodeid_load $nodeid
if [ $? == 1 ]; then 
echo "No such node \"$nodeid\""; 
else
 UPDTHIS_DISTR_UPD_current="ssh://$CONNECT_dnsname/${NODE_INSTPATH}"
fi

if [ -n "$UPDTHIS_DISTR_UPD" ]; then 
 msg="Use UPDTHIS_DISTR_UPD instead of nodeid"
 UPDTHIS_DISTR_UPD_current=$UPDTHIS_DISTR_UPD 
fi

if  [ -z $UPDTHIS_DISTR_UPD_current  ]; then
echo "Canot determine where to find updates - exit"
exit
fi
echo $msg

#UPDTHIS_DISTR_UPD_current=$UPDTHIS_DISTR_UPD
#UPDTHIS_DISTR_UPD
#exit

code="(cd dgrid; hg pull $UPDTHIS_DISTR_UPD_current ; hg update)"
echo $code
#$code

}

updthis_upd2()
{
echo 
updthis_showcfg
echo 
#exit
updthis_upd_cfg
updthis_upd_dist
dgridsys_cli_main module cache_clear
}

updthis_upd_cfg()
{

#echo "hg pull $UPDNODE_uplink_repo; hg update"
#hg pull $UPDNODE_uplink_repo; hg update

if [ "x$UPDTHIS_repo_cfg" == x ]; then
return
fi

echo "hg pull $UPDTHIS_repo_cfg; hg update"
hg pull $UPDTHIS_repo_cfg; hg update
}
updthis_upd_dist()
{

if [ "x$UPDTHIS_repo_dist" == x ]; then
return
fi


echo "hg pull $UPDTHIS_repo_dist; hg update"
(cd dgrid ;  hg pull $UPDTHIS_repo_dist; hg update )
}




updthis_showcfg()
{
#echo UPDTHIS_UPD_NODEID=$UPDTHIS_UPD_NODEID
#echo UPDTHIS_SITE_UPD=$UPDTHIS_SITE_UPD
#echo UPDTHIS_DISTR_UPD=$UPDTHIS_DISTR_UPD

set|grep ^UPDTHIS_
set|grep ^UPDNODE_


}



############ cli integration  ################



updthis_cli_help()
{
dgridsys_s;echo "updthis showcfg - <xxx> <yyy> .... -"
dgridsys_s;echo "updthis upd - <xxx> <yyy> .... -"
#dgridsys_s;echo "updinst01 upd-dist - <xxx> <yyy> .... -"
#dgridsys_s;echo "updinst01 upd-site - <xxx> <yyy> .... -"
#dgridsys_s;echo "updinst01 distupd-node-push <nodeid> - push dist upd to <nodeid>"
#dgridsys_s;echo "updinst01 siteupd-node-push <nodeid> - push site upd to <nodeid>"
#dgridsys_s;echo "updinst01 upd-node-push <nodeid> - push dist&site upd to <nodeid>"
}


updthis_cli_run()
{
local maincmd=$1
local cmd=$2
local name=$3
local cmd_found="0"



dbg_echo devhelper 5  x${maincmd} == x"updthis"
if [ x${maincmd} == x"updthis"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
#updthis_cli_help
updnode_cli_help
cmd_found=1
fi


if [ x${cmd} == x"upd"  ]; then
echo -n
updthis_upd2 $*
cmd_found=1
fi

#if [ x${cmd} == x"upd1"  ]; then
#echo -n
#updthis_upd2 $*
#cmd_found=1
#fi

if [ x${cmd} == x"showcfg"  ]; then
echo -n
updthis_showcfg $*
cmd_found=1
fi


if [ $cmd_found = "0" ]; then
echo "updthis : command line argument \"${cmd}\" not found"
fi


}

