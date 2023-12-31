#!/bin/bash


###################################################

DISTR_nodes_templ="dgrid-site/etc/tmplnodes/"


###################################################

distr_parse_nodeid() # [API]
{
  # USAGE: distr_parsenodestr nodeid=aaa@bbb:ttt [pref=xxx]
  dbg_echo distr 15 F "*=$*"
  local nodeid="" pref="" n_suffix n_host n_user _rest
  eval "local $*"
  #local nodestr=$1 pref=$2

  if [[ "${_rest}" =~ .*"@".* ]]; then
    echo "ERROR: distr_parse_nodeid: input should contain @" 1>&2
    exit
  fi
  local n_user _rest n_host n_path
  n_user=`echo $nodeid|cut -f1 -d\@`
  _rest=`echo $nodeid|cut -f2 -d@`
  if [[ "${_rest}" =~ .*":".* ]]; then
    n_host=`echo ${_rest}|cut -f1 -d:`
    n_suffix=`echo ${_rest}|cut -f2 -d:`
  else
    n_host=${_rest}
  fi
  echo "${pref}NODE_USER=${n_user} ${pref}NODE_HOST=$n_host ${pref}NODE_IDsuffix=$n_suffix"
}


distr_nodecfg_addthis_cli(){
distr_nodecfg_addthis
}

distr_nodecfg_addthis() {
  if [ "x$DGRID_dir_nodelocal" == "x" ]; then
    echo "DGRID_dir_nodelocal not defined, aborting!"
    exit
  fi

  HOST_dnsname=$1

  if [ -n "$HOST_dnsname" ]; then
    NODE_HOST=${HOST_dnsname%%.*}
    HOST_id=${HOST_dnsname%%.*}
  else
    NODE_HOST=$(hostname -s)
    HOST_id=$(hostname -s)
    HOST_dnsname=$(hostname -f)
  fi

  if [ -n "$NODE_ID" ]; then
    echo -n
  else
    NODE_IDsuffix=$(this_node_idsuffix)
    NODE_ID="${USER}@${HOST_id}:$NODE_IDsuffix"
  fi
  echo NODE_ID=$NODE_ID

  if hostcfg_hostid_exists "${HOST_id}"; then
    echo "hostcfg_hostid_exists "${HOST_id}" - host id already exists"
    hostid_exists="1"
  fi
  if nodecfg_nodeid_exists "${NODE_ID}"; then
    echo "nodecfg_nodeid_exists "${NODE_ID}" - node id already exists"
    nodeid_exists="1"
  fi

  local var=MODINFO_dbg_dgridsys
  if [ ! x${!var} == x ]; then
    if [ ${!var} -le 4 ]; then
      echo "-- Vars: --"
      set | grep "^DGRID"
      #dgridsys_vars_list
      echo "-- end Vars: --"
    fi
  fi

  outdir_host=${DGRID_dir_nodelocal}/attach/thisnode/cfg/${HOST_id}/
  outfile_host=${outdir_host}/${HOST_id}.hostinfo

  NODE_ID_dir=${NODE_ID/:/_} 
  outdir_node=${DGRID_dir_nodelocal}/attach/thisnode/cfg/${NODE_ID_dir}/
  outfile_node=${outdir_node}/this.nodeconf

  mkdir_ifnot ${outdir_host}
  mkdir_ifnot ${outdir_node}

  if [ x$hostid_exists != "x1" ]; then

    echo
    echo "# -- this_hostinfo -- "
    this_hostinfo
    echo -n "hostid_vars_all="
    hostid_vars_all
    print_vars $(hostid_vars_all)
    print_vars $(hostid_vars_all) >$outfile_host

  fi # if [ $hostid_exists != "1" ]; then

  if [ x$nodeid_exists != "x1" ]; then

    echo
    echo "# -- this_nodeinfo -- "
    this_nodeinfo
    print_vars $(nodeid_vars_all) | grep -v "^HOST_"
    print_vars $(nodeid_vars_all) | grep -v "^HOST_" >$outfile_node
    echo

  fi #

}

############

distr_hostcfg_empty_add_cli() {
  dbg_echo distr 5 F "start"
  local ret eid=$1
  shift 1
  local parsed=$(pref="" distr_params_keyval_all $*)
  eval "$parsed"
  distr_hostcfg_empty_add "$eid"
  ret=$?
  if [ $ret == 0 ]; then
    cache_clear ALL
  fi
  dbg_echo distr 5 F "end"
  return $ret
}

