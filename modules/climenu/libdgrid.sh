
################## dgrid support lib (1) for CLI util header ################
####  You should place this file to dgrid module directory   ################
#############################################################################

export DGRIDLIB1_version="0.1-0.6"

checkpath="../ ../../ ../../../ ../../../../ ../../../../../"

export DGRIDLIB_thisclidir=`pwd`

for d in $checkpath; do

pushd $d > /dev/null

if [ -f ./main/loadconfigs.sh ]; then
 if [ -f ../dgrid/main/loadconfigs.sh -a -d "../dgrid-site/etc" ]; then
  pushd ../ > /dev/null
  unset checkpath;
  source ./dgrid/main/loadconfigs.sh
  return
  popd > /dev/null
 else
  # start in distribution mode
  unset checkpath;
  source ./main/loadconfigs.sh
  return
 fi
else
 echo -n
fi
popd > /dev/null
done

echo "dgrid installation not found, aborting."
exit

################################################
