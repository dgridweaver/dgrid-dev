#!/bin/bash

# dgrid storage driver using mercurial DVCS

hgone_initthisnodestorage_initgrid()
{
hgone_initthisnodestorage
echo ""     >> .hg/hgrc
echo "[ui]" >> .hg/hgrc
echo "username=$USER@"`hostname -s` >> .hg/hgrc
echo ""     >> .hg/hgrc
}
hgone_initthisnodestorage()
{
echo -n
echo "hgone_initthisnodestorage()"
#cat ./dgrid/modules/system/hgone/hgignore.template >> .hgignore
cat ${MODINFO_modpath_system}/hgone/hgignore.template >> .hgignore
echo "will run: pushd ../; hg --config format.dotencode=0 init ${DGRID_dgridname} ; popd "
set -x
pushd ../ > /dev/null
hg --config format.dotencode=0 init ${DGRID_dgridname} ;
popd  > /dev/null
set +x
}

# stupid func
# hgone_register_all_changes `system_trans_genid`
hgone_register_all_changes()
{
#local trid=`system_trans_genid` 
local trid=$1
pushd $DGRIDBASEDIR > /dev/null
hg add .
echo "hg -v commit -m \"trans=\"$trid\" ; do hgone_register_all_changes() ;\""
hg -v commit -m "trans=\"$trid\" ; do hgone_register_all_changes() ;"
popd  > /dev/null
}

############## trans #################

hgone_trans_do_end_execute()
{
local trid=$1
local ifile=`system_trans_transfile $trid`
local files commit_str desc
#commit_str="${commit_str} $trid"
commit_str="trid=$trid"
while IFS=" " read -ra ARRAY; do
echo -n
#hook_trans_do_end_execute $trid $ifile $STR
#echo hook_trans_do_end_execute $trid $ifile $STR
if [ x${ARRAY[0]} == x"desc" ]; then
desc=${ARRAY[@]}
fi
if [ x${ARRAY[0]} == x"transtype" ]; then
ARRAY[0]=""
transtype=${ARRAY[@]}
fi
if [ x${ARRAY[0]} == x"modname" ]; then
ARRAY[0]=""
modname=${ARRAY[@]}
fi
if [ x${ARRAY[0]} == x"funcname" ]; then
ARRAY[0]=""
funcname=${ARRAY[@]}
fi

if [ x${ARRAY[0]} == x"register" ]; then
 echo hg add ${ARRAY[1]} 1>&2
 hg add ${ARRAY[1]} 1>&2
 files="$files "${ARRAY[1]}
fi 
done
commit_str="${commit_str} desc= $desc ; transtype=$transtype ; "
commit_str="${commit_str} modname=$modname ; funcname=$funcname ; files= $files ;"
echo hg commit -m \"$commit_str\" $files  1>&2
hg commit -m "$commit_str" $files  1>&2

}


