################## dgrid support lib (1) for CLI util header ################
####  You should place this file to dgrid module directory   ################
#############################################################################

export DGRIDLIB1_version="0.1-0.7"

checkpath="./ ../ ../../ ../../../ ../../../../ ../../../../../"

export DGRIDLIB_thisclidir=$(pwd)

for d in $checkpath; do
  pushd $d >/dev/null
  if [ -f ./dgrid/main/loadconfigs.sh -a -d "./dgrid-site/etc" ]; then
    unset checkpath; source ./dgrid/main/loadconfigs.sh; return
  fi

  if [ -f ./main/loadconfigs.sh ]; then
    # start in distribution mode
    unset checkpath; source ./main/loadconfigs.sh; return
  fi
  popd >/dev/null
done

echo "libdgrid.sh : dgrid installation not found, aborting."
exit

################################################
