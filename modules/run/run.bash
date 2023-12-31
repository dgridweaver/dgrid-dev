#!/bin/bash

if [ x$MODINFO_loaded_run == "x" ]; then
  export MODINFO_loaded_run="Y"
else
  return
fi

MODINFO_dbg_run=0
#MODINFO_enable_run=

source ${MODINFO_modpath_run}/connect.conf

if [ -f ./dgrid-site/etc/connect.conf ]; then
  source ./dgrid-site/etc/connect.conf
fi

source ${MODINFO_modpath_run}/run_cmd.bash

run_hostid_vars() {
  echo -n " CONNECT_dnsname CONNECT_type CONNECT_sshport HOST_sshport HOST_sshopts "
}

run_nodeid_vars() {
  #echo -n " NODE_sshport NODE_sshopts "
  echo -n NODE_sshport NODE_sshopts
}

run_env_start() {
  RUN_SSH_OPTS=" -A "
  #RUN_SSH_CMD="ssh"
  RUN_SSH_CMD=$(a_cmd=ssh a_mod=run system_alternative)
  dbg_echo run 3 "F RUN_SSH_CMD=$RUN_SSH_CMD" 1>&2
  #RUN_SSH_OPTS=$RUN_SSH_OPTS
}

run_hostid_post_load_api() {
  run_connect_dnsname_set $*
  #echo "run_hostid_post_load_api , CONNECT_dnsname=$CONNECT_dnsname " 1>&2
}

run_connect_dnsname_set() {
  local name v
  local _hostid=$1
  local _pref=$2

  export ${_pref}CONNECT_dnsname=$(generic_var_content_priority ${_pref}CONNECT_dnsname \
    ${_pref}HOST_dnsname ${_pref}HOST_id)
}

run_print_module_info() {
  echo "run: mod info, called run_print_module_info"

}

############## pings ##########################

run_ping_cli() {
  local entity_id=$1 _params
  _params=`run_rmt_snippet "showconfig" snp_remoteid="$entity_id"` # snp_connect_profile="${c_p}"
  #exit
  eval ${_params}
  dbg_echo run 5 F "($entity_id) configs, CONNECT_dnsname=$CONNECT_dnsname"
  generic_listvars CONNECT_
  echo "=========== devtcp ==============="
  run_check_ping_devtcp
  echo "=========== ping ==============="
  run_check_ping_ping
}

run_check_ping_ping() {
  ping -c $RUN_check_ping_ping_count $CONNECT_dnsname
}

run_check_ping_devtcp() {
  echo -n
  local pp=22
  if [ ! x$CONNECT_sshport == "x"  ]; then
    pp=$CONNECT_sshport
  fi
  generic_check_host_port "$CONNECT_dnsname"  $pp 3
  if [ "$?" == "0" ]; then
    echo "OK, port $pp open"
  else
    echo "NO_CONNECT, port $pp closed"
  fi
}
generic_check_host_port() { # [API] [GENERIC]
  REMOTE_HOSTNAME=$1
  CHECK_PORT=$2
  TIMEOUT=$3
  if [ x$dg_BASH == "x" ]; then dg_BASH="bash"; fi
  timeout 3 ${dg_BASH} -c "</dev/tcp/$REMOTE_HOSTNAME/$CHECK_PORT"
  return $?
}



############ grid level runs   ################

_run_allgrid_nodecmd_hlpr() {
  #echo TTT=$*
  nodecfg_load_nodeid ${NODE_ID}
  
  if [ x$hoststat_isup_this_host == "x1" ]; then
    #echo "Node ${NODE_ID} online, run cmd"
    dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
    run_nodecmd ${NODE_ID} ${_run_params}
  else
    dbg_echo run 1 "Node \"${NODE_ID}\" offline, do nothing"
    msg_echo run 2 "Node \"${NODE_ID}\" offline, do nothing"
  fi

}

run_allgrid_nodecmd() {
  echo -n
  export _run_params=$*
  nodecfg_iterate_nodeid _run_allgrid_nodecmd_hlpr $*
}

run_allgrid_nodecmd_cmd() {
  run_allgrid_nodecmd $*
}

###

_run_allgrid_hostcmd_hlpr() {
  if [ x$hoststat_isup_this_host == "x1" ]; then
    dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
    run_hostcmd ${HOST_id} ${_run_params}
  else
    msg_echo run 2 "Host \"${HOST_id}\" offline, do nothing"
    dbg_echo run 1 "Host \"${HOST_id}\" offline, do nothing"
  fi

}

run_allgrid_hostcmd() {
  echo -n
  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi
  export _run_params=$*
  dbg_echo run 2 "run_allgrid_hostcmd() : params=\"$*\""
  hostcfg_iterate_hostid _run_allgrid_hostcmd_hlpr $*
}

run_allgrid_hostcmd_cmd() {
  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi
  export _run_params=$*
  run_allgrid_hostcmd $*
}

