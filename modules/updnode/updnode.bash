#!/bin/bash


export mainrepo_cfgpath="dgrid-site/etc/updnode.repos/"

source ${MODINFO_modpath_updnode}/mainrepo.bash
source ${MODINFO_modpath_updnode}/updnode_allnodes.bash
#source ${MODINFO_modpath_updnode}/lib.bash
source ${MODINFO_modpath_updnode}/upd-this.bash

#####################

updnode_config_samples()
{
echo "updnode : default : etc.SAMPLES/updnode.conf : etc/updnode.conf ;"
echo "updnode : default : etc.SAMPLES/updnode-incoming.conf : etc/updnode-incoming.conf ;"
}



updnode_cli_help()
{
#dgridsys_s;echo "updthis showcfg - <xxx> <yyy> .... -"
updthis_cli_help
updnode_cli_help_func
}


updnode_cli_run()
{
updthis_cli_run $*
updnode_cli_run_func $*
}


updnode_env_start()
{
updthis_env_start
}

updnode_do_update_this_node()
{
updthis_upd2 $*
}

#####################

updnode_showcfg()
{
updthis_showcfg
}



updnode_status_all_mainrepos()
{
mainrepo_status_all_mainrepos
}


updnode_push_node_update()
{
nodeid=$1
local CONNECT_dnsname_2

 nodecfg_nodeid_load $nodeid
 if [ "x$?" == "x0" ]; then
  echo -n
  echo CONNECT_dnsname=$CONNECT_dnsname
  echo NODE_INSTPATH=$NODE_INSTPATH

  if [ x == x$NODE_USER ]; then
   CONNECT_dnsname_2=$CONNECT_dnsname
  else
   CONNECT_dnsname_2=${NODE_USER}@${CONNECT_dnsname}
  fi
  
 push_repo="ssh://$CONNECT_dnsname_2//$NODE_INSTPATH"
 else
  echo "error: nodeid to push update set incorerectly" 1>&2
  return
 fi

push_repo_cfg=$push_repo
push_repo_dist=${push_repo}/dgrid

echo push_repo_cfg=$push_repo_cfg
echo push_repo_dist=$push_repo_dist
#exit

echo hg push $push_repo_cfg
hg push $push_repo_cfg
echo "( cd dgrid ; hg push $push_repo_dist )"
(cd dgrid; hg push $push_repo_dist)
echo ssh $CONNECT_dnsname_2 "(cd $NODE_INSTPATH ; hg update ; cd dgrid ; hg update; ./modules/dgridsys/dgridsys module cache_clear )"
ssh $CONNECT_dnsname_2 "(cd $NODE_INSTPATH ; hg update ; cd dgrid ; hg update; ./modules/dgridsys/dgridsys module cache_clear )"
}

updnode_pull_node_update()
{
nodeid=$1
local CONNECT_dnsname_2

 nodecfg_nodeid_load $nodeid
 if [ "x$?" == "x0" ]; then
  echo -n
  echo CONNECT_dnsname=$CONNECT_dnsname
  echo NODE_INSTPATH=$NODE_INSTPATH

  if [ x == x$NODE_USER ]; then
   CONNECT_dnsname_2=$CONNECT_dnsname
  else
   CONNECT_dnsname_2=${NODE_USER}@${CONNECT_dnsname}
  fi
  
 pull_repo="ssh://$CONNECT_dnsname_2//$NODE_INSTPATH"
 else
  echo "error: nodeid to pull update from set incorerectly" 1>&2
  return
 fi

pull_repo_cfg=$pull_repo
pull_repo_dist=${pull_repo}/dgrid

echo pull_repo_cfg=$pull_repo_cfg
echo pull_repo_dist=$pull_repo_dist
#exit

echo hg pull $pull_repo_cfg
hg pull $pull_repo_cfg
echo "( cd dgrid ; hg pull $pull_repo_dist )"
(cd dgrid; hg pull $pull_repo_dist)
#echo ssh $CONNECT_dnsname_2 "(cd $NODE_INSTPATH ; hg update ; cd dgrid ; hg update)"
#ssh $CONNECT_dnsname_2 "(cd $NODE_INSTPATH ; hg update ; cd dgrid ; hg update; ./modules/dgridsys/dgridsys module cache_clear )"
(hg update; cd dgrid; hg update )
dgridsys_cli_main module cache_clear
}


