#!/bin/bash

mainrepo_pull_simple()
{
mainrepo=$1
hg pull $mainrepo
(cd ./dgrid; hg pull ${mainrepo}/dgrid;)
}

mainrepo_push_simple()
{
mainrepo=$1
hg push $mainrepo
(cd ./dgrid; hg push ${mainrepo}/dgrid;)
}

function mainrepo_repoone_status_1
{
#repo=$1
#repohost=`cut -d// -f2`
#repodir=`cut -d// -f1`

repohost=$1
repodir=$2

echo -n "$repohost : "
ssh $repohost "(cd $repodir; hg log -l 1|grep changeset)" 2> /dev/null
}



mainrepo_iterate_conf()
{
params=$*

cfgpath_full="$DGRIDBASEDIR/${mainrepo_cfgpath}/"
for cfg in $cfgpath_full/* ; do 
#echo -n "begin : "
#echo $cfg
source $cfg


if [ "x" == "x$mainrepo_id" ]; then
echo "empty id $cfg"
else
#echo call: $params
$params
fi
#echo "done"
done
}

mainrepo_print_item()
{
#echo $mainrepo_id : 
printf %20s "$mainrepo_name :  "
echo "[ $mainrepo_url ]"

}

#####

mainrepo_repohost()
{
repo=$1 #echo $repo
var=`echo $repo|sed "s@//@ % @g"`
var=`echo $var|cut -f2 -d% `
echo ${var}
}

mainrepo_repodir()
{
repo=$1 #echo $repo
var=`echo $repo|sed "s@//@ % @g"`
var=`echo $var|cut -f3 -d% `
echo ${var}
}


mainrepo_iterate_conf()
{
params=$*

cfgpath_full="$DGRIDBASEDIR/${mainrepo_cfgpath}/"
for cfg in $cfgpath_full/* ; do 
#echo -n "begin : "
#echo $cfg
source $cfg


if [ "x" == "x$mainrepo_id" ]; then
echo "empty id $cfg"
else

#hg push $mainrepo_url
mainrepo_host=`mainrepo_repohost $mainrepo_url`
#echo "mainrepo_host=${mainrepo_host};"

mainrepo_dir=`mainrepo_repodir $mainrepo_url`
mainrepo_dir="/${mainrepo_dir}";
#echo mainrepo_dir=$mainrepo_dir



#echo call: $params
$params
fi
#echo "done"
done
}

##################

mainrepo_updnode_pull()
{
printf %20s "$mainrepo_name :  "
echo "[ $mainrepo_url ]"

#export mainrepo=
#mainrepo_push_simple $mainrepo_url
hg pull $mainrepo_url
}

mainrepo_updnode_pull_dist()
{
printf %20s "$mainrepo_name :  "
echo "[ $mainrepo_url ]"

#export mainrepo=
#mainrepo_push_simple $mainrepo_url
( cd dgrid ; hg pull ${mainrepo_url}/dgrid )
}


udpmod1_pull_all_mainrepos()
{
echo DGRIDBASEDIR=$DGRIDBASEDIR
echo -n "PWD="; pwd
mainrepo_iterate_conf mainrepo_updnode_pull
mainrepo_iterate_conf mainrepo_updnode_pull_dist
}

mainrepo_updnode_push()
{
printf %20s "$mainrepo_name :  "
echo "[ $mainrepo_url ]"

#export mainrepo=
#mainrepo_push_simple $mainrepo_url

hg push $mainrepo_url
}

mainrepo_updnode_push_dist()
{
printf %20s "$mainrepo_name :  "
echo "[ $mainrepo_url ]"

#export mainrepo=
#mainrepo_push_simple $mainrepo_url

(cd dgrid; hg push $mainrepo_url/dgrid )
}


updnode_push_all_mainrepos()
{

echo DGRIDBASEDIR=$DGRIDBASEDIR
echo -n "PWD="; pwd

mainrepo_iterate_conf mainrepo_updnode_push
mainrepo_iterate_conf mainrepo_updnode_push_dist
}


function mainrepo_repoone_status_1
{
#repo=$1
#repohost=`cut -d// -f2`
#repodir=`cut -d// -f1`
repohost=$1
repodir=$2

echo -n "$repohost : "
ssh $repohost "(cd $repodir; hg log -l 1|grep changeset)" 2> /dev/null
}



mainrepo_list()
{

echo DGRIDBASEDIR=$DGRIDBASEDIR
echo -n "PWD="; pwd

#echo --------- DGRID CODE ------
mainrepo_iterate_conf mainrepo_print_item

}

mainrepo_updnode_status_code()
{
#printf %20s "$mainrepo_name :  "
#echo "[ $mainrepo_url ]"

mainrepo_repoone_status_1 $mainrepo_host ${mainrepo_dir}/dgrid
}

mainrepo_updnode_status_cfg()
{
#printf %20s "$mainrepo_name :  "
#echo "[ $mainrepo_url ]"

mainrepo_repoone_status_1 $mainrepo_host ${mainrepo_dir}/
}

mainrepo_status_all_mainrepos()
{

echo DGRIDBASEDIR=$DGRIDBASEDIR
echo -n "PWD="; pwd

echo " ----    DGRID CODE   ------  "
echo -n "THIS : " ;  (cd ./dgrid/ ; hg log -l 1 | grep changeset )
mainrepo_iterate_conf mainrepo_updnode_status_code

echo " ----    DGRID CONFIG   ------  "
echo -n "THIS : " ;  ( hg log -l 1 | grep changeset )
mainrepo_iterate_conf mainrepo_updnode_status_cfg

}