###

_run_allgrid_nodeshellcmd_hlpr() {
  #echo TTT=$*
  if [ x$hoststat_isup_this_host == "x1" ]; then
    #echo "Node ${NODE_ID} online, run cmd"
    dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
    run_hostcmd ${HOST_id} ${_run_params}
  else
    msg_echo run 2 "Host \"${HOST_id}\" offline, do nothing"
    dbg_echo run 1 "Host \"${HOST_id}\" offline, do nothing"
  fi

}


run_allgrid_nodeshellcmd() {
  echo -n
  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi
  export _run_params=$*
  dbg_echo run 2 "run_allgrid_nodeshellcmd() : params=\"$*\""
  hostcfg_iterate_hostid _run_allgrid_nodeshellcmd_hlpr $*
}

run_allgrid_nodeshellcmd_cmd() {
  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi
  export _run_params=$*
  run_allgrid_nodeshellcmd $*
}

run_connectcfg_cli(){
  local eid=$1
  shift 1
  if [ "x$eid" == "x" ]; then
    echo "use: run_connectcfg_cli (entityid)"
    exit
  fi
  run_showconfig $eid $*
  echo -----------------------
  export RUN_DRY_RUN=Y
  if nodecfg_nodeid_exists $eid; then
    run_nodecmd $eid $*
  fi
  if hostcfg_hostid_exists $eid; then
    run_hostcmd $eid $*
  fi
}

run_exec_f(){
  exec $@
}

run_is_entityid(){ # [API]
  distr_is_entityid $@
}
run_is_not_entityid(){ # [API]
  distr_is_not_entityid $@
}

############ climenu ##############




run_climenu_cmds() {
  local cmd=$1 eid=$2 f
  dbg_echo run 5 F ": $*"
  shift 2
  local params=$*
  dbg_echo run 5 F "if:" generic_word_in_list $cmd $RUN_climenu_cmd_list ";";
  if generic_word_in_list $cmd $RUN_climenu_cmd_list; then
    dbg_echo run 8 F "run_cli_run run $cmd $eid $params "
    run_cli_run run $cmd $eid $params 
    return 0
  else
    return 1
  fi
}



############ cli integration  ################

run_help_cli() {
  dgridsys_s;echo "run nodecmd <node id> <cmd> - run dgridsys command on node <nodeid>"
  dgridsys_s;echo "run hostcmd <host id> <cmd> - run command on host <hostid>"
  dgridsys_s;echo "run ping <hostid|nodeid> [params] - run ping/etc on <hostid+nodeid>"
  #dgridsys_s;echo "run local_exec - helper func for run"
  dgridsys_s;echo "run connectcfg <host|node id> - chack connect config <hostid>"
  dgridsys_s;echo "run nodeshellcmd <node id> <cmd> - run shell command on node <nodeid>"
  dgridsys_s;echo "run allgrid-nodecmd <cmd> - run dgridsys command on all (active) nodes"
  dgridsys_s;echo "run allgrid-hostcmd <cmd> - run command on all (active) hosts"
  dgridsys_s;echo "run allgrid-nodeshellcmd <cmd> - run shell command on   on all (active) hosts"
}

run_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo run 2 run_cli_run dgridsys_cli_run_argv=$dgridsys_cli_run_argv
  dbg_echo run 2 F "*=$*"

  dbg_echo run 5 x${maincmd} == x"run"
  if [ x${maincmd} == x"run" ]; then
    echo -n
  else
    return 1
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    run_help_cli
  fi


  if [ x${cmd} == x"ping" ]; then
    shift 2
    run_ping_cli $*
  fi

  if [ x${cmd} == x"shell" ]; then
    shift 2
    run_shell_cli $*
  fi


  if [ x${cmd} == x"nodeshellcmd" ]; then
    shift 2
    local n=$1
    shift 1
    run_nodecmd $1 run exec_f $*
  fi

  if [ x${cmd} == x"nodecmd" ]; then
    shift 2
    run_nodecmd $*
  fi

  if [ x${cmd} == x"hostcmd" ]; then
    shift 2
    echo "*=$*"
    run_hostcmd_cli $*
  fi

  if [ x${cmd} == x"connectcfg" ]; then
    echo -n
    shift 2
    run_connectcfg_cli $*
  fi

# helper function
  if [ x${cmd} == x"exec_f" ]; then
    echo -n
    shift 2
    run_exec_f $*
  fi

  if [ x${cmd} == x"allgrid-nodecmd" ]; then
    echo -n
    shift 2
    run_allgrid_nodecmd_cmd $*
  fi

  if [ x${cmd} == x"allgrid-hostcmd" ]; then
    echo -n
    shift 2
    run_allgrid_hostcmd_cmd $*
  fi

  if [ x${cmd} == x"allgrid-nodeshellcmd" ]; then
    echo -n
    shift 2
    run_allgrid_nodeshellcmd_cmd $*
  fi

}

