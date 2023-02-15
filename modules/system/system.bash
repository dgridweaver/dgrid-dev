#!/bin/bash

#
#
# system - is a module where all patched together. 
#
#

if [ x$MODINFO_loaded_system == "x" ]; then
export MODINFO_loaded_system="Y"
else
return
fi

#MODINFO_dbg_system=0
MODINFO_msg_system=1


source ${MODINFO_modpath_system}/patchwork.bash
source ${MODINFO_modpath_system}/patchwork2.bash


source ${MODINFO_modpath_system}/generic-code.bash
source ${MODINFO_modpath_system}/system_installable.bash


source ${MODINFO_modpath_system}/hgone/hgone.bash


# hook_envset_prestart
system_envset_prestart()
{
dgrid_dir_variables_set
#echo -n
}


msg_echo()
{
local mod this_msg_lvl var

mod=$1
this_msg_lvl=$2
shift 2
var=MODINFO_msg_$mod
#echo "$var = ${!var}"
if [ x${!var} == "x" ]; then
#echo "no messaging"
echo -n
else
if [ ${!var} -ge $this_msg_lvl ]; then
shift 2
echo $*
fi
fi
unset mod
}


dgrid_dir_variables_set()
{
DGRID_dirname="${USER}_${DGRID_dgridname}_${DGRIDBASEDIR//\//_}"
echo "export DGRID_dirname=\"$DGRID_dirname\" ;"
DGRID_dir_dotlocal="$HOME/.local/${DGRID_dirname}/"
echo "export DGRID_dir_dotlocal=\"$DGRID_dir_dotlocal\" ;"

DGRID_dir_dotconfig="$HOME/.config/${DGRID_dirname}/"
echo "export DGRID_dir_dotconfig=\"$DGRID_dir_dotconfig\" ;"

DGRID_dir_dotcache="$HOME/.cache/${DGRID_dirname}/"
echo "export DGRID_dir_dotcache=\"$DGRID_dir_dotcache\" ;"

DGRID_dir_nodelocal="$DGRIDBASEDIR/not-in-vcs/"
echo "export DGRID_dir_nodelocal=\"$DGRID_dir_nodelocal\" ;"

}

system_env_start()
{
cfgstack_cfg_thisnode "etc/system.conf"
source ${MODINFO_modpath_system}/system.defaultvalues

if [ x$system_dgrid_sample_node_dir == "x" ]; then
echo "ERROR: system_dgrid_sample_node_dir no have  default value"
exit
fi
if [ x$system_dgrid_sample_host_dir == "x" ]; then
echo "ERROR: system_dgrid_sample_host_dir no have default value"
exit
fi


#echo "system_dgrid_sample_node_dir=$system_dgrid_sample_node_dir"

if [ x$system_trans_log == x ]; then
export system_trans_log="${DGRID_dir_nodelocal}/system/trans.log"
fi
#export system_trans_log_dir="${DGRID_dir_nodelocal}/system/"
export system_trans_log_dir=`zg_dirname $system_trans_log`

system_trans_init
}

############                  ################


function system_call_dgridsys
{
if [ x$MODINFO_enable_dgridsys != xY ]; then
echo system_call_dgridsys:  dgridsys not enabled
return 
fi

pushd $DGRIDBASEDIR > /dev/null
#echo "./dgrid/modules/dgridsys/dgridsys $*"
##system_clear_list_vars
#eval `system_clear_list_vars`
##( set -o posix ; set )
##exit
system_f_cleanenv ./dgrid/modules/dgridsys/dgridsys $*
#bash ./dgrid/modules/dgridsys/dgridsys $*
popd > /dev/null
}



##############################################


########### trans - transactions #################

function system_trans_logpref
{
echo "`date_f1` (`date_f0`)"
}

function system_trans_localdataprefix
{
echo ${DGRID_dir_nodelocal}/system/
}
function system_trans_transdir
{ echo `system_trans_localdataprefix`/trans/ ; }
function system_trans_transfile
{ local trid=$1; echo `system_trans_transdir`/$trid ; }


function system_trans_init
{
echo -n
outdir=$system_trans_log_dir
mkdir_ifnot_q $outdir
}

function system_trans_genid
{

echo `date +%s-%N`-`zg_randompass 16`
}

system_trans_writelog()
{
local var="$*"
if [ "x${system_trans_log}" == "x" ]; then
dbg_echo system 1 "system_trans_writelog: \$system_trans_log == \"\""  1>&2
return
fi

if [ "x$var" == "x" ]; then
dbg_echo system 1 "system_trans_writelog: EMPTY MESSAGE"  1>&2
else
dbg_echo system 1 "system_trans_writelog: system_trans_log=${system_trans_log}"  1>&2
echo "$*" >> ${system_trans_log}
fi
}

