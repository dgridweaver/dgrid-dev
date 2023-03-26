#!/bin/bash

climenu_CLIMENU_CMDS_LIST="remotelshome test_debug do clm_do clm_ping6 clm_host_t \
nodecmd_status showvars"

# some test climenu commands
climenu_climenu_cmd_remotelshome() {
  local dhostid=$1
  echo "Test function remotelshome(): dhostid=$1"
  run_hostcmd $dhostid "ls -a ~/"
}

climenu_climenu_cmd_climenu_test_debug() {
  climenu_climenu_cmd_clm_do $*
}

climenu_climenu_cmd_do() {
  climenu_climenu_cmd_clm_do $*
}
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
  host $hostn
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
    (
      set -o posix
      set
    ) | grep showv_ | sed "s/showv_//g"
    return 0
  fi
  if nodecfg_nodeid_exists $snp_remoteid; then
    nodecfg_nodeid_load ${snp_remoteid} "showv_"
    (
      set -o posix
      set
    ) | grep showv_ | sed "s/showv_//g"
    return 0
  fi
  distr_error "ERROR, its not nodeid or hostid"
}
#climenu_climenu_cmd_showvars_node() {
