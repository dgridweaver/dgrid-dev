#!/bin/bash


###################################################


###################################################

distr_nodecfg_addthis_cli() {
  #main_load_module_into_context nodecfg
  # hack just for install
  source "./main/nodecfg.bash"
   echo "ABORT, curently not working"
  # need to write code for 
  exit
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
  #local new_nodeid="$3"
  distr_hostcfg_empty_add "$3" "type=empty"
  cache_clear ALL
  dbg_echo distr 5 F "end"
}

distr_hostcfg_empty_add() { 
# htype= empty | this
 dbg_echo distr 10 F "start"
 local new_HOST_id="$1"
 shift 1
 eval "$*"
 dbg_echo distr 10 F "type=$type"
 if [[ $new_HOST_id =~ ^[A-Za-z0-9\-]+$ ]]; then
   echo "OK, new_HOST_id alphanum"
 else
   echo "ERROR, new_hostid ($new_hostid) must be alphanum"
   exit #return 1
 fi

  local new_entity_dirname="$new_HOST_id"
  local outdir_new_entity=${DGRID_dir_nodelocal}/distr/new-hostcfg/cfg/${new_entity_dirname}
  local outfile_new_entity=${new_HOST_id}.hostinfo
  
  ####################### Creating ##########################


  local HOST_id=$new_HOST_id
  local HOST_hostname=$new_HOST_id
  #local HOST_hostid=`hostid`
  local HOST_uuid=`uuidgen`

  dbg_echo distr 5 F "--- Creating host ---"
  generic_listvars HOST_

  if [ -f ${outdir_new_entity}/$outfile_new_entity ]; then
    echo ABORT: this.nodeconf already exists.
    return
  fi

  echo mkdir ${outdir_new_entity}
  mkdir -p ${outdir_new_entity}

  generic_listvars HOST_ | tee ${outdir_new_entity}/$outfile_new_entity
  echo "#HOST_dnsname=" | tee -a ${outdir_new_entity}/$outfile_new_entity
  echo "#HOST_hostid=" | tee -a ${outdir_new_entity}/$outfile_new_entity

  cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/

}

############

distr_nodecfg_subnode_add_cli() {
  echo "distr_nodecfg_subnode_add_cli()"
  #local new_nodeid="$3"
  distr_nodecfg_node_add "$3" type="subnode" 
  cache_clear ALL
}

distr_nodecfg_node_add() { # [API]
# type=subnode|empty|addthis
  dbg_echo distr 10 F "*=$*"
  local new_nodeid="$1" hostid_exists
  shift 1
  #
  #local type="subnode" 
  eval "$*"
  dbg_echo distr 10 F "type=$type"
  
  if [ "x$new_nodeid" == "x" ]; then
    echo "empty new_nodeid"
    exit
  fi
  if nodecfg_nodeid_exists "${new_nodeid}"; then
    echo "nodecfg_nodeid_exists "${new_nodeid}" - node id already exists"
    return 1;
  fi
  if hostcfg_hostid_exists "${HOST_id}"; then
    echo "hostcfg_hostid_exists "${HOST_id}" - host id already exists"
    hostid_exists="1"
  fi

  if [ x$DGRID_f_distribution == x1 ]; then
    echo "DGRID_f_distribution == 1, No distribution mode allowed"
    exit
  fi
  if [ x$THIS_NODEID == "x" ]; then
    echo "Abort, no THIS_NODEID."
    exit
  fi

  nodecfg_nodeid_load $THIS_NODEID this_
  dbg_echo distr 10 F "this_NODE_HOST=$this_NODE_HOST"
  dbg_echo distr 10 F "this_HOST_id=$this_HOST_id"
  
  if [ x$this_HOST_id == "x" ]; then
    echo "Abort, no HOST_id"
    exit
  fi

  local _parsed=$(distr_parse_nodeid nodeid=$new_nodeid pref="new_")
  eval "local ${_parsed}"
  generic_listvars new_

  # CHECKS for type=SUBNODE
  if [ ! x$this_NODE_USER == "x$new_NODE_USER" -a "x$type" == x"subnode" ]; then
    echo "ABORT x\$this_NODE_USER == x\$new_NODE_USER"
    return 
  fi
  if [ ! x$this_HOST_id == "x$new_NODE_HOST" ]; then
    echo "xthis_HOST_id != xnew_NODE_HOST" 
    return
  fi


  local new_nodeid="$this_NODE_USER@$this_HOST_id:$new_node_suffix"
  local new_node_dirname="$this_NODE_USER@${this_HOST_id}_${new_node_suffix}"
  echo "Creating \"$new_nodeid\" in $new_node_dirname"
  
  local outdir_new_entity=${DGRID_dir_nodelocal}/distr/subnode-new/cfg/${new_node_dirname}
  echo " outdir_new_entity=$outdir_new_entity"
  
  local new_node_instpath=${DGRIDBASEDIR}/${DGRID_localdir}/subnode-$new_node_suffix
  echo "new_node_instpath=$new_node_instpath"
  # xxx = ${outdir_new_entity}/this.nodeconf
  ####################### Creating ##########################
  dbg_echo distr 5 F "--- Creating node ---"

  local NODE_ID=${new_nodeid}
  local NODE_IDsuffix="${this_NODE_IDsuffix}_${new_node_suffix}"
  local NODE_UUID=`uuidgen`
  local NODE_HOST=$this_NODE_HOST
  local NODE_INSTPATH=$new_node_instpath
  #${DGRIDBASEDIR}/${DGRID_dir_nodelocal}/subnode-$new_node_suffix
  local NODE_USER=$USER
  #generic_listvars NODE_
  
  echo mkdir $new_node_instpath
  mkdir -p ${new_node_instpath}
  echo mkdir ${outdir_new_entity}
  mkdir -p ${outdir_new_entity}
  if [ -f ${outdir_new_entity}/this.nodeconf ]; then
    echo ABORT: this.nodeconf already exists.
    return
  fi
  generic_listvars NODE_ | tee ${outdir_new_entity}/this.nodeconf
  
  cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/
  
  pushd $new_node_instpath > /dev/null
  ln -s ../../dgrid ./
  ln -s ../../dgrid-site ./
  ln -s ../../${dgrid_bynodes_dir}/ ./
  popd > /dev/null
  return
}

