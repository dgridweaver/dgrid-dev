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

climenu_sample_function() {
  msg_echo climenu 1 "Some message"
  msg_echo climenu 2 "Som,e message more verbose"
  msg_echo climenu 2 "Message extensively verbose"

  dbg_echo climenu 3 "debug info var=${var}"
  dbg_echo climenu 4 "more debug info"
}

climenu_sample_function2() {
  echo "climenu_run() pwd="$(pwd)
  dbg_echo climenu 4 "more debug info"
  local params=$*

  #export MODINFO_dbg_nodecfg=20
  cfgstack_cfg_thisnode "etc/climenu.conf"
  cfgstack_cfg_thisnode "climenu.conf"
  #cfgstack_load_byid "etc/climenu.conf" ${THIS_NODEID}
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

# climenu scripts
climenu_run_menu() {
  #export MODINFO_dbg_climenu=10

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

  d=${_file0}
  while true; do
    d=$(dirname $d)
    n=$(basename $d)
    dbg_echo climenu 14 "F n=$n" 1>&2
    if nodecfg_nodeid_exists "$n"; then
      dbg_echo climenu 4 "found NODEID $n" 1>&2
      break
    fi
    if hostcfg_hostid_exists "$n"; then
      dbg_echo climenu 4 "found HOSTID $n" 1>&2
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
  climenu_run_climenu_op_do $climenu_menuid $climenu_cmd
}

climenu_func_exists() {
  declare -f $1 >/dev/null
  return $?
}

climenu_run_climenu_op_do() {
  local f flag_found=0 ret
  local mid=$1 cmd=$2
  dbg_echo climenu 8 "F Begin menuid=$mid cmd=${cmd}"
  dbg_echo climenu 8 "F Check internal functions of modules"
  for m in $MODULE_list_enabled; do
    # check gateway function for cmd
    f="${m}_climenu_cmds"
    dbg_echo climenu 12 "8 f=${f}"
    if climenu_func_exists $f; then
      dbg_echo climenu 4 "F found, run $f() 1=$cmd \$2=$mid"
      eval "$f $cmd $mid"
      ret=$?
      if [ "x$ret" == "x0" ]; then 
        dbg_echo climenu 4 "CMD in $f() found, do not check other functions"
        flag_found=1
        continue; 
      fi
    fi
    # check specific function for cmd
    f="${m}_climenu_cmd_${cmd}"
    dbg_echo climenu 12 "8 f=${f}"
    if climenu_func_exists $f; then
      dbg_echo climenu 4 "F found, run $f() \$1=$mid"
      eval "$f $mid"
      flag_found=1
    else
      echo -n
    fi
  done
  main_call_hook run_climenu_op $mid $cmd

  if [ $flag_found == 0 ]; then
    dbg_echo climenu 4 "F \*_climenu_cmd_$cmd() not found"
    echo "this climenu not found, exit"
  fi
}

#climenu_run_menu_gw_hook()
#{
#}

############ cli integration  ################

climenu_cli_help() {
  dgridsys_s
  echo "climenu CMDONE - <xxx> <yyy> .... -"
  dgridsys_s
  echo "climenu CMDTWO - <xxx> <yyy> .... -"
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

  if [ x${cmd} == x"CMDONE" ]; then
    echo -n
    climenu_CMDONE $*
  fi
}

function climenu_is_climenuid {
  return 0
}
