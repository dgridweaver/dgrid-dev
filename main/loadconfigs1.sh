#!/bin/bash

#
# == dgrid mode_distribution loader ==
# drgid node (installation) have different modes of operation
# when you download dgrid from github/whatever and unpack archive 
# some scripts detect that and load modules in this mode_distribution state
#
###

# distribution mode loader START
# already should be called from root of dgrid unpacked archive
if [ -a ./main/dgrid-structure.conf ]; then
echo -n
else
echo "loadconfigs1: No unpacked dgrid distribution found"
exit
fi

source ./main/dgrid-structure.conf
if [ -a ./etc/dgrid-distr.conf ]; then
 source ./etc/dgrid-distr.conf
else
 echo -n #echo "No distribution config ./etc/dgrid-distr.conf" 1>&2 
fi
# sub-distribution config
# ./etc/dgrid-subdistr.conf"

export DGRIDBASEDIR=`pwd`
export DGRIDDISTDIR=$DGRIDBASEDIR
export DGRIDDISTDIRrel="."

source ./main/lib.sh
source ./main/main.bash

##############################################
# runtime load  ###
##############################################
export DGRID_this_arch=$(lib_get_arch)
dbg_echo loadconfigs 6 "arch=$DGRID_this_arch"
source ${DGRIDDISTDIRrel}/main/runtime.bash

# runtime load part2
export DGRID_PATH_rt=":";export DGRID_PATH_rtrel=":"
lib_runtime_load_rt_list $DGRID_RUNTIME_LOADLIST
##############################################

# redefine modpath for loadconfigs1.sh excution path. REMOVE IN THE FUTURE
export main_modpath=$main_modpath_distr

##############################################
# load "distrib" modules
##############################################
export MODINFO_files="`main_list_modinfo`"
MODINFO_files_distr_enabled=`loadconfigs1_active_modules_list "$MODINFO_files"`

# very simple way to load modules. not correct but assumed that distr mode 
# mods have adapted to do so

for __s in $MODINFO_files_distr_enabled; do
__s1="${__s/\.modinfo/.bash} ${__s1}"
done
MODINFO_files_distr_enabled=${__s1}
export MODULE_list_enabled="`loadconfigs1_enabled_modules_list`"
unset __s1 __s

dbg_echo loadconfigs1 10 MODINFO_files_distr_enabled=$MODINFO_files_distr_enabled

var=`modinfo_header_var1`; eval "$var"; 
dbg_echo loadconfigs1 10 "run+eval modinfo_header_var1 var=\"$var\""
unset var

# load all marked modules
for __s in $MODINFO_files_distr_enabled; do
dbg_echo loadconfigs1 6 "source ${__s}"
source ${__s}
done
##############################################

# set variables



##############################################

