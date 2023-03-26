#!/bin/bash

#
# run command (snippet) in different enviroment, including remote
#

function _n_get_profile { if [[ "$1" == */* ]]; then generic_cut_param "/" 2 "$1"; fi ;}
function _n_get_nodeid { generic_cut_param "/" 1 "$1"; }

run_nodecmd() { # [API] INTERFACE
  if [ "x$*" == "x" ]; then
    echo "run_nodecmd: need parameters"
    exit
  fi

  local p
  local rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  if [ x$rmtid == x$c_p ]; then
    unset c_p
  fi

  shift 1
  local params=$*
  export __snippet_params="$*"
  run_rmt_snippet "nodecmd" snp_remoteid="${rmtid}" snp_connect_profile="${c_p}" snp_params="$params"
}

run_nodecmdshell() { # [API] INTERFACE
  local rmtid cmd params r_cmd

  if [ "x$*" == "x" ]; then
    echo "run_nodecmdshell: need parameters"
    exit
  fi
  local rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  shift 1
  
  dbg_echo run 5 F snp_connect_profile=$c_p
  export __snippet_params="$*"
  run_rmt_snippet "nodecmdshell" snp_remoteid="${rmtid}" snp_connect_profile="${c_p}"
}

#
run_hostcmd_cli() { 
  run_hostcmd $*
}
run_hostcmd() { # [API] INTERFACE
  dbg_echo run 5 F "start, \$* = $*"
  if [ "x$*" == "x" ]; then
    echo "run_hostcmd: need parameters"
    exit
  fi

  local cmd params r_cmd
  local snp_rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  shift 1

  export __snippet_params="$*"
  snp_params="${__snippet_params}" run_rmt_snippet "hostcmd" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"
}

run_shell_cli(){
  dbg_echo run 5 F "start, \$* = $*"
  if [ "x$*" == "x" ]; then
    echo "run_hostcmd: need parameters"
    exit
  fi
  local snp_rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)

  CONNECT_exec_override="cli"
  snp_params="" run_rmt_snippet "hostcmd" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"
}

run_showconfig() { # [API] INTERFACE
  local cmd params r_cmd
  local snp_rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  dbg_echo run 5 F "Start snp_rmtid=$snp_rmtid c_p=$c_p"

  if [ "x$*" == "x" ]; then
    echo "run_showconfig: need parameters"
    exit
  fi
  shift 1
  # insert other params parsing

  if [ x$snp_rmtid == x$c_p ]; then
    unset c_p
  fi

  export __snippet_params="$*"
  dbg_echo run 5 F "Run snippet:" "showconfig" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"
  run_rmt_snippet "showconfig" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"
}


connect_config() { # [API] #usage: connect_config [entityid] pref="local "
  run_connect_config $@
}
run_connect_config() { # [API] #usage run_connect_config [entityid] pref="local "
  local snp_rmtid=$(_n_get_nodeid $1)
  local rmtid=$(_n_get_nodeid $1)
  #local out=$()
  shift 1
  eval "local $*"
  #RUN_DRY_RUN=Y run_rmt_snippet "hostcmd" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"|\
  run_rmt_snippet "showconfig" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"|\
    while read str; do
      #if [[ "$str" =~ "^DRY" ]]; then echo "#111"; continue; fi
      #if [[ "$str" =~ "^----" ]]; then echo "#111"; continue; fi
      echo "${pref} ${str}"
    done
  return 0
}





###################################
run_rmt_snippet() {
  # snippet types:
  # bashfunc, nodecmd , nodecmdshell, hostcmd, showconfig

  local nodeid cmd params r_cmd
  local snp_connect_profile="" snp_nodeid=""
  local snp_type=$1
  local snp_remoteid_type=""
  shift 1
  if [ "x$snp_type" == "x" ]; then
    echo "snippet type (snp_type) not set, abort"
    exit
  fi
  dbg_echo run 5 F Start
  dbg_generic_listvars run 5 "CONNECT" 1>&2

  # local func params
  dbg_echo run 5 F eval=\"$*\"

  #exit
  eval "$*"

  dbg_echo run 5 F snp_remoteid=$snp_remoteid
  #dbg_echo run 5 F snp_nodeid=$snp_nodeid
  dbg_echo run 5 F snp_type=$snp_type
  dbg_echo run 5 F __snippet_params=\"${__snippet_params}\"
  dbg_echo run 5 F snp_connect_profile=$snp_connect_profile
  dbg_echo run 5 F "this=$THIS_NODEID"

  pushd $DGRIDBASEDIR >/dev/null

  nodecfg_nodeid_load $THIS_NODEID "this_"

  local check_eid=0
  dbg_echo run 5 F "check snp_type=$snp_type"
  if [ x$snp_type == x"showconfig" -o x$snp_type == x"hostcmd" ]; then
    if hostcfg_hostid_exists "$snp_remoteid"; then
      #dbg_echo run 5 F "NO NODE MODE, hostid exists, load hostid"
      dbg_echo run 5 F "hostid exists, load hostid"
      hostcfg_hostid_load ${snp_remoteid} "rmt_"
      check_eid=1
      snp_remoteid_type="hostid"
    fi
  fi
  if generic_word_in_list $snp_type bashfunc hostcmd nodecmd nodecmdshell showconfig; then
    dbg_echo run 5 F "do check nodeid snp_type=$snp_type"
    if nodecfg_nodeid_exists "$snp_remoteid"; then
      dbg_echo run 5 F "nodeid \"$snp_remoteid\" found"
      dbg_echo run 5 F "Load nodeid ($snp_remoteid) configs"
      nodecfg_nodeid_load $snp_remoteid "rmt_"
      if [ -n $rmt_NODE_HOST ]; then
        dbg_echo run 5 F "Load hostid ($rmt_NODE_HOST) configs for nodeid $snp_remoteid"
        hostcfg_hostid_load ${rmt_NODE_HOST} "rmt_"
        check_eid=1
        snp_remoteid_type="nodeid"
      fi
    fi
  fi

  dbg_echo run 4 check_eid=$check_eid
  if [ x$check_eid == x"0" ]; then
    distr_error "ABORT: no nodeid for nodemds or hostid for host* cmds"
    exit
  fi

  if [ x"$snp_remoteid_type" == x"nodeid" ]; then
    export CONNECT_remoteid="${rmt_NODE_ID}"
  fi

  if [ x"$snp_remoteid_type" == x"hostid" ]; then
    export CONNECT_remoteid="${rmt_HOST_id}"
  fi


  dbg_echo run 4 this_NODE_INSTPATH=$this_NODE_INSTPATH

  # load connect profile default settings
  source ${MODINFO_modpath_run}/connect.conf
  if [ -z "$CONNECT_type" ]; then
    echo "ERROR: CONNECT_type not set so module config file not loaded, abort"
    exit
  fi

  # load connect profile
  dbg_echo run 4 F "Always load etc/connect.conf"
  cfgstack_load_byid etc/connect.conf $snp_remoteid
  if [ ! x${snp_connect_profile} == "x" ]; then
    dbg_echo run 4 F "Try load etc/connect_${snp_connect_profile}.conf"
    cfgstack_load_byid etc/connect_${snp_connect_profile}.conf $snp_remoteid
  else
    dbg_echo run 6 F "No profile set"
  fi

  dbg_echo run 4 F Configured CONNECT_type=$CONNECT_type
  #generic_listvars CONNECT_
  #generic_listvars rmt_


  ################## "optimize" CONNECT_type  ######################

  if [ "$rmt_NODE_HOST" == "$this_NODE_HOST" ]; then
    if [ "$rmt_NODE_USER" == "$this_NODE_USER" ]; then
      dbg_echo run 2 "hosts equiv, user eqiv, set CONNECT_type=local"
      CONNECT_type="local"
    else
      dbg_echo run 2 "hosts equiv, user NOT equiv, leave CONNECT_type"
    fi
  fi

  ##############################################################
  if [ x == x$rmt_NODE_USER ]; then
    echo -n
    export CONNECT_user=${rmt_NODE_USER}
  fi
  ############################################

  if [ -n "$CONNECT_exec_override" ]; then
    export CONNECT_exec=$CONNECT_exec_override
  fi
  if [ -n "$CONNECT_type_override" ]; then
    export CONNECT_type=$CONNECT_type_override
    dbg_echo run 4 "F OVERRIDE CONNECT_type_override, CONNECT_type=$CONNECT_type"
  fi
  dbg_echo run 4 CONNECT_type=$CONNECT_type

  export CONNECT_env_wdir=$CONNECT_wdir
  export CONNECT_wdir=$(generic_var_content_priority CONNECT_wdir rmt_NODE_INSTPATH)
  export CONNECT_dnsname=$(generic_var_content_priority CONNECT_dnsname rmt_CONNECT_dnsname)

  export CONNECT_sshport=$(generic_var_content_priority CONNECT_sshport rmt_NODE_sshport rmt_CONNECT_sshport rmt_HOST_sshport)
  export CONNECT_sshopts="$CONNECT_sshopts $rmt_NODE_sshopts \
$rmt_CONNECT_sshopts $rmt_HOST_sshopts"

  if [ -n "$CONNECT_sshport" ]; then
    #CONNECT_sshopts2="$CONNECT_sshopts2 -p $CONNECT_sshport "
    CONNECT_sshopts2="$CONNECT_sshopts2 -o Port=$CONNECT_sshport "
  fi

  if [ ! -n "$CONNECT_ssh_keydir" ]; then
    export CONNECT_ssh_keydir="$HOME/.ssh"
  fi

  if [ -n "$CONNECT_user" ]; then
    CONNECT_sshopts2="$CONNECT_sshopts2 -l $CONNECT_user "
  fi
  CONNECT_sshopts2="$CONNECT_sshopts2 -o hostname=$CONNECT_dnsname "
  CONNECT_sshopts2="$CONNECT_sshopts2 -o HostKeyAlias=$CONNECT_remoteid "
  CONNECT_sshopts2=$(generic_trim "$CONNECT_sshopts2")

  dbg_generic_listvars run 4 "CONNECT" 1>&2

  local connlst=$(main_call_hook rmt_snippet_do_api LIST)
  dbg_echo run 4 "F CONNECT_type=$CONNECT_type snp_remoteid_type=$snp_remoteid_type snp_type=$snp_type, avaliable \"$connlst\"" 1>&2

  # hook to select and run snippet with parameters defined in this function
  main_call_hook rmt_snippet_do_api $snp_type
}

run_rmt_snippet_do_api() {
  local snp_type=$1

  dbg_echo run 6 "F : start run module hook"

  #
  if [ x$snp_type == xLIST ]; then
    echo "std_ssh std_local"
  fi

  if [ x$snp_type == xshowconfig ]; then
      generic_listvars CONNECT_
      return 0
  fi

  if [ x$snp_type == xnodecmdshell -o x$snp_type == xnodecmd ]; then
    if [ "x$rmt_NODE_ID" == "x" ]; then
      echo "ERROR: rmt_NODE_ID not set for snp_type=$snp_type"
      return 1
      #exit
    fi
  fi

  # std_local snipped detection and call
  if [ x$snp_type == xnodecmdshell -o x$snp_type == xnodecmd ]; then
    if [ x$CONNECT_type == "xlocal" ]; then
      # std_local
      dbg_echo run 6 "F : select std_local : func run_rmt_snippet_do_std_local "
      run_rmt_snippet_do_std_local $*
      return 0
    fi
  fi

  # std_ssh use detection and call
  if [ x$snp_type == xnodecmdshell -o x$snp_type == xnodecmd -o x$snp_type == xhostcmd ]; then
    if [ x$CONNECT_type == "xssh" ]; then
      dbg_echo run 6 "F : func run_rmt_snippet_do_std_ssh "
      run_rmt_snippet_do_std_ssh $*
      return 0
    fi
  fi
  dbg_echo run 6 "F : end"
}

run_rmt_snippet_do_std_local() {
  local vars var1
  local snp_type=$1
  dbg_echo run 6 "F : begin"
  shift 1
  eval $*

  dbg_generic_listvars run 2 "CONNECT_" 1>&2
  dbg_generic_listvars run 2 "snp_" 1>&2

  local nodeid=$snp_nodeid
  local params=${__snippet_params}

  local r_cmd

  dbg_generic_listvars run 2 "CONNECT_" 1>&2
  dbg_generic_listvars run 2 "snp_" 1>&2

  #if [ x$snp_type == xnodecmdshell -o x$snp_type == xnodecmd  ]; then
  if [ x$snp_type == xnodecmd ]; then
    r_cmd=$RUN_dgridsyscmd
  fi

  pushd $DGRIDBASEDIR >/dev/null
  #generic_listvars "CONNECT" 1>&2
  dbg_echo run 2 "(cd $CONNECT_wdir ; env -i HOME=$HOME \
  LC_CTYPE=${LC_ALL:-${LC_CTYPE:-$LANG}} PATH=$PATH USER=$USER \
  $RUN_bash -l -c \"$r_cmd ${params}\" )"

  if [ ! x$RUN_DRY_RUN = "xY" ]; then
    echo -n
    #set -x
    (
      cd $CONNECT_wdir
      env -i HOME=$HOME \
        LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
        $RUN_bash -l -c "$r_cmd ${params}"
    )
  #set +x
  else
    echo "DRY_RUN: " "(cd $CONNECT_wdir ; env -i HOME=$HOME \
  LC_CTYPE=${LC_ALL:-${LC_CTYPE:-$LANG}} PATH=$PATH USER=$USER \
  $RUN_bash -l -c \"$r_cmd ${params}\" )"
  fi
  popd >/dev/null
}

run_rmt_snippet_do_std_ssh() {
  local vars var1 r_cmd
  local snp_type=$1
  shift 1
  eval "local $*"
  local _remoteid=$snp_remoteid
  local params=${snp_params}
  dbg_echo run 2 "F _remoteid=${_remoteid} \$*=$* ================ begin"
  dbg_generic_listvars run 2 "snp_" 1>&2
  dbg_generic_listvars run 2 "CONNECT" 1>&2
  dbg_echo run 2 "F ================ end"
  #local CONNECT_remoteid="${_remoteid}"

  if [ x$CONNECT_dnsname == "x" ]; then
    echo "ERROR: run_hostcmd(): x\$oth_CONNECT_dnsname == \"x\" , no remote hostname, abort" 1>&2
    exit
  fi

  if [ x$snp_type == xnodecmd ]; then
    r_cmd=$RUN_dgridsyscmd
  fi

  # definw $code - ssh run variable
  local code="$RUN_SSH_CMD $RUN_SSH_OPTS $CONNECT_sshopts $CONNECT_sshopts2 $CONNECT_remoteid"
  local RUN_stdin_cmd
  
  if [ x$snp_type == xnodecmd -o x$snp_type == xnodeshellcmd ]; then
    RUN_stdin_cmd="(cd $CONNECT_wdir;$RUN_stdin_sh)"
  fi
  dbg_echo run 8 F "snp_remoteid_type=$snp_remoteid_type"

  # if CONNECT_wdir was pre set
  dbg_echo run 8 F "CONNECT_env_wdir=$CONNECT_env_wdir"
  if [ -n "$CONNECT_env_wdir" ]; then
    dbg_echo run 8 F "use CONNECT_env_wdir in RUN_stdin_cmd"
    RUN_stdin_cmd="(cd $CONNECT_env_wdir;$RUN_stdin_sh)"
  fi

  dbg_echo run 8 F RUN_stdin_cmd=$RUN_stdin_cmd
  if [ ! -n "$RUN_stdin_cmd" ]; then
    RUN_stdin_cmd="$RUN_stdin_sh"
  fi  
  
  # code2 - what we are actually run
  code2="$r_cmd $params"



  dbg_echo run 6 "---------------- pre run ---------------------"
  dbg_generic_listvars run 2 "CONNECT"
  dbg_echo run 6 "code=\"$code $code2\"" 1>&2
  if [ "x$RUN_DRY_RUN" = "xY" ]; then
    if [ "x$CONNECT_exec" = x"cli" ]; then
      echo "DRY_RUN(cli): $code $code2"
    fi
    if [ "x$CONNECT_exec" = x"stdin" ]; then
      echo "DRY_RUN(stdin): echo \"$code2\" | $code $RUN_stdin_cmd"
    fi
  else
    if [ "x$CONNECT_exec" = x"cli" ]; then
      dbg_echo run 2 "no_DRY_RUN: $code $code2"
      $code $code2
    fi
    if [ "x$CONNECT_exec" = x"stdin" ]; then
      dbg_echo run 2 "no_DRY_RUN: echo \"$code2\" \| $code $RUN_stdin_cmd"
      echo $code2 | $code "$RUN_stdin_cmd"
    fi
  fi

}
