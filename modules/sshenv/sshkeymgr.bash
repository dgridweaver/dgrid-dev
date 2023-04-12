#!/bin/bash

#description="session management - ssh-agent for dgrid"

dcmd_fuser_q() { # [GENERIC] [API]
  if [ "x$*" == "x" ]; then
    echo -n
  else
    fuser $*
  fi
}

sshenv_env_start() {
  sshkeymgr_env_start
}

sshkeymgr_env_start() {

  #sshkeymgr_env_start
  export SESSDIR="sess-xxxx"
  export PARAMDIR=${DGRID_dir_dotlocal}/sshkeymgr
  sshkeymgr_run_sess_dir=${PARAMDIR}/${SESSDIR}/
  sshkeymgr_run_vars_file=${sshkeymgr_run_sess_dir}/ssh-agent-run-vars.sh
  sshkeymgr_run_pid_file=${sshkeymgr_run_sess_dir}/ssh-agent.pid
}

sshkeymgr_print_status() {
  local str
  str=$(sshkeymgr_status_sshagent)
  echo ${str/:/ | }
  #sshkeymgr_sshagent_status_print
}

sshkeymgr_installable_files() {
  # old api
  #echo "sshkeymgr : config_sample_node :  default : sshkeymgr.conf : etc/sshkeymgr.conf ;"
  echo "
[file entry begin]
module=sshkeymgr
handler=system
op=config_sample_node
infile=sshkeymgr.conf
outfile=etc/sshkeymgr.conf
[file entry end]
"
}

##########

function sshkeymgr_check_ssh_agent {
  ssh-add -l 1>/dev/null 2>/dev/null
}

function sshkeymgr_check_forwarded_ssh_agent {
  # SSH_CLIENT SSH_CONNECTION
  #set| grep
  if [ -n "$SSH_CLIENT" ]; then
    return 0
  fi
  return 1
}

function sshkeymgr_load_agent_vars {
  if [ -f ${sshkeymgr_run_vars_file} ]; then

    unset SSH_AUTH_SOCK SSH_AGENT_PID
    source ${sshkeymgr_run_vars_file} >/dev/null
  #echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  else
    echo -n
    return
  fi
}

function sshkeymgr_is_dgrid_sshagent_present {

  if [ -f ${sshkeymgr_run_vars_file} ]; then
    echo -n
  else
    return 1
  fi

  if [ -f ${sshkeymgr_run_pid_file} ]; then
    echo -n
  else
    return 1
  fi

  #SSHAGENT_PID=`cat ${sshkeymgr_run_pid_file}`
  #if [  x${SSHAGENT_PID} == x ]; then
  #return 1
  #fi

  unset SSH_AUTH_SOCK SSH_AGENT_PID
  source ${sshkeymgr_run_vars_file} >/dev/null

  if [ x${SSH_AGENT_PID} == x ]; then
    echo "x${SSH_AGENT_PID} == x"
    return 1
  fi

  dbg_echo sshenv 1 SSH_AUTH_SOCK=$SSH_AUTH_SOCK
  str=$(dcmd_fuser_q $SSH_AUTH_SOCK)
  dbg_echo sshenv 1 "dcmd_fuser_q \"$SSH_AUTH_SOCK\""
  dcmd_fuser_q $SSH_AUTH_SOCK
  #echo ----------------
  #echo str=$str

  #exit

  return 0
}

function sshkeymgr_start_sshagent {
  echo "sshkeymgr_start_sshagent : begin"
  if sshkeymgr_check_forwarded_ssh_agent; then
    echo "we are inside forwarded ssh agent - do not run our own"
    return
  fi

  if sshkeymgr_is_dgrid_sshagent_present; then
    echo "sshkeymgr_start_sshagent : sshkeymgr dgrid sshagent present "
    return
  fi

  #if sshkeymgr_check_ssh_agent ; then
  #echo "$DGRID_GRIDNAME ssh-agent found, no restart"
  #return
  #fi

  echo "Start $DGRID_GRIDNAME ssh-agent, for $USER"
  mkdir_ifnot_q $sshkeymgr_run_sess_dir
  ssh-agent >${sshkeymgr_run_vars_file}

  unset SSH_AUTH_SOCK SSH_AGENT_PID
  source ${sshkeymgr_run_vars_file} >/dev/null

  echo "$SSH_AGENT_PID" >${sshkeymgr_run_pid_file}

  #ret=$!
  #echo "ssh-agent > ${sshkeymgr_run_vars_file}"
  #echo "echo $ret > ${sshkeymgr_run_pid_file}"
  #echo $ret > ${sshkeymgr_run_pid_file}

  #SSH_AGENT_PID

  echo "sshkeymgr_start_sshagent : end"
}

