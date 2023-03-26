#!/bin/bash

if [ x$MODINFO_loaded_sshenv == "x" ]; then
  export MODINFO_loaded_sshenv="Y"
else
  return
fi

source ${MODINFO_modpath_sshenv}/sshenv.conf

#if [ x$DCMD_ID_ssh_copy_id == "x" ]; then
#  DCMD_ID_ssh_copy_id="ssh-copy-id"
#fi
sshenv_CLIMENU_CMDS_LIST="sshenv-install-id"

#MODINFO_dbg_sshenv=0
#MODINFO_enable_sshenv=

sshenv_print_module_info() {
  echo "--- sshenv : ssh wrapper for dgrid , proxy connections, etc"
  echo "   sess=$DGRID_dir_dotlocal/sshenv/sess/"
  echo "   run=$DGRID_dir_dotlocal/sshenv/run/"
}

#sshenv_status()

sshenv_activate_on_this_node() {
  #if []
  #mkdir -p $DGRID_dir_dotlocal/sshenv/sess/
  mkdir_ifnot $DGRID_dir_dotlocal/sshenv/sess/
  mkdir_ifnot $DGRID_dir_dotlocal/sshenv/run/
}

sshenv_ssh_config() {

  CFG1="./dgrid-site/sshenv/config"
  CFG2="$nodedir/sshenv/config"
  CFG3="$DGRID_dir_dotlocal/sshenv/config"
  #set +x
  dbg_echo sshenv 3 "CFG1=${CFG1}" 1>&2
  dbg_echo sshenv 3 "CFG2=$CFG2" 1>&2
  dbg_echo sshenv 3 "CFG3=$CFG3" 1>&2

  if [ -f $CFG1 ]; then
    CFG=$CFG1
  fi
  if [ -f $CFG2 ]; then
    CFG=$CFG2
  fi
  if [ -f $CFG3 ]; then
    CFG=$CFG3
  fi

  echo $CFG
}

sshenv_envelop_cmd() {
  local cmd_opts opt_CFG=

  if [ "x$ssh_package_cmd" == x ]; then
    dbg_echo sshenv 1 "sshenv_cmd() : exit, ssh_package_cmd env must be set" 1>&2
    exit
  fi

  if [ x$ssh_package_cmd == x"ssh" ]; then
    cmd_opts="-A"
  else
    cmd_opts=""
  fi

  local CFG=$(sshenv_ssh_config)
  dbg_echo sshenv 1 CFG=$CFG
  if [ x$CFG == "x" ]; then
    local opt_CFG=""
  else
    local opt_CFG="-F $CFG"
  fi
  dbg_echo sshenv 1 "$ssh_package_cmd $cmd_opts $opt_CFG  $*" 1>&2
  #echo "$ssh_package_cmd -F $CFG $*" 1>&2
  $ssh_package_cmd $cmd_opts $opt_CFG $*
}

sshenv_envelop_script() {
  #ssh_package_cmd
  if [ "x$ssh_package_cmd" == x ]; then
    dbg_echo sshenv 1 "sshenv_cmd() : exit, ssh_package_cmd env must be set" 1>&2
    exit
  fi

  local CFG=$(sshenv_ssh_config)
  dbg_echo sshenv 1 CFG=$CFG
  dbg_echo sshenv 1 "$ssh_package_cmd -F $CFG $*"

  alias ssh="sshenv_ssh"

  p=$(which $ssh_package_cmd)
  dbg_echo sshenv 1 "which $ssh_package_cmd  == $p"
  source $p $*
}

sshenv_ssh() {
  ssh_package_cmd="ssh" sshenv_envelop_cmd $*
}

sshenv_scp() {
  ssh_package_cmd="scp" sshenv_envelop_cmd $*
}

sshenv_ssh_copy_id() {
  ssh_package_cmd="ssh-copy-id" sshenv_envelop_script $*
}


