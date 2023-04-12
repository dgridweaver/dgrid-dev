#!/bin/bash

if [ x$MODINFO_loaded_distr == "x" ]; then
  export MODINFO_loaded_distr="Y"
else
  return
fi

source ${MODINFO_modpath_distr}/distr_nodecfg.bash

################################
# generic function in distr
################################

#generic_echo(){
#  local var="$1";printf %s\\n "$var";}

distr_error(){
  echo -n `pwd`"/${BASH_SOURCE[1]} "": " 1>&2
  echo -n "${FUNCNAME[1]}() : " 1>&2
  echo -n $* 1>&2
  echo
}
distr_error_echo(){
  echo -n $* 1>&2
  echo
}

generic_remove_word_from_list() { # [API]
  set -f
  IFS=' '
  local s=$2 w=$1 arg

  set -- $s
  shift 1
  for arg do
    shift
    [ "$arg" = "$w" ] && continue
    set -- "$@" "$arg"
  done
  printf '%s\n' "$*"
}


generic_word_prefix() { # [API]
  local p=$1
  shift 1
  for i in $*; do
    echo -n ${p}${i} " "
  done
}

_distr_mkdir() {
  # mkdir_init
  echo "create $1"
  mkdir -p ./$1
  touch ./$1/.keep_me
}

distr_entityid_cfgdir() { # [API] [RECOMENDED]
  local vv v _hostid=$1
  vv=$(nodecfg_varid_from_nodeid ${_hostid})
  v=NODECFG_hostid_cfgdir_${vv}
  if [ -n "${!v}" ]; then echo -n ${!v}; return 0; fi
  v=NODECFG_cfgdir_${vv}
  #echo NODECFG_nodeid_cfgdir_${vv}
  if [ -n "${!v}" ]; then
    echo -n ${!v}
    return 0
  fi
  return 1
}


# use pref="local " run_is_entityid ENTITY_ID
distr_is_entityid() # [API]
{
  local eid=$1
  if nodecfg_nodeid_exists "$eid"; then
    echo "${pref}eid_type=nodeid"
    return 0
  fi
  if hostcfg_hostid_exists "$eid"; then
    echo "${pref}eid_type=hostid"
    return 0
  fi
  echo "${pref}eid_type=NONE"
  return 1
}
distr_is_not_entityid() # [API]
{
  if run_is_entityid $1; then
    return 1
  else
    return 0
  fi
}

distr_is_module_name() { # API
  local var=MODINFO_modpath_$1
  if [ -n "${!var}" ]; then return 0; else return 1; fi
}

distr_is_not_module_name() { # API
  if distr_is_module_name $1; then return 1; else return 0; fi
}


distr_params_keyval_all() # [API] usage: pref="local " distr_params_keyval_all
{
  # 
  local p p0 p1
  for p in $*; do
    p0=$(generic_cut_param "=" 1 "$p")
    p1=$(generic_cut_param "=" 2 "$p")
    if [ -z "$p0" ]; then continue; fi
    if [ -z "$p1" ]; then continue; fi
    if [[ ! "$p0" =~ ^[[:alnum:]_]+$  ]]; then continue; fi
    local r="\"\'\`"
    if [[ "$p1" =~ $r  ]]; then continue; fi
    if [ -n "$keys" ]; then
      if generic_word_in_list $p0 $keys; then
        echo "${pref}${p0}=\"$p1\";"
      fi
    else
      echo "${pref}${p0}=\"$p1\";"
    fi
  done
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
    [ -n "${!v}" ] && vl="$vl $v=\"${!v}\" "
  done
  dbg_echo distr 5 F RUN env -i $vl $bash_cmd -c $cmds
  env -i $vl $bash_cmd -c "$cmds"
}


################################
# empty node creation
################################


