#!/bin/bash

if [ x$MODINFO_loaded_updnode == "x" ]; then
  export MODINFO_loaded_updnode="Y"
else
  return
fi

source ${MODINFO_modpath_updnode}/updthis.bash

export updnode_CLIMENU_CMDS_LIST="update_push_ssh_updthis push_vcs"
updnode_climenu_cmd_update_push_vcs(){ updnode_push_vcs_cli $@; }
updnode_climenu_cmd_vcs_url(){ updnode_vcs_url_cli $@; }
updnode_climenu_cmd_update_push_ssh_updthis() { updnode_push_ssh_updthis $@; }


updnode_vcs_url_cli(){
  dbg_echo updnode 5 F Start
  local nodeid=$1
  if nodecfg_nodeid_exists "$nodeid" ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
  fi
  eval `pref="local vcu_" run_connect_config $nodeid`
  #generic_listvars vcu_
  echo "${pref}vcs_url=\"ssh://${vcu_CONNECT_dnsname}/$vcu_CONNECT_wdir\""
}

updnode_push_vcs_cli(){
  dbg_echo updnode 5 F Start
  local nodeid=$1
  if nodecfg_nodeid_exists "$nodeid" ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
  fi
  eval `pref="local vcu_" run_connect_config $nodeid`
  #generic_listvars vcu_
  local vcs_url="ssh://${vcu_CONNECT_dnsname}/$vcu_CONNECT_wdir"
  local vcs_url2="ssh://${vcu_CONNECT_dnsname}/$vcu_CONNECT_wdir/dgrid"
  echo "pwd="`pwd`
  set -x
  hg push $vcs_url
  (cd dgrid ; hg push $vcs_url2)
  set +x
}

updnode_push_ssh_updthis_cli(){
  dbg_echo updnode 5 F Start
  if [ -n "$1" ]; then
    updnode_push_ssh_updthis $1
  else
    echo "nodeid not set, exiting"
  fi
}

updnode_push_ssh_updthis(){
  dbg_echo updnode 5 F Start
  local nodeid=$1
  if [ ! x$MODINFO_enable_run == "xY" ]; then
    echo "Enable \"run\" module to use"
    exit
  else
    dbg_echo updnode 5 F "Ok, \"run\" module enabled"
  fi
  if nodecfg_nodeid_exists $nodeid ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
  fi
  #run_nodecmd $nodeid status
  dbg_echo updnode 5 F "run_nodecmd $nodeid updthis upd"
  run_nodecmd $nodeid updthis upd
}


updnode_cli_help(){
  dgridsys_s;echo "updnode vcs-url <nodeid> - show VCS url (git/hg) of <nodeid>  "
  dgridsys_s;echo "updnode update-push-ssh-updthis <nodeid> - push upd (cfg&dist) to <nodeid>"
  dgridsys_s;echo "updnode update-push-vgs <nodeid> - hg/git push update to <nodeid>"
  updthis_cli_help
}

updnode_cli_run() {
  local maincmd=$1
  local cmd=$2
  local name=$3
  local cmd_found="0"

  dbg_echo updnode 5 x${maincmd} == x"updnode"
  dbg_echo updnode 5 "Call: updthis_cli_run \"$*\""
  updthis_cli_run $*
  if [ ! x${maincmd} == x"updnode" ]; then
    return
  fi

  if [ x${cmd} == x"" ]; then
    updnode_cli_help
    cmd_found=1
  fi

  if [ x${cmd} == x"update-push-ssh-updthis" ]; then
    echo -n
    shift 2
    updnode_push_ssh_updthis_cli $*
    cmd_found=1
  fi

  if [ x${cmd} == x"update-push-vcs" ]; then
    echo -n
    shift 2
    updnode_push_vcs_cli $*
    cmd_found=1
  fi


  if [ x${cmd} == x"vcs-url" ]; then
    echo -n
    shift 2
    updnode_vcs_url_cli $*
    cmd_found=1
  fi


  if [ $cmd_found = "0" ]; then
    echo "updnode : command line argument \"${cmd}\" not found"
  fi
}


