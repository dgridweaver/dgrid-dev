#!/bin/bash

if [ x$MODINFO_loaded_monitdg == "x" ]; then
  export MODINFO_loaded_monitdg="Y"
else
  return
fi

#MODINFO_dbg_monitdg=0
#MODINFO_enable_monitdg=

# load default config from module dir
source ${MODINFO_modpath_monitdg}/monitdg.defaultvalues

if [ -f ./dgrid-site/etc/monitdg.conf ]; then
  source ./dgrid-site/etc/monitdg.conf
fi

monitdg_print_module_info() {
  echo "monitdg: mod info, called monitdg_print_module_info"

}

monitdg_srv_is_registered_service() {
  echo monitdg
}

monitdg_status_string_service_monitdg() {
  echo -n monitdg_daemon:STATUS
}

monitdg_status_service_monitdg() {
  echo "--- monitdg_daemon:STATUS -- "
  echo
  ps ax | grep /monit | grep -v grep
  echo
}

monitdg_start_service_monitdg() {
  echo monitdg_daemon START
  #monitdg_run_monit start all
  monitdg_run_monit
}

monitdg_monit_command() {
  echo monitdg_daemon cmd
  monitdg_run_monit $*
}

monitdg_run_monit() {
  echo "monitdg_run_monit() pwd="$(pwd)
  local params=$*

  #export MODINFO_dbg_nodecfg=20
  cfgstack_cfg_thisnode "etc/monitdg.conf"
  #cfgstack_load_byid "etc/monitdg.conf" ${THIS_NODEID}
  #cfgstack_cfg trace UNKNOWN "/etc/monitdg.conf" $THIS_NODEID
  #export MODINFO_dbg_nodecfg=0

  local ourdir=$(nodecfg_nodeid_cfgdir $THIS_NODEID)
  local _nodecfgdir=$(nodecfg_nodeid_cfgdir $THIS_NODEID)
  local ourcfg_generated="${MONITZG_workdir}/monit-generated.conf"
  local ourcfg=${MONITZG_workdir}"/"$monitdg_config_name_use

  #$monit_cfg_use
  #local ourcfg=${ourdir}/monitdg-monit.d/xxxx.xxx
  #local ourcfg=${ourdir}/monitdg-monit.conf

  mkdir_ifnot_q ${MONITZG_workdir}

  chmod u+w ${ourcfg_generated}
  monitdg_output_monit_cfgfile >${ourcfg_generated}
  chmod 0700 ${ourcfg_generated}

  local logmy="$MONITZG_workdir/strace.log"

  local _run="$monitdg_bin_path -d $monit_daemon_seconds -c $ourcfg -p $MONITZG_workdir/monit.pid 
${monitdg_monit_opts} -s $MONITZG_workdir/monit.state $monitdg_monit_base_opts $params"
  echo ${_run}
  echo ----------------------------
  #strace -o $logmy ${_run}
  ${_run}
}

monitdg_stop_service_monitdg() {
  echo monitdg_daemon STOP
  monitdg_run_monit quit
}

monitdg_help_service_daemon_monitdg() {
  echo monitdg_daemon HELP
}

############

monitdg_output_monit_cfgfile() {
  local templ=${MODINFO_modpath_monitdg}/monit.conf.source
  local ev

  local _nodecfgdir=$(nodecfg_nodeid_cfgdir $THIS_NODEID)
  #MONITZG_rundir="${_nodecfgdir}/monitdg-monit.d/"
  MONITZG_cfgdir="$DGRIDBASEDIR/${_nodecfgdir}/etc/monitdg-monit.d/"
  MONITZG_email="xxxx@example.com"
  MONITZG_LOGFILE="${MONITZG_workdir}/monit.log"

  cat $templ | while read str; do
    ev="echo \"$str\""
    eval $ev
  done
}

############ cli integration  ################

monitdg_cli_help() {
  dgridsys_s; echo "monitdg cmd - send cmd to monit"
  #dgridsys_s; echo "monitdg CMDTWO - <xxx> <yyy> .... -"
}

monitdg_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo monitdg 5 x${maincmd} == x"monitdg"
  if [ x${maincmd} == x"monitdg" ]; then
    echo -n
  else
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    monitdg_cli_help
  fi

  if [ x${cmd} == x"cmd" ]; then
    echo -n
    shift 2
    monitdg_monit_command $*
  fi

  #if [ x${cmd} == x"CMDTWO"  ]; then
  #echo -n
  #monitdg_CMDTWO $*
  #fi

}
