#!/bin/bash

##########################################################

cfgstack_cfg_thisnode() { # [API] [RECOMENDED]
  local _cfgfile=$1

  if [ x"$THIS_NODEID" == "x" ]; then
    if [ x"$DGRID_f_allow_no_thisnode" == "x1" ]; then
      echo "ERROR: cfgstack_cfg_thisnode(${_cfgfile}): THIS_NODE not defined" 1>&2
      generic_stacktrace 1>&2
      exit
    fi
    cfgstack_load_byid ${_cfgfile} ${THIS_NODEID}
  fi
}

##########################################################

cfgstack_load_byid() { # [API] [RECOMENDED]
  local cmd cfgfile _nodeid
  cfgfile=$1
  _nodeid=$2
  cfgstack_cfg_op $cfgfile ${_nodeid} op="load"
}
################################################################

################################################################
# cfgstack_cfg_op etc/someconfig.conf $NODE_ID op=load|trace
################################################################
cfgstack_cfg_op() { # [API]
  # cmd : trace exports load listfiles
  local cmd cfgprefix cfgfile nodeid params op
  cfgfile=$1
  nodeid=$2
  entityid=$2
  shift 2
  params="$*"
  dbg_echo cfgstack 5 F "params=\"$params\""
  eval $params
  cfgprefix="UNKNOWN"

  cmd=$op

  pushd $DGRIDBASEDIR >/dev/null

  var=$(cfgstack_search_dir_list $entityid)
  eval $var
  unset var

  dbg_echo cfgstack 5 F "dir list to check=$CFGSTACK_search_dir_list"
  cfgstack_msg_trace $cmd
  for _dir in $CFGSTACK_search_dir_list; do
    ############cfgstack_msg_trace $cmd
    cfgstack_msg_trace $cmd -n "Check config : "
    cfg=${_dir}/$cfgfile
    #############echo cfgstack_cfg_one $cmd $cfgprefix $cfg
    cfgstack_cfg_one $cmd $cfgprefix $cfg
  done
  cfgstack_msg_trace $cmd
  popd >/dev/null

}

#############################

cfgstack_loadshellcfg() {
  cfgprefix=$1
  cfg=$2

  source $cfg
}

cfgstack_load_exports() {
  local cfg cfgprefix
  cfgprefix=$1
  cfg=$2
  cat $cfg | grep "^$cfgprefix"
}

cfgstack_msg_trace() {
  cmd=$1
  shift 1
  if [ x$cmd == x"trace" ]; then
    echo $*
  fi
}

cfgstack_msgprintf_trace() {
  cmd=$1
  shift 1
  if [ $cmd == "trace" ]; then
    printf $*
  fi
}

cfgstack_cfg_one() {
  cmd=$1
  cfgprefix=$2
  cfg=$3

  if [ -f $cfg ]; then
    cfgstack_msgprintf_trace $cmd "%8s%2s" "[FOUND] "
  else
    cfgstack_msgprintf_trace $cmd "%8s%2s" "[_not_] "
  fi

  cfgstack_msg_trace $cmd "$cfg  ."

  if [ -f $cfg ]; then
    # load config if needed
    if [ x$cmd == x"load" ]; then
      dbg_echo cfgstack 1 [2] "cfgstack_cfg_one(): cfgstack_loadshellcfg $cfgprefix $cfg"
      cfgstack_loadshellcfg $cfgprefix $cfg
    fi

    if [ x$cmd == x"exports" ]; then
      dbg_echo cfgstack 1 [2] "cfgstack_cfg_one():cfgstack_load_exports $cfgprefix $cfg"
      cfgstack_load_exports $cfgprefix $cfg
    fi

    return 0
  else
    return 1
  fi
}

##########################

cfgstack_search_dir_list() {
  local apath apath1 apath2 LIST
  local entityid=$1

  dbg_echo cfgstack 8 F Begin

  LIST=""
  LIST="${nodecfg_system_prefix}"
  #
  if nodecfg_nodeid_exists "$entityid"; then
    dbg_echo cfgstack 5 F "nodeid=$entityid"
    apath1=$(nodecfg_nodeid_cfgdir $entityid)

    nodecfg_nodeid_load $entityid "entityid_"
    apath2=$(hostcfg_hostid_cfgdir $entityid_NODE_HOST)
    LIST="$LIST $apath2 $apath1"
  fi

  if hostcfg_hostid_exists "$entityid"; then
    dbg_echo cfgstack 5 F "hostid=$entityid"
    apath=$(hostcfg_hostid_cfgdir $entityid)
    LIST="$LIST $apath"
  fi

  dbg_echo cfgstack 5 F entityid=$entityid
  #LIST="$LIST ${nodecfg_path}/$NODE_HOST"
  ####listvar="NODE_GROUPS_append_$varid"
  #dbg_echo cfgstack 5 F NODE_GROUPS_append= $NODE_GROUPS_append
  #dbg_echo cfgstack 5 F NODE_GROUPS_dirs= $NODE_GROUPS_dirs
  #LIST="$LIST $NODE_GROUPS_dirs"
  #LIST="$LIST ${nodecfg_path}/${nodeid}"

  LIST="$LIST ${nodecfg_latstime_prefix}"
  dbg_echo cfgstack 8 F LIST="\"$LIST\""
  echo "export CFGSTACK_search_dir_list=\"${LIST}\""
  dbg_echo cfgstack 8 F End
}
