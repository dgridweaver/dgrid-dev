#!/bin/bash


dgridsys_cli_help_cfgfiles()
{
#echo -n
dgridsys_s;echo "nodecfg cfgtrace <rel cfg path> - trace of cfg relative path, sample: etc/1.conf"
dgridsys_s;echo "nodecfg cfgvarshow <varname> [<rel cfg path>] - show variable on diff nodes"

}

_cfgfiles_var_show_hlp()
{
if [ -n "$cfgfiles_file" ]; then
cfgstack_load_byid $cfgfiles_file $NODE_ID
fi

#echo -n ${NODE_ID} : $cfgfiles_varname = \"${!cfgfiles_varname}\"
echo -n ${NODE_ID} : \"${!cfgfiles_varname}\"
echo

unset $cfgfiles_varname
}


cfgfiles_var_show()
{
local cfgfiles_varname cfgfiles_file
cfgfiles_varname=$1
cfgfiles_file=$2

unset $cfgfiles_varname
printf "    ------- %30s  -------\n" "variable: $cfgfiles_varname"
echo
nodecfg_iterate_full_nodeid _cfgfiles_var_show_hlp
echo
}


dgridsys_cli_cfgfiles()
{
local maincmd cmd param1
maincmd=$1
cmd=$2
param1=$3
param2=$4

if [ x$maincmd == x"nodecfg" ]; then
echo -n
else
return
fi

if [ x$cmd == x"cfgtrace" ]; then
echo
cfgstack_cfg_op $param1 $THIS_NODEID op=trace
echo
return
fi

if [ x$cmd == x"cfgvarshow" ]; then
echo
shift 2
#echo "param1=$param1"
if [ -n "$param1" ]; then
cfgfiles_var_show $*
return
else
echo "varname not set"
exit
fi
fi





return
}
