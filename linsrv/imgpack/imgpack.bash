#!/bin/bash

if [ x$MODINFO_loaded_imgpack == "x" ]; then
export MODINFO_loaded_imgpack="Y"
else
return
fi

#MODINFO_dbg_imgpack=0
#MODINFO_enable_imgpack=

source ${MODINFO_modpath_imgpack}/imgpack.defaultvalues

if [ -f ./dgrid-site/etc/imgpack.conf ]; then
source ./dgrid-site/etc/imgpack.conf
fi

function imgpack_is_climenuid
{
return 1
}

imgpack_cfg_vars()
{
echo -n imgpack_dev_disk_byid imgpack_id_name imgpack_src_iso imgpack_type imgpack_unpack_workdir
}

function imgpack_cmdrun
{
echo $*
}

# hook _run_menu_op() form climenu
imgpack_run_menu_op()
{
dbg_generic_listvars imgpack 2 "climenu_" 1>&2
local v
dbg_echo imgpack 4 F "START"
dbg_echo imgpack 6  "1=$1 2=$2"

local param1=$2 cmd=$1;
local imgpack_param1=$param1
local imgpack_cfgdir=`imgpack_target_cfgdir`

echo imgpack_cfgdir=$imgpack_cfgdir

if [ "x$imgpack_param1" == "x" ]; then echo "no target cfg file found"; echo "usage: $0 [imgpack target id]"; exit; fi

#dbg_echo imgpack 4 F "================ $imgpack_param1 ==================="
dbg_echo imgpack 4 "============ $imgpack_param1 =============="


#############################
# load template for config

_ff=$imgpack_cfgdir/$imgpack_param1/imgpack.conf

local imgpack_config_template=""
local _tm=`grep imgpack_config_template= $imgpack_cfgdir/$imgpack_param1/imgpack.conf`
#dbg_echo imgpack 6 tm=${_tm}
eval "${_tm}"
_tm=${MODINFO_modpath_imgpack}/templates/${imgpack_config_template}.conf
if [ "x${imgpack_config_template}" == "x" ]; then
dbg_echo imgpack 4 "No imgpack_config_template set"
else
dbg_echo  imgpack 4 "Config template file: ${_tm}"
fi
if [ -a ${_tm} ]; then
 dbg_echo imgpack 6 "source ${_tm}"
 source ${_tm};
else
 dbg_echo  imgpack 4 "Config template file not found"
fi


################################
# load config. "source" bash cmd should be removed in the future.
echo ${_ff}
source ${_ff}
export imgpack_this_cfgdir="$imgpack_cfgdir/$imgpack_param1/"
# end config loading

#check imgpack_type
if [ "x$imgpack_type" == "x" ]; then echo "imgpack_type should be set"; exit; fi

fvars="${MODINFO_modpath_imgpack}/${imgpack_type}/vars"

fcmd0="${MODINFO_modpath_imgpack}/univ/$cmd"
#fcmd="${MODINFO_modpath_imgpack}/${imgpack_default_exec}/$cmd"
fcmd="${MODINFO_modpath_imgpack}/${imgpack_type}/$cmd"
#fpath=


local _cmd_executed=0

# load default values of vars for repack type
if [ -a $fvars ]; then
 dbg_echo imgpack 4 F "source $fvars"
 source $fvars;
fi

# exec command if avaliable in repack type
if [ -a $fcmd ]; then
 dbg_echo imgpack 4 F "exec $fcmd $param1"  #echo source $fcmd $param1
 source $fcmd; _cmd_executed=1
fi

# exec command if avaliable in "universal" repack type
if [ -a $fcmd0 -a x${_cmd_executed} = "x0" ]; then
 dbg_echo imgpack 4 F "exec $fcmd $param1"  #echo source $fcmd $param1
 source $fcmd0;  _cmd_executed=1
fi


if [ "x${_cmd_executed}" == "x0" ]; then
dbg_echo imgpack 4 F "\"$cmd\" not found"
echo "NOT FOUND"
fi
}

imgpack_print_module_info()
{
echo "imgpack: pack/repack iso/usb/tftp linux boot images"
}

imgpack_target_cfgdir()
{
local pref=`nodecfg_nodeid_cfgdir $THIS_NODEID`
echo "${pref}/imgpack/$tt"
}


imgpack_status_full()
{
#echo "Check cfg file"

if imgpack_check_thisnode ; then
echo -n
#echo "YES, ret=$?"
dbg_echo imgpack 4 "imgpack_check_thisnode(), OK."
else
exit
#echo "NO"
fi


#nodecfg_nodeid_cfgdir $THIS_NODEID
#imgpack_target_cfgdir 111
echo
}

imgpack_check_thisnode()
{
if [ x$THIS_NODEID == "x" ]; then
echo "THIS_NODEID not defined"
return 4
fi
return 0
}

imgpack_cmd_list()
{
echo -n
if imgpack_check_thisnode ; then
dbg_echo imgpack 4 "imgpack_check_thisnode(), OK."
else
echo "imgpack_check_thisnode(), not OK."
exit
fi

local pref=`nodecfg_nodeid_cfgdir $THIS_NODEID`
pref=${pref}/imgpack
#echo "${pref}/imgpack/$tt"
ls $pref
}


############ cli integration  ################

imgpack_cli_help()
{
dgridsys_s;echo "imgpack status-full - check modules status, configs, etc"
dgridsys_s;echo "imgpack list - list targets to build-"
dgridsys_s;echo "imgpack cfg [trgt] - config load and show"
dgridsys_s;echo "imgpack ... - <xxx> <yyy> .... -"
}


imgpack_cli_run()
{
maincmd=$1
cmd=$2
name=$3
param1=$3


dbg_echo imgpack 5  x${maincmd} == x"imgpack"
if [ x${maincmd} == x"imgpack"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
imgpack_cli_help
fi


if [ x${cmd} == x"status-full"  ]; then
echo -n
echo "Run: imgpack_run_menu_op cfg status-full"
imgpack_status_full
fi

if [ x${cmd} == x"list"  ]; then
imgpack_cmd_list
fi

### try to run any cmd, check just  ####
if [[ $cmd =~ ^[A-Za-z0-9_]+$ ]]; then
dbg_echo imgpack 2 F "imgpack_run_menu_op $cmd $param1"
imgpack_run_menu_op $cmd $param1
fi
#### end ####


}

