#!/bin/bash

function imgpack_ask {
local ask
echo "[enter] to continue or Ctrl-C to abort"
read -n 1 ask
}

function imgpack_util_extract {
  local wdir=$1 fff=$2
  # imgpack_unpack_workdir
  file $fff
  if [ -d $wdir ]; then
    pushd $wdir
    echo tar -xvaf "$fff"
    tar -xvaf "$fff"
    popd
  else
    echo "Dir not found: $wdir"
    echo "ERROR, no workdir, ABORT"
    exit
  fi

}

function imgpack_util_mkdir_p {
  local var=$1;
  if [ ! x$var == "x" ]; then
     mkdir -p $var
  fi
}


imgpack_src_download() {
  local suff
  local _file
  _file="$imgpack_incoming_cache/$imgpack_src_file0"
  
  echo "Test if file already downloaded(cached): ${_file}"
  if [ ! -f ${_file} ]; then
    echo "DOWNLOAD (not implemented)"
  else
    echo "File already present"
  fi
  #unset _file
}
