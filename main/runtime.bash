#!/bin/bash
# (C)opyright 2022 deltagrid/dgrid project.
#
# main.bash : runtime.bash is a part of main module.
#

#####################################





#####################################

#runtime_check_bin(){
#local b=$1
#}

runtime_rt_vars()
{
# 
echo bin dir dirrel ldpreload name pip python 
}


lib_runtime_explode_path() {
  local iii=$IFS i
  local p1=$1 add=$2
  IFS=:
  for a in $add; do
    echo -n ":$p1/$a"
  done
  IFS=$iii
}


runtime_which() {
local p; params="p_rt_do=which "
lib_runtime_run_do_ "$params" $*
}

lib_runtime_run() {
local p; params="p_rt_do=run "
lib_runtime_run_do_ "$params" $*
}

runtime_query() {
local p; params="p_rt_do=query "
lib_runtime_run_do_ "$params" $*
}

#lib_runtime_isvar_eq_1

lib_runtime_run_do_() {
  local v p rt rrt tIFS gcmd g_cmd g_rt
  local params=$1
  local c=$2 s
  shift 2
  eval $params
  #echo "p_rt_do=$p_rt_do"
  rrt=$runtime_run_runtime
  if [ "x$rrt" == "x" ]; then
    rrt=$RUNTIME_default_list
  fi
  dbg_echo runtime 5 F "cmd c=\"$c\""
  dbg_echo runtime 5 F "check runtimes: \"$rrt\""
  tIFS="$IFS"; IFS=":"
  for rt in $rrt; do
    IFS=$tIFS
    dbg_echo runtime 10 F "rt=$rt c=$c"
    if lib_runtime_rt_isnot_defined $rt; then
      dbg_echo runtime 5 F "No rt=$rt loaded"
    else
      params="$params p_rt=$rt p_cmd=$c"
      dbg_echo runtime 10 F "_lib_runtime_getcmd_simple \"$params\""
      gcmd=`_lib_runtime_getcmd_simple "$params"`
      if [ "x$gcmd" == "x" ]; then
        dbg_echo runtime 10 F "cmd not found in rt=${rt}"
      else
        g_cmd=$gcmd
        g_rt=$rt
        break
      fi
      #_lib_runtime_getcmd_path  "$params" $*
      #return
    fi
  done
  dbg_echo runtime 2 F "g_cmd=$g_cmd"
  dbg_echo runtime 2 F "g_rt=$g_rt"
  if [ "x$p_rt_do" == x"query" ]; then
    echo "runtime_cmd=$g_cmd"
    echo "runtime_rt_id=$g_rt"
    #generic_listvars RUNTIME_rt_$g_rt | while read s; 
    #do echo ${s/RUNTIME_rt_$g_rt/runtime_rt_v}; #done
    return
  fi
  if [ "x$p_rt_do" == x"which" ]; then
    echo "$g_cmd"
    return
  fi
  if [ "x$p_rt_do" == x"run" ]; then
    echo "exec: $g_cmd $*"
    return
  fi
  dbg_echo runtime 2 F "command not found in runtimes"
}


