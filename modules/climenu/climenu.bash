#!/bin/bash

if [ x$MODINFO_loaded_climenu == "x" ]; then
  export MODINFO_loaded_climenu="Y"
else
  return
fi

#MODINFO_dbg_climenu=0
#MODINFO_enable_climenu=
#source ${MODINFO_modpath_climenu}/climenu.defaultvalues

source ${MODINFO_modpath_climenu}/climenu_cmds.bash

if [ -f ./dgrid-site/etc/climenu.conf ]; then
  source ./dgrid-site/etc/climenu.conf
fi

climenu_print_module_info() {
  echo "climenu: command line menu"

}


climenu_climenuid_exists_do() {
  if nodecfg_nodeid_exists "$n"; then
    dbg_echo climenu 4 "found NODEID $n"
    return 0
  fi
  if hostcfg_hostid_exists "$n"; then
    dbg_echo climenu 4 "found HOSTID $n" 1>&2
    return 0
  fi

  climenuid_exists

}

climenu_alias_expand()
{
  dbg_echo climenu 4 "F start"
  local v i a=$1
  if [ -z "$a" ]; then
    return 1
  fi
  for i in $NODECFG_nodeid_LIST ; do
    v=${i//:/_}
    #dbg_echo climenu 14  $i : $v compare $a
    if [ "$a" == "$v"   ]; then
      echo $i
      return 0
    fi
  done
  echo $a
}


# climenu scripts
climenu_run_menu() {
  #export MODINFO_dbg_climenu=10
  local params="$*"

  local clm_name p d0 d1 n1 n2
  dbg_echo climenu 4 "=================================== "
  dbg_echo climenu 4 "ORIGDIR=$ORIGDIR"
  export climenu_ORIGDIR=$ORIGDIR
  dbg_echo climenu 4 "_file0=${_file0}"
  export climenu_file0=${_file0}
  climenu_cmd=$(basename ${_file0})
  dbg_echo climenu 4 "climenu_cmd=\"${climenu_cmd}\""
  dbg_echo climenu 4 DGRIDBASEDIR=$DGRIDBASEDIR
  dbg_echo climenu 4 pwd=$(pwd)
  dbg_echo climenu 4 params=${params}

  d=${_file0}
  while true; do
    d=$(dirname $d)
    n=$(basename $d)
    dbg_echo climenu 14 "F n=$n"
    n=`climenu_alias_expand $n`
    dbg_echo climenu 14 "F EXPAND climenu ALIAS n=$n"
    
    if nodecfg_nodeid_exists "$n"; then
      dbg_echo climenu 4 "found NODEID $n"
      break
    fi
    if hostcfg_hostid_exists "$n"; then
      dbg_echo climenu 4 "found HOSTID $n"
      break
    fi
    dbg_echo climenu 14 "d=$d ($DGRIDBASEDIR)"
    if [ "x$d" == "x$DGRIDBASEDIR" ]; then
      dbg_echo climenu 14 "Reach dgrid install dir, no luck"
      return
    fi
  done
  export climenu_menuid=${n}
  export climenu_dir0=$(dirname ${_file0})
  export climenu_dir=$(basename ${climenu_dir0})
  dbg_echo climenu 4 "F menuid=${climenu_menuid} climenu_cmd=${climenu_cmd}"

  if [ x$climenu_dir == x$climenu_menuid ]; then
    export climenu_dir=""
  fi
  climenu_run_climenu_op_do $climenu_menuid $climenu_cmd ${params}
}

climenu_func_exists() {
  declare -f $1 >/dev/null
  return $?
}

climenu_run_climenu_op_do() {
  local f flag_found=0 ret
  local mid=$1 cmd=$2
  shift 2
  local params="$*"
  dbg_echo climenu 8 "F Begin menuid=$mid cmd=${cmd}"
  dbg_echo climenu 8 "F Check internal functions of modules"
  for m in $MODULE_list_enabled; do
    # check gateway function for cmd
    f="${m}_climenu_cmds"
    dbg_echo climenu 12 "8 f=${f}"
    if climenu_func_exists $f; then
      dbg_echo climenu 4 "F found, run $f() 1=$cmd \$2=$mid *=$params"
      eval "$f $cmd $mid $params"
      ret=$?
      if [ "x$ret" == "x0" ]; then 
        dbg_echo climenu 4 "CMD in $f() found, do not check other functions"
        flag_found=1
        continue; 
      fi
    fi
    # check specific function for cmd
    local cmdv2=${cmd//-/_}
    f="${m}_climenu_cmd_${cmdv2} $params"
    dbg_echo climenu 12 "8 f=${f}"
    if climenu_func_exists $f; then
      dbg_echo climenu 4 "F found, run $f() \$1=$mid"
      eval "$f $mid"
      flag_found=1
    else
      echo -n
    fi
  done
  main_call_hook run_climenu_op $mid $cmd $params

  if [ $flag_found == 0 ]; then
    dbg_echo climenu 4 "F \*_climenu_cmd_$cmdv2() not found"
    echo "this climenu not found, exit"
  fi
}

#climenu_run_menu_gw_hook()
#{
#}
climenu_list_cli()
{
  for m in $MODULE_list_enabled; do
    var="${m}_CLIMENU_CMDS_LIST"
    for v in ${!var}; do
      echo "$v:$m"
    done
  done
}



climenu_list() # [API]  #usage: delim=":" climenu_list
{
  if [ ! -n $delim ]; then
    delim=" "
  fi
  for m in $MODULE_list_enabled; do
    var="${m}_CLIMENU_CMDS_LIST"
    for v in ${!var}; do
      echo "$v:$m"
    done
  done
}



############ cli integration  ################

climenu_cli_help() {
  dgridsys_s
  echo "climenu list - list avaliable menu-commands"
  #dgridsys_s
  #echo "climenu CMDTWO - <xxx> <yyy> .... -"
}

climenu_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo climenu 5 x${maincmd} == x"climenu"
  if [ x${maincmd} == x"climenu" ]; then
    echo -n
  else
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    climenu_cli_help
  fi

  if [ x${cmd} == x"list" ]; then
    echo -n
    shift 2
    climenu_list_cli $*
  fi
}

function climenu_is_climenuid {
  return 0
}
