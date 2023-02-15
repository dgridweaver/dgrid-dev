#!/bin/bash

if [ x$MODINFO_loaded_run == "x" ]; then
export MODINFO_loaded_run="Y"
else
return
fi

MODINFO_dbg_run=0
#MODINFO_enable_run=

source ${MODINFO_modpath_run}/connect.conf

if [ -f ./dgrid-site/etc/connect.conf ]; then
source ./dgrid-site/etc/connect.conf
fi

source ${MODINFO_modpath_run}/run_cmd.bash

run_hostid_vars()
{
echo -n " CONNECT_dnsname CONNECT_type CONNECT_sshport HOST_sshport HOST_sshopts "
}

run_nodeid_vars()
{
#echo -n " NODE_sshport NODE_sshopts "
echo NODE_sshport NODE_sshopts
}

run_env_start()
{
RUN_SSH_OPTS=" -A "
#RUN_SSH_CMD="ssh"
RUN_SSH_CMD=`a_cmd=ssh a_mod=run system_alternative`
dbg_echo run 3 "F RUN_SSH_CMD=$RUN_SSH_CMD" 1>&2
#RUN_SSH_OPTS=$RUN_SSH_OPTS
}


run_hostid_post_load_api()
{
run_connect_dnsname_set $*
#echo "run_hostid_post_load_api , CONNECT_dnsname=$CONNECT_dnsname " 1>&2
}


run_connect_dnsname_set()
{
local name v
local _hostid=$1
local _pref=$2

#if [ x"$MODINFO_enable_hoststat" == xY  ]; then
#fi

#HOST_dnsname
#incoming_scanhst

export ${_pref}CONNECT_dnsname=`generic_var_content_priority ${_pref}CONNECT_dnsname \
${_pref}HOST_dnsname  ${_pref}HOST_id`


}


run_print_module_info()
{
echo "run: mod info, called run_print_module_info"

}

_is_nodeid_exists()
{
echo -n
}


############ grid level runs   ################


_run_allgrid_nodecmd_hlpr()
{
#echo TTT=$*
if [ x$hoststat_isup_this_host == "x1" ]; then
#echo "Node ${NODE_ID} online, run cmd"
dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
run_nodecmd ${NODE_ID} ${_run_params}
else
dbg_echo run 1 "Node \"${NODE_ID}\" offline, do nothing"
msg_echo run 2 "Node \"${NODE_ID}\" offline, do nothing"
fi

}

run_allgrid_nodecmd()
{
echo -n
export _run_params=$*
nodecfg_iterate_full_nodeid _run_allgrid_nodecmd_hlpr $*
}

run_allgrid_nodecmd_cmd()
{
run_allgrid_nodecmd $*
}

###

_run_allgrid_hostcmd_hlpr()
{
if [ x$hoststat_isup_this_host == "x1" ]; then
dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
run_hostcmd ${HOST_id} ${_run_params}
else
msg_echo run 2 "Host \"${HOST_id}\" offline, do nothing"
dbg_echo run 1 "Host \"${HOST_id}\" offline, do nothing"
fi

}

run_allgrid_hostcmd()
{
echo -n
if [ "x$*" == "x" ]; then
echo "run: need parameters"
exit
fi
export _run_params=$*
dbg_echo run 2 "run_allgrid_hostcmd() : params=\"$*\""
hostcfg_iterate_hostid _run_allgrid_hostcmd_hlpr $*
}

run_allgrid_hostcmd_cmd()
{
if [ "x$*" == "x" ]; then
echo "run: need parameters"
exit
fi
export _run_params=$*
run_allgrid_hostcmd $*
}

###

_run_allgrid_nodeshellcmd_hlpr()
{
#echo TTT=$*
if [ x$hoststat_isup_this_host == "x1" ]; then
#echo "Node ${NODE_ID} online, run cmd"
dbg_echo run 4 "run_nodecmd ${NODE_ID} ${_run_params}"
run_hostcmd ${HOST_id} ${_run_params}
else
msg_echo run 2 "Host \"${HOST_id}\" offline, do nothing"
dbg_echo run 1 "Host \"${HOST_id}\" offline, do nothing"
fi

}

run_allgrid_nodeshellcmd()
{
echo -n
if [ "x$*" == "x" ]; then
echo "run: need parameters"
exit
fi
export _run_params=$*
dbg_echo run 2 "run_allgrid_nodeshellcmd() : params=\"$*\""
hostcfg_iterate_hostid _run_allgrid_nodeshellcmd_hlpr $*
}

run_allgrid_nodeshellcmd_cmd()
{
if [ "x$*" == "x" ]; then
echo "run: need parameters"
exit
fi
export _run_params=$*
run_allgrid_nodeshellcmd $*
}



############ cli integration  ################

run_cli_help()
{
dgridsys_s;echo "run nodecmd <node id> <cmd> - run dgridsys command on node <nodeid>"
dgridsys_s;echo "run hostcmd <host id> <cmd> - run command on host <hostid>"
dgridsys_s;echo "run local_exec - helper func for run"
dgridsys_s;echo "run nodeshellcmd <node id> <cmd> - run shell command on node <nodeid>"
dgridsys_s;echo "run nodecli <node id> [cmd] - run cli command on node <nodeid> like ../module-list"

dgridsys_s;echo "run allgrid-nodecmd <cmd> - run dgridsys command on all (active) nodes"
dgridsys_s;echo "run allgrid-hostcmd <cmd> - run command on all (active) hosts"
dgridsys_s;echo "run allgrid-nodeshellcmd <cmd> - run shell command on   on all (active) hosts"
}


run_cli_run()
{
maincmd=$1
cmd=$2
name=$3

dbg_echo run 2 run_cli_run dgridsys_cli_run_argv=$dgridsys_cli_run_argv
#*=$dgridsys_cli_run_argv
#exit

dbg_echo run 5  x${maincmd} == x"run"
if [ x${maincmd} == x"run"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
run_cli_help
fi

if [ x${cmd} == x"nodeshellcmd"  ]; then
echo -n
shift 2
cli_cmd=$cmd run_nodecmd $*
fi


if [ x${cmd} == x"nodecmd"  ]; then
echo -n
shift 2
run_nodecmd $*
fi





if [ x${cmd} == x"nodecli"  ]; then
echo -n
shift 2
run_nodecli $*
fi

if [ x${cmd} == x"hostcmd"  ]; then
echo -n
shift 2
run_hostcmd $*
fi


if [ x${cmd} == x"local_exec"  ]; then
echo -n
shift 2
run_local_exec $*
fi


if [ x${cmd} == x"allgrid-nodecmd"  ]; then
echo -n
shift 2
run_allgrid_nodecmd_cmd $*
fi

if [ x${cmd} == x"allgrid-hostcmd"  ]; then
echo -n
shift 2
run_allgrid_hostcmd_cmd $*
fi

if [ x${cmd} == x"allgrid-nodeshellcmd"  ]; then
echo -n
shift 2
run_allgrid_nodeshellcmd_cmd $*
fi



}

