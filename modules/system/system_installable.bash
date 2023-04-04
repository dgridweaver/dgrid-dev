#!/bin/bash

function system_config_samples_install_item {
  local mod=${ARRAY[0]}

  #echo ${ARRAY[1]}
  #echo ${ARRAY[2]}
  #echo ${ARRAY[3]}
  local varname="MODINFO_modpath_${mod}"
  #echo $varname#echo aaaa=$MODINFO_modpath_updmod1
  eval "module_dir=\$$varname"
  #module_dir=${!varname}#echo bbb=${!varname}#echo module_dir=\"$module_dir\";

  local out=${system_dgrid_sample_node_dir}/${ARRAY[3]}
  local outdir=$(dcmd_dirname $out)
  echo mkdir_ifnot $outdir

  echo "cp ${module_dir}/${ARRAY[2]} ./${out}"
}

###########

function system_installable_files_install_op_bin {
  #local out=${system_dgrid_sample_node_dir}/${outfile}
  local out=./dgrid-site/bin/${outfile}
  local outdir=$(dcmd_dirname $out)
  echo mkdir_ifnot $outdir

  echo "cp ${module_dir}/${infile} ${out}"

  system_trans_register $CURRENT_TRANSACTION_ID system installable_files_install ${out} op_bin

  #local out=${system_dgrid_sample_node_dir}/${outfile}
}

function system_installable_files_install_op_config_sample_node {
  local out=${system_dgrid_sample_node_dir}/${outfile}
  local outdir=$(dcmd_dirname $out)
  echo mkdir_ifnot_q $outdir
  mkdir_ifnot_q $outdir

  echo "cp ${module_dir}/${infile} ${out}"
  cp ${module_dir}/${infile} ${out}

  system_trans_register $CURRENT_TRANSACTION_ID system installable_files_install ${out} op_bin
}

#function system_installable_files_install_op_config_default_allgrid
function system_installable_files_install_op_bin_allgrid {
  local out=./dgrid-site/bin/${DGRIDNAME}-${outfile}
  local outdir=$(dcmd_dirname $out)
  echo mkdir_ifnot $outdir

  echo "cp ${module_dir}/${infile} ${out}"
}

######

function system_installable_files_install_item {

  local varname="MODINFO_modpath_${module}"
  dbg_echo system 4 "system_installable_files_install_item() mod=$module handler=$handler flags=$flags ..."
  eval "module_dir=\$$varname"
  #module_dir=${!varname}#echo bbb=${!varname}#echo module_dir=\"$module_dir\";

  if [ x$handler == x"system" ]; then
    local F_op="system_installable_files_install_op_${op}"
    if is_function_exists $F_op; then
      echo "---- Run operation \"${op}\" ----"
      $F_op
      echo "---- End operation \"${op}\" ----"
    else
      echo "No such operation \"${op}\""
    fi
  fi

}
function system_installable_files_get {
  echo -n
  main_call_hook installable_files $*
}

function system_deploy_entries_get {
  echo -n
  #main_call_hook deploy_entries $*
  main_call_hook deploy_entries_register $*
}

system_installable_files_install_execute_entry() {
  echo -n
}

system_installable_files_cfgvars() {
  echo entryid module handler flags infile outfile
}

system_installable_files_install_hlpr() {
  local mod=$1
  dbg_echo system 4 "system_installable_files_install_hlpr() module=$module"
  dbg_echo system 6 "if $module == $mod "
  if [ x$module == x$mod ]; then
    system_installable_files_install_item
  fi
}

system_installable_files_install() {
  local mod=$1
  local trid=$2
  local FUNCNAME="system_installable_files_install"

  if [ x$mod == x ]; then
    echo "mod!!"
    return
  fi

  dbg_echo system 4 "system_installable_files_install: begin"
  local trid=$(system_trans_genid)
  system_trans_begin $trid system installable_files_install $FUNCNAME
  system_installable_files_iterate system_installable_files_install_hlpr $mod
  system_trans_end "$trid" system installable_files_install
  dbg_echo system 4 "system_installable_files_install: end"
}

