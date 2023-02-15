#!/bin/bash

#
#
# srv - system V like services for dgrid. External and internal as well.
#
#

if [ x$MODINFO_loaded_srv == "x" ]; then
export MODINFO_loaded_srv="Y"
else
return
fi

#MODINFO_dbg_system=0
MODINFO_msg_system=1

srv_is_registered_service()
{
local name=$1
echo -n
local _list=`main_call_hook srv_is_registered_service`
dbg_echo srv 4 "_list=${_list}"

local _srv
for _srv in ${_list}; do
    dbg_echo srv 4 "if [ x${_srv} == x$name ];"
    if [ x${_srv} == x$name ]; then
	dbg_echo srv 1 "Service \"$name\" registered"
	return 1
    fi
done
return 0
}



srv_CMD_service()
{
local srvcmd=$1
local srvname=$2

# test simple srv hooks if service present
if srv_is_registered_service $srvname ; then
echo "Service \"$srvname\" not registered"
exit
fi

local func

# call full implementation of srv start/stop/... if present
func="full_srv_implementation"
#set -x
unset srv_full_srv_implementation
main_call_hook $func $srvname
#set +x
dbg_echo srv 3 srv_full_srv_implementation=\"${srv_full_srv_implementation}\"
if [ x${srv_full_srv_implementation} == x1 ]; then
echo "Service \"$srvname\" implemented in full override xxx_full_srv_implementation() hook"
return
fi
# if full override implementation of srv not preset, use next level of hooks

# first - use 
local func="${srvcmd}_service_${srvname}"
main_call_hook $func

}

####


srv_status_service()
{
echo
srv_CMD_service status $*
echo
}

srv_start_service()
{
srv_CMD_service start $*
}

srv_stop_service()
{
srv_CMD_service stop $*
}


srv_help_service()
{
srv_CMD_service help $*
}

#################

srv_list_print_cmd()
{
local _list=`main_call_hook srv_is_registered_service`
dbg_echo srv 4 "_list=${_list}"

local _srv
for _srv in ${_list}; do
echo $_srv
done
}


############################################

srv_cli_help()
{
dgridsys_s;echo "srv        -  sysV like services for node daemons"
dgridsys_s;echo "srv list"
dgridsys_s;echo "srv status-all"
dgridsys_s;echo "srv [servicename] stop|start|status|help"
}


srv_cli_run()
{
maincmd=$1
name=$2
cmd=$3


dbg_echo srv 5  x${maincmd} == x"srv"
if [ x${maincmd} == x"srv"  ]; then
echo -n
export dgridsys_cli_cmd_exists=1
else
return 0
fi

shift 1

if [ x${name} == x""  ]; then
echo -n
shift 2
srv_cli_help
export dgridsys_cli_cmd_exists=1
exit 1
fi

# predefined services

if [ x${name} == x"list"  ]; then
echo -n
shift 2
#  list avail services
echo "Availiable servicres:"
srv_list_print_cmd
return 1
fi


if [ x${name} == x"status-all"  ]; then
echo -n
shift 2
#  list avail services
#echo "Availiable services:"
echo "STATUS-ALL STUB"
#srv_status_all_cmd
return 1
fi


# [end] predefined services


if [ x${cmd} == x""  ]; then
echo -n
shift 2
srv_help_service $name 
export dgridsys_cli_cmd_exists=1
return
fi



# commands to services

if [ x${cmd} == x"start"  ]; then
echo -n
shift 2
srv_start_service $name 
fi

if [ x${cmd} == x"stop"  ]; then
echo -n
shift 2
srv_stop_service $name 
fi

if [ x${cmd} == x"status"  ]; then
echo -n
shift 2
srv_status_service $name 
fi




return 1

if [ x${cmd} == x"update"  ]; then
echo -n
#srv_cmd_ $*
fi


}

