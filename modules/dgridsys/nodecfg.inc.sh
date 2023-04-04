#!/bin/bash


nodecfg_show_cli() {
  local eid=$1
  dbg_echo nodecfg 8 F "* = $*"
  local var=`distr_is_not_entityid $eid`
  if [ ! x"$?" == x0 ]; then
    echo "Exit, \"$eid\" must be nodeid/hostid/... "
    exit
  fi
  eval "local $var"
  dbg_echo nodecfg 8 F eid_type=$eid_type
  if [ x"$eid_type" == x"hostid" ]; then
    hostcfg_hostid_load $eid "showcli_"
    #return
  fi
  if [ x"$eid_type" == x"nodeid" ]; then
      nodecfg_nodeid_load $eid "showcli_"
  fi
  generic_listvars showcli_ | sed s/showcli_//g
}

nodecfg_gethostlist_hlpr() {
  echo "$HOST_id : hst=$HOST_dnsname"
}
nodecfg_gethostlist() {
  hostcfg_iterate_hostid 'nodecfg_gethostlist_hlpr'
}

_nodecfg_nodelist_col1() {
  var=$1
  _name=$2
  if [ x"${!var}" == "x" ]; then
    echo -n
  else
    echo -n ${_name}=\"${!var}\"
    echo -n " "
  fi
}

_nodecfg_nodelist_col2() {
  var=$1
  _name=$2
  if [ x"${!var}" == "x" ]; then
    echo -n
  else
    echo "       "${_name}=\"${!var}\"
  fi
}

_nodecfg_getnodelist_short_hlpr() {
  printf "%20s : " $NODE_ID
  ##_nodecfg_nodelist_col1 NODE_hostname hostname;
  _nodecfg_nodelist_col1 HOST_dnsname dns
  _nodecfg_nodelist_col1 NODE_INSTPATH path
  ##echo -n "hostname=$NODE_hostname "
  ##echo -n "grp=\"$NODE_GROUPS_append\" "
  #_nodecfg_nodelist_col1 NODE_GROUPS_append grp;
  #_nodecfg_nodelist_col1 NODE_INSTPATH inst;
  #echo ----
  echo
}

nodecfg_getnodelist_short() {
  nodecfg_iterate_full_nodeid _nodecfg_getnodelist_short_hlpr
}

_nodecfg_getnodelist_full_hlpr() {
  local var
  #printf "== %25s  " $NODE_ID
  echo " ==  $NODE_ID   [$NODE_HOST]"
  echo
  for var in $(nodeid_vars_all); do
    if [ -n "${!var}" ]; then
      echo $var=${!var}
    else
      echo "$var [NOT SET]"
    fi

  done

  echo
  echo
}

nodecfg_getnodelist_full() {
  nodecfg_iterate_full_nodeid _nodecfg_getnodelist_full_hlpr
}

print_vars() {
  local $i
  for i in $*; do
    if [ -n "${!i}" ]; then
      echo $i=${!i}
    fi
  done
}

nodecfg_register_cli(){
  nodecfg_register_entityid $1
}
nodecfg_register_entityid() {
  local eid=$1 _params=""
  local _params=`distr_entitycfg_get_info $eid`
  eval "local ${_params}"
  #generic_listvars eid_
  if [ -z "$eid_dir" ]; then 
     distr_error "eid_dir is \"\""
     return 1;
  fi
  #local f=`find $eid_dir`
  local f=`$eid_dir`
  
  echo system_register_file_changes "nodecfg_register" "$FUNCNAME" $f
  system_register_file_changes "nodecfg_register" "$FUNCNAME" $f
}

nodecfg_register_all_cli() {
  nodecfg_register_entityid_all $@
}


nodecfg_register_entityid_all() {
  local f="$dgrid_bynodes_dir"
  echo system_register_file_changes "nodecfg_register" "$FUNCNAME" $f
  system_register_file_changes "nodecfg_register" "$FUNCNAME" $f
}


dgridsys_nodecfg_addthis() {
distr_nodecfg_addthis $@
}


dgridsys_cli_help_nodecfg() {
  #echo -n
  dgridsys_s; echo "nodecfg add <new-id> type=node-this - create config for \"this\" node"
  dgridsys_s; echo "nodecfg add <new-id> type=node-empty - create empty node"
  dgridsys_s; echo "nodecfg add <new-id> type=node-subnode - create subnode of this node"
  dgridsys_s; echo "nodecfg add <new-id> type=host-empty - create empty node"
#  dgridsys_s; echo "nodecfg addthis - try to add host & node of this install"
  dgridsys_s; echo "nodecfg register-changes <nodeid/hostid> - commit to vcs entityid chages"
  dgridsys_s; echo "nodecfg register-changes-all - commit to vcs all node/entity changes"
  dgridsys_s; echo "nodecfg show <nodeid/hostid>"
  dgridsys_s; echo "nodecfg hostlist - list hostid"
  dgridsys_s; echo "nodecfg nodelist - list nodeid"
  dgridsys_s; echo "nodecfg nodelist-full - list nodeid info"

}

_add_hostcfg_hlpr() {
  #echo [2] hst1=$hst1 1>&2
  #echo [2] hst2=$hst2 1>&2
  echo [2] HOST_id=$HOST_id 1>&2
}


dgridsys_cli_nodecfg() {
  local maincmd="$1"  cmd="$2"  name="$3"
  local hst1="$3" param1="$3" hst2="$4" ret=0

  dbg_echo dgridsys 5 F "\$* = $*"

  if [ x$cmd == x"hostlist" ]; then
    #echo
    echo "--- host of nodes list  ---"
    nodecfg_gethostlist
    echo
    return
  fi

  if [ x$cmd == x"nodelist" ]; then
    echo
    echo --------- node list -----------
    echo
    nodecfg_getnodelist_short
    echo
    return
  fi

  if [ x$cmd == x"nodelist-full" ]; then
    #echo
    echo --------- node list -----------
    nodecfg_getnodelist_full
    ret=$?
    echo
    return $ret
  fi

  if [ x$cmd == x ]; then
    dgridsys_cli_help_nodecfg
    dgridsys_cli_help_cfgfiles
    #echo ".... module <name>"
    exit
  fi

  if [ x$cmd == x"add" ]; then
    shift 2
    dgridsys_cli_main distr entitycfg-add $*
    return $?
  fi

  if [ x$cmd == x"show" ]; then
    shift 2
    nodecfg_show_cli $*
    return $?
  fi

  if [ x$cmd == x"register-changes" ]; then
    shift 2
    nodecfg_register_cli $*
    return $?
  fi

  if [ x$cmd == x"register-changes-all" ]; then
    shift 2
    nodecfg_register_all_cli $*
    return $?
  fi

}