#############################################

# push updates from this node to other system nodes

_updnode_push_to_grid_do_node()
{
dbg_echo udpnode 5 "[5] = " 1>&2
#echo "incoming_scanhst=$incoming_scanhst"
dbg_echo udpnode 5 "[5]hoststat_isup_this_host=$hoststat_isup_this_host" 1>&2
#echo "[5]hoststat_isup_this_host=$hoststat_isup_this_host" 1>&2

#echo "incoming_scanhst=$incoming_scanhst"
dbg_echo udpnode 5 "[5]hoststat_isup_this_host=$hoststat_isup_this_host" 1>&2
#echo "hoststat_do_scan=$hoststat_do_scan"
#echo "incoming_detect_type=$incoming_detect_type"

if [ x$hoststat_isup_this_host == x1 ]; then
dbg_echo udpnode 5 "DO_UPD ${NODE_ID}"
echo -n "DO_UPD ${NODE_ID} : "
updnode_push_node_update ${NODE_ID}
fi
}


updnode_push_to_grid()
{
echo -n
#hostcfg_iterate_hostid _updnode_push_to_grid_do_hst
nodecfg_iterate_full_nodeid _updnode_push_to_grid_do_node
}


updnode_push_to_grid_cmd()
{
updnode_push_to_grid
}

###

updnode_grid_updthis_upd()
{
echo -n
#nodecfg_iterate_full_nodeid _updnode_grid_runupd_node
main_exit_if_not_enabled run
run_allgrid_nodecmd updthis upd
}

updnode_grid_updthis_upd_cmd()
{
updnode_grid_updthis_upd
}




#########################

updnode_cli_help_func()
{
#dgridsys_s;echo "updnode distupd-node-push <nodeid> - push dist upd to <nodeid>"
dgridsys_s;echo "updnode push-node-update <nodeid> - push upd (cfg&dist) to <nodeid>"
dgridsys_s;echo "updnode pull-node-update  <nodeid> - pull (cfg&dist) upd from <nodeid>"
dgridsys_s;echo "updnode push-all-mainrepos - push all configured mainrepos"
dgridsys_s;echo "updnode pull-all-mainrepos - pull all configured mainrepos"
dgridsys_s;echo "updnode status-all-mainrepos - status all configured mainrepos"
dgridsys_s;echo ""
dgridsys_s;echo "updnode push-to-grid - push to all active grid nodes"
dgridsys_s;echo "updnode grid-updthis-upd - run \"updthis upd\" on grid nodes"

}


updnode_cli_run_func()
{
local maincmd=$1
local cmd=$2
local name=$3
local cmd_found="0"



dbg_echo devhelper 5  x${maincmd} == x"updnode"
if [ x${maincmd} == x"updnode"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
#updnode_cli_help_func
updnode_cli_help
cmd_found=1
fi


if [ x${cmd} == x"push-node-update"  ]; then
echo -n
shift 2
updnode_push_node_update $*
cmd_found=1
fi

if [ x${cmd} == x"pull-node-update"  ]; then
echo -n
shift 2
updnode_pull_node_update $*
cmd_found=1
fi


if [ x${cmd} == x"push-all-mainrepos"  ]; then
echo -n
shift 2
updnode_push_all_mainrepos
cmd_found=1
fi

if [ x${cmd} == x"pull-all-mainrepos"  ]; then
echo -n
shift 2
udpmod1_pull_all_mainrepos
cmd_found=1
fi

if [ x${cmd} == x"status-all-mainrepos"  ]; then
echo -n
shift 2
updnode_status_all_mainrepos
cmd_found=1
fi


if [ x${cmd} == x"showcfg"  ]; then
echo -n
updthis_showcfg $*
cmd_found=1
fi

if [ x${cmd} == x"push-to-grid"  ]; then
echo -n
shift 2
updnode_push_to_grid_cmd
cmd_found=1
fi

if [ x${cmd} == x"grid-updthis-upd"  ]; then
echo -n
shift 2
updnode_grid_updthis_upd_cmd
cmd_found=1
fi


if [ $cmd_found = "0" ]; then
echo "updthis : command line argument \"${cmd}\" not found"
fi




}