distr_hostcfg_empty_add() { 
 # htype= empty | this
  dbg_echo distr 10 F "start"
  local new_HOST_id="$1"
  shift 1
  eval "$*"
  dbg_echo distr 10 F "template=$template" "prepdir=$prepdir"
  if [[ $new_HOST_id =~ ^[A-Za-z0-9\-]+$ ]]; then
    echo "OK, new_HOST_id alphanum"
  else
    echo "ERROR, new_hostid ($new_hostid) must be alphanum"
    exit #return 1
  fi

  dbg_echo distr 5 F "outdir_new_entity=$outdir_new_entity"
  local new_entity_dirname="$new_HOST_id"
  local outfile_new_entity=${new_HOST_id}.hostinfo

  # output dir
  if [ -n "$prepdir" ]; then
    local outdir_new_entity=${prepdir}/${new_entity_dirname}
  else
    local outdir_new_entity=${DGRID_dir_nodelocal}/distr/new-hostcfg/cfg/${new_entity_dirname}
  fi

  
  ####################### Creating ##########################


  local HOST_id=$new_HOST_id
  local HOST_hostname=$new_HOST_id
  #local HOST_hostid=`hostid`
  local HOST_uuid=`uuidgen`

  dbg_echo distr 5 F "--- Creating host ---"
  generic_listvars HOST_

  if [ -f ${outdir_new_entity}/$outfile_new_entity ]; then
    echo ABORT: this.nodeconf already exists.
    return 1
  fi

  dbg_echo distr 5 F "outdir_new_entity/outfile_new_entity=${outdir_new_entity}/$outfile_new_entity"
  echo mkdir ${outdir_new_entity}
  mkdir -p ${outdir_new_entity}

  # templates
  if [ -n "$template" ]; then
    local td=$DISTR_nodes_templ/$template
    if [ -d $td ]; then
      dbg_echo distr 5 F "Template \"$template\" found"
      msg_echo distr 2 "Using template \"$template\""
      cp -ar $td/* ${outdir_new_entity}/
    fi
  fi
  
  generic_listvars HOST_ | tee ${outdir_new_entity}/$outfile_new_entity
  echo "#HOST_dnsname=" | tee -a ${outdir_new_entity}/$outfile_new_entity
  echo "#HOST_hostid=" | tee -a ${outdir_new_entity}/$outfile_new_entity

  dbg_echo distr 5 F "cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/"
  cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/
}

############

distr_nodecfg_subnode_add_cli() {
  dbg_echo distr 5 F "start"
  local ret eid=$1
  local keys="template register prepdir"
  shift 1
  #local parsed=$(pref="local cliopt_" distr_params_keyval_all $*)
  local parsed=$(pref="" keys="$keys" distr_params_keyval_all $*)
  eval "$parsed"
  distr_nodecfg_subnode_add "$eid"
  ret=$?
  if [ $ret == 0 ]; then
    cache_clear ALL
  fi
  dbg_echo distr 5 F "end"
  return $ret
}

distr_nodecfg_subnode_add() {
  dbg_echo distr 5 F "start"
  local new_nodeid="$1" type="subnode"
  shift 1
  #eval "$*"
  dbg_echo distr 10 F "instpath=$instpath template=$template" "prepdir=$prepdir"
  if [ "x$new_nodeid" == "x" ]; then
    echo "empty new_nodeid"
    return 1
  fi

  if [ x$THIS_NODEID == "x" ]; then
    echo "Abort, no THIS_NODEID."
    return 1
  fi

  local _parsed=$(distr_parse_nodeid nodeid=$new_nodeid pref="new_")
  eval "local ${_parsed}"
  generic_listvars new_

  local _parsed=$(distr_parse_nodeid nodeid=$THIS_NODEID pref="this1_")
  eval "local ${_parsed}"
  generic_listvars this1_

  if [ "x$new_NODE_IDsuffix" == "x" ]; then
    distr_error "ERROR, new NODE_IDsuffix is \"\", need for subnode"
    exit
  fi

  # CHECKS for type=SUBNODE
  if [ ! x$this1_NODE_USER == "x$new_NODE_USER" ]; then
    echo "ABORT x\$this1_NODE_USER != x\$new_NODE_USER, you need same user for subnode"
    return 1
  fi
  if [ ! x$this1_NODE_HOST == "x$new_NODE_HOST" ]; then
    echo "xthis1_NODE_HOST != xnew_NODE_HOST, you need same host for subnode" 
    return 1
  fi

  local new_node_instpath=${DGRIDBASEDIR}/${DGRID_localdir}/subnode-$new_NODE_IDsuffix
  local instpath=$new_node_instpath # for distr_nodecfg_node_add_empty function
  echo mkdir $new_node_instpath
  mkdir -p ${new_node_instpath}


  dbg_echo distr 5 F "distr_nodecfg_node_add_empty $new_nodeid"
  distr_nodecfg_node_add_empty $new_nodeid
  dbg_echo distr 5 F "ret=$?"

  pushd $new_node_instpath > /dev/null
  ln -s ../../dgrid ./
  ln -s ../../dgrid-site ./
  ln -s ../../${dgrid_bynodes_dir}/ ./
  mkdir ${DGRID_localdir} 
  popd > /dev/null
  dbg_echo distr 5 F "end"
  return 0
}


############

distr_nodecfg_empty_add_cli() {
  dbg_echo distr 5 F "start"
  local ret eid=$1
  local keys="template register prepdir"
  shift 1
  #local parsed=$(pref="local cliopt_" keys="$keys"  distr_params_keyval_all $*)
  local parsed=$(pref="" keys="$keys"  distr_params_keyval_all $*)
  eval "$parsed" # load params
  unset keys parsed
  distr_nodecfg_node_add_empty "$eid" 
  ret=$?
  if [ $ret == 0 ]; then
    cache_clear ALL
  fi
  dbg_echo distr 5 F "end"
  return $ret
}


distr_nodecfg_node_add_empty() {
# prepdir= instpath= template=  type=subnode|empty|addthis
  dbg_echo distr 10 F "*=$*"
  local new_nodeid="$1" hostid_exists
  shift 1
  #eval "$*"
  dbg_echo distr 10 F "instpath=$instpath template=$template" "prepdir=$prepdir"
  
  if [ "x$new_nodeid" == "x" ]; then
    echo "empty new_nodeid"
    exit
  fi
  dbg_echo distr 10 F "new_nodeid=${new_nodeid}"

  local _parsed=$(distr_parse_nodeid nodeid=$new_nodeid pref="new_")
  eval "local ${_parsed}"

  if [ "x$new_NODE_IDsuffix" == "x" ]; then
    # if new NODE_IDsuffix not set - use default
    new_NODE_IDsuffix="one"
  fi

  local new_nodeid="$new_NODE_USER@$new_NODE_HOST:$new_NODE_IDsuffix"
  local new_node_dirname="$new_NODE_USER@${new_NODE_HOST}_${new_NODE_IDsuffix}"

  if nodecfg_nodeid_exists "${new_nodeid}"; then
    distr_error "ERROR!"
    distr_error_echo "ERROR: nodecfg_nodeid_exists \"${new_nodeid}\" - node id already exists"
    return 1;
  fi
  if hostcfg_hostid_exists "${new_NODE_HOST}"; then
    echo "hostcfg_hostid_exists \"${new_NODE_HOST}\" - host id already exists"
    hostid_exists="1"
  fi

  echo "Creating \"$new_nodeid\" in $new_node_dirname"
  if [ -n "$prepdir" ]; then
    local outdir_new_entity=${prepdir}/${new_node_dirname}
  else
    local outdir_new_entity=${DGRID_dir_nodelocal}/distr/emptynode-new/cfg/${new_node_dirname}
  fi
  local new_node_instpath=${HOME}/${DGRID_dgridname}
  echo " outdir_new_entity=$outdir_new_entity"
  echo " new_node_instpath=$new_node_instpath"

  ####################### Creating ##########################
  dbg_echo distr 5 F "--- Creating node ---"

  local NODE_ID=${new_nodeid}
  local NODE_IDsuffix="${new_NODE_IDsuffix}"
  local NODE_UUID=`uuidgen`
  local NODE_HOST=$new_NODE_HOST
  local NODE_INSTPATH=$new_node_instpath
  local NODE_USER=$USER
  generic_listvars NODE_
  echo mkdir ${outdir_new_entity}
  mkdir -p ${outdir_new_entity}
  if [ -f ${outdir_new_entity}/this.nodeconf ]; then
    echo ABORT: this.nodeconf already exists.
    return 1
  fi
  generic_listvars NODE_ | tee ${outdir_new_entity}/this.nodeconf
  ##########
  echo "# " | tee -a ${outdir_new_entity}/this.nodeconf

  # templates
  if [ -n "$template" ]; then
    local td=$DISTR_nodes_templ/$template
    if [ -d $td ]; then
      dbg_echo distr 5 F "Template \"$template\" found"
      msg_echo distr 2 "Using template \"$template\""
      cp -ar $td/* ${outdir_new_entity}/
    fi
  fi

  # finalizing 
  cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/

  
  if [ ! x$hostid_exists == "x1" ]; then
    dbg_echo distr 6 F "hostid not exists, create new hostid"
    template="$hosttemplate" distr_hostcfg_empty_add $new_NODE_HOST
  fi
  return 0
}


############

distr_entitycfg_add_cli() {
  dbg_echo distr 5 F "start"
  local ret type_found=0 eid=$1 
  local keys="template register prepdir type"
  shift 1
  local parsed=$(pref="" keys="$keys"  distr_params_keyval_all $*)
  eval "$parsed" # load params
  unset keys parsed
  if [ x$DGRID_f_distribution == x1 ]; then
    echo "DGRID_f_distribution == 1, No distribution mode allowed"
    exit
  fi

  if [ x"$type" == x"node-this" ]; then
    if [ ! x$THIS_NODEID == "x" ]; then
      echo "Abort, THIS_NODEID already set."
      return 1
    fi
    distr_nodecfg_addthis
  fi
  
  if [ x"$type" == x"node-empty" ]; then
    unset type
    distr_nodecfg_node_add_empty "$eid"
    ret=$?
    type_found=1
  fi
  if [ "x$type" == x"node-subnode" ]; then
    unset type
    distr_nodecfg_subnode_add "$eid"
    ret=$?
    type_found=1
  fi
  if [ "x$type" == x"host-empty" ]; then
    unset type
    distr_hostcfg_empty_add "$eid"
    ret=$?
    type_found=1
  fi
  
  if [ ! "x$type_found" == "x1" ]; then
    echo "type=$type not found, exit"
    exit
  fi
  
  if [ $ret == 0 ]; then
    cache_clear ALL
  fi
  dbg_echo distr 5 F "end"
  return $ret
}




############## addthis ################

this_hostinfo() {
  #HOST_dnsname

  #if [ -x"$HOST_id" == x ]; then
  #HOST_id=
  #fi

  host_cfg_dir=$nodecfg_path/$HOST_id/
  #if [ -x"$HOST_dnsname" == x ]; then
  #HOST_dnsname=`hostname`
  #fi
  HOST_hostname=$(hostname)
  HOST_hostid=$(hostid)
  HOST_uuid=$(uuidgen)
}

this_node_idsuffix() {
  #echo -n "home1"
  echo -n "one"
}

this_nodeinfo() {
  #local NODE_HOST
  NODE_UUID=$(uuidgen)
  ##NODE_ID=stas@sh21:home1
  NODE_IDsuffix=$(this_node_idsuffix)
  #if [ -n "$HOST_dnsname" ]; then
  #NODE_HOST=${HOST_dnsname%%.*}
  #HOSTid=${HOST_dnsname%%.*}
  #fi

  if [ -n $DGRIDBASEDIR ]; then
    NODE_INSTPATH=$DGRIDBASEDIR
  fi
  NODE_USER=$USER
}


###################################################
# nodecfg edit
###################################################
distr_entitycfg_parse_path(){
  echo -n
}

distr_entitycfg_get_info(){
  local eid=$1 ret
  echo "eid=$eid"
  if nodecfg_nodeid_exists "${eid}"; then
    #v=`nodecfg_varid_from_nodeid ${eid}`
    eid_dir=`nodecfg_nodeid_cfgdir ${eid}`
    eid_file=`nodecfg_nodeid_cfgfile ${eid}`
    eid_type="node"
  fi
  if hostcfg_hostid_exists "${eid}"; then
    eid_dir=`hostcfg_hostid_cfgdir ${eid}`
    eid_file=`hostcfg_hostid_cfgfile ${eid}`
    eid_type="host"
  fi
  echo "eid_dir=$eid_dir eid_file=$eid_file  eid_type=$eid_type"
  return 0;
}

distr_entitycfg_set_cli() {
  dbg_echo distr 8 F "$*"
  distr_entitycfg_set $*
}

distr_entitycfg_set() {
  local p=$1 val=$2 p1 eid _params sedcmd
  dbg_echo distr 5 F "params p=$p val=$val"
  var=${p##*/}
  p=${p%/*}
  dbg_echo distr 5 F "params p=$p var=$var val=$val"
  eid=`generic_cut_param "/" 2 "$p"`  #eid=${p%*/*/}
  p=${p#*/*/}
  dbg_echo distr 5 F "params eid=$eid p=$p var=$var val=$val"
  echo ===========
  #  distr_entitycfg_parse_path $eid
  _params=`distr_entitycfg_get_info $eid`
  eval "local ${_params}"
  p="${eid_dir}/$p"
  dbg_echo distr 5 F "params eid=$eid p=$p var=$var val=$val"
  if [ ! -d $eid_dir ]; then
    echo "ABORT, no eid_dir ($eid_dir)"
    exit
  fi
  
  if [ ! -f $p ]; then
      dbg_echo distr 5 F "Not exists, run mkdir -p && touch $p"
      mkdir -p `dirname $p`
      touch $p
  fi
  ls $p
  if grep "^$var=" $p ; then
    _sedcmd="/^$var=/s/=.*/=$val/" 
    dbg_echo distr 5 F "Use sed -i ${_sedcmd}"
    sed -i ${_sedcmd} $p
  else
    dbg_echo distr 5 F "key/val pair not in file, adding"
    echo "$var=\"$val\"" >> $p
  fi
  
}
