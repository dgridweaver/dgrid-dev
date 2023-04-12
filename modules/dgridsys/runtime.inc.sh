#!/bin/bash



dgridsys_cli_help_runtime() {
  dgridsys_s; echo "runtime list-installed"
  dgridsys_s; echo "runtime list"
}

dgridsys_runtime_info_cli() {
  local rt=$1


}


dgridsys_cli_runtime() {
  cmd=$2
  name=$3

  if [ x$cmd == x"list" ]; then
    distr_cli_runtime_list
    return
  fi

  if [ x$cmd == x"list-installed" ]; then
    dgridsys_runtime_list_inst_cli
    return
  fi

  if [ x$cmd == x"info" ]; then
    dgridsys_runtime_info_cli $@
    return
  fi



}



