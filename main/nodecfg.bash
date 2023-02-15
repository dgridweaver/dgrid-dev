#!/bin/bash

export nodecfg_path="./${dgrid_bynodes_dir}"
export nodecfg_system_prefix="./dgrid-site"
export nodecfg_latstime_prefix="./not-in-vcs"

export nodecfg_grppath="./bygroups"

############################################

nodeconf_vars()
{
echo -n " " NODE_ID NODE_IDsuffix NODE_UUID NODE_HOST NODE_INSTPATH \
 NODE_GROUPS_append NODE_hostname NODE_hostid NODE_USER " "
}

nodeconf_vars_all()
{
nodeid_vars_all
}

nodeid_vars_all() # [API]
{
#nodeid_vars
nodeconf_vars
echo -n " "
hostid_vars_all
#hostinfo_vars
echo -n " "
#hook_nodeid_vars
main_call_hook nodeid_vars $*
}



# 
generic_loadconf() # [API]
{
local cfg varprefix varsuffix varfunc params output_mode
cfg=$1
varfunc=$2
params=$3
eval $params
#params=" varprefix=$varprefix varsuffix=$varsuffix "
dbg_echo generic 8 "generic_loadconf(): output_mode=$output_mode"

if [ "x$output_mode" == "x" ]; then
output_mode="simple"
fi
params=`generic_filter_param_str output_mode "$params"`
dbg_echo generic 4 "generic_loadconf(): cfg=$cfg varfunc=$varfunc params=\"$params\"" 
dbg_echo generic 8 "generic_loadconf(): output_mode=$output_mode"
if [ "$output_mode" = "simple" ]; then
 dbg_echo generic 4 "generic_loadconf(): call __load_cfg_file_simple"
 __load_cfg_file_simple $cfg $varfunc $params
 return
fi
if [ "$output_mode" = "stdout" ]; then
 dbg_echo generic 4 "generic_loadconf(): call __load_cfg_file_export"
 __load_cfg_file_export $cfg $varfunc $params 
 return
fi
}

load_cfg_file_stdout()
{
local cfg varprefix varsuffix varfunc params
cfg=$1
varfunc=$2
#params="export_vars=1 varprefix=aaa varsuffix=bbb"
params="_export=1"
dbg_echo generic 4 "load_cfg_file_stdout(): cfg=$cfg varfunc=$varfunc varprefix=$varprefix varsuffix=$varsuffix" 
__load_cfg_file_export $cfg $varfunc $params
}

__load_cfg_file_export()
{
local cfg varprefix varsuffix varfunc cfg params params2
cfg=$1
varfunc=$2
params=$3
eval $params;

#varprefix=$3
#varsuffix=$4

dbg_echo generic 4 "__load_cfg_file_export(): cfg=$cfg varfunc=$varfunc varprefix=$varprefix varsuffix=$varsuffix" 
dbg_echo generic 4 "__load_cfg_file_export(): params=\"$params\"" 

if [ -f $cfg ]; then
echo -n
else
return
fi
source $cfg

if [ x$varsuffix == "xNO_SUFFIX" ]; then unset varsuffix ; fi
if [ x$varprefix == "xNO_PREFIX" ]; then unset varprefix ; fi

local vars=`$varfunc`
dbg_echo generic 4 "__load_cfg_file_export(): vars=\"$vars\"" 
for var in $vars; do
if [ "x${!var}" == "x" ]; then
echo -n
else
echo "export ${varprefix}${var}${varsuffix}=\"${!var}\" ;"
fi
done
}

__load_cfg_file_simple()
{
cfg=$1
varfunc=$2

if [ -a $cfg ]; then
source $cfg
else
dbg_echo nodecfg 3 "load_cfg_file_simple() : file $cfg not exists" 
fi
}


