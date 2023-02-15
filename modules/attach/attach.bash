#!/bin/bash

if [ x$MODINFO_loaded_attach == "x" ]; then
export MODINFO_loaded_attach="Y"
else
return
fi

#MODINFO_dbg_attach=5
MODINFO_msg_attach=1

ATTACH_timestamp=`date +%Y%d-%H%M-%s`

ATTACH_workdir="${GRIDBASEDIR}/not-in-vcs/attach/current-op-${ATTACH_timestamp}"
ATTACH_remote_workdir_rel="not-in-vcs/attach/this_node_tmp"

if [ -f ./dgrid-site/etc/attach.conf ]; then
source ./dgrid-site/etc/attach.conf
else
# load default config from module dir
source ${MODINFO_modpath_attach}/attach.default.conf
#ATTACH_HGCLONE_PARAMS=" --config format.dotencode=0 --config format.usedotencode=0 "
fi


attach_print_module_info()
{
echo "attach: mod info, called attach_print_module_info"

}

attach_create_nodearch()
{
mkdir -p ${ATTACH_workdir}

#hg archive -p ${DGRID_dgridname} ${ATTACH_workdir}/current_node.tar
#attach_create_arch1 ${DGRID_dgridname} ${ATTACH_workdir}/current_node.tar
mkdir -p ${ATTACH_workdir}/tmp1/
hg $ATTACH_HGCLONE_PARAMS clone --pull ./ ${ATTACH_workdir}/tmp1/${DGRID_dgridname}

echo tar cf ${ATTACH_workdir}/current_node.tar ${ATTACH_workdir}/tmp1/${DGRID_dgridname}/
pushd ${ATTACH_workdir}/tmp1/${DGRID_dgridname}/  > /dev/null
tar cf ${ATTACH_workdir}/current_node.tar ./
popd > /dev/null
#rm -rf ${ATTACH_workdir}/tmp1/
rm -rf ${ATTACH_workdir}/tmp1/

mkdir -p ${ATTACH_workdir}/tmp1/
pushd dgrid > /dev/null
#hg archive -p dgrid  ${ATTACH_workdir}/current_node_dgriddistr.tar
#attach_create_arch1 ${ATTACH_workdir}/current_node_dgriddistr.tar
hg $ATTACH_HGCLONE_PARAMS clone  --pull ./ ${ATTACH_workdir}/tmp1/dgrid
popd > /dev/null
pushd ${ATTACH_workdir}/tmp1/  > /dev/null
tar cf ${ATTACH_workdir}/current_node_dgriddistr.tar ./
popd > /dev/null

echo -n "pwd=" ; pwd
cp ./dgrid/modules/attach/attach-copied-installer.sh ${ATTACH_workdir}/

rm -rf ${ATTACH_workdir}/tmp1/

#exit
}

attach__savevar()
{
echo "export $1=\"$2\"">> ${ATTACH_workdir}/attach.vars
}


attach_parsenodestr()
{

newnode_user=`echo $*|cut -f1 -d\@`
_rest=`echo $*|cut -f2 -d@`
newnode_host=`echo ${_rest}|cut -f1 -d:`
newnode_path=`echo ${_rest}|cut -f2 -d:`

}

attach_newnode___prepare()
{
echo -n
}

