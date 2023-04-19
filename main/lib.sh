#!/bin/bash

##############################################

# debug functions

dbg_echo() { # [API]
  dbg_echo_stdout $* 1>&2
}

dbg_echo_stdout() {
  local mod this_msg_lvl var s

  s=${BASH_SOURCE[1]}

  mod=$1
  this_msg_lvl=$2
  shift 2
  var=MODINFO_dbg_$mod
  #echo this_msg_lvl=$this_msg_lvl
  if [ "x$this_msg_lvl" == "x" ]; then
    echo "$s : error dbg_echo no level"
    exit
  fi
  #echo "$var = ${!var}"
  if [ x${!var} == "x" ]; then
    #echo "no debug"
    echo -n
  else
    if [ ${!var} -ge $this_msg_lvl ]; then
      #echo "[$this_msg_lvl] " "($s)" $*
      if [ "x$1" == "xF" ]; then
        shift 1
        echo "$mod[$this_msg_lvl] ${FUNCNAME[2]}()" $*
      else
        echo "$mod[$this_msg_lvl]" $*
      fi
    fi
  fi
  unset mod
}

dbg_generic_listvars() { # [API]
  mod=$1
  this_msg_lvl=$2
  shift 2
  var=MODINFO_dbg_$mod
  #echo this_msg_lvl=$this_msg_lvl
  if [ "x$this_msg_lvl" == "x" ]; then
    echo "$s : error dbg_echo no level"
    exit
  fi

  if [ x${!var} == "x" ]; then echo -n; else
    if [ ${!var} -ge $this_msg_lvl ]; then
      echo "$mod[$this_msg_lvl] ---- BEGIN generic_listvars -----"
      generic_listvars $*
      echo "$mod[$this_msg_lvl] ---- END generic_listvars -----"
    fi
  fi
}

generic_stacktrace() { # [API]
  _generic_stacktrace_do 1>&2
}
_generic_stacktrace_do() {
  #   local i=1
  #      while caller $i | read line func file; do
  #        echo >&2 "[$i] $file:$line $func(): $(sed -n ${line}p $file)"
  #      ((i++))
  #     done
  echo -n this:${FUNCNAME[2]} ""
  echo -n 1:${FUNCNAME[3]} ""
  echo -n 2:${FUNCNAME[4]} ""
  echo -n 3:${FUNCNAME[5]} ""
}

generic_trim() {
  echo -n $*
}

