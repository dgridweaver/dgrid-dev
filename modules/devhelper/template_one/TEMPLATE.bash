#!/bin/bash

if [ x$MODINFO_loaded_TEMPLATE == "x" ]; then
  export MODINFO_loaded_TEMPLATE="Y"
else
  return
fi

MODINFO_msg_TEMPLATE=2

source ${MODINFO_modpath_TEMPLATE}/TEMPLATE.defaultvalues

if [ -f ./dgrid-site/etc/TEMPLATE.conf ]; then
  source ./dgrid-site/etc/TEMPLATE.conf
fi

TEMPLATE_print_module_info() {
  echo "TEMPLATE: mod info, called TEMPLATE_print_module_info"

}

TEMPLATE_sample_function() {
  msg_echo TEMPLATE 1 "Some message"
  msg_echo TEMPLATE 2 "Som,e message more verbose"
  msg_echo TEMPLATE 2 "Message extensively verbose"

  dbg_echo TEMPLATE 3 F "debug info var=${var}"
  dbg_echo TEMPLATE 4 "more debug info"
}

TEMPLATE_sample_function2() {
  dbg_echo TEMPLATE 4 F "TEMPLATE_run() pwd="$(pwd)
  local params=$*

  #export MODINFO_dbg_nodecfg=20
  cfgstack_cfg_thisnode "etc/TEMPLATE.conf"
  #cfgstack_load_byid "etc/TEMPLATE.conf" ${THIS_NODEID}

}

############ cli integration  ################

TEMPLATE_cli_help() {
  dgridsys_s; echo "TEMPLATE CMDONE - <xxx> <yyy> .... -"
  dgridsys_s; echo "TEMPLATE CMDTWO - <xxx> <yyy> .... -"
}

TEMPLATE_cli_run() {
  local maincmd=$1 cmd=$2 name=$3

  dbg_echo TEMPLATE 5 x${maincmd} == x"TEMPLATE"
  if [ ! x${maincmd} == x"TEMPLATE" ]; then return; fi

  if [ x${cmd} == x"" ]; then
    TEMPLATE_cli_help
  fi

  if [ x${cmd} == x"CMDONE" ]; then
    shift 2
    TEMPLATE_CMDONE $*
  fi

  #if [ x${cmd} == x"CMDTWO"  ]; then
  #  shift 2
  #  TEMPLATE_CMDTWO $*
  #fi

}
