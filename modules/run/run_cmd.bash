#!/bin/bash

#
# run command (snippet) in different enviroment, including remote
#

#function _n_get_profile { echo $1|cut -d/ -f2; }
#function _n_get_nodeid  { echo $1|cut -d/ -f1; }
function _n_get_profile { generic_cut_param "/" 2 "$1"; }
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
  run_rmt_snippet "nodecmd" snp_remoteid="${rmtid}" snp_connect_profile="${c_p}"
}

run_nodecmdshell() { # [API] INTERFACE
  local rmtid cmd params r_cmd

  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi

  local rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  if [ x$rmtid == x$c_p ]; then
    unset c_p
  fi

  shift 1
  dbg_echo run 5 F snp_connect_profile=$c_p
  export __snippet_params="$*"
  run_rmt_snippet "nodecmdshell" snp_remoteid="${rmtid}" snp_connect_profile="${c_p}"
}

#
run_hostcmd() { # [API] INTERFACE
  local cmd params r_cmd
  local snp_rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  shift 1

  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
    exit
  fi

  if [ x$snp_rmtid == x$c_p ]; then
    unset c_p
  fi

  export __snippet_params="$*"
  run_rmt_snippet "hostcmd" snp_remoteid="$snp_rmtid" snp_connect_profile="${c_p}"
}


run_showconfig() { # [API] INTERFACE
  local cmd params r_cmd
  local snp_rmtid=$(_n_get_nodeid $1)
  local c_p=$(_n_get_profile $1)
  dbg_echo run 5 F "Start snp_rmtid=$snp_rmtid c_p=$c_p"

  if [ "x$*" == "x" ]; then
    echo "run: need parameters"
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


###################################
run_rmt_snippet() {
  # snippet types:
  # bashfunc, nodecmd , nodecmdshell, hostcmd, showconfig

  local nodeid cmd params r_cmd
  local snp_connect_profile="" snp_nodeid=""
  local snp_type=$1
  shift 1
  if [ "x$snp_type" == "x" ]; then
    echo "snippet type (snp_type) not set, abort"
    exit
  fi

  # local func params
  dbg_echo run 5 F eval=\"$*\"
  eval "$*"

  dbg_echo run 5 F snp_remoteid=$snp_remoteid
  #dbg_echo run 5 F snp_nodeid=$snp_nodeid
  dbg_echo run 5 F snp_type=$snp_type
  dbg_echo run 5 F __snippet_params=\"${__snippet_params}\"
  dbg_echo run 5 F snp_connect_profile=$snp_connect_profile
  dbg_echo run 5 F "this=$THIS_NODEID"

  pushd $DGRIDBASEDIR >/dev/null

  nodecfg_nodeid_load $THIS_NODEID "this_"

  if nodecfg_nodeid_exists "$snp_remoteid"; then
    dbg_echo run 5 F "nodeid \"$snp_remoteid\" found"
    dbg_echo run 5 F "Load nodeid ($snp_remoteid) configs"
    nodecfg_nodeid_load $snp_remoteid "rmt_"
    if [ "x$?" == "x0" ]; then
      echo -n
    else
      echo "abort on nodecfg_nodeid_load  ret=$?"
      exit
    fi
  else
    dbg_echo run 4 F "Node not exists"
    if hostcfg_hostid_exists "$snp_remoteid"; then
      dbg_echo run 5 F "NO NODE MODE, hostid exists, load hostid"
      hostcfg_hostid_load ${snp_remoteid} "rmt_"
    else
      echo "no nodeid or hostid, abort"
      exit
    fi
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

  if [ ! -z "$CONNECT_type_override" ]; then
    export CONNECT_type=$CONNECT_type_override
    dbg_echo run 4 "F OVERRIDE CONNECT_type_override, CONNECT_type=$CONNECT_type"
  fi
  dbg_echo run 4 CONNECT_type=$CONNECT_type

  export CONNECT_wdir=${rmt_NODE_INSTPATH}
  export CONNECT_dnsname=$(generic_var_content_priority CONNECT_dnsname rmt_CONNECT_dnsname)

  export CONNECT_sshport=$(generic_var_content_priority CONNECT_sshport rmt_NODE_sshport rmt_CONNECT_sshport rmt_HOST_sshport)
  export CONNECT_sshopts="$CONNECT_sshopts $rmt_NODE_sshopts \
$rmt_CONNECT_sshopts $rmt_HOST_sshopts"
  dbg_generic_listvars run 4 "CONNECT" 1>&2

  local connlst=$(main_call_hook rmt_snippet_do_api LIST)
  dbg_echo run 4 "F CONNECT_type=$CONNECT_type snp_type=$snp_type, avaliable \"$connlst\"" 1>&2

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
    r_cmd=$dgridsyscmd
  fi

  pushd $DGRIDBASEDIR >/dev/null
  #generic_listvars "CONNECT" 1>&2
  dbg_echo run 2 "(cd $CONNECT_wdir ; env -i HOME=$HOME \
  LC_CTYPE=${LC_ALL:-${LC_CTYPE:-$LANG}} PATH=$PATH USER=$USER \
  $RUN_bash -l -c \"$r_cmd ${params}\" )"

  if [ ! x$DRY_RUN = "xY" ]; then
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
  eval $*
  local _hostid=$snp_hostid
  local params=${__snippet_params}
  dbg_echo run 2 "F _hostid=${_hostid} params=$*"

  dbg_echo run 2 "F _hostid=${_hostid} ================ begin"
  dbg_generic_listvars run 2 "snp_" 1>&2
  dbg_generic_listvars run 2 "CONNECT" 1>&2
  dbg_echo run 2 "F ================ end"

  if [ x$CONNECT_dnsname == "x" ]; then
    echo "ERROR: run_hostcmd(): x\$oth_CONNECT_dnsname == \"x\" , no remote hostname, abort" 1>&2
    exit
  fi

  if [ x$snp_type == xnodecmd ]; then
    r_cmd=$dgridsyscmd
  fi

  #export do_CONNECT_sshopts="$oth_CONNECT_sshopts $oth_HOST_sshopts"
  #CONNECT_sshopts=`generic_var_content_priority CONNECT_sshopts do_CONNECT_sshopts`

  if [ -n "$CONNECT_sshport" ]; then
    CONNECT_sshopts="$CONNECT_sshopts -p $CONNECT_sshport "
  fi

  if [ -n "$CONNECT_user" ]; then
    CONNECT_sshopts="$CONNECT_sshopts -l $CONNECT_user "
  fi

  CONNECT_sshopts=$(generic_trim "$CONNECT_sshopts")

  code="$RUN_SSH_CMD $RUN_SSH_OPTS $CONNECT_sshopts $CONNECT_dnsname $params"

  dbg_echo run 6 "---------------- pre run ---------------------"
  dbg_generic_listvars run 2 "CONNECT"
  dbg_echo run 6 "code=\"$code\"" 1>&2
  if [ "x$DRY_RUN" = "xY" ]; then
    echo "DRY_RUN: $code"
  else
    echo -n
    dbg_echo run 2 "no_DRY_RUN: $code"
    $code
  fi

}
