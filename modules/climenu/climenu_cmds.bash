#!/bin/bash

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

climenu_climenu_cmd_showvars_hst() {
  local snp_remoteid=$1
  hostcfg_hostid_load ${snp_remoteid} "showv_"
  (
    set -o posix
    set
  ) | grep showv_ | sed "s/showv_//g"
}
climenu_climenu_cmd_showvars_node() {
  #hostid
  local snp_remoteid=$1
  nodecfg_nodeid_load ${snp_remoteid} "showv_"
  (
    set -o posix
    set
  ) | grep showv_ | sed "s/showv_//g"
}
