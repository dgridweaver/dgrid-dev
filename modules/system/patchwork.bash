#!/bin/bash

# hacks & dirty stuff, stubs , etc.
# for needed when we dont have good api, or have it partial.
# But want to release new dgrid version.

system_alternative_vars() {
  echo a_cmd a_mod a_modtag a_defaultcmd a_function
}
system_alternative_provide_vars() {
  echo a_priority a_mod_provide a_cmd_provide
}

system_alternative() { # [API] [RECOMENDED]
  #local a_cmd=$1
  #local a_mod=$2
  #local a_modtag=$3
  #local a_defaultcmd=$4
  local tmp
  dbg_echo system 3 -n "system_alternative() : " 1>&2
  print_vars_str $(system_alternative_vars) | read tmp 1>&2
  dbg_echo system 3 $tmp 1>&2
  dbg_echo system 3 "" 1>&2

  if [ x$a_cmd == x ]; then
    echo "system_alternative() - params needed, a_cmd=\"\" exit" 1>&2
    exit
  fi

  local f="system_alternative_resolv_manual_$a_cmd"
  if is_function_exists $f; then
    eval $f
    return
  fi
  echo "main_call_hook _alternative_provide : " 1>&2

  alt=$(main_call_hook alternative_rewrite $alt)

  local alt=$(main_call_hook alternative_provide)
  echo $alt | while read -d ";" str; do
    echo str=$str 1>&2
  done 1>&2

}

system_alternative_resolv_manual_ssh() {

  if [ x$MODINFO_enable_sshzg == xY ]; then
    echo "sshzg_ssh"
  else
    echo "ssh"
  fi

}

#####################################################################

# functions for "remote call"

# call func
system_connect_if_not_this_host() {
  local nodeid=$1
  local func=$2
  shift 2
  local params=$*
  #set -x
  if [ x$THIS_NODEID == x$nodeid ]; then
    echo -n
    dbg_echo system 2 "ok, we are here. do nothing" 1>&2
    return 255
  #$func $params
  else
    if system_srvremote_if_allowed_function $func; then
      echo -n
    else
      echo "system_connect_if_not_this_host() : remote call of \"$func\" not allowed"
      return
    fi
    set +x

    if [ x$MODINFO_enable_run=xY ]; then
      echo "${FUNCNAME} :  dgridsys_cli_main run nodecmd $nodeid system system_srvremote_exec_function $func"
      dgridsys_cli_main run nodecmd $nodeid system system_srvremote_exec_function $func $params
      return 0

    else
      echo "${FUNCNAME}: ERROR, \"run\" module not enabled"
      return 255
    fi # if [ x$MODINFO_enable_run=xY ]; then

  fi

}

system_srvremote_function_allow() {
  main_call_hook srvremote_function_allowed
}

system_srvremote_if_allowed_function() { #
  local f=$1                             # function to call

  if [ x$f == x ]; then
    echo "system_srvremote_exec_function() function to call == \"\", abort " 1>&2
    exit
  fi
  local ok=0
  local funclist=$(system_srvremote_function_allow)
  dbg_echo system 2 "system_srvremote_exec_function() funclist=$funclist" 1>&2

  for testf in $funclist; do
    if [ $testf == $f ]; then
      #echo "000000000000000000000000000"
      return 0
    fi
  done
  return 255
}
system_srvremote_exec_function() { # exec func from "network"
  local f=$1                       # function to call

  if [ x$f == x ]; then
    echo "system_srvremote_exec_function() function to call == \"\", abort " 1>&2
    exit
  fi
  if system_srvremote_if_allowed_function $f; then
    #echo call
    $f
  fi
}

########################################

system_timestamp_dirname() {
  date +%Y%d-%H%M-%s
}


############ system_f_cleanenv  ##################

function system_clear_list_vars_pref {
  echo DGRID MODINFO MODULE cache $MODULE_list_enabled
}

system_clear_list_vars_item() {
  for i in ${ARRAY[0]}; do
    echo -n "unset $i ; "
  done
}

function system_clear_list_vars {
  for pref in $(system_clear_list_vars_pref); do
    ( set -o posix; set ) | grep -i ^$pref | split_iterate_stream system_clear_list_vars_item "="
  done
}

system_f_cleanenv_do() { #
  pushd $DGRIDBASEDIR >/dev/null
  local cmd="$1" bashcmd="bash -l"
  shift 1
  [ -z "$cmd" ] && distr_error "$cmd notfound" && exit

  # clear all dgrid variables
  eval $(system_clear_list_vars)
  #( set -o posix ; set ) #exit
  $bashcmd -c "$cmd $*"

  popd >/dev/null
}

system_f_cleanenv() { # [API] [RECOMENDED]
  pushd $DGRIDBASEDIR >/dev/null
  ./dgrid/modules/system/system-runcleanenv $*
  popd >/dev/null
}

#####################################





