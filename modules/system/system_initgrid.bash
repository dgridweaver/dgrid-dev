#!/bin/bash

#
# initgrid hook
#

system_initgrid()
{
echo "$0: Run system.initgrid script"
echo "Initializing storage - dgrid config repository"

#echo "1=$1 2=$2 3=$3"

if [ x$1 == x"stage3" ]; then
echo "Enable modules"
echo -n "pwd="`pwd`

initgrid_dgridsys module enable run
initgrid_dgridsys module enable attach
initgrid_dgridsys module enable sshenv
initgrid_dgridsys module enable updnode
#initgrid_dgridsys module enable hoststat
#initgrid_dgridsys module enable srv

fi
}
