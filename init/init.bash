#!/bin/bash

if [ x$MODINFO_loaded_init == "x" ]; then
  export MODINFO_loaded_init="Y"
else
  return
fi



#MODINFO_dbg_init=0
MODINFO_msg_init=2
#MODINFO_enable_init=

init_print_module_info() {
  echo "init: initialize this node"
}

############ cli integration  ################

init_cli_help() {
  dgridsys_s;  echo "init attach-mode-cmd - command excuted by \"attach\" module"
  dgridsys_s;  echo "init addthis - use addthis function to create nodecfg in tmp dir"
  dgridsys_s;  echo "init get-host-ids - get hostid,hostname,... "
}


init_attach_this_node_cli(){
  dbg_echo init 5 F "Start"
  msg_echo init 2 "---------- init this node --------------"
  INIT_get_host_ids_outdir="$INIT_remote_outgoing" init_get_host_ids_conf
  #distr_params_keyval_all INIT_
  dbg_echo init 5 F "end"
}


init_get_host_ids_cli() {
  dbg_echo init 5 F "Start"
  if [ -n "$INIT_get_host_ids_outdir" ]; then
    INIT_get_host_ids_outdir="./${DGRID_localdir}/attach/thisnode/cfg/"
  fi
  generic_listvars NODE_ 
  generic_listvars INIT_
  dbg_echo init 5 F "INIT_remote_outgoing=$INIT_get_host_ids_outdir"
  #need set here INIT_get_host_ids_outdir
  msg_echo init 1 "Output to INIT_get_host_ids_outdir=$INIT_get_host_ids_outdir"
  #generic_listvars DGRID
  init_get_host_ids_conf
  dbg_echo init 5 F "End"
}

init_get_host_ids_conf() {
  dbg_echo init 5 Start
  if [ -n "$INIT_get_host_ids_outdir" ]; then
    mkdir -p $INIT_get_host_ids_outdir
  else
    distr_error "ERROR! INIT_get_host_ids_outdir should be set"
    exit
  fi
  echo "" > "$INIT_get_host_ids_outdir/host_ids.conf"
  init_get_host_ids_stdout | tee -a "$INIT_get_host_ids_outdir/host_ids.conf"
}

init_get_host_ids_stdout()
{
  echo "HOST_hostid=\""`hostid`\"
  echo "HOST_hostname=\""`hostname`\"
  init_get_host_ids_nethw
}

init_get_host_ids_nethw()
{
  local n=0
  local cards=`ls -1 /sys/class/net/|grep ^enp` `ls -1 /sys/class/net/|grep ^eth`
  dbg_echo init 5 F cards=$cards
  for c in $cards; do
    echo "HOST_if${n}_name=$c" 
    echo -n "HOST_if${n}_mac=" 
    ifconfig $c| grep -o -E ..:..:..:..:..:..
    let n++
  done
}


init_addthis_cli() {
  echo "OUTPUT: ${DGRID_dir_nodelocal}/attach/thisnode/cfg/"
  echo "-------             "
  distr_nodecfg_addthis
}


init_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo init 5 x${maincmd} == x"init"
  if [ ! x${maincmd} == x"init" ]; then
    return
  fi

  if [ x${cmd} == x"" ]; then
    init_cli_help
  fi

  if [ x${cmd} == x"attach-this-node" ]; then
    shift 2
    init_attach_this_node_cli $*
    echo ""
  fi

  if [ x${cmd} == x"addthis" ]; then
    shift 2
    init_addthis_cli $*
    echo ""
  fi

  if [ x${cmd} == x"get-host-ids" ]; then
    shift 2
    init_get_host_ids_cli $*
    echo ""
  fi

}