distr_nodecfg_empty_add_cli() {
  echo "distr_empty_cfg_empty_add_cli()"
  distr_nodecfg_node_add_empty__ "$3" type="empty" 
  cache_clear ALL
}


distr_nodecfg_node_add_empty__() {
# type=subnode|empty|addthis
  dbg_echo distr 10 F "*=$*"
  local new_nodeid="$1" hostid_exists
  shift 1
  eval "$*"
  dbg_echo distr 10 F "type=$type new_node_instpath=$new_node_instpath"
  
  if [ "x$new_nodeid" == "x" ]; then
    echo "empty new_nodeid"
    exit
  fi
  dbg_echo distr 10 F "new_nodeid=${new_nodeid}"
  
  if nodecfg_nodeid_exists "${new_nodeid}"; then
    echo "nodecfg_nodeid_exists \"${new_nodeid}\" - node id already exists"
    return;
  fi

  local _parsed=$(distr_parse_nodeid nodeid=$new_nodeid pref="new_")
  eval "local ${_parsed}"

  if hostcfg_hostid_exists "${new_NODE_HOST}"; then
    echo "hostcfg_hostid_exists \"${new_NODE_HOST}\" - host id already exists"
    hostid_exists="1"
  fi

  local new_nodeid="$new_NODE_USER@$new_NODE_HOST:$new_node_suffix"
  local new_node_dirname="$new_NODE_USER@${new_NODE_HOST}_${new_node_suffix}"

  echo "Creating \"$new_nodeid\" in $new_node_dirname"
  
  local outdir_new_entity=${DGRID_dir_nodelocal}/distr/subnode-new/cfg/${new_node_dirname}
  
  local new_node_instpath=${HOME}/${DGRID_dgridname}
  #${DGRIDBASEDIR}/${DGRID_localdir}/subnode-$new_node_suffix
  echo " outdir_new_entity=$outdir_new_entity"
  echo " new_node_instpath=$new_node_instpath"

  ####################### Creating ##########################
  dbg_echo distr 5 F "--- Creating node ---"

  local NODE_ID=${new_nodeid}
  local NODE_IDsuffix="${new_node_suffix}"
  local NODE_UUID=`uuidgen`
  local NODE_HOST=$new_NODE_HOST
  local NODE_INSTPATH=$new_node_instpath
  local NODE_USER=$USER
  generic_listvars NODE_
  echo mkdir ${outdir_new_entity}
  mkdir -p ${outdir_new_entity}
  if [ -f ${outdir_new_entity}/this.nodeconf ]; then
    echo ABORT: this.nodeconf already exists.
    return
  fi
  generic_listvars NODE_ | tee ${outdir_new_entity}/this.nodeconf
  ##########
  echo "# " | tee -a ${outdir_new_entity}/this.nodeconf
  cp -a ${outdir_new_entity} ./${dgrid_bynodes_dir}/
  
  if [ ! x$hostid_exists == "x1" ]; then
    dbg_echo distr 6 F "hostid not exists, create new hostid"
    distr_hostcfg_empty_add $new_NODE_HOST
  fi
}

distr_parse_nodeid() # [API]
{
  # USAGE: distr_parsenodestr nodeid=aaa@bbb:ttt [pref=xxx]
  dbg_echo distr 15 F "*=$*"
  local nodeid="" pref=""
  eval "local $*"
  #local nodestr=$1 pref=$2

  local n_user _rest n_host n_path
  n_user=`echo $nodeid|cut -f1 -d\@`
  _rest=`echo $nodeid|cut -f2 -d@`
  n_host=`echo ${_rest}|cut -f1 -d:`
  n_suffix=`echo ${_rest}|cut -f2 -d:`
  echo "${pref}NODE_USER=${n_user} ${pref}NODE_HOST=$n_host ${pref}node_suffix=$n_suffix"
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
    eid_file=`hostcfg_hostid_cfgfilwe ${eid}`
    eid_type="host"
  fi
  echo "eid_dir=$eid_dir eid_file=$eid_file  eid_type=$eid_type"
  return 0;
}


distr_entitycfg_set_cli() {
  dbg_echo distr 8 F "$*"
  shift 2
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