_lib_runtime_getcmd_simple() {
  local p ccmd1
  eval $1 1> /dev/null
  shift 1
  #generic_listvars "p_"
  v=RUNTIME_rt_${p_rt}_dir
  dbg_echo runtime 8 F "v=$v"
  p=${!v}
  dbg_echo runtime 8 F "p=$p"
  if [ "x$p" == "x" ]; then dbg_echo runtime 1 "runtime=${p_rt} dir var empty"; return; fi
  ccmd1=$p/bin/$p_cmd
  ccmd1=${ccmd1/\/\///}
  dbg_echo runtime 5 F "check f=$ccmd1"
  if [ -x $ccmd1 ]; then
    echo "$ccmd1"
  fi
}

_lib_runtime_getcmd_path() {
  local p p1 c rt
  local spath=$PATH
  eval $*
  v=RUNTIME_rt_${rt}_dir
  p=${!v}
  echo "p=$p"
  p1=$p/bin/
  #ccmd1=${ccmd1/\/\///}

  PATH=$p1
  if command -v $c ; then
    echo "$c ok"
  else
    echo "$c not found"
  fi
}

lib_runtime_runcmd_all1() {
  local rr ccmd
  local c=$1
  local iii=$IFS
  IFS=":"
  for rr in ${DGRID_PATH_rt}; do
    #DGRID_PATH_rt
    ccmd=$rr/bin/$c
    if [ -x $ccmd ]; then
      echo exec $ccmd
      return
    fi
  done
  echo "No cmd $c found in runtimes"
  return 5
  IFS=$iii
}

###############################

lib_runtime_getvar()
{ 
  local v p 
  local rt=$1
  v=RUNTIME_rt_${rt}_dir; p=${!v}; 
  dbg_echo runtime 12 F "$v = $p"
  echo $v
}

lib_runtime_isvar_eq_1()
{ 
  local v p rt=$1
  v=`lib_runtime_getvar $rt`
  if [ x$v == x1  ]; then
    return 0
  else
    return 1
  fi
}


lib_runtime_rt_isnot_defined() {
  local v
  local rt=$1
  v=RUNTIME_rt_${rt}_name
  ##echo v=$v = ${!v}
  if [ x${!v} == x${rt} ]; then
    return 1
  else
    return 0
  fi
}
#
# 
#
lib_runtime_load_rt() {
  local tpath v
  local rt=$1
  if [ x$rt = "x" ]; then
    echo "lib_runtime_add_rt() error, runtime should be set"
    exit
  fi

  if lib_runtime_rt_isnot_defined $rt; then
    dbg_echo runtime 4 "ERROR: runtime \"${rt}\" not defined." 1>&2
    return
  fi

  if [ "x$DGRID_RUNTIME_DIRS" = "x" ]; then
    tpath="runtime:dgrid-site/runtime"
  else
    tpath="$DGRID_RUNTIME_DIRS"
  fi
  local iii=$IFS
  IFS=:
  for i in $tpath; do
    dbg_echo runtime 10 "lib_runtime_check_rdir1 $i $rt"
    eval "export RUNTIME_rt_${rt}_name=${rt}"
    # absolute path variable set
    lib_runtime_check_rdir_abs $rt $i
    # relative path variable set
    lib_runtime_check_rdir_rel $rt $i
  done
  IFS=$iii
}

lib_runtime_check_rdir_rel() {
  local _r fl
  local rt=$1
  local rdir=$2
  # rel path
  if [ $DGRIDBASEDIR == $DGRIDDISTDIR ]; then
    dbg_echo runtime 10 F "Rel path, Dist mode ON"
    if [[ $rdir == DISTDIR* ]]; then
      rdir=${rdir/DISTDIR/.}
    else
      return
    fi
  else
    dbg_echo runtime 10 F "Rel path, Node mode ON"
    if [[ $rdir == NODEDIR* || $rdir == HOME* || $rdir == DISTDIR* ]]; then
      rdir=${rdir/NODEDIR/.}
      #echo "DGRIDDISTDIR=$DGRIDDISTDIR";exit
      rdir=${rdir/DISTDIR/$DGRIDDISTDIRrel}
    else
      return
    fi
  fi

  _r="${rdir}/${rt}-${DGRID_this_arch}/"
  dbg_echo runtime 10 F _r=${_r}

  if [ ! -d ${_r} ]; then
    dbg_echo runtime 12 "runtime \"${rt}-${DGRID_this_arch}\" not found"
  else
    dbg_echo runtime 5 "OK, runtime \"${rt}-${DGRID_this_arch}\" found"
    #eval "export RUNTIME_rt_${rt}_name=${rt}"
    eval "export RUNTIME_rt_${rt}_dirrel=${_r}"
    DGRID_PATH_rtrel="$DGRID_PATH_rtrel:${_r}"
    export DGRID_PATH_rtrel=${DGRID_PATH_rtrel/::/}
  fi
}

lib_runtime_check_rdir_abs() {
  local _r fl
  local rt=$1
  local rdir=$2 #dbg_echo runtime 3 F DGRIDBASEDIR=$DGRIDBASEDIR
  # abs path
  if [ $DGRIDBASEDIR == $DGRIDDISTDIR ]; then
    # dist mode
    dbg_echo runtime 10 F "Abs path, Dist mode ON"
    if [[ $rdir == HOME* || $rdir == DISTDIR* ]]; then
      rdir=${rdir/HOME/${HOME}}
      rdir=${rdir/DISTDIR/${DGRIDDISTDIR}}
    else
      return
    fi
  else
    # node mode
    dbg_echo runtime 10 F Node mode ON
    if [[ $rdir == NODEDIR* || $rdir == HOME* || $rdir == DISTDIR* ]]; then
      rdir=${rdir/NODEDIR/${DGRIDBASEDIR}}
      rdir=${rdir/HOME/${HOME}}
      rdir=${rdir/DISTDIR/${DGRIDDISTDIR}}
    else
      return
    fi
  fi

  _r="${rdir}/${rt}-${DGRID_this_arch}/"
  dbg_echo runtime 10 F _r=${_r}
  if [ ! -d ${_r} ]; then
    dbg_echo runtime 12 "runtime \"${rt}-${DGRID_this_arch}\" not found"
  else
    dbg_echo runtime 6 "OK, runtime \"${rt}-${DGRID_this_arch}\" found"
    #eval "export RUNTIME_rt_${rt}_name=${rt}"
    eval "export RUNTIME_rt_${rt}_dir=${_r}"
    DGRID_PATH_rt="$DGRID_PATH_rt:${_r}"
    export DGRID_PATH_rt=${DGRID_PATH_rt/::/}
  fi
}

#############

lib_runtime_load_rt_list()
{
  local r tIFS l=$1
  dbg_echo runtime 6 F "START"
  tIFS="$IFS";IFS=":"
  for r in $l; do
    IFS="$tIFS"
    dbg_echo runtime 6 F "r=$r"
    lib_runtime_load_rt "$r"
  done
  IFS="$tIFS"
}

