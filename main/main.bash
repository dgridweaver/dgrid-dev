#!/bin/bash

if [ x$MODINFO_loaded_main == "x" ]; then
export MODINFO_loaded_main="Y"
fi

# load other support modules


main_getmodlist_hlpr()
{
#echo $name;
mod_dir=`dirname $F`
modvar1="MODINFO_enable_${name}"

if [ x$f_experimental == x1 ]; then if [ ! x$allow_experimental == x1 ]; then
dbg_echo main 4 F "omitting f_experimental module"
echo main 4 F "omitting f_experimental module"
return
fi;fi

if [ x${!modvar1} == x"Y" ]; then modstat="[x]"; else modstat="[_]"; fi
if [ x${group} == x"" ]; then group="other";fi

#echo " $modstat | $name : $description;  [ $mod_dir ]"
printf "%7s | " $group
printf "%3s" "$modstat"
printf "%11s |" $name
printf "%10s | " $version
echo -n  "$description"
echo

#unset group modstat name version description f_experimental

}

function main_getmodlist
{
main_mod_runfunc 'main_getmodlist_hlpr'| sort
}


main_load_mod_cfg()
{
name=$1
mcfgdir=$main_cfg_modpath
cfg=$mcfgdir/${name}.modconfig
echo "main_load_mod_cfg : cfg = $cfg"
if [ -f "$cfg" ]; then
echo loadshellcfg "$cfg"
loadshellcfg "$cfg"
else
echo -n
fi
}

main_save_mod_cfg()
{
mcfgdir=$main_cfg_modpath
name=$1

cfg="$mcfgdir/${name}.modconfig"
echo "out $cfg"
if [ -f $cfg ]; then
dbg_echo main 3 "main_save_mod_cfg: (\"${cfg}\" exists, do \"cp $cfg ${cfg}.bak\""  1>&2
cp $cfg ${cfg}.bak
else
dbg_echo main 3 "main_save_mod_cfg: \"${cfg}\" not exists, do not create ${cfg}.bak"  1>&2
fi
cat /dev/null > $cfg
for i in `main_mod_state_vars`; do

if [ x${!i} == x ]; then
echo -n
else
echo $i=${!i}
#echo "write"
echo "$i=${!i}" >> $cfg
fi
#"$mcfgdir/$name"

done

# clear cache
cache_clear ALL
}



main_check_mod_present_hlpr()
{
local modname=$name # name defined inside
dbg_echo main 9 "[9] main_check_mod_present() modname_check=\"$modname_check\" modname=\"$modname\"" 1>&2

if [ "x${modname}" == "x${modname_check}" ]; then
dbg_echo main 9 "[9] main_check_mod_present() OK, modname_check=$modname_check found" 1>&2 
_returncode=0
return 0
else
dbg_echo main 9 "[9] main_check_mod_present() NONE, name=\"$modname_check\" not matched modname=\"$modname\"" 1>&2 
fi
}

main_check_mod_present() # check if module avaliable in search dirs
{
local modname_check=$1
local _returncode=255
if [ x$modname_check == x ]; then
echo "system_check_mod_present, error - need module name"
exit
fi
main_mod_runfunc "main_check_mod_present_hlpr"
dbg_echo main 9 "main_check_mod_present() {_returncode}=${_returncode}" 1>&2 
#dbg_echo main 9 "main_check_mod_present() modname_check=\"$modname_check\" modname=\"$modname\"" 1>&2 
#dbg_echo main 4 "main_check_mod_present() NONE, modname_check=$modname_check not found" 1>&2 
return ${_returncode}
}



# version stamp computation
main_mod_version_stamp_hlpr()
{
local var1=$1; local var3=$3; local var4=$4; local res ; #echo $var1*100000+1000*$var3+$var4
let res=1000000*var1+1000*var3+var4 ; echo $res
}
main_mod_version_stamp()
{
local var=$1 ; local var1=${var/-/ } ; local var2=${var1/./ } ; local var3=${var2/./ }
main_mod_version_stamp_hlpr $var3
}
# end: version stamp computation

