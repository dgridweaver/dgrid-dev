#!/bin/bash

if [ x$MODINFO_loaded_attach == "x" ]; then
  export MODINFO_loaded_attach="Y"
else
  return
fi

#MODINFO_dbg_attach=5
MODINFO_msg_attach=2

ATTACH_timestamp=$(date +%Y%d-%H%M-%s)

ATTACH_workdir="${DGRIDBASEDIR}/${DGRID_localdir}/attach/current-op-${ATTACH_timestamp}"
ATTACH_workdir_out=${ATTACH_workdir}/out
# use in init module during init
INIT_remote_workdir_rel="./${DGRID_localdir}/attach/thisnode/cfg_incoming/"
INIT_remote_outgoing_rel="./${DGRID_localdir}/attach/thisnode/cfg_outgoing/"

source ${MODINFO_modpath_attach}/attach.default.conf

if [ -f ./dgrid-site/etc/attach.conf ]; then
  source ./dgrid-site/etc/attach.conf
fi

export ATTACH_DRY_RUN=0

export attach_CLIMENU_CMDS_LIST="attach_deploy attach_redeploy attach_check"
attach_climenu_cmd_attach_deploy(){ attach_deploy_cli $@; }
attach_climenu_cmd_attach_redeploy(){ attach_redeploy_cli $@; }
attach_climenu_cmd_attach_check(){ attach_check_cli $@; }




attach_run(){
  if [ x$ATTACH_DRY_RUN == x1 ]; then
    echo $*
  else
    eval $*
  fi
}

attach_print_module_info() {
  echo "attach: create cfg and deploy new nodes, remotely and locally"
}

attach_nodeid_vars() {
  echo NODE_f_attach_mode
}

attach__savevar() {
  echo "export $1=\"$2\"" >>${ATTACH_workdir_out}/attach.vars
}

attach__savestr() {
  echo "$1" >>${ATTACH_workdir_out}/attach.vars
}

attach_parsenodestr() {
  local str=$1 _rest str1 str2
  dbg_echo attach 8 F "start"
  
  if [[ "$str" == *"/"* ]]; then
     str1=$(echo ${str} | cut -f1 -d/)
     str2=${str/"$str1"/}
  else
     str1=$str
  fi

  local newnode_id=$str1
  local newnode_user=$(echo $str1 | cut -f1 -d\@)
  _rest=$(echo $str1 | cut -f2 -d@)
  local newnode_host=$(echo ${_rest} | cut -f1 -d:)
  local newnode_namesuffix=$(echo ${_rest} | cut -f2 -d:)
  local newnode_path="$str2"
  echo -n "newnode_id=\"$newnode_id\" "
  echo -n "newnode_user=\"$newnode_user\" newnode_host=\"$newnode_host\" "
  echo -n "newnode_namesuffix=\"$newnode_namesuffix\" newnode_path=\"$newnode_path\""

  dbg_echo attach 8 F "end"
}


attach_create_nodepack_cli(){
  dbg_echo attach 5 F start
  echo "Output in ATTACH_workdir_out=$ATTACH_workdir_out"
  nodepack_outdir="$ATTACH_workdir_out" attach_create_nodepack2
  #nodepack_outdir="$DGRIDBASEDIR/" attach_create_nodepack2
  dbg_echo attach 5 F end
}

attach_create_nodepack2() {
  dbg_echo attach 8 F "Begin"
  if [ -z "$nodepack_outdir" ]; then
    distr_error "ERROR! nodepack_outdir shoud be set"
    return 1
  fi

  mkdir -p ${ATTACH_workdir_out}
  mkdir -p ${ATTACH_workdir}/tmp1/
  hg $ATTACH_HGCLONE_PARAMS clone --pull ./ ${ATTACH_workdir}/tmp1/
  pushd dgrid >/dev/null
  hg $ATTACH_HGCLONE_PARAMS clone --pull ./ ${ATTACH_workdir}/tmp1/dgrid
  popd >/dev/null
  pushd ${ATTACH_workdir}/tmp1/ >/dev/null
  set -x
  tar cf ${nodepack_outdir}/current_node.tar ./
  set +x
  popd >/dev/null

  echo -n "pwd="
  pwd
  #rm -rf ${ATTACH_workdir}/tmp1/
}

