#!/bin/bash

if [ x$MODINFO_loaded_sshenv == "x" ]; then
  export MODINFO_loaded_sshenv="Y"
else
  return
fi
export MODINFO_msg_sshenv=3

source ${MODINFO_modpath_sshenv}/sshenv.conf
source ${MODINFO_modpath_sshenv}/sshkeymgr.bash
source ${MODINFO_modpath_sshenv}/sshenv_sshfs.bash

#sshenv_CLIMENU_CMDS_LIST="ssh-config-update sshenv-update-sshconfig"
sshenv_CLIMENU_CMDS_LIST="ssh-dg sshenv-install-id sshfs-mount sshfs-umount sshfs-list"

# hook to define variables
sshenv_envset_start(){
  #echo "export SSHENV_dir_local=\"${DGRID_dir_dotlocal}\""
  local SSHENV_dir_local=${DGRID_dir_nodelocal}
  echo "export SSHENV_dir_local=\"$SSHENV_dir_local\""
  echo "export SSHENV_ssh_config_generated=\"${SSHENV_dir_local}sshenv/ssh_config\""
}

sshenv_print_module_info() {
  echo "--- sshenv : ssh wrapper for dgrid , proxy connections, etc"
  echo "   sess=$SSHENV_dir_local/sshenv/sess/"
  echo "   run=$SSHENV_dir_local/sshenv/run/"
}

#sshenv_status()

sshenv_activate_on_this_node() {
  #mkdir -p $SSHENV_dir_local/sshenv/sess/
  mkdir_ifnot $SSHENV_dir_local/sshenv/sess/
  mkdir_ifnot $SSHENV_dir_local/sshenv/run/
}


sshenv_output_sshconfig()
{
  local list1 f n 
  local CFG1="./dgrid-site/sshenv/config"
  dbg_echo sshenv 5 F "Begin"
  dbg_echo sshenv 5 F "grid-level config: $CFG1"

  echo ""
  for n in $NODECFG_hostid_LIST $NODECFG_nodeid_LIST; do
    echo "Host $n"
    f=`distr_entityid_cfgdir $n`"/etc/ssh_config"
    if [ -f "$f" ]; then
      echo "# cat $f"; cat $f
    else
      echo "# No ssh_config in "`dirname $f`
    fi
    echo
  done
  dbg_echo sshenv 5 F "End"
}


sshenv_update_sshconfig_cli(){
  msg_echo sshenv 1 "Updating generated ssh_config ( Located in: $SSHENV_ssh_config_generated )"
  sshenv_update_sshconfig
}


sshenv_update_sshconfig()
{
  dbg_echo sshenv 5 F "Begin"
  local CFG="$SSHENV_dir_local/sshenv/ssh_config"
  mkdir -p `dirname $CFG`
  dbg_echo sshenv 3 "CFG=${CFG}"
  sshenv_output_sshconfig > $CFG
  dbg_echo sshenv 5 F "End"
}

sshenv_ssh_config() {
  local CFG="$SSHENV_dir_local/sshenv/ssh_config"
  dbg_echo sshenv 5 F "Begin"
  [ x$SSHENV_sshconfig_autoupdate == x1 ] && sshenv_update_sshconfig_cli
  if [ -f $CFG ] ; then 
    echo $CFG; return 0;
  else
    dbg_echo sshenv 1 "Config for ssh not exists : ${CFG}"
    echo ""
    return 1
  fi
}



sshenv_get_param_from_optstr(){
  dbg_echo sshenv 6 F "Begin"
  local skip=0 p 
  [ x$list1 == x ] && (distr_error "list1 must be set" ;exit)
  [ x$list2 == x ] && (distr_error "list2 must be set" ;exit)
  
  for p in $@; do
    if [ $skip == 1 ]; then
       dbg_echo sshenv 12 "skip PARAM of opt"; skip=0; continue;
    fi
    if [[ $p == -*  ]]; then
      p=${p/-/}
      dbg_echo sshenv 12 F "opt p=$p"
      if [[ "$list1" == *"$p"* ]]; then dbg_echo sshenv 12 "is a no-param option"; continue; fi
      if [[ "$list2" == *"$p"* ]]; then dbg_echo sshenv 12 "is a PARAM option";skip=1; fi
    else
      echo $p
      break
    fi
  done
  dbg_echo sshenv 6 F "End"
}

