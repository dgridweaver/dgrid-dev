#!/bin/bash

if [ x$MODINFO_loaded_updnode == "x" ]; then
  export MODINFO_loaded_updnode="Y"
else
  return
fi

source ${MODINFO_modpath_updnode}/updthis.bash

export MODINFO_msg_updnode=2

export updnode_CLIMENU_CMDS_LIST="update_push_ssh_updthis update_push_vcs update_push_vcs_sshfs update_showconfig"

updnode_climenu_cmd_update_showconfig(){ updnode_showconfig_cli $@; }
updnode_climenu_cmd_update_push_vcs(){ updnode_push_vcs_cli $@; }
updnode_climenu_cmd_vcs_url(){ updnode_vcs_url_cli $@; }
updnode_climenu_cmd_update_push_ssh_updthis() { updnode_push_ssh_updthis $@; }
updnode_climenu_cmd_update_push_vcs_sshfs(){ updnode_push_vcs_sshfs_cli $@; }

### universal ####


updnode_showconfig_cli(){
  local nodeid=$1
  dbg_echo updnode 5 F "Start, params: $*"
  if nodecfg_nodeid_exists "$nodeid" ; then 
    cfgstack_cfg_op "etc/updnode.conf" $nodeid op=trace
  else
    msg_echo updnode 2 "nodeid not found"
    return 1
  fi
  #MODINFO_dbg_cfgstack=14
  cfgstack_cfg_op "etc/updnode.conf" "$nodeid"
  generic_listvars UPDTHIS_
  generic_listvars UPDNODE_
  echo
  dbg_echo updnode 5 F "End"
}

updnode_update_push_cli(){
  dbg_echo updnode 8 F Start
  local nodeid=$1
  local upt1
  [ ! -n "$nodeid" ] && distr_error "==> ERROR! \$1 (nodeid) of function should be not empty" && exit

  prefix="uppushd_" cfgstack_load_byid etc/updnode.conf $nodeid
  #echo " -- generic_listvars B ---"
  #generic_listvars uppushd_
  ##generic_listvars UPDNODE
  #echo " -- generic_listvars END ---"
  msg_echo updnode 2 UPDNODE_update_push_type=$uppushd_UPDNODE_update_push_type
  
  dbg_echo updnode 8 F End
  dgridsys_cli_main updnode "$uppushd_UPDNODE_update_push_type" $nodeid
  dbg_echo updnode 8 F End
}


### vcs sshfs ####

updnode_push_vcs_sshfs_cli(){
  local nodeid=$1
  dbg_echo updnode 5 F Start
  main_exit_if_not_enabled sshenv
  
  if nodecfg_nodeid_exists "$nodeid" ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
    exit
  fi
  eval `pref="local vcs_" run_connect_config $nodeid`
  local p=`sshenv_sshfs_get_mount_dir_main $vcs_CONNECT_HOST_id`
  echo p=$p
  
  [ -z "${vcs_CONNECT_wdir}" ] && msg_echo updnode 1 "No CONNECT_wdir for \"$nodeid\"" && exit

  local vcs_url="$p/${vcs_CONNECT_wdir}"
  local vcs_url2="$p/${vcs_CONNECT_wdir}/dgrid"
  generic_listvars vcs
  #ls $vcs_url; exit

  set -x
  hg push $vcs_url; (cd $vcs_url; hg update)
  (cd dgrid ; hg push $vcs_url2)
  (cd $vcs_url2; hg update)
  set +x
  dbg_echo updnode 2 F run_nodecmd $nodeid module cc
  run_nodecmd $nodeid module cc
}


### vcs ##########

updnode_vcs_url_cli(){
  dbg_echo updnode 5 F Start
  local nodeid=$1
  if nodecfg_nodeid_exists "$nodeid" ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
  fi
  eval `pref="local vcs_" run_connect_config $nodeid`
  #generic_listvars vcs_
  echo "${pref}vcs_url=\"ssh://${vcs_CONNECT_dnsname}/$vcs_CONNECT_wdir\""
}

updnode_push_vcs_cli(){
  dbg_echo updnode 5 F Start
  local nodeid=$1
  if nodecfg_nodeid_exists "$nodeid" ; then 
    dbg_echo updnode 5 F "Ok, \"$nodeid\" exists"
  else  
    distr_error "ERROR, nodeid=$nodeid not exists"
  fi
  eval `pref="local vcs_" run_connect_config $nodeid`
  #generic_listvars vcs_
  local vcs_url="ssh://${vcs_CONNECT_dnsname}/$vcs_CONNECT_wdir"
  local vcs_url2="ssh://${vcs_CONNECT_dnsname}/$vcs_CONNECT_wdir/dgrid"
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
  dgridsys_s;echo "updnode vcs-url <nodeid> - show VCS url (git/hg) of <nodeid>"
  dgridsys_s;echo "updnode update-showconfig <nodeid> - show update config of <nodeid>"
  dgridsys_s;echo "updnode update-push <nodeid> - push update by configured method"
  dgridsys_s;echo "updnode update-push-ssh-updthis <nodeid> - push upd (cfg&dist) to <nodeid>"
  dgridsys_s;echo "updnode update-push-vcs <nodeid> - hg/git push update to <nodeid>"
  dgridsys_s;echo "updnode update-push-vcs-sshfs <nodeid> - sshfs+hg/git push update"
  updthis_cli_help
}

updnode_cli_run() {
  local maincmd=$1
  local cmd=$2
  local name=$3
  local cmd_found="0"

  dbg_echo updnode 5 F x${maincmd} == x"updnode"
  dbg_echo updnode 5 "Call: updthis_cli_run \"$*\""
  updthis_cli_run $*
  if [ ! x${maincmd} == x"updnode" ]; then
    return
  fi

  if [ x${cmd} == x"" ]; then
    updnode_cli_help
    cmd_found=1
  fi

  if [ x${cmd} == x"update-showconfig" ]; then
    shift 2
    updnode_showconfig_cli $*
    cmd_found=1
  fi

  if [ x${cmd} == x"update-push" ]; then
    shift 2
    updnode_update_push_cli $*
    cmd_found=1
  fi


  if [ x${cmd} == x"update-push-ssh-updthis" ]; then
    shift 2
    updnode_push_ssh_updthis_cli $*
    cmd_found=1
  fi

  if [ x${cmd} == x"update-push-vcs" ]; then
    shift 2
    updnode_push_vcs_cli $*
    cmd_found=1
  fi


  if [ x${cmd} == x"update-push-vcs-sshfs" ]; then
    shift 2
    updnode_push_vcs_sshfs_cli $*
    cmd_found=1
  fi

  if [ x${cmd} == x"vcs-url" ]; then
    shift 2
    updnode_vcs_url_cli $*
    cmd_found=1
  fi


  if [ $cmd_found = "0" ]; then
    echo "updnode : command line argument \"${cmd}\" not found"
  fi
}