attach_newnode_stage__pack2() {
  # create archives with node files
  msg_echo attach 2 "create archives with node config and script files, dgrid distribytion"
  nodepack_outdir="$ATTACH_workdir_out" attach_create_nodepack2
}


attach_newnode_stage__vars2() {
  dbg_echo attach 3 F "start"
  mkdir -p ${ATTACH_workdir}
  mkdir -p ${ATTACH_workdir_out}

  cp ./dgrid/modules/attach/attach-copied-installer.sh ${ATTACH_workdir_out}/

  attach__savevar DGRID_dgridname ${DGRID_dgridname}
  generic_listvars NODE_ | sed "s/^/export /g" >> ${ATTACH_workdir_out}/attach.vars
  
  INIT_tmpdir_remote_incoming=${NODE_INSTPATH}/${INIT_remote_workdir_rel}
  INIT_remote_outgoing="${NODE_INSTPATH}/$INIT_remote_outgoing_rel"
  _dgriddir_remote=${NODE_INSTPATH}/${DGRID_dgridname}
  #attach__savevar INIT_get_host_ids_outdir ${INIT_remote_workdir_rel}
  #"./${DGRID_localdir}/attach/thisnode/cfg/"  #${INIT_get_host_ids_outdir}
  generic_listvars INIT_ | sed "s/^/export /g" >> ${ATTACH_workdir_out}/attach.vars

  attach__savevar _tmpdir_newnode ${INIT_tmpdir_remote_incoming}
  attach__savevar _dgriddir_newnode ${_dgriddir_remote}
}



