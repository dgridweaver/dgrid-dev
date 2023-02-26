#!/bin/bash

if [ x$MODINFO_loaded_distr == "x" ]; then
  export MODINFO_loaded_distr="Y"
else
  return
fi

################################
# empty node creation
################################

_distr_mkdir() {
  # mkdir_init
  echo "create $1"
  mkdir -p ./$1
  touch ./$1/.keep_me
}

distr__en_create_dirs() {
  mkdir -p ./dgrid-site/
  _distr_mkdir dgrid-site/bin
  _distr_mkdir dgrid-site/modules
  _distr_mkdir dgrid-site/etc
  _distr_mkdir dgrid-site/etc/modules
}

################################
# support functions
################################

distr_run_bash_clean() {
  local bash_cmd="bash -l"
  local oifs v vl
  local vars="$1"
  shift 1
  local cmds="$*"
  oifs=$IFS
  export IFS=","
  for v in $vars; do
    export IFS="$oifs"
    vl="$vl $v=\"${!v}\" "
  done
  echo RUN env -i $vl $bash_cmd $cmds 1>&2
  env -i $vl $bash_cmd $cmds
}

################################

distr_cli_vars() {
  generic_listvars MODINFO
}

distr_cli_cmds_check() {
  local cchk="pip3 ls python bb"
  echo "RUNTIME_default_list=$RUNTIME_default_list"
  distr_cmds_list_check $cchk
}

distr_cmds_list_check() {
  local cchk=$*
  local v1 v2
  local v3=$(runtime_rt_vars)
  local rt_vars=$(generic_word_prefix runtime_rt_v_ $v3)
  local $rt_vars

  for i in ${cchk}; do
    #echo -----------------------------
    v1=$(distr_runtime_query $i)
    eval $v1
    unset v1
    #echo aAAA runtime_rt_v_name=$runtime_rt_v_name
    echo -n "$i : "
    if [ "x$runtime_rt_id" == "x" ]; then
      echo -n "NOT_FOUND"
    else
      echo -n " $runtime_rt_id"
    fi
    echo
    #generic_listvars runtime_rt

    unset $rt_vars
  done
}

distr_var_print_simple() {
  local v=$1
  echo "$v=${!v}"
}

distr_cli_status() {
  echo -n
  echo "---------- status short -------------"
  distr_var_print_simple DGRID_f_loadconfigs
  echo MODINFO_files_distr_enabled=$MODINFO_files_distr_enabled
  echo DGRID_f_distribution=$DGRID_f_distribution
  distr_var_print_simple DGRID_f_allow_no_thisnode
  distr_var_print_simple THIS_NODEID
}
distr_cli_status_long() {
  distr_cli_status
  echo "---------- status long () -------------"
  if [ x$DGRID_f_loadconfigs == x"loadconfigs.sh" ]; then
    echo "loadconfigs.sh : code path for \"node mode\" (default, not distr mode)"
  fi
  if [ x$DGRID_f_loadconfigs == x"loadconfigs1.sh" ]; then
    echo "loadconfigs1.sh :  code path for distribution[!] mode"
  fi
  if [ x$DGRID_f_distribution == x1 ]; then
    echo "DGRID_f_distribution flag set. Working in \"distribution mode\""
  else
    echo "DGRID_f_distribution flag not set."
  fi
  if [ x"$THIS_NODEID" == x ]; then
    echo "This node ID not detected. (THIS_NODEID ==\"\")"
  else
      echo "This node ID (THIS_NODEID ==\"$THIS_NODEID\")"
  fi

}
distr_cli_modlist() {
  local s
  for s in $MODULE_list_enabled; do
    echo $s
  done
}
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

  #hostcfg_hostid_exists "${HOST_id}"
  #ret=$? #echo "hostid=${HOST_id}  ret=$ret"
  #if [ "x$ret" == "x0"  ];  then
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



#############   runtime ###########################

distr_cli_runtime_which() {
  shift 2
  dbg_echo distr 5 F "*=$*"
  runtime_which $*
}

distr_cli_runtime_query() {
  shift 2
  dbg_echo distr 5 F "*=$*"
  distr_runtime_query $*
}

#generic_echo(){
#  local var="$1";printf %s\\n "$var";}

generic_word_prefix() {
  local p=$1
  shift 1
  for i in $*; do
    echo -n ${p}${i} " "
  done
}

distr_runtime_query() {
  local v v2 out1
  local runtime_cmd runtime_rt_id

  dbg_echo distr 5 F "*=$*"
  v=$(runtime_query $*)
  eval $v
  echo "runtime_cmd=\"$runtime_cmd\""
  echo "runtime_rt_id=\"$runtime_rt_id\""
  if [ "x${runtime_rt_id}" == "x" ]; then return 1; fi
  v2="RUNTIME_rt_${runtime_rt_id}"
  generic_listvars RUNTIME_rt_${runtime_rt_id} | while read s; do
    # change variable names only, not content
    out1=$(generic_cut_param "=" 1 "$s") #echo "out1=[[[$out1]]]"
    echo -n ${out1/$v2/runtime_rt_v}
    echo -n "="
    generic_cut_param "=" 2 "$s"
    echo
  done
  #exit
}

################  interface ###################

distr_cli_main() {
  dbg_echo distr 5 F Start
  distr_cli_run distr-cmd $*
}


distr_cli_help() {
distr_cli_help_do "     distr "
}

distr_cli_help_do() {
  local pref=$1
  echo -n  
  echo "${pref}status - show this installation status"
  echo "${pref}cmds-check   - check/show cmd path"
  echo "${pref}vars   - show system variables"
  echo "${pref}module-list   - show system variables"
  echo "${pref}runtime-which   - \"which\" in runtimes"
  echo "${pref}runtime-query   - query cmd in runtimes"
  echo "${pref}nodecfg-addthis   - call function to create node config (in subdir)"
  #echo "  module-list   - "
}

distr_cli_run() {
  local maincmd=$1 cmd=$2 name=$3
  local params="$*"

  dbg_echo distr 5 x${maincmd} == x"distr"
  if [ x${maincmd} == x"distr" -o x${maincmd} == x"distr-cmd"  ]; then
    echo -n
  else
    return
  fi

#### "prefix" #####
  local a b
  if [ "x$DGRID_dir_nodelocal" == "x" ]; then
    dbg_echo distr 5 "DGRID_dir_nodelocal not defined, try to set up"
    a=`dirname $DGRIDBASEDIR`; b=`basename $DGRIDBASEDIR`
    DGRID_dir_nodelocal="$a/${b}--local-dir"
    #mkdir -p $DGRID_dir_nodelocal
  fi
  unset a b

###################



  if [ x${cmd} == x"status" ]; then distr_cli_status_long; fi
  if [ x${cmd} == x"cmds-check" ]; then distr_cli_cmds_check; fi
  if [ x${cmd} == x"module-list" ]; then distr_cli_modlist; fi
  if [ x${cmd} == x"vars" ]; then distr_cli_vars; fi
  if [ x${cmd} == x"runtime-which" ]; then distr_cli_runtime_which $params; fi
  if [ x${cmd} == x"runtime-query" ]; then distr_cli_runtime_query $params; fi
  if [ x${cmd} == x"nodecfg-addthis" ]; then distr_nodecfg_addthis_cli $params; fi
  if [ x${cmd} == x"" ]; then
    echo -n
    
    if [ x${maincmd} == x"distr-cmd"  ]; then
      echo "---------- help -----------"
      distr_cli_status
      distr_cli_help_do "   "
    else
      echo aaa
      distr_cli_help_do "      distr "
    fi
    
  fi

}