function system_trans_begin
{
local trid=$1
local modname=$2
local transtype=$3
local func=$4
pushd $DGRIDBASEDIR > /dev/null
mkdir_ifnot_q `system_trans_transdir`
system_trans_write_trans $trid "trid $trid"
system_trans_write_trans $trid "modname $modname"
system_trans_write_trans $trid "funcname $func"
system_trans_write_trans $trid "transtype $transtype"
system_trans_write_trans $trid "trans_logpref "`system_trans_logpref`
system_trans_writelog `system_trans_logpref` ": $trid : $modname : $transtype : begin transaction"
popd > /dev/null
}


system_trans_do_end_execute_EXP1()
{
local ifile=`system_trans_transfile $trid`
while read STR; do
echo -n
#hook_trans_do_end_execute $trid $ifile $STR
echo hook_trans_do_end_execute $trid $ifile $STR
done < $ifile
}



system_trans_drv_repo_type()
{
local f=$1
shift 1

if [ x$system_dgrid_repo_type == "x" ]; then
system_dgrid_repo_type="hgone"
fi

driverfunction2 $system_dgrid_repo_type $f $*
}
system_trans_do_end_execute()
{
local trid=$1
local ifile=`system_trans_transfile $trid`
system_trans_drv_repo_type trans_do_end_execute $* < $ifile
}

function system_trans_end
{
local trid=$1
local modname=$2
local transtype=$3
pushd $DGRIDBASEDIR > /dev/null
system_trans_do_end_execute $trid
system_trans_writelog `system_trans_logpref` ": $trid : $modname : $transtype : end transaction"
popd > /dev/null
}


function system_trans_write_trans
{
local trid=$1
shift 1
local param=$*
local ofile=`system_trans_transfile $trid`
dbg_echo system 4 "$FUNCNAME() : ofile=$ofile" 1>&2
echo $param  >> $ofile
}

function system_trans_register
{
local trid=$1
local modname=$2
local transtype=$3
shift 3
files="$*"
pushd $DGRIDBASEDIR > /dev/null
system_trans_writelog `system_trans_logpref` ": $trid : $modname : $transtype :" "register_files: $files"
system_trans_write_trans $trid "register $files"
popd > /dev/null

}

############   trans END      ################

#system_check_mod_present_hlpr()
#{
#echo $name
#}

system_check_mod_present()
{
main_check_mod_present $*
local ret=$?
dbg_echo system 11 "system_check_mod_present() ret=$ret"
return $ret
}


function system_enable_one_mod
{
local system_enable_one_mod_name=$1
local trid=`system_trans_genid`

#export CACHE_TYPE="NONE"
#local moddir=MODINFO_modpath_${system_enable_one_mod_name}
#dbg_echo system 3 [3] moddir=${moddir}  1>&2

local modenabled=MODINFO_enable_${system_enable_one_mod_name}
if [ x${!modenabled} == "xY" ]; then 
echo "system_enable_one_mod : \"$system_enable_one_mod_name\" already enabled"; return;fi

system_check_mod_present "$system_enable_one_mod_name" ;
local _ret=$?
if [ "x${_ret}" != "x0" ]; then 
  echo "system_enable_one_mod : no such module \"$system_enable_one_mod_name\""; return; 
else dbg_echo system 3 \"${system_enable_one_mod_name}\" module present  1>&2 ; fi

echo "system_enable_one_mod $system_enable_one_mod_name begin"
# hook before module enabling
main_call_hook before_system_enable_one_mod $*

export CURRENT_TRANSACTION_ID=$trid
system_trans_begin $trid system module_enable $FUNCNAME

main_enable_one_mod $system_enable_one_mod_name

local modcfg="${main_cfg_modpath}/${system_enable_one_mod_name}.modconfig"
system_trans_register  $trid system module_enable $modcfg
if [ -f ${modcfg}.bak ]; then
system_trans_register  $trid system module_enable ${modcfg}.bak
else
msg_echo system 1 "\"$name\" module enabled first time..."
fi

# after module enabling
main_call_hook after_system_enable_one_mod $*

#MODINFO_dbg_cache=4
#system_installable_files_install $name
system_call_dgridsys system finish_module_enabling $system_enable_one_mod_name $trid

system_trans_end "$trid" system module_enable
unset CURRENT_TRANSACTION_ID

echo "system_enable_one_mod $system_enable_one_mod_name end"
}
function system_finish_module_enabling
{
local name="$1"
local trid="$2"
#MODINFO_dbg_cache=4

export CURRENT_TRANSACTION_ID=$trid

# after module enabling
main_call_hook before_system_finish_module_enabling $*

system_installable_files_install $name $trid
#system_config_samples_install $name $trid

# main hook to add something in system_finish_module_enabling
main_call_hook system_finish_module_enabling $*

# after finishing of module enabling
main_call_hook after_system_finish_module_enabling $*

}

