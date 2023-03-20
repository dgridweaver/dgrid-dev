#!/bin/bash


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

#source ${MODINFO_modpath_dgridsys}/thishostinfo.inc.bash

dgridsys_nodecfg_addthis() {
distr_nodecfg_addthis $@
}


dgridsys_cli_help_nodecfg() {
  #echo -n
  dgridsys_s; echo "nodecfg hostlist - list modules"
  dgridsys_s; echo "nodecfg hostadd <> - ..."
  dgridsys_s; echo "nodecfg add <> - ..."
  dgridsys_s; echo "nodecfg addthis - try to add host & node of this install"
  dgridsys_s; echo "nodecfg nodelist <> - ..."
  dgridsys_s; echo "nodecfg nodelist-full <> - ..."

}

_add_hostcfg_hlpr() {
  #echo [2] hst1=$hst1 1>&2
  #echo [2] hst2=$hst2 1>&2
  echo [2] HOST_id=$HOST_id 1>&2
}

dgridsys_nodecfg_add_hostcfg() {
  #export hst1=$1
  #hst2=$2

  HOST_id=$1
  HOST_hostname=$2

  nodecfg_add_hostcfg _add_hostcfg_hlpr
}

dgridsys_cli_nodecfg() {
  hst1=$3
  param1=$3
  hst2=$4

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
    #echo
    nodecfg_getnodelist_full
    echo
    return
  fi

  if [ x$cmd == x"addthis" ]; then
    dbg_echo nodecfg_cli 3 "do addthis"
    shift 2
    dgridsys_nodecfg_addthis $*
    return
  fi

  if [ x$hst1 == x ]; then
    dgridsys_cli_help_nodecfg
    dgridsys_cli_help_cfgfiles
    #echo ".... module <name>"
    exit
  fi

  dbg_echo nodecfg_cli 4 "Before hostadd"


  if [ x$cmd == x"hostcfg-empty-add" ]; then
    shift 2
    dgridsys_cli_main distr hostcfg-empty-add $*
  fi
  if [ x$cmd == x"nodecfg-empty-add" ]; then
    shift 2
    dgridsys_cli_main distr nodecfg-empty-add $*
  fi

  if [ x$cmd == x"hostadd" ]; then
    dbg_echo nodecfg_cli 3 "do hostadd"

    if [ x$hst2 == x ]; then
      echo "nodecfg hostadd  <host name as ID,short> <hostname>"
      echo
      exit
    fi
    #nodecfg_add_hostcfg_cli1 $hst1 $hst2
    dgridsys_nodecfg_add_hostcfg $hst1 $hst2
    exit
  fi
}
