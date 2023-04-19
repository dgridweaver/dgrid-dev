#!/bin/bash

climenu_CLIMENU_CMDS_LIST="remotelshome remotelsproc remoteids update_climenu \
 clm_do clm_ping6 clm_host_t nodecmd_status showvars"
# test_debug

# some test climenu commands
climenu_climenu_cmd_remotelshome() {
  local dhostid=$1
  echo "Test function remotelshome(): dst hostid=$1"
  run_hostcmd $dhostid "ls -a ~/"
}
climenu_climenu_cmd_remotelsproc() {
  local dhostid=$1
  echo "Test function remotelsproc(): dst hostid=$1"
  run_hostcmd $dhostid "ls /proc"
}
climenu_climenu_cmd_remoteids() {
  local dhostid=$1
  echo "Test function remoteids(): dst hostid=$1"
  run_hostcmd $dhostid "id"
}

climenu_climenu_cmd_update_climenu() {
  local dhostid=$1 tIFS i aaa op
  msg_echo climenu 2 "Update climenu dir"
  echo DGRIDLIB_thisclidir=$DGRIDLIB_thisclidir
  local dst=$DGRIDLIB_thisclidir
  tIFS="$IFS" ; IFS=$'\n'
  #climenu_list_op
  #climenu_list_op_cli
  #delim=":" climenu_list
  #exit
  [ -d ${dst} ] && mkdir -p ${dst}/newmenus/
  for i in $(delim=":" climenu_list ); do
    IFS="$tIFS"
    op=$( generic_cut_param ":" 1 ${i} )
    op=${op//_/-}
    #echo "op=$op"
    if [ ! -f $dst/$op ]; then
      echo "Not found $op, update to \${dst}/newmenus/"
      cp ${MODINFO_modpath_climenu}/templates/do ${dst}/newmenus/$op
    fi
  done

}


climenu_climenu_cmd_climenu_test_debug() { climenu_climenu_cmd_clm_do $*; }
climenu_climenu_cmd_do() { climenu_climenu_cmd_clm_do $*;}

climenu_climenu_cmd_clm_do() {
  echo "climenu_climenu_cmd_clm_do()"
  echo "\$*=\"$*\""
}

# test ping commands
climenu_climenu_cmd_clm_ping6() {
  local hostn=$1
  ping6 $hostn
}
climenu_climenu_cmd_clm_ping() {
  local hostn=$1
  ping $hostn
}

climenu_climenu_cmd_clm_host_t() {
  local hostn=$1
  if hostcfg_hostid_exists $hostn; then
    hostcfg_hostid_load ${hostn} "mm_"
    generic_listvars "mm_"
    [ -n "$mm_CONNECT_dnsname" ] && echo "host -t ANY $mm_CONNECT_dnsname" && host -a $mm_CONNECT_dnsname
    [ -n "$mm_HOST_dnsname" ]&& echo "host -t ANY $mm_HOST_dnsname" && host -a $mm_HOST_dnsname
    #host -t ANY $hostn
  fi
}

# remote node cmds (dgridsys xxx yyy)
climenu_climenu_cmd_nodecmd_status() {
  local nodeid=$1
  run_nodecmd $nodeid status
}

################

climenu_climenu_cmd_showvars() {
  local snp_remoteid=$1
  if hostcfg_hostid_exists $snp_remoteid; then
    hostcfg_hostid_load ${snp_remoteid} "showv_"
    generic_listvars showv_ | sed "s/showv_//g"
    return 0
  fi
  if nodecfg_nodeid_exists $snp_remoteid; then
    nodecfg_nodeid_load ${snp_remoteid} "showv_"
    generic_listvars showv_ | sed "s/showv_//g"
    return 0
  fi
  distr_error "ERROR, its not nodeid or hostid"
}
#climenu_climenu_cmd_showvars_node() {
