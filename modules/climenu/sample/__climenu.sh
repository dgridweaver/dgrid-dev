#
# CLIMENU shell libary
#
# Version 0.4
#

#if [ x${_CLIMENU_DEBUG} == "x1" ]; then 
#function d_echo () { echo $*;}
#else
#function d_echo () { echo -n; }
#fi

function d_echo () {
if [ x${_CLIMENU_DEBUG} == "x1" ]; then 
 echo $* ;
else
echo -n;
fi
}


d_echo EXECUTE __climenu.sh

function __climenucheck 
{
set +x
_c=$1;_c2="../${_c}"
_CFG="__climenu.conf.sh"
#echo "----------------- function __climenucheck $1 , ${_c2}"
if [ -f ${_c2}/${_CFG} ]; then
source ${_c2}/${_CFG}
export _CLIMENU_CFG_DIR=${_c2}
#ls ${_c2}/__climenu.conf #ls -d ${_c}
pushd ${_c} > /dev/null 2> /dev/null
_d=`pwd` #; echo "  PWD=${_d}"
#_d=`dirname ${_d}`
n=`basename ${_d}`
export _CLIMENU_ENTITY=$n
# echo "_CLIMENU_ENTITY=${_CLIMENU_ENTITY}"
popd > /dev/null 2> /dev/null
fi
}

export _CLIMENU_PWD=`pwd`

__climenucheck ""
__climenucheck ..
__climenucheck ../..
__climenucheck ../../..
#__climenucheck ../../../..
# local climenu config

_cfloc="${_CLIMENU_PWD}/__climenu.conf.sh"
if [ -f "${_cfloc}" ]; then
source ${_cfloc}
fi

export _CLIMENU_OP=$1

cd ${_CLIMENU_CFG_DIR}
d_echo "Now in : `pwd`"
cd $CLIMENU_INST_ROOT
d_echo "Now in : `pwd`"

for __d in `echo $CLIMENU_MAIN_CMD_LIST|tr ':' '\n'`; do

__p="${__d}/${_CLIMENU_OP}"
if [ -x ${__p}  ]; then
d_echo "Cmd found(dir) : ${__p} ${_CLIMENU_ENTITY}";
${__p} ${_CLIMENU_ENTITY} 
exit; else d_echo "No cmd in : \"${__d}\""; fi

__p="${__d}"
if [ -f ${__p} -a -x ${__p} ]; then
d_echo "Cmd found(cmd) : ${__p} ${_CLIMENU_OP} ${_CLIMENU_ENTITY}";
${__p} ${_CLIMENU_ENTITY} ${_CLIMENU_OP}
exit; else d_echo "No cmd in : \"${__d}\""; fi

done

