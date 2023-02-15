#!/bin/bash

###################


function split_iterate_var # [GENERIC] [API]
{
local FUNC=$1
local DELIM=$2
shift 2
IN=$*
local ADDR
 while IFS=$DELIM read -ra ARRAY; do
      for item in "${ARRAY[@]}"; do
                 # process "$i"
                 $FUNC
       done
done <<< "$IN"
}

split_iterate_stream() # [GENERIC] [API]
{
local FUNC=$1
local DELIM=$2
shift 2
IN=$*
local ADDR
 while IFS=$DELIM read -ra ARRAY; do
                 # process "$ADDR"
                 $FUNC
done
}


split_var() # [GENERIC] [API]
{
local FUNC=$1
local DELIM=$2
shift 2
IN=$*
local ARRAY
 while IFS=$DELIM read -ra ARRAY; do
                 # process "$ARRAY"
                 $FUNC
done <<< "$IN"

}

function mkdir_ifnot  # [GENERIC] [API]
{
local dir=$1
if [ x$dir == x ]; then
return
fi

if [ -a "$dir" ]; then
echo "mkdir_ifnot: dir=$dir exists " 1>&2
return
else
mkdir -p $dir
fi
}


function mkdir_ifnot_q # [GENERIC] [API]
{
local dir=$1
if [ x$dir == x ]; then
return
fi

if [ -a "$dir" ]; then
#echo "mkdir_ifnot: dir=$dir exists " 1>&2
return
else
mkdir -p $dir
fi
}


function zg_dirname # [GENERIC] [API]
{
dirname $1
}

function date_f1
{
LC_ALL=C date
}

function date_f0
{
LC_ALL=C date +%s
}


#
# http://blog.leenix.co.uk/2010/04/bashsh-random-stringpassword-generator.html
#
function zg_randompass # [GENERIC] [API]
{
        local randompassLength
        if [ $1 ]; then
                randompassLength=$1
        else
                randompassLength=8
        fi
 
        pass=</dev/urandom tr -dc A-Za-z0-9 | head -c $randompassLength
        echo $pass
}


function is_function_exists # [GENERIC] [API]
{
F=$1
fTST=`type -t $F`

#echo "[2] fTST=$fTST" 1>&2
#dbg_echo main 4  fTST=$fTST 1>&2

if [ x$fTST  == x"function"  ]; then
 return 0
else
 return 1
fi
}

unset -f print_vars
print_vars()  # [GENERIC] [API]
{
local $i
for i in $*; do
if [ -n "${!i}" ]; then
echo $i=${!i}
fi
done
}

print_vars_str()  # [GENERIC] [API]
{
local $i
for i in $*; do
if [ -n "${!i}" ]; then
echo -n $i=\"${!i}\"" "
fi
done
}




############################################

driverfunction2()
{
local drv BF
BF=$1
drv=$2

#F="dgrid_base_export_${install_dgrid_base_src_type}"
F="${BF}_${drv}"

fTST=`type -t $F`
if [ x$fTST  == x"function"  ]; then
shift 2
$F $*
else
echo "$F not found"
exit
fi
}


driverfunction()
{
local drv BF
BF=$1
drv=$2

#F="dgrid_base_export_${install_dgrid_base_src_type}"
F="${drv}_${BF}"

fTST=`type -t $F`
if [ x$fTST  == x"function"  ]; then
shift 2
$F $*
else
echo "$F not found"
exit
fi
}

driverfunction2()
{
local drv BF
drv=$1
BF=$2

#F="dgrid_base_export_${install_dgrid_base_src_type}"
F="${drv}_${BF}"

fTST=`type -t $F`
if [ x$fTST  == x"function"  ]; then
shift 2
$F $*
else
echo "$F not found"
exit
fi
}