function system_disable_one_mod
{
local system_disable_one_mod_name=$1
local trid=`system_trans_genid`

local moddir=MODINFO_modpath_${system_disable_one_mod_name}
if [ x${!moddir} == x ]; then echo "system_disable_one_mod : no such module \"$system_disable_one_mod_name\""; return;fi

local modenabled=MODINFO_enable_${system_disable_one_mod_name}
if [ x${!modenabled} != "xY" ]; then echo "system_disable_one_mod : \"$system_disable_one_mod_name\" already disabled"; return;fi

echo "system_disable_one_mod $system_disable_one_mod_name begin"

export CURRENT_TRANSACTION_ID=$trid
system_trans_begin $trid system module_disable $FUNCNAME

# actions
main_disable_one_mod $system_disable_one_mod_name

local modcfg="${main_cfg_modpath}/${system_disable_one_mod_name}.modconfig"
system_trans_register  $trid system module_enable $modcfg
system_trans_register  $trid system module_enable ${modcfg}.bak


system_finish_module_disabling $system_disable_one_mod_name $trid

system_trans_end $trid system module_disable
unset CURRENT_TRANSACTION_ID
echo "system_disable_one_mod $system_disable_one_mod_name end"
}

function system_finish_module_disabling
{
local name="$1"
local trid="$2"

export CURRENT_TRANSACTION_ID=$trid
#MODINFO_dbg_cache=4
#system_installable_files_remove $name
#system_installable_files_remove $name
}

# call hooks to activate module on this node
system_activate_one_mod()
{
local name=$1
dbg_echo system 2 "system_activate_one_mod: begin"  1>&2
dbg_echo system 2 "system_activate_one_mod: end"  1>&2
}
system_activate_all_mods()
{
echo -n
dbg_echo system 2 "system_activate_all_mods: begin"  1>&2
main_call_hook activate_on_this_node $*
dbg_echo system 2 "system_activate_all_mods: end"  1>&2
}


system_cmd_update()
{
echo -n
dbg_echo system 2 "system_cmd_update: begin"  1>&2
local mod=${system_dgrid_update_module}
local f=${system_update_override_module}_update_override

if is_function_exists $f ; then
dbg_echo system 2  "system_cmd_update() run $f $*"  1>&2
eval "$f $*"
exit
else
dbg_echo system 2  "system_cmd_update() \"$f\" not exists, ok, normal way"  1>&2
fi
main_call_hook pre_update_this_node $*
# summon download&update
main_call_hook do_update_this_node $*
# normal modules do what they need
main_call_hook update_this_node $*
main_call_hook post_update_this_node $*

dbg_echo system 2 "system_cmd_update: end"  1>&2
}

##############################################

system_print_module_info()
{
echo "system: mod info, called system_print_module_info"

}




##############################################


############ cli integration  ################

system_cli_help()
{
dgridsys_s;echo "system        - operations with this node"
dgridsys_s;echo "system update - update system [interface, using some present module]"
#dgridsys_s;echo "system activate-all-mods - activate all modules"
#dgridsys_s;echo "system install-files - [sys] install installable (when module enabled) files"
dgridsys_s;echo "system install-files <module name> - [sys] install installable files for module"
dgridsys_s;echo "system install-files-list - list modules installable files"
dgridsys_s;echo "system deploy-entry-list - list modules deploy packages"
dgridsys_s;echo "system deploy-entry-do <deploy id> - deploy deplyables for this node"
#dgridsys_s;echo "system CMDTWO - <xxx> <yyy> .... -"
}


system_cli_run()
{
maincmd=$1
cmd=$2
name=$3

dbg_echo system 5  x${maincmd} == x"system"
if [ x${maincmd} == x"system"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
system_cli_help
fi


if [ x${cmd} == x"system_srvremote_exec_function"  ]; then
echo -n
shift 2
system_srvremote_exec_function $*
fi

if [ x${cmd} == x"update"  ]; then
echo -n
system_cmd_update $*
fi


if [ x${cmd} == x"config_samples_list"  -o x${cmd} == x"system_config_samples_list" ]; then
export MODINFO_dbg_cache=4
system_installable_files_get
fi
if [ x${cmd} == x"install-files-list"  -o x${cmd} == x"install_files_list" ]; then
#system_config_samples_get
#export MODINFO_dbg_cache=4
system_installable_files_list_cmd
fi

if [ x${cmd} == x"install_files"  -o x${cmd} == x"install-files"  ]; then
echo -n
export CURRENT_TRANSACTION_ID="NONE"
system_installable_files_install $name
fi

if [ x${cmd} == x"deploy-entry-list" ]; then
#export MODINFO_dbg_system=4
system_deploy_entry_list_cmd
fi

if [ x${cmd} == x"deploy-entry-do"  ]; then
echo -n
export CURRENT_TRANSACTION_ID="NONE"
system_deploy_entry_do_cmd $name
fi




if [ x${cmd} == x"activate-all-mods"  -o x${cmd} == x"activate-all"  ]; then
echo -n
system_activate_all_mods
fi


# "system"
if [ x${cmd} == x"finish_module_enabling"  ]; then
echo -n
shift 2
echo "system_finish_module_enabling $*"
system_finish_module_enabling $*
fi
if [ x${cmd} == x"finish_module_disabling"  ]; then
echo -n
shift 2
echo "system_finish_module_disabling $*"
system_finish_module_disabling $*
fi


}

