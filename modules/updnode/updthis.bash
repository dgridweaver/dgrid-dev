#!/bin/bash

#updthis_env_start() {
updthis_set_vars_for_nodeid() {
  dbg_echo updnode 8 F Start
  local nodeid=$1
  if [ ! -n "$nodeid" ]; then
    distr_error "==> ERROR! \$1 (nodeid) of function should be not empty"
    exit
  fi
  cfgstack_load_byid etc/updnode.conf $nodeid op=stdout

  export UPDTHIS_UPD_NODEID=$UPDNODE_uplink_nodeid
  if [ ! x$UPDNODE_uplink_nodeid == "x" ]; then
    nodecfg_nodeid_load $UPDNODE_uplink_nodeid
    if [ "x$?" == "x0" ]; then
      echo -n
      echo CONNECT_dnsname=$CONNECT_dnsname
      echo NODE_INSTPATH=$NODE_INSTPATH
      UPDNODE_uplink_repo="ssh://$CONNECT_dnsname//$NODE_INSTPATH"
    else
      echo "error: UPDNODE_uplink_node set incorrectly" 1>&2
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
  dbg_echo updnode 8 F End
}

updthis_print_module_info() {
  echo "updinst01: mod info, called updthis_print_module_info"

}

updthis_printcfg() {
  generic_listvars UPDTHIS
}


updthis_upd_simple() {
  dbg_echo updnode 5 F Start
  echo
  updthis_set_vars_for_nodeid $THIS_NODEID
  updthis_showcfg
  updthis_upd_cfg
  updthis_upd_dist
  dgridsys_cli_main module cache_clear
  dbg_echo updnode 5 F End
}

updthis_upd_cfg() {
  if [ "x$UPDTHIS_repo_cfg" == x ]; then
    return
  fi
  echo "hg pull $UPDTHIS_repo_cfg; hg update"
  #hg pull $UPDTHIS_repo_cfg ; hg update
}

updthis_upd_dist() {
  if [ "x$UPDTHIS_repo_dist" == x ]; then
    return
  fi

  echo "cd dgrid; hg pull $UPDTHIS_repo_dist; hg update"
  ( cd dgrid; hg pull $UPDTHIS_repo_dist; hg update )
}

updthis_showcfg() {
  set | grep ^UPDTHIS_
  set | grep ^UPDNODE_
}

############ cli integration  ################

updthis_cli_help() {
  dgridsys_s;  echo "updthis showcfg - show configs"
  dgridsys_s;  echo "updthis upd - update this node"
}

updthis_cli_run() {
  dbg_echo updnode 5 F Start
  local maincmd=$1
  local cmd=$2
  local name=$3
  local cmd_found="0"

  dbg_echo updnode 5 F x${maincmd} == x"updthis"
  if [ ! x${maincmd} == x"updthis" ]; then
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    updnode_cli_help
    cmd_found=1
  fi

  if [ x${cmd} == x"upd" ]; then
    echo -n
    updthis_upd_simple $*
    cmd_found=1
  fi

  if [ x${cmd} == x"showcfg" ]; then
    echo -n
    updthis_showcfg $*
    cmd_found=1
  fi

  if [ $cmd_found = "0" ]; then
    echo "updthis : command line argument \"${cmd}\" not found"
  fi

}