sshenv_install_id_cli() {
  #echo "p=$*"
  if [ ! -n "$1" ]; then
     distr_error "ERROR, exit."
     distr_error_echo "sshenv_install_id_cli need parameter"
     exit
  fi
  #exit
  if run_is_not_entityid $1 > /dev/null; then
    distr_error "ERROR, cannot load connection (no entityid possible)"
    exit
  fi
  local eid=$1
  
  local paramslist="use_pubkey"
  shift 1
  local parsed=$(pref="" keys="$paramslist" distr_params_keyval_all $*)
  eval "$parsed" # load params
  unset parsed paramslist
  
  eval local `run_connect_config $eid`;

  if [ x$use_pubkey == x"yes" ]; then
    dbg_echo sshenv 2 "use_pubkey=yes, use deafult PubkeyAuthentication"
    CONNECT_sshopts2="$CONNECT_sshopts2 -o PubkeyAuthentication=yes "
  fi
  if [ x$use_pubkey == x"no" -o x$use_pubkey == "x" ]; then
    dbg_echo sshenv 2 "use_pubkey=no, use deafult PubkeyAuthentication"
    CONNECT_sshopts2="$CONNECT_sshopts2 -o PubkeyAuthentication=no "
  fi


  dbg_generic_listvars sshenv 2 "CONNECT_" 1>&2  #dbg_generic_listvars sshenv 2 "RUN_" 1>&2
  #$SSHENV_SSH_CMD  $CONNECT_remoteid
  local ssh_opts=" $SSHENV_SSH_OPTS $CONNECT_sshopts $CONNECT_sshopts2"
  if [ -n "$CONNECT_ssh_keyfile" ]; then
    local i_opt="-i $CONNECT_ssh_keydir/$CONNECT_ssh_keyfile"
    #export ="$HOME/.ssh"
  fi
  #dcmd ssh-copy-id $ssh_opts -i aaa
  dbg_echo sshenv 2 ssh-copy-id $ssh_opts ${i_opt} $CONNECT_remoteid
  ssh-copy-id $ssh_opts ${i_opt} $CONNECT_remoteid
  #echo $code
}

sshenv_climenu_cmd_sshenv_install_id()
{
  sshenv_install_id_cli $@
}


########################

sshenv_launch_proxy_nodeid() {
  echo -n

}

sshenv_ls_proxy() {
  echo "$DGRID_dir_dotlocal/sshenv/sess/"
  ls -1 $DGRID_dir_dotlocal/sshenv/sess/
}

sshenv_launch_proxy() {
  local host_entry=$1

  if [ x$host_entry == x ]; then
    echo "sshenv_launch_proxy() hostname needed"
    exit
  fi
  #ssh
  #sshenv_ssh -fMN -v $host_entry
  mkdir_ifnot $DGRID_dir_dotlocal/sshenv/sess/
  echo "sshenv_ssh -A -fMN $host_entry"
  sshenv_ssh -A -fMN $host_entry
  mkdir_ifnot $DGRID_dir_dotlocal/sshenv/run/
  set -x
  echo $! >$DGRID_dir_dotlocal/sshenv/run/${host_entry}.pid
  set +x
}

############ cli integration  ################

sshenv_cli_help() {
  dgridsys_s;echo "sshenv ssh - <xxx> <yyy> .... -"
  dgridsys_s;echo "sshenv install-id - install ssh id using default settings for nodeid/hostid"
  dgridsys_s;echo "sshenv login|startsshproxy - <xxx> <yyy> .... -"
  dgridsys_s;echo "sshenv list|listsshproxy"
  dgridsys_s;echo "sshenv scp [params...] - wrapped scp"
  dgridsys_s;echo "sshenv ssh-copy-id [params...] - wrapped ssh-copy-id"
}

sshenv_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo sshenv 5 x${maincmd} == x"sshenv"
  if [ x${maincmd} == x"sshenv" ]; then
    echo -n
  else
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    sshenv_cli_help
  fi

  if [ x${cmd} == x"ssh" ]; then
    echo -n
    shift 2
    sshenv_ssh $*
  fi


  if [ x${cmd} == x"scp" ]; then
    echo -n
    shift 2
    sshenv_scp $*
  fi

  if [ x${cmd} == x"install-id" ]; then
    echo -n
    shift 2
    sshenv_install_id_cli $*
  fi


  if [ x${cmd} == x"launch_proxy" -o x${cmd} == x"startsshproxy" -o x${cmd} == x"login" ]; then
    echo -n
    shift 2
    sshenv_launch_proxy $*
  fi

  if [ x${cmd} == x"listsshproxy" -o x${cmd} == x"list" ]; then
    echo -n
    shift 2
    sshenv_ls_proxy $*
  fi

  if [ x${cmd} == x"ssh-copy-id" ]; then
    echo -n
    shift 2
    sshenv_ssh_copy_id $*
  fi

}