attach_newnode()
{
#msg_echo attach 2 "start "
dbg_echo attach 3 "start"
attach_parsenodestr $attach_newnodestr

if [ x$attach_opt_n == x ]; then
local newnode_namesuffix="one"
else
local newnode_namesuffix=$attach_opt_n
fi

if [ x$newnode_path = "x" ]; then 
msg_echo attach 1 "Path to new node not set, exiting"
exit
fi


echo newnode_user=$newnode_user
echo newnode_host=$newnode_host
echo newnode_path=$newnode_path
echo newnode_namesuffix=$newnode_namesuffix


#exit
#ssh ${newnode_user}@${newnode_host}
#DGRID_dgridname

# create archives with node files
msg_echo attach 2 "create archives with node config and script files, dgrid distribytion"
attach_create_nodearch

attach__savevar DGRID_dgridname ${DGRID_dgridname}
attach__savevar newnode_host $newnode_host
attach__savevar newnode_user $newnode_user
attach__savevar newnode_path $newnode_path
attach__savevar newnode_namesuffix $newnode_namesuffix

_tmpdir_remote=${newnode_path}/${DGRID_dgridname}/${ATTACH_remote_workdir_rel}
_dgriddir_remote=${newnode_path}/${DGRID_dgridname}

attach__savevar _tmpdir_newnode ${_tmpdir_remote}
attach__savevar _dgriddir_newnode ${_dgriddir_remote}

msg_echo attach 2 "Copy install files to target user@host (${newnode_user}@${newnode_host})"
set -x
ssh ${newnode_user}@${newnode_host} mkdir -p ${_tmpdir_remote}
scp ${ATTACH_workdir}/current_node.tar \
  ${ATTACH_workdir}/current_node_dgriddistr.tar \
  ${ATTACH_workdir}/attach.vars \
  ${ATTACH_workdir}/attach-copied-installer.sh \
  ${newnode_user}@${newnode_host}:${_tmpdir_remote}

#ssh ${newnode_user}@${newnode_host} "(cd ${_dgriddir_remote} ; tar xf ${_tmpdir_remote}/current_node.tar ; tar xf ${_tmpdir_remote}/current_node_dgriddistr.tar )"
ssh ${newnode_user}@${newnode_host} bash -x ${_tmpdir_remote}/attach-copied-installer.sh ${_dgriddir_remote}
#ssh ${newnode_user}@${newnode_host} "(cd ${_dgriddir_remote}; sh -x ./dgrid/modules/attach/attach-this-node.sh )"


# download and install configs for new node
msg_echo attach 2  "download and install configs for new node"
dbg_echo attach 3  "_dgriddir_remote=\"${_dgriddir_remote}\""
#exit
_incoming_tmp="${ATTACH_workdir}/new-node-incoming/"
mkdir ${_incoming_tmp}
dbg_echo attach 3 "scp -r ${newnode_user}@${newnode_host}:${_dgriddir_remote}/not-in-vcs/attach/thisnode/cfg/* ${_incoming_tmp}"
scp -r ${newnode_user}@${newnode_host}:${_dgriddir_remote}/not-in-vcs/attach/thisnode/cfg/* ${_incoming_tmp}

set +x
msg_echo attach 2 ""
msg_echo attach 2 "-----------"

local _hostcfgfile=`find ${_incoming_tmp} -iname "*.hostinfo"`
echo _hostcfgfile=${_hostcfgfile}
if [ -f ${_hostcfgfile} ]; then
echo "Write CONNECT_dnsname=$newnode_host"
echo -n
echo "" >> ${_hostcfgfile}
echo "CONNECT_dnsname=$newnode_host" >> ${_hostcfgfile}
fi
export _incoming_tmp=${_incoming_tmp}
echo attach_newnode_finish_stage ${_incoming_tmp}
#pwd
#exit
msg_echo attach 2 "Finish stage of node installation."
attach_newnode_finish_stage ${_incoming_tmp}
}


attach_newnode_finish_stage()
{
local _incoming_tmp=$1

echo -n "attach_newnode_finish_stage() pwd=" ; pwd
set -x
#echo cp -rvn ${_incoming_tmp}/ ./bynodes/
cp -rvn ${_incoming_tmp}/* ./bynodes/
set +x

# register new nodes in system
local trid=`system_trans_genid`
local FUNCNAME=attach_newnode_finish_stage

for i in ${_incoming_tmp}/* ; do
_newcfg=`basename $i`
echo "new node/host config dir: ${_newcfg}"
local f=`ls ./bynodes/${_newcfg}/*.nodeconf`
local f1=`ls ./bynodes/${_newcfg}/*.hostinfo`
f="$f $f1"
system_trans_begin $trid system newnodeadd $FUNCNAME
system_trans_register $trid system newnodeadd $f
system_trans_end "$trid" system newnodeadd

#system.bash:system_trans_register  $trid system module_enable ${modcfg}.bak
#system.bash:system_trans_end "$trid" system module_enable
done
#exit
}

attach_newnode_local()
{
local newnodepathdir=$1

if [ x$attach_opt_n == x ]; then
local newnode_namesuffix="one"
else
local newnode_namesuffix=$attach_opt_n
fi

if [ x$newnodepathdir = "x" ]; then 
msg_echo attach 1 "Path to new node not set, exiting"
exit
fi
newnodepath="$newnodepathdir/${DGRID_dgridname}"
msg_echo attach 1 "New local node in \"$newnodepath\""
attach_create_nodearch

if [ -a "$newnodepath" ]; then
msg_echo attach 1 "New local node cannot be created in $newnodepath , dir exists"
exit
fi
mkdir -p $newnodepath
if [ ! -d "$newnodepath" ]; then
msg_echo attach 1 "cannot create \"$newnodepath\""
exit
fi

mkdir -p ${ATTACH_workdir}
mkdir -p ${ATTACH_workdir}/newnode-local-cfg


nodecfg_nodeid_load $THIS_NODEID
#print_vars `nodeid_vars_all`
#exit

pushd $newnodepath > /dev/null
echo -n "pwd="
pwd
tar -xf ${ATTACH_workdir}/current_node.tar
tar -xf ${ATTACH_workdir}/current_node_dgriddistr.tar
# ok


# run addthis
mkdir -p ./not-in-vcs/attach/
export NODE_ID="$USER@${NODE_HOST}:$newnode_namesuffix"
export NODE_IDsuffix="$newnode_namesuffix"
echo -n "pwd="
pwd

# inside new node mode
pushd $DGRIDBASEDIR > /dev/null
#

./dgrid/modules/system/system-runcleanenv-othernode $newnodepath \
  ./dgrid/modules/dgridsys/dgridsys  module cache_clear

./dgrid/modules/system/system-runcleanenv-othernode $newnodepath \
  ./dgrid/modules/dgridsys/dgridsys nodecfg addthis

popd > /dev/null
popd > /dev/null

cp -r ${newnodepath}/not-in-vcs/attach/thisnode/cfg/*  \
  ${ATTACH_workdir}/newnode-local-cfg/

attach_newnode_finish_stage ${ATTACH_workdir}/newnode-local-cfg/

}

attach_addthis_run_script()
{
#echo "params=$*"
local _cfgdir=$1
#echo THIS_NODEID="$THIS_NODEID"
#echo THIS_HOST=$THIS_HOST
echo _cfgdir=${_cfgdir}

}
############                  ################

attach_newnode_local_cmd()
{

export attach_newnodestr=$1
attach_parse_getopt $*
attach_newnode_local $*
}

attach_newnode_cmd()
{
export attach_newnodestr=$1
#shift 1 #echo "#$*#"
attach_parse_getopt $*
#echo attach_opt_n=$attach_opt_n
attach_newnode $*
}
############ cli integration  ################

attach_cli_help()
{
#dgridsys_s;echo "attach CMDONE - <xxx> <yyy> .... -"
dgridsys_s;echo "attach newnode  <user>@<host>:<path> [-n <id>] - create&attach new node form host <host>"
dgridsys_s;echo "attach newnode-local <path-to-node> [-n <id>]- attach newnode in same user on same host"
dgridsys_s;echo "	-n <id>  - additional id to distiguish nodes in one user on one host   "
dgridsys_s;echo "attach newnode-samehost-interuser"
}

attach_parse_getopt()
{
echo "attach_parse_getopt()"
shift 1
#echo "params=$*"

while getopts ":n:" opt; do
  case $opt in
    n)
      #echo "-n was triggered, Parameter: $OPTARG" >&2
      export attach_opt_n=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

}


attach_cli_run()
{
maincmd=$1
cmd=$2
name=$3

dbg_echo attach 5  x${maincmd} == x"attach"
if [ x${maincmd} == x"attach"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
attach_cli_help
fi

if [ x${name} == x""  ]; then
echo -n
echo "Path to new node not set: dgridsys attach <cmd> <path>"
fi


if [ x${cmd} == x"newnode"  ]; then
echo -n
shift 2
attach_newnode_cmd $*
fi

if [ x${cmd} == x"newnode-local"  ]; then
echo -n
shift 2
attach_newnode_local_cmd $*
fi

if [ x${cmd} == x"addthis-run-script"  ]; then
echo -n
echo --------------------------------------
shift 2
attach_addthis_run_script $*
fi


if [ x${cmd} == x"newnode-xxx"  ]; then
echo -n
attach_CMDONE $*
fi



#if [ x${cmd} == x"CMDTWO"  ]; then
#echo -n
#attach_CMDTWO $*
#fi


}

