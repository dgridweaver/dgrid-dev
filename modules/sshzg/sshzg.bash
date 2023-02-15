#!/bin/bash

if [ x$MODINFO_loaded_sshzg == "x" ]; then
export MODINFO_loaded_sshzg="Y"
else
return
fi

#MODINFO_dbg_sshzg=0
#MODINFO_enable_sshzg=


sshzg_print_module_info()
{
echo "--- sshzg : ssh wrapper for dgrid , proxy connections, etc"
echo  "   sess=$DGRID_dir_dotlocal/sshzg/sess/"
echo  "   run=$DGRID_dir_dotlocal/sshzg/run/"
}

#sshzg_status()

sshzg_activate_on_this_node()
{
#if []
#mkdir -p $DGRID_dir_dotlocal/sshzg/sess/
mkdir_ifnot $DGRID_dir_dotlocal/sshzg/sess/
mkdir_ifnot $DGRID_dir_dotlocal/sshzg/run/
}

sshzg_ssh_config()
{

CFG1="./dgrid-site/etc/sshzg/config"
CFG2="$nodedir/etc/sshzg/config"
CFG3="$DGRID_dir_dotlocal/sshzg/config"
#set +x
dbg_echo sshzg 3  "CFG1=${CFG1}"  1>&2 ; dbg_echo sshzg 3  "CFG2=$CFG2"  1>&2 ; dbg_echo sshzg 3  "CFG3=$CFG3"  1>&2

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


sshzg_envelop_cmd() 
{
#ssh_package_cmd
if [ "x$ssh_package_cmd" == x ]; then
dbg_echo sshzg 1  "sshzg_cmd() : exit, ssh_package_cmd env must be set"  1>&2
exit
fi

if  [ x$ssh_package_cmd == x"ssh" ]; then
cmd_opts="-A"
else
cmd_opts=""
fi

local CFG=`sshzg_ssh_config`
dbg_echo sshzg 1  CFG=$CFG  1>&2
if [ x$CFG == "x" ]; then
local opt_CFG=""
else
local opt_CFG="-F $CFG"
fi
dbg_echo sshzg 1 "$ssh_package_cmd $cmd_opts $opt_CFG  $*" 1>&2
#echo "$ssh_package_cmd -F $CFG $*" 1>&2
$ssh_package_cmd  $cmd_opts $opt_CFG $*
}


sshzg_envelop_script() 
{
#ssh_package_cmd
if [ "x$ssh_package_cmd" == x ]; then
dbg_echo sshzg 1  "sshzg_cmd() : exit, ssh_package_cmd env must be set"  1>&2
exit
fi

local CFG=`sshzg_ssh_config`
dbg_echo sshzg 1  CFG=$CFG  1>&2
dbg_echo sshzg 1 "$ssh_package_cmd -F $CFG $*" 1>&2

alias ssh="sshzg_ssh"


p=`which $ssh_package_cmd`

echo p=$p 1>&2
#set -x
source $p $*
#set +x
#echo "$ssh_package_cmd -F $CFG $*" 1>&2
#$ssh_package_cmd -F $CFG $*

}


sshzg_ssh()
{
ssh_package_cmd="ssh" sshzg_envelop_cmd $*
}

sshzg_scp()
{
ssh_package_cmd="scp" sshzg_envelop_cmd $*
}


sshzg_ssh_copy_id() 
{
ssh_package_cmd="ssh-copy-id" sshzg_envelop_script $*
}

sshzg_launch_proxy_nodeid()
{
echo -n

}

sshzg_ls_proxy()
{
echo "$DGRID_dir_dotlocal/sshzg/sess/"
ls -1  $DGRID_dir_dotlocal/sshzg/sess/
}

sshzg_launch_proxy()
{
local host_entry=$1

if [ x$host_entry == x ]; then
echo "sshzg_launch_proxy() hostname needed"
exit
fi
#ssh 
#sshzg_ssh -fMN -v $host_entry
mkdir_ifnot $DGRID_dir_dotlocal/sshzg/sess/
echo "sshzg_ssh -A -fMN $host_entry" 
sshzg_ssh -A -fMN $host_entry
mkdir_ifnot $DGRID_dir_dotlocal/sshzg/run/
set -x; echo $! > $DGRID_dir_dotlocal/sshzg/run/${host_entry}.pid ; 
set +x
}

############ cli integration  ################

sshzg_cli_help()
{
dgridsys_s;echo "sshzg ssh - <xxx> <yyy> .... -"
dgridsys_s;echo "sshzg login|startsshproxy - <xxx> <yyy> .... -"
dgridsys_s;echo "sshzg list|listsshproxy"
dgridsys_s;echo "sshzg scp [params...] - wrapped scp"
dgridsys_s;echo "sshzg ssh-copy-id [params...] - wrapped ssh-copy-id"
}



sshzg_cli_run()
{
maincmd=$1
cmd=$2
name=$3

dbg_echo sshzg 5  x${maincmd} == x"sshzg"
if [ x${maincmd} == x"sshzg"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
sshzg_cli_help
fi


if [ x${cmd} == x"CMDONE"  ]; then
echo -n
sshzg_CMDONE $*
fi

if [ x${cmd} == x"ssh"  ]; then
echo -n
shift 2
sshzg_ssh $*
fi

if [ x${cmd} == x"scp"  ]; then
echo -n
shift 2
sshzg_scp $*
fi

if [ x${cmd} == x"launch_proxy" -o x${cmd} == x"startsshproxy"   -o x${cmd} == x"login" ]; then
echo -n
shift 2
sshzg_launch_proxy  $*
fi

if [ x${cmd} == x"listsshproxy"  -o x${cmd} == x"list"  ]; then
echo -n
shift 2
sshzg_ls_proxy  $*
fi


if [ x${cmd} == x"ssh-copy-id"  ]; then
echo -n
shift 2
sshzg_ssh_copy_id  $*
fi




}