nodecfg_varid_from_nodeid() # [API]
{
varid=$1
varid=${varid/@/_0_}
varid=${varid/:/_1_}
varid=${varid//./_}
varid=${varid/-/_}
echo $varid
}

nodecfg_nodeid_exists() # [API] [RECOMENDED]
{
#nodeconf_exists_nodeid $*
local nodeid cfg
nodeid=$1

if [ -z "$nodeid" ]; then 
dbg_echo nodecfg 1 "nodecfg_nodeid_exists : empty nodeid" 
return ;
fi

cfg=`nodecfg_nodeid_cfgfile $nodeid`
dbg_echo nodecfg 10 "F nodecfg_nodeid_exists : cfg=$cfg" 

if [ -z "$cfg" ]; then
 return 1
fi

if [ -f $cfg ]; then
 echo -n
else
 return 1
fi
return 0
}

nodecfg_nodedir_list_set()
{
var=`find $nodecfg_path -iname "*.nodeconf" | xargs --no-run-if-empty -n 1 dirname `
echo "export NODECFG_nodedir_list=\"$var\" ; "
dbg_echo nodecfg 12 "find : var=\"$var\"" 
export NODECFG_nodedir_list="$var"
}
nodecfg_nodeconf_list_set()
{
var=`find $nodecfg_path -iname "*.nodeconf"`
echo "export NODECFG_nodeconf_list=\"$var\" ; "
dbg_echo nodecfg 12 "find : var=\"$var\"" 
export NODECFG_nodeconf_list="$var"
}


_nodeconf_load_nodeprefixed()
{
local nodeid pref varprefix
echo -n
nodeid=$1

varid=`nodecfg_varid_from_nodeid $nodeid`
#varsuffix=_$varid
varprefix="${varid}_"

_nodeconf_load $nodeid $varprefix
}

_nodeconf_load()
{
#
local nodeid pref
nodeid=$1
pref=$2
pushd $DGRIDBASEDIR > /dev/null

# check if any node like this
nodecfg_nodeid_exists $nodeid
if [  $? == 0 ]; then
 dbg_echo nodecfg 2 "_nodeconf_load : ok, node $nodeid found" 
else
 echo "ERROR: no such node \"$nodeid\""
 exit
fi

unset `nodeconf_vars_all`

#NODE_GROUPS_all=","

_nodeid_cfgfile=`nodecfg_nodeid_cfgfile ${nodeid}`
_nodeid_cfgdir=`nodecfg_nodeid_cfgdir ${nodeid}`

##### ADDITIONAL CFG #######

#_path=${nodecfg_path}/${nodeid}/etc/nodeconf
_path=${_nodeid_cfgdir}/etc/nodeconf

if [ -d ${_path} ]; then

 LISTFILES=`find ${_path}  -type f`
 for cfg in $LISTFILES; do
 varX=`load_cfg_file_stdout $cfg nodeconf_vars_all`
 #echo $varX;
 eval $varX;
 NODE_GROUPS_all="$NODE_GROUPS_all $NODE_GROUPS_append"
 #unset `nodeconf_vars_all`
 unset NODE_GROUPS_append
 done

fi

####### MAIN CFG ###########


#cfg=${nodecfg_path}/${nodeid}/this.nodeconf
cfg=${_nodeid_cfgfile}

var1=`load_cfg_file_stdout $cfg nodeconf_vars_all`
#echo $var1;
eval $var1;
NODE_GROUPS_all="$NODE_GROUPS_all,$NODE_GROUPS_append"
#unset `nodeconf_vars_all`
unset NODE_GROUPS_append

#### groups #####
NODE_GROUPS_all=${NODE_GROUPS_all//,/ }
dbg_echo nodecfg 3 [2] NODE_GROUPS_all=$NODE_GROUPS_all 
NODE_GROUPS_append=$NODE_GROUPS_all

export NODE_GROUPS_dirs

for grp in $NODE_GROUPS_all; do
cfg=${nodecfg_grppath}/${grp}/;
#echo echo $cfg ";"
if [ -f ${cfg}/this.groupconf ]; then 
dbg_echo nodecfg 3 [2] "$cfg : ok, this dir exists" 
NODE_GROUPS_dirs="$NODE_GROUPS_dirs ${cfg}"
fi
done

###### output  #####

for var in `nodeconf_vars_all` NODE_GROUPS_dirs ; do
if [ x"${!var}" == x ]; then
echo -n
else

# trim leading & ... spaces
res="${!var}"; res=`generic_trim "$res"`
read -r $var <<< "$res"

echo "export ${pref}${var}=\"${!var}\" ;"

#echo
fi
done
popd $DGRIDBASEDIR > /dev/null
}

############################

_nodecfg_nodeid_from_file()
{
local _id _res __f f NODE_ID
f=$1
dbg_echo nodecfg 12  "_nodecfg_nodeid_from_file() f=$f"
############
# find/load hostid
local saved_NODE_ID="$NODE_ID"
if [ -a "${f}" ]; then
__res=`grep NODE_ID= ${f}`
eval ${__res}
unset __res
else
echo -n; exit
fi
_id="$NODE_ID"
HOST_id="$saved_NODE_ID"; unset saved_NODE_ID
echo ${_id}
# nodeid loaded
#############
}



# 
nodecfg_vars_list_set()
{
local f _id varid var d
dbg_echo hostcfg 8  "nodecfg_vars_list_set() start, NODECFG_nodeconf_list=\"$NODECFG_nodeconf_list\" "
for f in $NODECFG_nodeconf_list ; do
_id=`_nodecfg_nodeid_from_file $f`
dbg_echo hostcfg 8  "_id=${_id}"

varid=`nodecfg_varid_from_nodeid ${_id}`
var="NODECFG_cfgfile_$varid"
echo "export $var=\"$f\" ; "
d=`dirname $f`
var="NODECFG_cfgdir_$varid"
echo "export $var=\"$d\" ; "
done
dbg_echo hostcfg 8  "nodecfg_vars_list_set() end"
}






nodecfg_nodeid_cfgfile() # [API]
{
local _id var cfg cfg1
_id=$1
var=`nodecfg_varid_from_nodeid ${_id}`
var=NODECFG_cfgfile_$var
dbg_echo nodecfg 6 "nodecfg_nodeid_cfgfile() : id=${_id} var=${var}" 

echo -n ${!var}
}
nodecfg_nodeid_cfgdir() # [API]
{
local _id var cfg cfg1
_id=$1
var=`nodecfg_varid_from_nodeid ${_id}`

var=NODECFG_cfgdir_$var

echo -n ${!var}
}



nodecfg_nodeid_load() # [API] [RECOMENDED]
{
local cfg varX nodeid pref

nodeid=$1
pref=$2

if [ x"$nodeid" == x ]; then
echo "[2] msg: nodecfg_nodeid_load(): nodeid is empty" 
return 1
fi

# next: use variables with cache

unset `nodeid_vars_all`

# chack if config present
cfg=`nodecfg_nodeid_cfgfile ${nodeid}`
if [ x"$cfg" == x"" ]; then
echo "[2] msg: nodecfg_nodeid_load(): nodeid=$nodeid not exists" 
return 1
fi

main_call_hook nodeid_before_load_api $*

varX=`_nodeconf_load $nodeid $pref`
dbg_echo nodecfg 12 "_nodeconf_load $nodeid $pref -->  varX=${varX}"  
eval $varX;unset varX

local _node_host_var="${pref}NODE_HOST"
local _node_host=${!_node_host_var}
dbg_echo nodecfg 3 "$NODE_ID NODE_HOST=${_node_host}"  

export hostinfo_loadconf_mode_exports=1
varX=`hostcfg_hostid_load_stdout ${_node_host} $pref`
eval $varX;

#hook_nodeid_load_api
main_call_hook nodeid_load_api $*
main_call_hook nodeid_after_load_api $*

}


nodecfg_nodeid_load_api()
{
#echo nid=$NODE_ID

if [ x$NODE_USER ]; then

while IFS='@' read -ra ARRAY; do
export NODE_USER=${ARRAY[0]}
done <<< "$NODE_ID"
#echo NODE_USER=$NODE_USER
export NODE_USER=$NODE_USER
fi

}




nodecfg_iterate_full_nodeid() # [API] [RECOMENDED]
{
local func _id _nodeconf_vars_list _dir
func=$1

pushd $DGRIDBASEDIR >  /dev/null

_nodeconf_vars_list=`nodeid_vars_all`


unset ${_nodeconf_vars_list}
#for _dir in $NODECFG_nodedir_list; do
for _cfg in $NODECFG_nodeconf_list; do

_id=`_nodecfg_nodeid_from_file ${_cfg}`


nodecfg_nodeid_load $_id

dbg_echo nodecfg 3 "$NODE_ID node=$NODE_HOST"  

# DEVELMARK
#echo "HOST_id $HOST_id" 2>&1

eval $func

unset ${_nodeconf_vars_list}
done

popd >  /dev/null
}




nodecfg_iterate_simple_nodeid()
{
local _dir f cfg
func=$1

pushd $DGRIDBASEDIR >  /dev/null

_nodeconf_vars_list="`nodeconf_vars_all` `hostfullconfig_vars_all`"
unset ${_nodeconf_vars_list}

for cfg in $NODECFG_nodeconf_list; do
dbg_echo nodecfg 12 "cfg=$cfg"

varX=`load_cfg_file_stdout $cfg nodeconf_vars_all`
eval $varX; dbg_echo nodecfg 20 "varX=\"$varX\""

hostcfg_hostid_load $NODE_HOST > /dev/null

#nodecfg_nodeid_load $NODE_HOST > /dev/null

# run iterate function
eval $func

unset ${_nodeconf_vars_list}
done
popd >  /dev/null
}


_this_nodeid_detect_hlpr()
{
HOSTNAME=`hostname`
local check_hostname

dbg_echo this 3 NODE_INSTPATH=$NODE_INSTPATH  DGRIDBASEDIR=$DGRIDBASEDIR
dbg_echo this 3 NODE_hostname=\"$NODE_hostname\" HOSTNAME=\"$HOSTNAME\"
dbg_echo this 3 "NODE_ID=$NODE_ID HOST_hostname=\"$HOST_hostname\""


check_hostname=$NODE_hostname
if [ x"$check_hostname" == x ]; then
check_hostname=$HOST_hostname
fi
dbg_echo this 3 "check_hostname=\"$check_hostname\""

if [ x"$NODE_INSTPATH" == x"$DGRIDBASEDIR" ]; then
if [ x"$check_hostname" == x"$HOSTNAME" ]; then
dbg_echo this 2 "THIS_NODEID=$NODE_ID"
echo "export THIS_NODEID=$NODE_ID"
return 0
fi
fi
return 1
}

this_nodeid_detect()
{
dbg_echo nodecfg 8 "this_nodeid_detect() start"
if [ -f ./not-in-vcs/etc/this-install.conf ]; then
source ./not-in-vcs/etc/this-install.conf
if [ x"$THIS_NODEID" == x ]; then
echo -n
else
echo "export THIS_NODEID=$THIS_NODEID"
return
fi
fi

nodecfg_iterate_simple_nodeid _this_nodeid_detect_hlpr

dbg_echo nodecfg 8 "DGRIDBASEDIR=$DGRIDBASEDIR"
dbg_echo nodecfg 8 "this_nodeid_detect() end"
}


nodecfg_envset_prestart()
{
dbg_echo nodecfg 2 "nodecfg_envset_prestart(): START"
nodecfg_nodedir_list_set
nodecfg_nodeconf_list_set
nodecfg_vars_list_set
dbg_echo nodecfg 4 "nodecfg_envset_prestart(): call hostcfg_hostconf_list_set"
hostcfg_hostconf_list_set
hostcfg_vars_list_set
dbg_echo nodecfg 4 "nodecfg_envset_prestart(): call this_nodeid_detect"
dbg_echo nodecfg 2 "nodecfg_envset_prestart(): END"
}
nodecfg_envset_prestart2()
{
dbg_echo nodecfg 2 "nodecfg_envset_prestart2(): START"

if [ x$dgrid_this_nodeid_notcached == "x1" ]; then
dbg_echo nodecfg 4 "dgrid_this_nodeid_notcached == 1, so no this_nodeid cache"
this_nodeid_detect
else
cache_wrap_func this_nodeid_detect this_nodeid_detect
fi
dbg_echo nodecfg 2 "nodecfg_envset_prestart2(): END"
}

source ${MODINFO_modpath_nodecfg}/hostcfg.bash
source ${MODINFO_modpath_nodecfg}/nodecfg_cfgstack.bash

