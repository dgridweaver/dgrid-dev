#!/bin/bash
#!/bin/bash -x


run()
{

echo "##################"


}
#run
#exit
################## dgrid header1 ################ 
if [ x$ORIGDIR == x ]; then
export ORIGDIR=`pwd`
fi

_file0=`readlink -f $0`
cd `dirname $_file0`

. ./libdgrid.sh

################## [END] dgrid header1 ################ 

main_exit_if_not_enabled updnode

#echo 
#echo "                  << updnode CLI util   >>"
#echo 

run
