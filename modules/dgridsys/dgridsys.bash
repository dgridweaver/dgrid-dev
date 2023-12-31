#!/bin/bash

if [ x$MODINFO_loaded_dgridsys == "x" ]; then
  export MODINFO_loaded_dgridsys="Y"
else
  return
fi

#export MODINFO_dbg_dgridsys=4

#DGRIDSYS_context=service|client|unknown

dgridsys_print_module_info() {
  echo "dgridsys: mod info"
}

dgridsys_activate_on_this_node() {
  cmd1=$HOME/bin/${DGRID_dgridname}-dgridsys
  if [ -f $cmd1 ]; then
    echo "ok, \$HOME/bin/${DGRID_dgridname}-dgridsys already installed"
  else
    set -x
    #$DGRID_dgridname
    mkdir_ifnot $HOME/bin/
    ln -s $DGRIDBASEDIR/dgrid-site/bin/${DGRID_dgridname}-dgridsys $HOME/bin/
    echo -n
    set +x
  fi

}

dgridsys_s() {
  echo -n "     "
}

source ${MODINFO_modpath_dgridsys}/module.inc.sh
source ${MODINFO_modpath_dgridsys}/nodecfg.inc.sh
source ${MODINFO_modpath_dgridsys}/cfgfiles.inc.sh
source ${MODINFO_modpath_dgridsys}/status.inc.sh
source ${MODINFO_modpath_dgridsys}/runtime.inc.sh

dgridsys_f() { # [API] [RECOMENDED]
  dgridsys_f_cleanenv $@
}

dgridsys_f_cleanenv() { # [API] [RECOMENDED]
  pushd $DGRIDBASEDIR >/dev/null
  #( set -o posix ; set ) #exit
  system_f_cleanenv ./dgrid/modules/dgridsys/dgridsys $@
  popd >/dev/null
}

dgridsys_cli_help_helpsys() {
  dgridsys_s
  echo "help <topic> - call help system on topic"
}

dgridsys_cli_help() {
  dgridsys_cli_help_helpsys
  dgridsys_cli_help_module
  dgridsys_cli_help_runtime
  dgridsys_cli_help_nodecfg
  dgridsys_cli_help_cfgfiles
  dgridsys_cli_help_status

  dgridsys_s
  echo "exec <cmd>  - execute shell cmd"
}

dgridsys_cli_main_help() {
  cli_name=$(basename $0)
  echo " "
  echo "Usage: $cli_name  <sub cmd name> .. <param1> ..."
  echo " "
}

dgridsys_cli_help_hook() {
  if command -v less; then
    (
      dgridsys_cli_main_help
      main_call_hook cli_help $*
    ) | less
  else
    dgridsys_cli_main_help
    main_call_hook cli_help $*
  fi
}

export dgridsys_cli_run_argv
dgridsys_cli_run_hook() {
  local var
  #dgridsys_cli_main_run
  export dgridsys_cli_run_argv="$*"
  var="$*"
  var=${var//(/\\\(}
  var=${var//)/\\\)}
  var=${var//;/\\\;}
  var=${var//\"/\\\"}
  var=${var//\'/\\\'}
  var=${var//\`/\\\`}
  dbg_echo dgridsys  3 F var=$var
  main_call_hook cli_run "$var"
}

dgridsys_cli_run() {
  local maincmd="$1"  cmd="$2"  name="$3"

  dbg_echo dgridsys 5 x${maincmd} == x"module"
  if [ x${maincmd} == x"module" ]; then
    dgridsys_cli_module $*
    return
  fi

  dbg_echo dgridsys 5 x${maincmd} == x"help"
  if [ x${maincmd} == x"help" ]; then
    dgridsys_cli_helpsys $*
    return
  fi

  if [ x${maincmd} == x"nodecfg" ]; then
    dgridsys_cli_nodecfg $*
    dgridsys_cli_cfgfiles $*
    return
  fi

  if [ x${maincmd} == x"status" ]; then
    dgridsys_cli_status $*
    return
  fi

  if [ x${maincmd} == x"runtime" ]; then
    dgridsys_cli_runtime $*
    return
  fi



  ###### misc ########

  if [ x${maincmd} == x"exec" ]; then
    shift 1
    eval $*
    return
  fi

}

dgridsys_cli_helpsys() {
  echo "helpsys stub"
}

dgridsys_cli_main() { # [API] [RECOMENDED]
  #echo "cli start"
  local cmd=$1
  local dgridsys_cli_main_cmd_found=0

  if [ x"$cmd" == x -o x"$cmd" == x"NONE" ]; then
    dgridsys_cli_help_hook $@
    echo ""
    exit
  fi
  dgridsys_cli_run_hook $@
  #echo "cmd \"$1\" not found"
}