distr__en_create_dirs() {
  mkdir -p ./dgrid-site/
  _distr_mkdir dgrid-site/bin
  _distr_mkdir dgrid-site/modules
  _distr_mkdir dgrid-site/etc
  _distr_mkdir dgrid-site/etc/modules
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


#############   runtime ###########################

distr_cli_runtime_which() {
  dbg_echo distr 5 F "*=$*"
  runtime_which $*
}

distr_cli_runtime_query() {
  dbg_echo distr 5 F "*=$*"
  distr_runtime_query $*
}

distr_cli_runtime_list() {
  dbg_echo distr 5 F "*=$*"
  distr_runtime_list $*
}

__distr_runtime_dir_list_found() {
  local r_id
  mdirs=$DGRID_RUNTIME_DIRS
  mdirs=${mdirs/NODEDIR/$DGRIDBASEDIR}
  mdirs=${mdirs/DISTDIR/$DGRIDDISTDIR}
  mdirs=${mdirs/HOME/$HOME}
  dbg_echo runtime 8 "expanded: DGRID_RUNTIME_DIRS=$mdirs"
  tIFS="$IFS"; IFS=":"
  dbg_echo runtime 8  "------------"
  for rtd in $mdirs; do
    IFS="$tIFS"
    if [ ! -d "$rtd" ]; then dbg_echo distr 8 F "\"$rtd\" dir not exists."; continue; fi
    #echo bbbb=`ls $rtd`" "
    tIFS="$IFS"; IFS=" "
    echo `ls -1 $rtd`" " | while read -r s; do 
      rtdir1=$rtd/${s}
      # check
      if [ -n "`ls $rtdir1`"  ]; then 
        r_id=$(generic_cut_param "-" 1 "$s")
        r_arch=$(generic_cut_param "-" 2 "$s")
        echo -n "r_id=${r_id} r_dirname=$s r_fulldir=\"$rtdir1\" r_arch=\"$r_arch\""
        echo
      fi
    done
    IFS="$tIFS"
  done 
}


distr_runtime_list_configured(){ # [API]
  local s s1 s2 v
  generic_listvars RUNTIME_rt_| while read s; do
    s=$(generic_cut_param "=" 1 $s)
    if [[ "$s" == "RUNTIME_rt_"*"_name" ]]; then
      v=${!s}
      echo -n $v" "
    fi
  done
}

__distr_runtime_dir_list_configued()
{
  local r_id
  for r_id in $(distr_runtime_list_configured) ; do
    echo "r_id=$r_id r_cfg=1"
  done
}

distr_runtime_list() {
  dbg_echo distr 5 F "*=$*"
  local mdirs rtd rdlist s runtime_list_configured list1 var vvv
  
  runtime_list_configured=$(distr_runtime_list_configured)
  dbg_echo runtime 5 F DGRID_RUNTIME_DIRS=$DGRID_RUNTIME_DIRS
  dbg_echo runtime 5 F runtime_list_configured=$runtime_list_configured
  list1=$runtime_list_configured

  ( __distr_runtime_dir_list_found; __distr_runtime_dir_list_configued  )| \
  while read var; do
    unset r_id r_dirname r_arch
    eval "local $var"
    vvv=flag_${r_id}
    if [ x${!vvv} == x1 ]; then continue; fi
    if [ x${r_arch} == x ]; then r_arch=" - "; fi
    if generic_word_in_list $r_id $runtime_list_configured;  then
      printf "%12s | %7s | %9s | %8s\n" $r_id "$r_arch" "CONFIGURED" "$r_dirname"
      list1=$(generic_remove_word_from_list $r_id $list1)
    else
      printf "%12s | %7s | %9s | %8s\n" $r_id "$r_arch" "NOT_CONF" $r_dirname
    fi
    local flag_${r_id}=1
  done
}

distr_runtime_list_detected() {
  dbg_echo distr 5 F "*=$*"

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

distr_vars_simple(){
  #set|grep ^DGRID
  generic_listvars DGRID
  generic_listvars GRID
  generic_listvars MODINFO_
  generic_listvars MODULE_
  generic_listvars RUNTIME_
  generic_listvars mods_
  generic_listvars NODECFG_
}


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
  echo "${pref}module-list  - list enabled modules"
  echo "${pref}runtime-list  - list installed runtimes"
  echo "${pref}runtime-which   - \"which\" in runtimes"
  echo "${pref}runtime-query   - query cmd in runtimes"
  echo "${pref}nodecfg-addthis   - call function to create node config (in subdir)"
  echo "${pref}hostcfg-empty-add [new-host-id] - create empty host (config, in subdir)"
  echo "${pref}nodecfg-empty-add [new-node-id] - create empty node (config, in subdir)"
  echo "${pref}nodecfg-subnode-add - add subnode of THIS_... node"
  echo "${pref}entitycfg-set  - set param in file"
  echo "${pref}entitycfg-add [new-id] - add nodeid/hostid"
}

distr_cli_run() {
  local maincmd=$1 cmd=$2 name=$3
  shift 2
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



  if [ x${cmd} == x"status" ]; then distr_cli_status_long; return $?; fi
  if [ x${cmd} == x"cmds-check" ]; then distr_cli_cmds_check; return $?; fi
  if [ x${cmd} == x"module-list" ]; then distr_cli_modlist; return $?; fi
  if [ x${cmd} == x"vars" ]; then distr_cli_vars; return $?; fi
  if [ x${cmd} == x"runtime-list" ]; then distr_cli_runtime_list $params; return $?; fi
  if [ x${cmd} == x"runtime-which" ]; then distr_cli_runtime_which $params; return $?; fi
  if [ x${cmd} == x"runtime-query" ]; then distr_cli_runtime_query $params; return $?; fi
  if [ x${cmd} == x"nodecfg-addthis" ]; then distr_nodecfg_addthis_cli $params; return $?; fi
  if [ x${cmd} == x"nodecfg-subnode-add" ]; then distr_nodecfg_subnode_add_cli $params; return $?; fi
  if [ x${cmd} == x"nodecfg-empty-add" ]; then distr_nodecfg_empty_add_cli $params; return $?; fi
  if [ x${cmd} == x"hostcfg-empty-add" ]; then distr_hostcfg_empty_add_cli $params; return $?; fi  
  if [ x${cmd} == x"entitycfg-set" ]; then distr_entitycfg_set_cli $params; return $?; fi
  if [ x${cmd} == x"entitycfg-add" ]; then distr_entitycfg_add_cli $params; return $?; fi

  if [ ! x${cmd} == x"" ]; then
      echo "ERROR! - distr module do not have \"$cmd\" subcommand"
      return 1
  fi


  if [ x${cmd} == x"" ]; then
    echo -n
    
    if [ x${maincmd} == x"distr-cmd"  ]; then
      echo "---------- help -----------"
      distr_cli_status
      distr_cli_help_do "   "
    else
      distr_cli_help_do "      distr "
    fi
    return 1
  fi
  
}
