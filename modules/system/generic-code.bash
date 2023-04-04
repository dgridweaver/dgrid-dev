#!/bin/bash

###################

function split_iterate_var { # [GENERIC] [API]
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
  done <<<"$IN"
}

split_iterate_stream() { # [GENERIC] [API]
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

split_var() { # [GENERIC] [API]
  local FUNC=$1
  local DELIM=$2
  shift 2
  IN=$*
  local ARRAY
  while IFS=$DELIM read -ra ARRAY; do
    # process "$ARRAY"
    $FUNC
  done <<<"$IN"

}

function mkdir_ifnot { # [GENERIC] [API]
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

function mkdir_ifnot_q { # [GENERIC] [API]
  local dir=$1
  if [ x$dir == x ]; then
    return
  fi

  if [ -a "$dir" ]; then
    return
  else
    mkdir -p $dir
  fi
}

function dcmd_dirname { # [GENERIC] [API]
  dirname $1
}

function date_f1 {
  LC_ALL=C date
}

function date_f0 {
  LC_ALL=C date +%s
}

#
# http://blog.leenix.co.uk/2010/04/bashsh-random-stringpassword-generator.html
#
function generic_randompass { # [GENERIC] [API]
  local randompassLength
  if [ $1 ]; then
    randompassLength=$1
  else
    randompassLength=8
  fi

  pass= tr </dev/urandom -dc A-Za-z0-9 | head -c $randompassLength
  echo $pass
}

function is_function_exists { # [GENERIC] [API]
  F=$1
  fTST=$(type -t $F)

  #echo "[2] fTST=$fTST" 1>&2
  #dbg_echo main 4  fTST=$fTST 1>&2

  if [ x$fTST == x"function" ]; then
    return 0
  else
    return 1
  fi
}

unset -f print_vars
print_vars() { # [GENERIC] [API]
  local $i
  for i in $*; do
    if [ -n "${!i}" ]; then
      echo $i=${!i}
    fi
  done
}

print_vars_str() { # [GENERIC] [API]
  local $i
  for i in $*; do
    if [ -n "${!i}" ]; then
      echo -n $i=\"${!i}\"" "
    fi
  done
}

############################################

driverfunction2() {
  local drv BF
  BF=$1
  drv=$2
  F="${BF}_${drv}"
  fTST=$(type -t $F)
  if [ x$fTST == x"function" ]; then
    shift 2
    $F $*
  else
    echo "$F not found"
    exit
  fi
}

driverfunction() {
  local drv BF
  BF=$1
  drv=$2
  F="${drv}_${BF}"
  fTST=$(type -t $F)
  if [ x$fTST == x"function" ]; then
    shift 2
    $F $*
  else
    echo "$F not found"
    exit
  fi
}

driverfunction2() {
  local drv BF
  drv=$1
  BF=$2

  #F="dgrid_base_export_${install_dgrid_base_src_type}"
  F="${drv}_${BF}"

  fTST=$(type -t $F)
  if [ x$fTST == x"function" ]; then
    shift 2
    $F $*
  else
    echo "$F not found"
    exit
  fi
}

##############################################

#getopt support

system_parse_getopt() {
  dbg_echo system 5 "system_parse_getopt()"
  #echo "params=$*"
  local module=$1
  local params=$2
  if [ x$params == x"" ]; then
    msg_echo system 1 "system_parse_getopt() no params"
    exit
  fi
  shift 2
  #echo ===============
  #echo "while getopts $params opt; do"
  while getopts "$params" opt; do
    case $opt in
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    *)
      #echo "-n was triggered, Parameter: $OPTARG" >&2
      echo "-$opt was triggered, Parameter: $OPTARG" >&2
      #local var="${module}_opt_$opt"
      # ${!var}
      #export =$OPTARG
      export ${module}_opt_$opt=$OPTARG
      export ${module}_opt_${opt}_set=1
      ;;
    esac
  done

}

###########################################


