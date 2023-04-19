#!/bin/bash

if [ x$MODINFO_loaded_mininode == "x" ]; then export MODINFO_loaded_mininode="Y"; else return; fi

MODINFO_msg_mininode=3
MININODE_types="mini tiny"


#source ${MODINFO_modpath_mininode}/mininode.defaultvalues
source ${MODINFO_modpath_mininode}/mininode_f.bash

export mininode_CLIMENU_CMDS_LIST="mininode_build mininode_info"
mininode_climenu_cmd_mininode_build(){ mininode_build_cli $@; }
mininode_climenu_cmd_mininode_info(){ mininode_info_cli $@; }

###########

mininode_info_cli() {
  dbg_echo mininode 5 F "Begin: $*"
  local nodeid=$1 ; shift 1;  local params=$*
  local f list

  nodecfg_nodeid_not_exists $nodeid && msg_echo 1 "No such nodeid, exit" && exit
  nodecfg_nodeid_load $nodeid bld_
  cfgstack_load_byid "etc/mininode.conf" ${nodeid}
  generic_listvars MININODE_
  generic_listvars bld_ | sed s/bld_//
  #msg_echo mininode 1 "Some message"
}


_mininode_filtercfg() {
  local s p0 p1
  while read s; do
    p0=$(generic_cut_param " " 1 "$s")
    p1=${s#$p0}
    if [ -z "$p0" ]; then continue; fi
    if [[ ! "$p0" =~ ^[[:alnum:]_]+$  ]]; then continue; fi
    dbg_echo mininode 4 F "build cfg: ${prefix}$p0 $p1"
    echo "${prefix}$p0 $p1"
  done
}

mininode__copy_filelist_tar(){
  local ifile=$1 odir=$2
  dbg_echo mininode 4 F "src_file=$ifile dst_dir=$odir"
  [ -z "$ifile" ] && distr_error "ERROR, src file \"\"" && return;
  [ ! -d "$odir" ] && distr_error "ERROR, dst dir not exists" && return;
  tar -c -T $ifile | tar -f - -x -C $odir
}

mininode_get_build_result_dir(){
  local NODE_ID=$1
  local mininode_dir=$DGRID_dir_nodelocal/mininode
  echo -n $mininode_dir/out/`nodecfg_varid_from_nodeid $NODE_ID`
}

mininode_build_cli() {
  dbg_echo mininode 4 F "pwd="$(pwd)
  local nodeid=$1 ; shift 1;  local params=$*; local filelist="" var
  local mininode_wdir=$DGRID_dir_nodelocal/mininode/wdir
  local mininode_dir=$DGRID_dir_nodelocal/mininode/
  mkdir -p $mininode_wdir

  nodecfg_nodeid_not_exists $nodeid && msg_echo mininode 1 "No such nodeid, exit" && exit
  nodecfg_nodeid_load $nodeid

  dbg_echo mininode 4 NODE_type=$NODE_type 
  generic_word_in_list "$NODE_type" $MININODE_types || ( msg_echo mininode 1 "NODE_type must be \"mini\" or other,exit" && exit )
  
  local mininode_buildroot=$mininode_dir/buildroot/`nodecfg_varid_from_nodeid $NODE_ID`/
  mkdir -p $mininode_buildroot
  local mininode_outdir=$mininode_dir/out/`nodecfg_varid_from_nodeid $NODE_ID`/
  mkdir -p $mininode_outdir
   
  dbg_echo mininode 4 "... build $nodeid"
  list=`cfgstack_load_byid etc/mininode.conf ${nodeid} op=filenames`
  dbg_echo mininode 4 "list=$list"
  IFS=$'\n'
  for f in $list; do
    IFS=' '
    dbg_echo mininode 6 "load build script f=$f"
    var=$( cat $f | prefix="mininode_f_" _mininode_filtercfg )
    eval $var
  done
  echo ------------------
  generic_listvars mininode_bv_
  echo ------------------
 
  mininode_filelist_get  | sort | uniq > $mininode_wdir/list #|tee $mininode_wdir/list
  echo mininode_buildroot=$mininode_buildroot
  #ls -a $mininode_buildroot

  msg_echo mininode 2 "DO: tar copy \$mininode_wdir/list to \$mininode_buildroot"
  tar -c -T $mininode_wdir/list | tar -f - -x -C $mininode_buildroot
  
  mininode_op_dgrid_site_full
  mininode_op_force_THIS_NODEID
  mininode_op_this_enityid_configs
  
  msg_echo mininode 2 "DO: Write result in \$mininode_outdir/"
  cp -ar $mininode_buildroot/* $mininode_outdir/
  #$mininode_buildroot/current_node.tar
}

mininode_filelist_get(){
  local mod modpath v cmd
  mininode_cmd="list"
  for mod in $mininode_bv_all_mods ; do
    v=MODINFO_modpath_$mod
    modpath=${!v}
      dbg_echo mininode 4 8 mod=$mod modpath=$modpath
    mininode_mod_filelist $mod | sed "s#./#$modpath/#"
  done
}
mininode_mod_filelist(){
  local pp f
  f="mininode_modf_list_$mod"
  dbg_echo mininode 8 $modpath $mod
  if is_function_exists $f ; then
    eval $f
    return
  fi
  f=${mod}_mininode_mod
  if is_function_exists $f ; then
    eval $f $mininode_cmd
    return
  fi
  echo "./libdgrid.sh"
  pushd $modpath > /dev/null
  dbg_echo mininode 10 pwd=`pwd`
  find ./ |grep ^./$mod
  popd > /dev/null
}



##########

_mininode_list_hlpr(){
  if generic_word_in_list "$NODE_type" $MININODE_types ; then
    printf "%10s %8s\n"  $NODE_ID $NODE_type
  fi
}

mininode_list_cli(){
  nodecfg_iterate_nodeid _mininode_list_hlpr
}

############ cli integration  ################

mininode_cli_help() {
  dgridsys_s; echo "mininode build <id> - build node install from this node"
  dgridsys_s; echo "mininode info <id> - mininode settings info"
}

mininode_cli_run() {
  local maincmd=$1 cmd=$2 name=$3

  dbg_echo mininode 5 x${maincmd} == x"mininode"
  if [ ! x${maincmd} == x"mininode" ]; then return; fi

  if [ x${cmd} == x"" ]; then
    mininode_cli_help
  fi

  if [ x${cmd} == x"build" ]; then
    shift 2
    mininode_build_cli $*
  fi

  if [ x${cmd} == x"info" ]; then
    shift 2
    mininode_info_cli $*
  fi

  if [ x${cmd} == x"list" ]; then
    shift 2
    mininode_list_cli $*
  fi


}