main_find_module_dir()
{
local name=$1
local f
if [ x$name == x ]; then
echo "main_find_module_dir : module name not set"; exit
fi

for f in $MODINFO_files ; do
if [ `basename $f` == ${name}.modinfo ]; then
dirname $f
return
fi
done
}
main_find_module_modinfo_file()
{
local name=$1
local f
if [ x$name == x ]; then
echo "main_find_module_dir : module name not set"; exit
fi

for f in $MODINFO_files ; do
if [ `basename $f` == ${name}.modinfo ]; then
echo $f
return
fi
done
}


main_enable_one_mod()
{
echo "main_enable_one_mod : start"
local enable_one_mod_name=$1
if [ x$enable_one_mod_name == x ]; then
echo "main_enable_one_mod : name not set"; exit
fi
if [ x${MOD_enable} == xY ]; then
echo "main_enable_one_mod : module already enabled"
return
fi
dbg_echo main 3 "main_enable_one_mod() name = $enable_one_mod_name"  1>&2

main_check_mod_present "$enable_one_mod_name"
local _ret=$?
dbg_echo main 3 "main_enable_one_mod() -----  main_check_mod_present "$enable_one_mod_name" ret = ${_ret}"  1>&2
#print_vars
if [ x${_ret} == x0 ] ; then 
dbg_echo main 3 "\"${enable_one_mod_name}\" module present, ok"  1>&2 ; 
else 
  echo "main_enable_one_mod : no such module \"$enable_one_mod_name\""; return; 
fi

unset `main_mod_state_vars`
local moddir_value=`main_find_module_dir $enable_one_mod_name`
#local modinfo_file=`main_find_module_modinfo_file $name`
dbg_echo main 3 "main_enable_one_mod() moddir_value == $moddir_value"  1>&2
source ${moddir_value}/${enable_one_mod_name}.modinfo
#need load mod manually, so commented out
#main_load_mod_cfg $name

if [ x$f_experimental == x1 ]; then if [ ! x$allow_experimental == x1 ]; then
echo "ERROR: module is blocked(experimental), aborting."
echo "You need to set allow_experimental=1 in your dgrid-site/etc/dgrid.conf"
return
fi; fi
MOD_name="$enable_one_mod_name"
MOD_version="$version"
dbg_echo main 3 "main_enable_one_mod: version=$version"  1>&2
MOD_path=${!moddir}
MOD_version_stamp=`main_mod_version_stamp "$version"`
export MOD_enable="Y"
main_save_mod_cfg $enable_one_mod_name
dbg_echo main 3 "main_enable_one_mod : end"
}


main_disable_one_mod()
{
echo "main_disable_one_mod : start"
disable_one_mod_name=$1
if [ x$disable_one_mod_name == x ]; then
echo "main_disable_one_mod : name not set"; exit
fi
moddir=MODINFO_modpath_${disable_one_mod_name}
if [ x${!moddir} == x ]; then echo "main_disable_one_mod : no such module"; return;fi

unset `main_mod_state_vars`
main_load_mod_cfg $disable_one_mod_name
source ${!moddir}/${disable_one_mod_name}.modinfo

if [ x${MOD_enable} == xN ]; then
echo "main_disable_one_mod : module already disabled"
return
fi
if [ x${MOD_enable} == x ]; then
echo "main_disable_one_mod : module already disabled"
return
fi


MOD_name="$disable_one_mod_name"
MOD_path=${!moddir}
MOD_version="$version"
#MOD_version_stamp=
export MOD_enable="N"
main_save_mod_cfg $disable_one_mod_name
echo "main_disable_one_mod : end"
}



main_exit_if_not_enabled()
{
local name variable

name=$1
#set|grep ^MODI
#echo variable=MODINFO_enable_$name
variable=MODINFO_enable_$name
if [ x${!variable} == xY ]; then
echo -n
else
echo "module \"$name\" not enabled, exiting"
exit
fi
}