system_installable_files_list_hlpr() {
  printf "%14s | %25s | %s (%s)\n" $module $outfile $handler $op
}

system_installable_files_list_cmd() {
  printf "%14s | %25s | %s (%s)\n" MODULE OUTFILE handler op
  echo "-----------------------------------------------------------"
  system_installable_files_iterate system_installable_files_list_hlpr
  echo
}

function system_installable_files_iterate {
  #system_installable_files_iterate $*
  dbg_echo system 5 "system_installable_files_iterate: begin"
  #system_deploy_entries_iterate $*
  system_ini_entries_iterate system_installable_files_cfgvars system_installable_files_get $*
  dbg_echo system 5 "system_installable_files_interate: end"
}

function system_deploy_entries_iterate {
  dbg_echo system 5 "system_deploy_entries_iterate: begin"
  system_ini_entries_iterate system_installable_files_cfgvars system_deploy_entries_get $*
  dbg_echo system 5 "system_deploy_entries_iterate: end"
}

function system_ini_entries_iterate {
  local funcvars=$1
  local funcentrylist=$2
  local func=$3
  shift 3
  local params=$*

  dbg_echo system 5 "system_deploy_entries_iterate: begin"
  local cfgstr cfgentry
  local key val

  # read file entries from hooks
  #system_installable_files_get| while read cfgstr; do
  unset $(system_installable_files_cfgvars)
  $funcentrylist | while read cfgstr; do

    IFS="="
    set -- $cfgstr
    key=$1
    val=$2
    IFS=" "
    dbg_echo system 9 "  k=\"$key\" v=\"$val\""
    if [ "x$key" == "x[file entry begin]" ]; then
      unset $(system_installable_files_cfgvars)
      local $(system_installable_files_cfgvars)
      cfgstr=""
    else
      if [ "x$key" == "x[file entry end]" ]; then
        # do entry proceeding
        dbg_echo system 8 ------------ $cfgentry
        dbg_echo system 8 ------------
        eval "$cfgentry"
        cfgentry=""
        dbg_echo system 5 "do entry proceeding, module=\"$module\""
        dbg_echo system 5 "call $func() params=$params"
        $func $params
      else
        cfgentry="$cfgentry
$cfgstr"

      fi
    fi

  done

  dbg_echo system 5 "system_deploy_entryes_iterate: end"
}

function system_installable_files_remove {
  local mod=$1

}

#################################################

function system_deploy_entries_register {
  #local mod=$1
  echo "
[file entry begin]
module=system
entryid=vardir
handler=system_vardir_deploy
op=config_sample_node
infile=hoststat.conf.sample
outfile=dgrid-var
[file entry end]
"
}
function system_vardir_deploy {
  echo -n
  echo DEPLOY_VARDIR
}

#################################################

function system_deploy_entry_hlpr() {
  echo module=$module
}

function system_deploy_entry_cmd {
  echo -n
  local deploy_id=$1
  echo system_deploy_cmd
  system_deploy_entries_iterate system_deploy_id_hlpr
}

##############

system_deploy_entry_list_hlpr() {
  printf "%14s | %14s | %s ()\n" $entryid $module $handler
}

system_deploy_entry_list_cmd() {
  printf "%14s | %14s | %s ()\n" "Entry id" MODULE handler
  echo "-----------------------------------------------------------"
  system_deploy_entries_iterate system_deploy_entry_list_hlpr
  echo
}

system_deploy_id_do_cmd() {
  echo -n

  local name=$1
  local trid=$2
  local FUNCNAME="system_deploy_id_do_cmd"

  if [ x$mod == x ]; then
    echo "mod!!"
    return
  fi

  dbg_echo system 4 "$FUNCNAME: begin"
  local trid=$(system_trans_genid)
  system_trans_begin $trid system deploy_id $FUNCNAME
  #system_installable_files_iterate system_installable_files_install_hlpr $mod
  system_trans_end "$trid" system deploy_id
  dbg_echo system 4 "$FUNCNAME: end"
}