generic_trim2() {
  local var="$*"
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

dbg_echo_var_stderr() {
  local mod this_msg_lvl var

  mod=$1
  this_msg_lvl=$2
  shift 2
  var=$*

  dbg_echo $mod $this_msg_lvl $mod $this_msg_lvl "LOADCONF ##### var #####" 1>&2
  #echo ${!var}  1>&2
  dbg_echo $mod $this_msg_lvl $mod $this_msg_lvl ${var} 1>&2
  dbg_echo $mod $this_msg_lvl $mod $this_msg_lvl "LOADCONF #####  #####" 1>&2
}

##############################################

dgrid_lib_vars() {
  echo -n DGRIDLIB_version DGRIDLIB_thisclidir
}

dgrid_vars() {
  echo -n DGRIDBASEDIR GRIDBASEDIR DGRID_GRIDNAME dgrid_core \
    dgrid_core_version dgrid_core_version_major dgrid_core_version_minor
}

dgrid_fullenv_vars() {
  dgrid_lib_vars dgrid_vars
}

##################################

_generic_listvar_x1() {
  var=$1
  shift 1
  unset f
  if [ $var == "'" ]; then
    f=0
  fi

  for i in $*; do
    if [ $var == $i ]; then
      f=0
    fi
  done

  if [ x$f == x0 ]; then
    echo -n
  else
    echo -n $var
    echo -n " "
  fi
}

generic_listvars() { # [API]
  (
    set -o posix
    set
  ) | grep ^$1
}

generic_listvar_except() { # [API]
  pat="=*"
  (
    set -o posix
    set
  ) | while read F; do
    var=${F%%$pat}
    #echo "#$var#" 1>&2
    _generic_listvar_x1 ${var} pat $*
  done
  unset pat
}

######################################################
# sample : generic_cut_param ":" 2 "aaaa:bbb:ccc:ddd"
######################################################
generic_cut_param() { # [API]
  local ADDR
  local ifs=$1
  local pos=$2
  local IN=$3
  let pos=$pos-1 >/dev/null
  IFS=$ifs read -ra ADDR <<<"$IN"
  dbg_echo generic 12 "generic_cut_param():pos=$pos addr=\""${ADDR[${pos}]}"\""
  echo -n ${ADDR[$pos]}
}
generic_cut_stdin() { # [API]
  local ifs=$1
  local pos=$2
  shift 2
  #IFS=':' read -ra ADDR <<< "$IN"
  IFS=$ifs read -ra ADDR
  #echo ${ADDR[1]}
  #for i in "${ADDR[@]}"; do
  #  # process "$i"
  # done
}

generic_filter_param_str() { # [API]
  local str var value
  local _filter=$1
  shift 1
  str=$*
  #eval $str
  for i in $*; do
    var=$(generic_cut_param "=" 1 $i)
    value=$(generic_cut_param "=" 2 $i)
    dbg_echo generic 12 "generic_filter_param_str() $i --> ($var) = ($value)"
    if [ x$var = x${_filter} ]; then echo -n; else
      echo -n "${var}=${value} "
    fi
  done
}

generic_var_content_priority() {
  local var
  local list=$*
  dbg_echo generic 6 "generic_var_content_priority(): list=\"${list}\"" 1>&2
  for i in $list; do
    if [ "x${!i}" == "x" ]; then
      echo -n
      dbg_echo generic 6 "generic_var_content_priority(): var \"${i}\" is empty" 1>&2
    else
      dbg_echo generic 6 "generic_var_content_priority(): var \"${i}\" have content, return" 1>&2
      echo ${!i}
      return
    fi
  done
}

generic_word_in_list() { # [API]
  local sword=$1
  shift 1
  local plist=$*
  dbg_echo generic 6 "plist=$plist sword=$sword"
  for word in $plist; do
    if [ x$sword == x$word ]; then
      return 0
    fi
  done
  return 1
}




##################################

modinfo_vars() {
  echo name description version core group modtypes f_experimental distribution_mode
}

modinfo_loadconf() {
  local f=$1
  unset $(modinfo_vars)

  if [ -f $f ]; then echo -n; else
    dbg_echo main 6 "modinfo_loadconf(): not found \"$f\""
    return 1
  fi
  dbg_echo main 6 "modinfo_loadconf(): load $f"
  source $1
  if [ x${group} == x"" ]; then group="other"; fi
}

###################################

loadshellcfg() {
  # MUST ADD CHECKS!
  source $1
}

main_list_modinfo() {
  local list var vars _file _dir path

  # MODINFO_files
  list=$(find $main_modpath -iname "*.modinfo" -printf " %p ")
  for path in $list; do
    _file=$(basename $path)
    _dir=$(dirname $path)
    _file=${_file%%.modinfo}
    var=tmp_${_file}
    #local $var
    vars="$vars $var"
    read -r $var <<<$path
    #echo $var 1>&2
  done
  #echo $vars 1>&2
  for var in $vars; do
    if [ x${!var} == x ]; then
      echo -n
    else
      echo -n ${!var}" "
      unset $var
    fi
  done
}

modinfo_header_var1() {
  local F _dir varname
  dbg_echo loadconfigs 15 "modinfo_header_var1() begin"
  pushd $DGRIDBASEDIR >/dev/null
  for F in $MODINFO_files; do
    dbg_echo loadconfigs 15 "modinfo_header_var1() process F=$F"

    # load module info from .info file
    unset $(modinfo_vars)
    modinfo_loadconf $F
    varname="MODINFO_modpath_${name}"
    read -r $varname <<<"$F"
    _dir=$(dirname $F)

    if [ x"$name" == "x" ]; then echo -n; else
      echo "export $varname=\"${_dir}\" ; "
      # export enable/disable module state
      modinfo_etc_outvar $name
    fi

    unset $(modinfo_vars)
  done
  popd >/dev/null
  dbg_echo loadconfigs 15 "modinfo_header_var1() end" 1>&2
}

modinfo_etc_outvar() {
  pushd $DGRIDBASEDIR >/dev/null

  name=$1
  unset $(modinfo_state_vars)
  modinfo_etcconf $name
  varname_enable="MODINFO_enable_${name}"
  dbg_echo loadconfigs 15 F "start ${varname_enable}=${!varname_enable}"
  if [ x${!varname_enable} == "xY" ]; then
    echo -n
  else
    dbg_echo loadconfigs 15 F "read var ${varname_enable}"
    read -r $varname_enable <<<"$MOD_enable"
  fi
  dbg_echo loadconfigs 15 F "MOD_enable=$MOD_enable"
  if [ x${!varname_enable} == "x" ]; then echo -n; else
    echo "export ${varname_enable}=\"${!varname_enable}\" ; "
  fi
  unset $(modinfo_state_vars)
  popd >/dev/null

}

modinfo_setvar1_snippet() {

  ##
  varname_enable="MODINFO_enable_${name}"
  if [ x${!varname_enable} == xY ]; then
    #echo "dbg: mods_enabled=$name $mods_enabled"
    mods_enabled="$name $mods_enabled"
  #echo "export mods_enabled=\"$mods_enabled\";"
  else
    mods_disabled="$name $mods_disabled"
  #echo "export mods_disabled=\"$mods_disabled\";"
  fi
  mods_all="$name $mods_all"
  ##
}

modinfo_header_module_list() {
  #export mods_enabled mods_disabled mods_all

  pushd $DGRIDBASEDIR >/dev/null
  main_mod_runfunc 'modinfo_setvar1_snippet' >/dev/null
  popd >/dev/null

  dbg_echo "modinfo" 4 "[2] mods_enabled=\"${mods_enabled}\";" 1>&2

  echo "export MODULE_list_enabled=\"$mods_enabled\"; "
  echo "export MODULE_list_disabled=\"$mods_disabled\"; "
  echo "export MODULE_list_all=\"$mods_all\"; "

  #echo "export MODULE_list_enabled=\"\$mods_enabled\";unset mods_enabled ;"
  #echo "export MODULE_list_disabled=\"\$mods_disabled\";unset mods_disabled ;"
  #echo "export MODULE_list_all=\"\$mods_all\";unset mods_all ;"
}

modinfo_state_vars() {
  echo MOD_name MOD_enable MOD_version MOD_path MOD_version_stamp
}

main_mod_state_vars() {
  modinfo_state_vars
}

loadshellcfg() {
  # MUST ADD CHECKS!
  source $1
}

modinfo_etcconf() {
  name=$1
  cfg=$main_cfg_modpath/${name}.modconfig
  if [ -f $cfg ]; then
    #echo "bbb=$cfg"
    loadshellcfg $cfg
  else
    echo -n
  fi
}

function main_mod_runfunc {
  local code F _dir
  code=$1
  pushd $DGRIDBASEDIR >/dev/null
  dbg_echo main 6 "main_mod_runfunc() -------------- " 1>&2
  dbg_echo main 6 DGRIDBASEDIR=$DGRIDBASEDIR 1>&2

  #find $main_modpath -iname "*.modinfo"  | while read F;
  #echo $MODINFO_files  | while read -d\  F; do
  for F in $MODINFO_files; do
    unset $(modinfo_vars)
    dbg_echo main 6 "main_mod_runfunc() last pwd="$(pwd) 1>&2
    cd $DGRIDBASEDIR
    dbg_echo main 6 "main_mod_runfunc() set pwd="$(pwd) 1>&2
    modinfo_loadconf $F 1>&2
    _dir=$(dirname $F)
    export mod_dir=${_dir}
    dbg_echo main 6 "F=$F name=$name description=$description depend=$depend group=$group version=$version " 1>&2
    #eval "( cd $GRIDBASEDIR ; $code )"
    cd $DGRIDBASEDIR
    eval "$code"
    cd $DGRIDBASEDIR
  done

  popd >/dev/null
}

function main_mod_runfunc_fast_enable {
  local i var code
  code=$*
  for i in $MODULE_list_enabled; do

    var=MODINFO_modpath_$i
    #echo $var=${!var} 1>&2
    name=$i
    mod_dir=${!var}
    eval "$code"
    unset mod_dir
    #fi
  done
}

###############################################

# loading .bash modules

main_load_mod_functions() {
  #name=$1;
  #moddir=$2;
  s="$mod_dir/${name}.bash"
  if [ -f $s ]; then

    modvar1="MODINFO_enable_${name}"
    if [ x${!modvar1} == x"Y" ]; then
      dbg_echo main 3 "load $s, enabled" 1>&2
      echo "source $s ;"
    else
      dbg_echo main 3 "not load $s, not enabled" 1>&2
      echo -n
    fi

  else
    dbg_echo main 3 "$name : .bash not found" 1>&2
  fi
}

main_load_mod_functions_fast() {
  dbg_echo main 3 source ${mod_dir}/${name}.bash 1>&2
  echo "source ${mod_dir}/${name}.bash ;"
}

###############################################

main_modules_always_enabled() {
  local e
  for i in $DGRID_always_enabled; do
    #e="export MODINFO_enable_$i=Y"
    #eval $e
    read -r MODINFO_enable_$i <<<"Y"
  done
  #export MODINFO_enable_main=Y
  #export MODINFO_enable_nodecfg=Y
  #export MODINFO_enable_system=Y
}

###############################################
# runtimes

lib_get_arch() {
  if ! command -v "arch" &>/dev/null; then
    echo "No 'arch' command"
    exit
  fi
  arch
}

###############################################

# for loadconfigs1.sh
loadconfigs1_active_modules_list() {
  local MODINFO_files=$*
  for i in $MODINFO_files; do
    #echo $i
    if grep "^distribution_mode\=1" $i 1>/dev/null; then echo $i; fi
    if grep "^distribution_mode\=\"1\"" $i 1>/dev/null; then echo $i; fi
  done
}

loadconfigs1_enabled_modules_list() {
  local
  for f in $MODINFO_files_distr_enabled; do
    b=$(basename $f)
    generic_cut_param "." 1 "$b"
    echo -n " "
  done
}

#############################
