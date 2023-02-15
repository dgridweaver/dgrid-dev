#!/bin/bash

################## dgrid header1 ################
if [ x$ORIGDIR == x ]; then
  export ORIGDIR=$(pwd)
fi

_file0=$(readlink -f $0)
_dir0=$(dirname $_file0)
cd ${_dir0}

. ./libdgrid.sh
################## [END] dgrid header1 ################

. ./dgrid/init/initgrid.bash
. ./dgrid/init/distr.bash

########## log setup ###############
DGRID_initgrid_log="./not-in-vcs/initgrid_this/initgrid-2nd-stage.log"
if [ -d $(dirname $DGRID_initgrid_log) ]; then
  touch $DGRID_initgrid_log
else
  echo "ERROR, no $(dirname $DGRID_initgrid_log)" 1>&2
fi
####################################

initgrid_echo "======= Start initgrid-2nd-stage.bash  =========="

if [ "x${RUN_FROM_init_dgrid_structure}" == "x" ]; then
  initgrid_echo "ERROR. This is support script that should be run only from initgrid module"
  exit
fi
# ok, we hope/trust caller know what its doing.

_initgrid_cfg="./not-in-vcs/initgrid_this/installed_grid.conf"
if [ -a ${_initgrid_cfg} ]; then
  source ${_initgrid_cfg}
else
  initgrid_echo "initgrid-2nd-stage.bash : ERROR, NO CONFIG TO WORK FOUND, EXITING."
  exit
fi

initgrid_echo "ok...."
initgrid_echo "installvar_name=$installvar_name"

initgrid_echo "==== INITGRID SECOND STAGE ===="

initgrid_echo_n "pwd="
pwd | initgrid_save_to_log
# exit:before-initgrid-2nd-stage-run
initgrid_installvar_exit before-initgrid-2nd-stage-run

#mkdir -p ./not-in-vcs/initgrid-2nd-stage/
initgrid_2stage_run 2>&1 | tee -a ./not-in-vcs/initgrid_this/initgrid-2nd-stage.log