main_load_module_into_context() # [API] - load module into context. warning - for system use only
{
local mod=$1
local name=$mod
echo -n
cd $DGRIDBASEDIR

#if main_check_mod_present $mod ; then exit ; fi
unset `main_mod_state_vars` `modinfo_vars`
main_load_mod_cfg $mod
echo MOD_enable=$MOD_enable
if [ x$MOD_enable == xY ]; then
echo -n
else
echo "cannot load not enabled module"
return
fi
#( set -o posix ; set )
#local modinfo_file=`main_find_module_modinfo_file $mod`; #source $modinfo_file
local mod_dir=`main_find_module_dir $mod`

local varname="MODINFO_modpath_${name}"
# http://mywiki.wooledge.org/BashFAQ/006 : # In Bash, we can use read and Bash's here string syntax:  #IFS= read -r $varname <<< "$F"
read -r $varname <<< "$mod_dir"
unset varname

local varname="MODINFO_enable_${name}"
# http://mywiki.wooledge.org/BashFAQ/006 : # In Bash, we can use read and Bash's here string syntax:  #IFS= read -r $varname <<< "$F"
read -r $varname <<< "Y"
unset varname

echo "source ${mod_dir}/${mod}.bash" 1>&2
source ${mod_dir}/${mod}.bash

# mark as loaded
local varname="MODINFO_loaded_${name}"
# http://mywiki.wooledge.org/BashFAQ/006 : # In Bash, we can use read and Bash's here string syntax:  #IFS= read -r $varname <<< "$F"
read -r $varname <<< "Y"
unset varname

unset `main_mod_state_vars` `modinfo_vars`
}



###########
###########



_main_call_hook_list()
{

local hook params code hook_exists fTST PARAMS F mod
hook=$1
shift 1

#hook_exists_vars="hook_funclist_$hook="

for mod in $MODULE_list_enabled ; do

F=${mod}_${hook}
fTST=`type -t $F`

#echo "[2] fTST=$fTST" 1>&2
#dbg_echo main 4  fTST=$fTST 1>&2

if [ x$fTST  == x"function"  ]; then
 hook_exists="$hook_exists $F"
fi
done

echo $hook_exists

#cache_wrap_vars hook_${hook}_funclist "$hook_exists_vars" 1>&2

}

main_call_hook()
{
local hook params code funclist
hook=$1
shift 1
#var=

#funclist=`_main_call_hook_list $hook`
funclist=`cache_wrap_func hook_func_list_$hook _main_call_hook_list  $hook`

for F in $funclist ; do
dbg_echo main 2 run ${F} $PARAMS 1>&2
code="${F} $*"
eval $code
done

}

main_call_hook_OR()
{
local hook params code funclist ret r
hook=$1
shift 1
ret=1 # ret set to false

funclist=`cache_wrap_func hook_func_list_$hook _main_call_hook_list  $hook`
echo "funclist=$funclist"
for F in $funclist ; do
dbg_echo main 2 run ${F} $PARAMS 1>&2
code="${F} $*"
eval $code
r=$?; dbg_echo main 2 F "--- return=$r"
echo main 2 F "--- return=$r"
if [ "x$r" == "x0" ]; then ret=0; fi
done
echo "ret=$ret"
return $ret
}



#############

# init hook call

main_envset_start_hook()
{
# call at start of CLI/something program, to set env
main_call_hook envset_start $*
}
main_env_start_hook()
{
# call at start of CLI/something program
main_call_hook env_start $*
}
main_env_prestart_hook()
{
main_call_hook env_prestart $*
}
main_envset_prestart_hook()
{
main_call_hook envset_prestart $*
}

main_env_prestart2_hook()
{
main_call_hook env_prestart2 $*
}
main_envset_prestart2_hook()
{
main_call_hook envset_prestart2 $*
}


main_env_poststart_hook()
{
main_call_hook env_poststart $*
}
main_envset_poststart_hook()
{
main_call_hook envset_poststart $*
}


