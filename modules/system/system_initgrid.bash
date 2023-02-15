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

initgrid_dgridsys module enable attach
initgrid_dgridsys module enable sshzg
initgrid_dgridsys module enable hoststat
initgrid_dgridsys module enable updnode
initgrid_dgridsys module enable run
initgrid_dgridsys module enable srv

# NOT WORK AND BROKE SYSTEM
#./dgrid/modules/dgridsys/dgridsys module enable attach
#./dgrid/modules/dgridsys/dgridsys module enable sshzg
#./dgrid/modules/dgridsys/dgridsys module enable updnode
#./dgrid/modules/dgridsys/dgridsys module enable hoststat
#./dgrid/modules/dgridsys/dgridsys module enable run
#./dgrid/modules/dgridsys/dgridsys module enable srv

#./dgrid/main/modules-enable attach
#./dgrid/main/modules-enable sshzg
#./dgrid/main/modules-enable updnode
#./dgrid/main/modules-enable hoststat
#./dgrid/main/modules-enable run
#./dgrid/main/modules-enable srv
fi
}
