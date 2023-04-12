#!/bin/bash

dgridsys_cli_help_module() {
  #echo -n
  #echo "dgridsys_cli_main_help(): TEST"
  dgridsys_s;  echo "module list - list modules"
  dgridsys_s;  echo "module vars"
  dgridsys_s;  echo "module cache_clear - clear all cache"
  dgridsys_s;  echo "module enable [module name] - ..."
  dgridsys_s;  echo "module disable [module name] - ..."
  dgridsys_s;  echo "module register-changes [module name] - ..."
  #dgridsys_s;echo "module activate [module name] - activate module on this node"
  dgridsys_s;  echo "module print-all-info - info from all modules printed by defined hook"

}

dgridsys_vars_list() {
  set | grep ^MODINFO_
  set | grep ^MODULE_
}

dgridsys_module_print_all_info() {
  main_call_hook print_module_info
}


dgridsys_module_register() {
  if [ -z "$1" ]; then
    echo "string(mod name)  expected as input"
    exit
  fi
  if distr_is_not_module_name $1; then
    echo "module name expected"
  fi
  local modn=$1

  f="./etc/modules/${modn}.modconfig"
  system_register_file_changes "module_register" "$FUNCNAME" $f
}


dgridsys_cli_module() {
  cmd=$2
  name=$3

  if [ x$cmd == x"list" ]; then
    echo
    main_getmodlist
    echo
    return
  fi

  if [ x$cmd == x"vars" ]; then
    echo
    dgridsys_vars_list
    echo
    return
  fi

  if [ x$cmd == x"print-all-info" ]; then
    echo
    dgridsys_module_print_all_info
    echo
    return
  fi

  if [ x$cmd == x"cache_clear" -o x$cmd == x"cc" ]; then
    echo
    #dgridsys_vars_list
    cache_clear ALL
    echo
    return
  fi

  if [ x$name == x ]; then
    dgridsys_cli_help_module
    #echo ".... module <name>"
    exit
  fi

  if [ x$cmd == x"enable" ]; then
    #echo "Run main_enable_one_mod $name"
    system_enable_one_mod $name
    return $?
  fi

  if [ x$cmd == x"disable" ]; then
    #echo "Run main_enable_one_mod $name"
    system_disable_one_mod $name
    return $?
  fi

  if [ x$cmd == x"activate" ]; then
    #echo "Run main_enable_one_mod $name"
    #system_activate_one_mod $name
    echo -n
  fi

  if [ x$cmd == x"register-changes" ]; then
    shift 2
    #echo "Run main_enable_one_mod $name"
    #system_activate_one_mod $name
    dgridsys_module_register $*
    return $?
  fi

}
