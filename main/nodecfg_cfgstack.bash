#!/bin/bash

##########################################################

cfgstack_cfg_thisnode() { # [API] [RECOMENDED]
  local _cfgfile=$1

  if [ x"$THIS_NODEID" == "x" ]; then
    if [ ! x"$DGRID_f_allow_no_thisnode" == "x1" ]; then
      echo "ERROR: cfgstack_cfg_thisnode(${_cfgfile}): THIS_NODE not defined" 1>&2
      generic_stacktrace 1>&2
      exit
    fi
  else
    cfgstack_load_byid ${_cfgfile} ${THIS_NODEID}
  fi
}

##########################################################

cfgstack_load_byid() { # [API] [RECOMENDED]
  local cmd cfgfile _nodeid
  cfgfile=$1
  _nodeid=$2
  shift 2
  cfgstack_cfg_op $cfgfile ${_nodeid} op="load" $*
}
################################################################

################################################################
# cfgstack_cfg_op etc/someconfig.conf $NODE_ID op=source|load|trace|filenames
################################################################
cfgstack_cfg_op() { # [API]
  # cmd : trace load filenames source
  local cmd cfgprefix params op var
  local cfgfile=$1 nodeid=$2 entityid=$2
  shift 2
  params="$*"
  dbg_echo cfgstack 5 F "Start params=\"$params\""

  #cfgprefix="UNKNOWN"
  [ -n "$params" ]  && eval "local $params"
  [ -z "$op" ] && op="load"

  cmd=$op
  pushd $DGRIDBASEDIR >/dev/null

  var=$(cfgstack_search_dir_list $entityid)
  eval $var 
  unset var
  dbg_echo cfgstack 5 F "op=\"$op\" prefix=\"$prefix\" cfgprefix=\"$cfgprefix\""
  dbg_echo cfgstack 5 F "dir list to check=$CFGSTACK_search_dir_list"
  cfgstack_msg_trace $cmd
  for _dir in $CFGSTACK_search_dir_list; do
    ############cfgstack_msg_trace $cmd
    cfgstack_msg_trace $cmd -n "Check config : "
    cfg=${_dir}/$cfgfile
    ############# cfgstack_cfg_one cmd=$cmd cfgprefix=$cfgprefix cfg=$cfg
    if [ x"$op" == x"source" -o x"$op" == x"trace" -o x"$op" == x"stdout" -o x"$op" == x"filenames"  ]; then
      cfgstack_cfg_one $cfg
    fi
    if [ x"$op" == x"load"  ]; then
      var=$( cfgstack_cfg_one $cfg )
      eval $var
    fi
  done
  cfgstack_msg_trace $cmd
  popd >/dev/null

}

#############################


cfgstack_cfg_one() {
  # cmd= cfgprefix= # inherit
  local var cfg=$1
  dbg_echo cfgstack 5 F "cmd=$cmd cfgprefix=$cfgprefix cfg=$cfg"

  if [ x"$op" == x"trace" ]; then
    if [ -f $cfg ]; then
      cfgstack_msgprintf_trace $cmd "%8s%2s" "[FOUND] "
    else
      cfgstack_msgprintf_trace $cmd "%8s%2s" "[_not_] "
    fi
    cfgstack_msg_trace $cmd "$cfg  ."
    return 0
  fi

  if [ -f $cfg ]; then
    # load config if needed
    if [ x$cmd == x"source" ]; then
      dbg_echo cfgstack 4 F " source $cfg"
      source $cfg
      return 0
    fi
    if [ x$cmd == x"filenames" ]; then
      echo $cfg
    fi
    if [ x$cmd == x"stdout" -o x$cmd == x"load" ]; then
      dbg_echo cfgstack 4 F " cfgstack_load_stdout $cfg"
      cfgstack_load_stdout $cfg  # inherit $cfgprefix
      return 0
    fi
    dbg_echo cfgstack 4 F "cmd=\"$cmd\" not found"
    return 1
  else
    return 1
  fi
}

######################

_cfgstack_filtercfg1() {
  local s p0 p1
  while read s; do
    #echo "sssss $prefix $s"
    p0=$(generic_cut_param "=" 1 "$s")
    #p1=$(generic_cut_param "=" 2 "$s") 
    # may be = in variable
    p1=${s#$p0=}
    if [ -z "$p0" ]; then continue; fi
    if [[ ! "$p0" =~ ^[[:alnum:]_]+$  ]]; then continue; fi
    echo "${prefix}$p0=$p1"
  done
}

cfgstack_load_stdout() {
  local cfg=$1
  cat $cfg | _cfgstack_filtercfg1
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


##########################

cfgstack_search_dir_list_grp() {
  local g f i l="$*"
  local tIFS="$IFS";IFS=","
  for i in $l; do
    IFS="$tIFS"
      g=`nodecfg_grp_groups $i`
      [ -n "$g" ] && l="$l,$g"
  done
  dbg_echo cfgstack 6 F "expanded grps: $l"
  IFS=","
  for i in $l; do
    IFS="$tIFS"
    f="$f `nodecfg_grp_cfgdir $i`"
  done
  echo -n $f
}


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

  LIST="$LIST ${nodecfg_lasttime_prefix}"
  dbg_echo cfgstack 8 F LIST="\"$LIST\""
  echo "export CFGSTACK_search_dir_list=\"${LIST}\""
  dbg_echo cfgstack 8 F End
}