sshenv_envelop_cmd() {
  local cmd_opts opt_CFG eid

  if [ "x$ssh_package_cmd" == x ]; then
    dbg_echo sshenv 1 "sshenv_cmd() : exit, ssh_package_cmd env must be set"
    exit
  fi
  [ x$ssh_package_cmd == x"ssh" ] && cmd_opts="-A"

  # list1 list2 is a list of ssh/scp parameters
  # we need entity id to load CONNECT parametes
  eid=$(list1="1246AaCfGgKkMNnqsTtVvXxYy" list2="bcDEeFIiJLlmOopQRSWw" sshenv_get_param_from_optstr $@)
  dbg_echo sshenv 2 F "eid=$eid"
  
  if [ -n "$eid" ]; then
    eval `pref="local " run_connect_config $eid`;
  fi
  dbg_generic_listvars sshenv 6 "CONNECT_" 1>&2

  local CFG=$(sshenv_ssh_config); dbg_echo sshenv 1 CFG=$CFG
  [ "x$CFG" == "x" ] || ( opt_CFG="-F $CFG" )
  
  dbg_echo sshenv 1 "$ssh_package_cmd $cmd_opts $opt_CFG $CONNECT_sshopts $CONNECT_sshopts2  $@"
  $ssh_package_cmd $cmd_opts $opt_CFG $CONNECT_sshopts $CONNECT_sshopts2  $@
}

sshenv_envelop_script() {
  if [ "x$ssh_package_cmd" == x ]; then
    distr_error "ssh_package_cmd env must be set, exit"
    exit
  fi

  local CFG=$(sshenv_ssh_config)
  dbg_echo sshenv 1 CFG=$CFG "$ssh_package_cmd -F $CFG $*"

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
  
  eval `pref="local " run_connect_config $eid`;

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

sshenv_climenu_cmd_sshenv_install_id(){
  sshenv_install_id_cli $@
}

sshenv_climenu_cmd_ssh_config_update(){
  sshenv_update_sshconfig_cli
}

sshenv_climenu_cmd_ssh_dg(){
  sshenv_ssh $@
}




########################

sshenv_launch_proxy_nodeid() {
  echo -n

}

sshenv_ls_proxy() {
  echo "$SSHENV_dir_local/sshenv/sess/"
  ls -1 $SSHENV_dir_local/sshenv/sess/
}

sshenv_launch_proxy() {
  local host_entry=$1

  if [ x$host_entry == x ]; then
    echo "sshenv_launch_proxy() hostname needed"
    exit
  fi
  #ssh
  #sshenv_ssh -fMN -v $host_entry
  mkdir_ifnot $SSHENV_dir_local/sshenv/sess/
  echo "sshenv_ssh -A -fMN $host_entry"
  sshenv_ssh -A -fMN $host_entry
  mkdir_ifnot $SSHENV_dir_local/sshenv/run/
  set -x
  echo $! >$SSHENV_dir_local/sshenv/run/${host_entry}.pid
  set +x
}

############ cli integration  ################

sshenv_cli_help() {
  dgridsys_s;echo "sshenv ssh - run ssh with dgrid settings"
  dgridsys_s;echo "sshenv install-id - install ssh id using default settings for nodeid/hostid"
#  dgridsys_s;echo "sshenv login|startsshproxy - <xxx> <yyy> .... -"
#  dgridsys_s;echo "sshenv list|listsshproxy"
  dgridsys_s;echo "sshenv scp [params...] - wrapped scp"
  dgridsys_s;echo "sshenv ssh-copy-id [params...] - wrapped ssh-copy-id"
  dgridsys_s;echo "sshenv update-sshconfig - update(merge) config from all nodes and hosts"
  sshenv_cli_help_sshfs
}

sshenv_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo sshenv 5 F x${maincmd} == x"sshenv"
  if [ ! x${maincmd} == x"sshenv" ]; then return; fi

  dbg_echo sshenv 8 F "Do sshenv_cli_run_sshfs"
  sshenv_cli_run_sshfs $@ && return 0

  dbg_echo sshenv 8 F "Do sshenv_cli_run_sshkeymgr"
  sshenv_cli_run_sshkeymgr $@ && return 0

  if [ x${cmd} == x"" ]; then sshenv_cli_help; fi
  if [ x${cmd} == x"ssh" ]; then shift 2; sshenv_ssh $@; fi
  if [ x${cmd} == x"scp" ]; then shift 2; sshenv_scp $@;  fi
  if [ x${cmd} == x"install-id" ]; then shift 2; sshenv_install_id_cli $*; fi

  if [ x${cmd} == x"update-sshconfig" ]; then
    shift 2
    sshenv_update_sshconfig_cli $*
  fi

  if [ x${cmd} == x"launch_proxy" -o x${cmd} == x"startsshproxy" -o x${cmd} == x"login" ]; then
    shift 2
    sshenv_launch_proxy $*
  fi

  if [ x${cmd} == x"listsshproxy" -o x${cmd} == x"list" ]; then
    shift 2
    sshenv_ls_proxy $*
  fi

  if [ x${cmd} == x"ssh-copy-id" ]; then
    shift 2
    sshenv_ssh_copy_id $*
  fi
}