sshkeymgr_status_sshagent() {
  if sshkeymgr_is_dgrid_sshagent_present; then
    echo "sshkeymgr : ssh-agent [OK] , pid=$SSH_AGENT_PID"
  else
    echo "sshkeymgr : ssh-agent [stopped]"
  fi
}

sshkeymgr_status() {
  unset SSH_AUTH_SOCK SSH_AGENT_PID
  sshkeymgr_load_agent_vars

  sshkeymgr_status_sshagent

  echo fuser \"$SSH_AUTH_SOCK\"
  dcmd_fuser_q $SSH_AUTH_SOCK

  (
    set -o posix
    set
  ) | grep "^SSH_"
  echo "  -- \"ps ax\" of ssh-agent --"
  ps ax | grep ssh-agent | grep -v grep
  #echo "------------ internal ------------"
  #( set -o posix ; set )|grep "^sshkeymgr"
}

sshkeymgr_stop() {
  if sshkeymgr_check_forwarded_ssh_agent; then
    echo "sshkeymgr_stop: we are inside forwarded ssh agent - do not run our own"
    exit
  fi

  if sshkeymgr_is_dgrid_sshagent_present; then
    echo -n
  else
    echo "sshkeymgr_stop : sshkeymgr dgrid sshagent already down "
    exit
  fi

  unset SSH_AUTH_SOCK SSH_AGENT_PID
  source ${sshkeymgr_run_vars_file} >/dev/null

  echo "kill -11 $SSH_AGENT_PID"
  kill -11 $SSH_AGENT_PID

  echo "rm ${sshkeymgr_run_vars_file}"
  rm ${sshkeymgr_run_vars_file}

  echo "rm ${sshkeymgr_run_pid_file}"
  rm ${sshkeymgr_run_pid_file}
}

sshkeymgr_start() {

  sshkeymgr_start_sshagent
  echo --------------------------
  cat ${sshkeymgr_run_vars_file}
}

sshkeymgr_sshadd() {
  local argv=$*

  if sshkeymgr_check_forwarded_ssh_agent; then
    echo "sshkeymgr_sshadd: we are inside forwarded ssh agent - do not run our own"
    exit
  fi

  if sshkeymgr_is_dgrid_sshagent_present; then
    echo -n
  else
    echo "sshkeymgr_sshadd : sshkeymgr dgrid sshagent down"
    exit
  fi

  unset SSH_AUTH_SOCK SSH_AGENT_PID
  sshkeymgr_load_agent_vars

  ssh-add ${argv}

}

########### srv integration #################3

# hook_ srv_is_registered_service

sshkeymgr_srv_is_registered_service() {
  echo sshkeymgr
}

sshkeymgr_status_service_sshkeymgr() {
  #echo -n sshkeymgr:STATUS
  sshkeymgr_status
}

sshkeymgr_start_service_sshkeymgr() {
  echo sshkeymgr START
}

sshkeymgr_stop_service_sshkeymgr() {
  echo sshkeymgr STOP
}

sshkeymgr_help_service_sshkeymgr() {
  echo sshkeymgr HELP
}

############ cli integration  ################

sshkeymgr_cli_help() {
  dgridsys_s;  echo "sshkeymgr start - start dgrid ssh-agent"
  dgridsys_s;  echo "sshkeymgr stop - stop dgrid ssh-agent"
  dgridsys_s;  echo "sshkeymgr status - status dgrid ssh-agent"
  dgridsys_s;  echo "sshkeymgr ssh-add - ssh-add in sshkeymgr context"
}

sshenv_cli_run_sshkeymgr() {
#sshkeymgr_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo run 5 x${maincmd} == x"sshkeymgr"
  if [ x${maincmd} == x"sshkeymgr" ]; then
    echo -n
  else
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    sshkeymgr_cli_help
  fi

  if [ x${cmd} == x"start" ]; then
    echo -n
    #shift 1
    sshkeymgr_start
  fi

  if [ x${cmd} == x"stop" ]; then
    echo -n
    #shift 1
    sshkeymgr_stop
  fi

  if [ x${cmd} == x"status" ]; then
    echo -n
    #shift 1
    sshkeymgr_status
  fi

  if [ x${cmd} == x"ssh-add" ]; then
    echo -n
    shift 2
    sshkeymgr_sshadd $*
  fi

}