attach_newnode_stage___transfer2() {
  dbg_echo attach 3 F "start"
  msg_echo attach 2 "Copy install files to target user@host (${CONNECT_user}@${CONNECT_HOST_id})"

  set -x
  attach_run ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} mkdir -p ${INIT_tmpdir_remote_incoming}
  attach_run scp ${CONNECT_sshopts2} ${CONNECT_sshopts} ${ATTACH_workdir_out}/* ${CONNECT_HOST_id}:${INIT_tmpdir_remote_incoming}
  set +x
}

attach_newnode_stage___initnode2(){
  set -x
  #attach_run ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} bash -x ${INIT_tmpdir_remote_incoming}/attach-copied-installer.sh ATTACH-RUN
  attach_run ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} bash ${INIT_tmpdir_remote_incoming}/attach-copied-installer.sh ATTACH-RUN 
  set +x

  # download and install configs for new node
  msg_echo attach 2 "download and install configs for new node"

  mkdir -p ${_incoming_tmp}
  #dbg_echo attach 3 
  #scp -r ${newnode_user}@${newnode_host}:${_dgriddir_remote}/$DGRID_localdir/attach/thisnode/cfg/* ${_incoming_tmp}
  set -x
  attach_run scp ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id}:${INIT_remote_outgoing}/* ${_incoming_tmp}
  set +x
  msg_echo attach 2 ""
  msg_echo attach 2 "--------------------------------------------------"

}


attach_newnode_stage___finish2(){
  dbg_echo attach 3 F "start"
  local ff=${_incoming_tmp}/host_ids.conf
  if [ x$redeploy == "x1" ]; then 
    attach_remote_cache_clear
    dbg_echo attach 3 F "Do not do finish stage in redeploy mode"
    return 0
  fi

  # _incoming_tmp need to be set
  echo "--- ls \${_incoming_tmp} ---"
  ls ${_incoming_tmp}
  if [ ! -f "$ff" ]; then
    distr_error "ERROR! {_incoming_tmp}/host_ids.conf not found!"
    exit
  else
    dbg_echo attach 3 F "OK, host_ids.conf from attach node found"
  fi
  cat $ff
  echo NODE_ID=$NODE_ID
  echo HOST_id=$HOST_id
  local nodefile=$(nodecfg_nodeid_cfgfile $NODE_ID)
  local hostfile=$(hostcfg_hostid_cfgfile $HOST_id)
  echo nodefile=$nodefile
  echo hostfile=$hostfile
  if [ ! -f "$hostfile" ]; then
    distr_error "ERROR! No hostfile, (\"$hostfile\")  not found!"
    exit
  fi
  # do the thing :D. in future need to do correct merge
  dbg_echo attach 2 "cat $ff >> $hostfile"
  cat $ff >> $hostfile
  dbg_echo attach 2 "Clear cache"
  attach_remote_cache_clear
}

attach_remote_cache_clear(){
  # ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} 
  dbg_echo attach 5 "ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} bash ${CONNECT_wdir}/dgrid/modules/dgridsys/dgridsys module cache_clear"
  attach_run ssh ${CONNECT_sshopts2} ${CONNECT_sshopts} ${CONNECT_HOST_id} bash ${CONNECT_wdir}/dgrid/modules/dgridsys/dgridsys module cache_clear
}




attach_deploy_cli(){
  attach_node_mode2 $@
}

attach_redeploy_cli(){
  attach_node_mode2 $@ redeploy=1
}


attach_node_mode2()
{
  dbg_echo attach 3 F "start"
  local newnode_id=$1
  if nodecfg_nodeid_exists $newnode_id; then
    dbg_echo attach 5 F "Ok, $newnode_id exists"
  else
    msg_echo attach 1 "Need existing (empty) node to attach installation to"
    return 1 
  fi

  local paramslist="exit_p redeploy"
  shift 1
  local parsed=$(pref="" keys="$paramslist" distr_params_keyval_all $*)
  eval "$parsed" # load params
  unset parsed paramslist

  nodecfg_nodeid_load $newnode_id
  eval `pref="local " run_connect_config $newnode_id`
  dbg_generic_listvars attach 8 "CONNECT_" 1>&2
  dbg_generic_listvars attach 8 "HOST_" 1>&2
  dbg_generic_listvars attach 8 "NODE_" 1>&2
  
  msg_echo attach 2 "-------------- Vars stage ---------------"
  attach_newnode_stage__vars2
  msg_echo attach 2 "-------------- Pack stage ---------------"
  attach_newnode_stage__pack2

  if [ x$exit_stage == "xbefore_transfer" ]; then
    msg_echo attach 1 "Do exit_stage=before_transfer, exiting"
    exit
  fi
  msg_echo attach 2 "-------------- Transfer stage ---------------"
  attach_newnode_stage___transfer2

  if [ x$exit_stage == "xbefore_initnode" ]; then
    msg_echo attach 1 "Do exit_stage=before__initnode, exiting"
    exit
  fi

  local _incoming_tmp="${ATTACH_workdir}/new-node-incoming/"

  msg_echo attach 2 "-------------- Init node stage ---------------"
  attach_newnode_stage___initnode2

  if [ x$exit_stage == "xbefore_finishnode" ]; then
    msg_echo attach 1 "Do exit_stage=before_finishnode, exiting"
    exit
  fi

  msg_echo attach 2 "-------------- Finish stage ---------------"
  # do integration of node with main nodecfg repo
  attach_newnode_stage___finish2

  msg_echo attach 2 "------------------------ attach END -----------------------"
  dbg_echo attach 3 F "end"
}

attach_newnode_local() {
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
  attach_create_nodepack

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

  pushd $newnodepath >/dev/null
  echo -n "pwd="
  pwd
  tar -xf ${ATTACH_workdir}/current_node.tar
  tar -xf ${ATTACH_workdir}/current_node_dgriddistr.tar
  # ok

  # run addthis
  mkdir -p ./$DGRID_localdir/attach/
  export NODE_ID="$USER@${NODE_HOST}:$newnode_namesuffix"
  export NODE_IDsuffix="$newnode_namesuffix"
  echo -n "pwd="
  pwd

  # inside new node mode
  pushd $DGRIDBASEDIR >/dev/null
  #

  ./dgrid/modules/system/system-runcleanenv-othernode $newnodepath \
    ./dgrid/modules/dgridsys/dgridsys module cache_clear

  ./dgrid/modules/system/system-runcleanenv-othernode $newnodepath \
    ./dgrid/modules/dgridsys/dgridsys nodecfg addthis

  popd >/dev/null
  popd >/dev/null

  cp -r ${newnodepath}/$DGRID_localdir/attach/thisnode/cfg/* \
    ${ATTACH_workdir}/newnode-local-cfg/

  attach_newnode_finish_stage ${ATTACH_workdir}/newnode-local-cfg/

}

############                  ################

attach_newnode_local_cmd() {
  export attach_newnodestr=$1
  #attach_parse_getopt $*
  attach_newnode_local $*
}

attach_newnode_cli() {
  local attach_newnodestr=$1
  shift 1
  #attach_parse_getopt $*
  #echo attach_opt_n=$attach_opt_n
  dbg_echo attach 5 F *=$*
  attach_newnode $attach_newnodestr $*
}

attach_create_empty_cli(){
  dbg_echo attach 5 F start
}


############ cli integration  ################

attach_cli_help() {
  dgridsys_s; echo "attach create-empty  <nodepath> - create empty node with NODE_f_attach_mode=1 "
  dgridsys_s; echo "attach newnode  <nodepath> - create&attach new node from host <host>"
  dgridsys_s; echo "                <nodepath> -  <user>@<host>:<suffix>/path"
  dgridsys_s; echo "attach enable [hostid|nodeid] - set flag to allow \"attach\" fo this node"
  dgridsys_s; echo "attach disable [hostid|nodeid] - unset flag allowing \"attach\" module"
  dgridsys_s; echo "attach check [nodeid] - check if attach possible"
  dgridsys_s; echo "attach deploy [nodeid] - deploy installation"
  dgridsys_s; echo "attach redeploy [nodeid] - re-deploy installation"
  dgridsys_s; echo "attach create-nodepack - create tarball of new node from current node"
#  dgridsys_s; echo "attach newnode-local <path-to-node> - attach newnode in same user on same host"
#  dgridsys_s; echo "	-n <id>  - additional id to distiguish nodes in one user on one host   "
}

attach_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo attach 5 x${maincmd} == x"attach"
  if [ ! x${maincmd} == x"attach" ]; then
    return
  fi

  if [ x${cmd} == x"" ]; then
    attach_cli_help
    return
  fi

  if [ x${cmd} == x"create-nodepack" ]; then
    echo -n
    shift 2
    attach_create_nodepack_cli $*
    return
  fi

  if [ x${name} == x"" ]; then
    echo "Path to new node not set: dgridsys attach <cmd> <path>"
    return
  fi

  if [ x${cmd} == x"create-empty" ]; then
    shift 2
    attach_create_empty_cli $*
    return
  fi

  if [ x${cmd} == x"newnode" ]; then
    shift 2
    attach_newnode_cli $*
    return
  fi

  if [ x${cmd} == x"check" ]; then
    shift 2
    attach_check_cli $*
    return
  fi

  if [ x${cmd} == x"deploy" ]; then
    shift 2
    attach_deploy_cli $*
    return
  fi

  if [ x${cmd} == x"redeploy" ]; then
    shift 2
    attach_redeploy_cli $*
    return
  fi


#  if [ x${cmd} == x"newnode-local" ]; then
#    echo -n
#    shift 2
#    attach_newnode_local_cmd $*
#    return
#  fi

}
