
################## dgrid support lib for CLI util header ####################
####  You should place this file to dgrid module directory   ################
#############################################################################

export DGRIDLIB_version="0.1-0.6"

checkpath="../ ../../ ../../../ ../../../../ ../../../../../"

export DGRIDLIB_thisclidir=`pwd`

for d in $checkpath; do

pushd $d > /dev/null
#pwd
if [ -f ./dgrid/main/loadconfigs.sh ]; then
#echo OK ./dgrid/main/loadconfigs.sh
. ./dgrid/main/loadconfigs.sh

unset checkpath;
return
else
echo -n
fi
popd > /dev/null
done
echo "dgrid installation not found, aborting."
exit

################################################
