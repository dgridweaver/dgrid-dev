#!/bin/bash

if [ x$MODINFO_loaded_init == "x" ]; then
export MODINFO_loaded_init="Y"
else
return
fi

#MODINFO_dbg_init=0
#MODINFO_enable_init=


init_print_module_info()
{
echo "init: mod info, called init_print_module_info"

}

############ cli integration  ################

init_cli_help()
{
dgridsys_s;echo "init CMDONE - <xxx> <yyy> .... -"
dgridsys_s;echo "init CMDTWO - <xxx> <yyy> .... -"
}


init_cli_run()
{
maincmd=$1
cmd=$2
name=$3

dbg_echo init 5  x${maincmd} == x"init"
if [ x${maincmd} == x"init"  ]; then
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
init_cli_help
fi


if [ x${cmd} == x"check"  ]; then
echo -n
#init_check $*
echo ""
fi

}

