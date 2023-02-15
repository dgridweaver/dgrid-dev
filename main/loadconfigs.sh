
#############  bootstrap file for shell scripts -- 1st stage  #########################

# DGRID_mode_distrubution_enable  --  set this var in script to allow 
#   distrubution only execution mode. I.e script that work after just 
#   unpack dgrid archive and run.
# DGRID_mode__enable 
export DGRID_f_distribution=0 # check path & files and flag if distribution detected
export DGRID_f_allow_no_thisnode=0

# loading of dgrid main config

if [ -f "./dgrid-site/etc/dgrid.conf" ]; then
echo -n
else
 if [ -a "./main/loadconfigs1.sh" -a "x$DGRID_mode_distrubution_enable" == x1 ]; then
  # load dgrid in distribution mode
  # set flags 
  export DGRID_f_distribution=1
  export DGRID_f_allow_no_thisnode=1
  export DGRID_f_loadconfigs="loadconfigs1.sh"
  source "./main/loadconfigs1.sh"
  return
 else 
  echo -n "loadconfigs.sh:  ./dgrid-site/etc/dgrid.conf not found : "
  echo "node mode unavaliable, dgrid not initialized, aborting"
  exit
 fi
fi
export DGRID_f_loadconfigs="loadconfigs.sh" # default mode

#### dbg_echo loadconfigs "loadconfigs load dgrid-structure.conf" 1>&2
source ./dgrid/main/dgrid-structure.conf

source ./dgrid-site/etc/dgrid.conf

if [ -f "./dgrid-site/etc/cache-dgrid.conf" ]; then
source "./dgrid-site/etc/cache-dgrid.conf"
fi

#

export DGRID_gridname
export DGRIDBASEDIR=`pwd`
export DGRIDDISTDIR=${DGRIDBASEDIR}/dgrid
export DGRIDDISTDIRrel=./dgrid
export dgrid_this_nodeid_notcached

if [ -d ./dgrid ]; then
echo -n
else
echo "ABORT! [BUG] we are not in dgrid install dir!"
exit
fi

############

unset d

############

# main module
######dbg_echo loadconfigs "loadconfigs main/lib.sh ; main/main.bash"
. ./dgrid/main/lib.sh
. ./dgrid/main/main.bash
dbg_echo loadconfigs 12 "loadconfigs.sh dbg_echo loaded; after main/lib.sh ; main/main.bash " 1>&2


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


############
# cache
source ./dgrid/main/cache/cache.inc.sh

var=`cache_key_set`
eval ${var} ; unset var

var=`cache_path_set`
#echo [2] var=$var 1>&2
eval $var; unset var


#echo [2] cache_key=$cache_key 1>&2
dbg_echo cache 3 loadconfigs:cache_path=$cache_path 1>&2

# end cache init
############

dbg_echo loadconfigs 10 "DGRIDBASEDIR=$DGRIDBASEDIR"

###############################
# MODINFO_files variable set
dbg_echo loadconfigs 10 "MODINFO_files=\`main_list_modinfo\`"
export MODINFO_files="`main_list_modinfo`"
dbg_echo loadconfigs 10 "MODINFO_files=\"$MODINFO_files\""

# set mod state variables for always enabled modules
main_modules_always_enabled

##############################
# Set MODINFO_modpath_* , MODINFO_enable_*
var=`modinfo_header_var1`; eval "$var"; 
dbg_echo loadconfigs 10 "run+eval modinfo_header_var1 var=\"$var\""
unset var


###############################
# Set MODULE_list , set MODINFO_modpath_* variables
# MODULE_list_all , MODULE_list_enabled , MODULE_list_disabled
var=`cache_wrap_func modinfo_header_module_list`
#var=`modinfo_header_module_list`
dbg_echo loadconfigs 10 "run+eval modinfo_header_module_list var="
dbg_echo loadconfigs 10 "--Begin var--"; dbg_echo loadconfigs 10 $var; dbg_echo loadconfigs 10  "--End var--"
eval "$var";unset var


#############  bootstrap file for shell scripts  - 2nd stage  ##################

dbg_echo loadconfigs 10 "run+eval_result main_mod_runfunc_fast_enable main_load_mod_functions_fast"
var=`main_mod_runfunc_fast_enable main_load_mod_functions_fast`
eval $var;unset var;


################################################################################

# call hooks before anything happened in CLI/script/whatever

# hook for var set
dbg_echo loadconfigs 10 "call hook main_envset_prestart_hook" 1>&2
if [ x$dgrid_notcached_envset_prestart == "x1" ]; then
var=`main_envset_prestart_hook`
else
var=`cache_wrap_func main_envset_prestart_hook`
fi
eval $var;
dbg_echo_var_stderr loadconfigs 8 $var ;
unset var;
# for calls
dbg_echo loadconfigs 10 "call hook main_env_prestart_hook" 1>&2
main_env_prestart_hook
###############################

###############################
# hook for var set but after first var set
dbg_echo loadconfigs 10 "call hook main_envset_prestart2_hook" 1>&2
var=`main_envset_prestart2_hook`;eval $var;
dbg_echo_var_stderr loadconfigs 8 $var ;
dbg_echo loadconfigs 10 "call hook main_env_prestart2_hook" 1>&2
main_env_prestart2_hook
################################

###############################
# main hook for var set
dbg_echo loadconfigs 10 "call hook main_envset_start_hook"
var=`main_envset_start_hook`
eval $var;
dbg_echo_var_stderr loadconfigs 4 $var ;
unset var;
# main hook
dbg_echo loadconfigs 10 "call hook main_env_start_hook"
main_env_start_hook

# hook for var set
dbg_echo loadconfigs 10 "call hook main_envset_poststart_hook"
var=`main_envset_poststart_hook`
eval $var;dbg_echo_var_stderr loadconfigs 4 $var ;
unset var;
# hook for fixes
main_env_poststart_hook

# end call hooks before anything happened in CLI/script/whatever
##############################################################
