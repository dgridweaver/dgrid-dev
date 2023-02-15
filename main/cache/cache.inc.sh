#
# shell cache subsystem
#

cache_drv_all="devshm dotcache"

cache_key_set()
{
local pref pathkey key
cache_pathkey=${DGRIDBASEDIR//\//_}/cache.inc/
echo "export cache_pathkey=\"$cache_pathkey\" ;"
}

_cache_test_path_1()
{
local p
p=$1
if [ -d $p ]; then
echo -n
else
mkdir -p ${p} 2> /dev/null
fi

if [ -d ${p} -a -w $p -a -O $p ]; then
echo "export cache_path=${p}"
dbg_echo cache 2 "[2] set cache_path=${p}" 1>&2
return 0
else
return 1
fi

}

cache_devshm()
{
local i
local cache_key="${USER}_${DGRID_dgridname}_${cache_pathkey}"
local p="/dev/shm/$cache_key"
local cmd=$1

if [ x$cmd == x"path_set" ]; then
_cache_test_path_1 $p
return $?
fi

# clear
if [ "x$cmd" == "xclear" -a "x$2" == "xALL" ]; then
cache_clear_dir $p
return
fi

echo "1=$1" 1>&2

if [ x$1 == x"clear" ]; then
i=$2
echo mv $p/$i $p/RMOVED_$i 1>&2
#mv $p/$i $p/$i.RMOVED
return
fi

}
# $HOME/.cache/
cache_dotcache()
{
local cache_key="cache_${DGRID_dgridname}_${cache_pathkey}"
local p="$HOME/.cache/$cache_key"
local cmd=$1

if [ x$cmd == x"path_set" ]; then
_cache_test_path_1 $p
return $?
fi

if [ "x$cmd" == "xclear" -a "x$2" == "xALL" ]; then
cache_clear_dir $p
return
fi
}

cache_NONE()
{
dbg_echo cache 2 "[2] cache NONE hit" 1>&2
}

cache_path_set()
{
local pref pathkey key
#echo [2] cache_key=$cache_key 1>&2
if [ "x$CACHE_TYPES" == "x"  ]; then
echo [2] error, CACHE_TYPES empty 1>&2
return
fi

for t in $CACHE_TYPES; do
if [ x$t == x"devshm" ]; then
cache_devshm path_set
if [ $? == 0 ]; then 
dbg_echo cache 2 "[2] ok, cache=$t" 1>&2
echo "export cache_type=${t} ;"
return ; fi
fi

if [ x$t == x"dotcache" ]; then
cache_dotcache path_set
if [ $? == 0 ]; then 
dbg_echo cache 2 "[2] ok, cache=$t" 1>&2
echo "export cache_type=${t} ;"
return; fi
fi

if [ x$t == x"NONE" ]; then
cache_NONE path_set
return
fi

done
#DGRID_dgridname
#DGRIDBASEDIR
}

cache_wr()
{
local f=${cache_path}/cache_$cacheid
if [ x"${cache_path}" == x ]; then
echo -n
else
echo $* > $f
fi


}

cache_wrap_vars()
{
local cacheid;
local param;
local var;
cacheid=$1
shift 1
param=$*

#if [ x"${param}" == x ]; then param=$cacheid; fi

if [ x"${cacheid}" == x ]; then return 1 ; fi

if [ x"${cache_path}" ==  "x" ]; then
echo "[2] ERROR, cache_path empty" 1>&2
echo $param;
return
fi

f=${cache_path}/cache_$cacheid

if [ -f $f -a -O $f  ]; then 
dbg_echo cache 2 [2] cache hit ${f} 1>&2
cat $f; 
else 
var="$param";
dbg_echo cache 2 [2] cache miss ${f}, try write 1>&2
cache_wr "$var"
echo $var
fi

}

cache_wrap_func()
{
local cacheid;
local param;
local var;
cacheid=$1
shift 1
param=$*

if [ x"${param}" == x ]; then param=$cacheid; fi

if [ x"${cacheid}" == x ]; then return 1 ; fi

if [ x"${cache_path}" ==  "x" ]; then
echo "[2] ERROR, cache_path empty" 1>&2
eval $param;
return
fi

f=${cache_path}/cache_$cacheid

dbg_echo cache 3 [3] CACHE_TYPE=$CACHE_TYPE  1>&2
if [ x$CACHE_TYPE == "xNONE" ]; then
var=`eval $param;`
dbg_echo cache 2 [2] cache NONE ${f}, compute without cache 1>&2
echo $var
else if [ -f $f -a -O $f  ]; then 
dbg_echo cache 2 [2] cache hit ${f} 1>&2
cat $f; 
else 
#var=`eval $param;`
var=$( $param )
dbg_echo cache 2 [2] cache miss ${f}, try write 1>&2
cache_wr "$var"
echo $var
fi
fi
}

#cache_aliases{}
cache_clear()
{
local drv
for drv in $cache_drv_all; do
echo [2] cache_$drv clear $1 1>&2
cache_$drv clear $1
done
}

cache_clear_dir()
{
local i
local list=$p/cache_*
dbg_echo cache 3 [2] list=`echo $list` 1>&2
#if [ x$list == x"$p/cache_\*" ]; then
#return
#fi

for i in $p/cache_*; do
if [ -f $i ]; then
echo -n
else
dbg_echo cache 3 "[2] no cache files" 1>&2
return
fi
dbg_echo cache 2  mv $i $p/RMOVED_`basename $i` [2] 1>&2
mv $i $p/RMOVED_`basename $i`
done

}

######

#export cache_base_path_list="/dev/shm/ $HOME/.cache/ "
#export cache_base2_path_list="$HOME/.config/cache/ $DGRIDBASEDIR/not-in-vcs/cache/"

#cache_key="${USER}_${DGRID_dgridname}_${cache_pathkey}"
#echo [2] cache_key=$key 1>&2
#echo [2] DGRID_dgridname=$DGRID_dgridname 1>&2
#echo
#echo "export cache_key=\"$key\" ;"

