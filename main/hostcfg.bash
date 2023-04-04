#!/bin/bash

#############################################

hostinfo_vars() {
  #echo -n HST HSTNAME SCANHST DNSNAMES HOST_NAME HOST_SCANHST \
  echo -n \
    HOST_id HOST_hostid HOST_hostname HOST_dnsname HOST_uuid " "
}

hostinfo_vars_all() {
  hostid_vars_all
}

hostid_vars_all() { # [API]
  #hostfullconfig_vars
  hostinfo_vars
  echo -n " "
  main_call_hook hostfullconfig_vars $*
  main_call_hook hostid_vars $*
}

hostfullconfig_vars_all() {
  hostid_vars_all
}

_hostcfg_hostid_from_file() {
  local _id _res __f f
  f=$1
  dbg_echo hostcfg 12 "_hostfg_hostid_from_file() f=$f"
  ############
  # find/load hostid
  local saved_HOST_id="$HOST_id"
  if [ -a "${f}" ]; then
    __res=$(grep HOST_id= ${f})
    eval ${__res}
    unset __res
  else
    echo -n
    exit
  fi
  _id="$HOST_id"
  HOST_id="$saved_HOST_id"
  unset saved_HOST_id
  echo ${_id}
  # hostid loaded
  #############
}

hostcfg_vars_list_set() {
  local f _id varid var d list1
  dbg_echo hostcfg 8 "hostcfg_vars_list_set() start"
  for f in $NODECFG_hostconf_list; do
    _id=$(_hostcfg_hostid_from_file $f)
    dbg_echo hostcfg 8 "_id=${_id}"

    # use same func for host
    varid=$(nodecfg_varid_from_nodeid ${_id})
    #var="NODECFG_cfgdir_$varid"
    var="NODECFG_hostid_cfgfile_$varid"
    echo "export $var=\"$f\" ; "
    d=$(dirname $f)
    var="NODECFG_hostid_cfgdir_$varid"
    echo "export $var=\"$d\" ; "

    var2="NODECFG_hostid_ID_$varid"
    echo "export $var2=\"${_id}\" ; "
    
    list1="${_id} $list1"
  done
  echo "export NODECFG_hostid_LIST=\"${list1}\" ; "
}

hostcfg_hostconf_list_set() {
  #var=`find $nodecfg_path -iname "*.hostconf" | xargs --no-run-if-empty -n 1 dirname `
  var=$(find $nodecfg_path -iname "*.hostinfo")
  echo "export NODECFG_hostconf_list=\"$var\" ; "
  dbg_echo hostcfg 12 "find : var=\"$var\""
  export NODECFG_hostconf_list="$var"
}

hostinfo_loadconf() {
  local varX=$(hostinfo_loadconf_stdio $*)
  eval $varX
  unset varX
}
hostinfo_loadconf_stdio() {
  local params
  local _f=$1
  local _pref=$2
  local $(hostinfo_vars_all) varX

  #generic_loadconf $1 hostinfo_vars "output_mode=vars _export=1"
  params="output_mode=stdout _export=1 varprefix=${_pref}"
  dbg_echo hostcfg 8 "hostinfo_loadconf_stdio() _pref=\"${_pref}\" params=\"$params\""
  dbg_echo hostcfg 8 "hostinfo_vars=\""$(hostinfo_vars_all)"\""
  varX=$(generic_loadconf ${_f} hostinfo_vars_all "$params")
  dbg_echo hostcfg 8 "hostinfo_loadconf_stdio() varX='$varX'"
  echo $varX
}

hostcfg_hostid_cfgfile() { # [API] [RECOMENDED]
  local vv v _hostid=$1
  #echo -n ${nodecfg_path}/${_hostid}/${_hostid}.hostinfo
  vv=$(nodecfg_varid_from_nodeid ${_hostid})
  v=NODECFG_hostid_cfgfile_${vv}
  echo -n ${!v}
}

hostcfg_hostid_cfgdir() { # [API] [RECOMENDED]
  local vv v _hostid=$1
  ##echo -n ${nodecfg_path}/${_hostid}
  vv=$(nodecfg_varid_from_nodeid ${_hostid})
  v=NODECFG_hostid_cfgdir_${vv}
  echo -n ${!v}
}

hostcfg_hostid_load() { # [API] [RECOMENDED]
  local varx=$(hostcfg_hostid_load_stdout $*)
  eval $varx
}

hostcfg_hostid_load_stdout() { # [API] [RECOMENDED]
  local _hostid cfgfile varX i var hostid_vars_list _pref
  _hostid=$1
  _pref=$2
  dbg_echo hostcfg 4 "hostcfg_hostid_load() start"

  if [ x"${_hostid}" == "x" ]; then
    dbg_echo hostcfg 1 "hostcfg_hostid_load() UNKNOWN _hostid == ''"
    return
  fi

  main_call_hook hostid_pre_load_api ${_hostid} ${_pref}

  hostid_vars_list=$(hostid_vars_all)

  unset $hostid_vars_list
  local $(echo $hostid_vars_list)

  cfgfile=$(hostcfg_hostid_cfgfile "${_hostid}")
  dbg_echo hostcfg 3 "hostcfg_hostid_load() _hostid=${_hostid}  cfgfile=$cfgfile "

  # load base hostid config
  unset hostcfg_hostid_load_content
  export hostcfg_hostid_load_content=$(hostinfo_loadconf_stdio $cfgfile)
  dbg_echo hostcfg 3 "hostcfg_hostid_load(): END: hostinfo_loadconf_stdio $cfgfile"

  export hostcfg_hostid_load_content="$hostcfg_hostid_load_content
"

  # call hooks to load additional hostid configs supplied by modules
  dbg_echo hostcfg 8 "hostcfg_hostid_load() :: call main_call_hook hostid_load_api ${_hostid} ${_pref}"
  export hostcfg_hostid_load_content="$hostcfg_hostid_load_content 
$(main_call_hook hostid_load_api ${_hostid} ${_pref})"
  eval $hostcfg_hostid_load_content

  for i in $hostid_vars_list; do
    eval "export ${_pref}$i=\"${!i}\" ; "
  done

  dbg_echo hostcfg 8 "hostcfg_hostid_load() :: call main_call_hook hostid_post_load_api ${_hostid} ${_pref}"
  main_call_hook hostid_post_load_api ${_hostid} ${_pref}

  unset hostcfg_hostid_load_vars

  for i in $hostid_vars_list; do
    local i2="${_pref}$i"
    echo -n "export ${_pref}$i=\"${!i2}\"; "
  done

  dbg_echo hostcfg 4 "hostcfg_hostid_load() end"

}

function hostcfg_iterate_hostid { # [API] [RECOMENDED]
  local hostinfo_vars_list code F varX

  code=$1
  pushd $DGRIDBASEDIR >/dev/null

  hostinfo_vars_list=$(hostid_vars_all)
  dbg_echo nodecfg 2 hostcfg_iterate_hostid [2] hostinfo_vars_list=$hostinfo_vars_list

  find $nodecfg_path -iname "*.hostinfo" | while read F; do
    unset $hostinfo_vars_list

    varX=$(hostinfo_loadconf_stdio $F)
    eval $varX
    unset varX

    varX=$(hostcfg_hostid_load_stdout $HOST_id)
    eval $varX
    unset varX

    dbg_echo hostcfg 1 hostcfg_iterate_hostid [2] incoming_scanhst=$incoming_scanhst
    dbg_echo hostcfg 1 hostcfg_iterate_hostid [2] incoming_detect_type=$incoming_detect_type

    _dir=$(dirname $F)
    export cfgfile_dir=$_dir
    eval "$code"

    unset $hostinfo_vars_list
  done

  popd >/dev/null
}

############################################################

# adding and etc

nodecfg_add_this_node() {
  #nodemainname=$1
  #nodeid=${USER}@${nodemainname}

  HSTNAME=$(hostname)
  HST=$(hostname)
  NODEPATH=$(pwd)

  nodecfg_add_nodecfg $USER $HSTNAME $NODEPATH
}

#nodecfg_load_

nodecfg_add_nodecfg() {
  nodeuser=$1
  nodehost=$2
  nodepath=$3
  nodeid=${USER}@${nodehost}

  echo "create nodeid=$nodeid"

  NODEDIR="./bynodes/$nodeid/"

  mkdir -p $NODEDIR
  touch ${NODEDIR}/.keep_me

}
nodecfg_add_hostcfg() {
  paramfunc=$1
  # add node host

  var=$($paramfunc)
  eval $var
  unset var

  NODEHOST_DIR="./bynodes/$HOST_id/"
  cfg=${NODEHOST_DIR}/$HOST_id.hostinfo

  dbg_echo nodecfg 5 nodecfg_add_hostcfg HOST_id=$HOST_id

  #exit

  if [ -f $NODEHOST_DIR ]; then
    if [ -d $NODEHOST_DIR ]; then
      echo -n
    else
      echo "$NODEHOST_DIR existed and it is not directory!"
      return
    fi
  fi

  if [ -d $NODEHOST_DIR ]; then
    echo "host dir already exited"
    return
  else
    echo "Creating $NODEHOST_DIR for $HOST_id"
    mkdir -p ${NODEHOST_DIR}
    touch ${NODEHOST_DIR}/.keep_me
  fi

  echo "[2] hostinfo_vars=$(hostinfo_vars)" 2>&1

  for var in $(hostinfo_vars); do
    if [ x"${!var}" == "x" ]; then
      echo "#$var=\"\"" >>$cfg
    else
      echo "$var=\"${!var}\"" >>$cfg
    fi
  done
  echo "" >>$cfg
}

hostcfg_hostid_exists() { # [API] [RECOMENDED]
  #nodeconf_exists_nodeid $*
  local hostid cfg
  hostid=$1

  if [ -z "$hostid" ]; then
    echo "hostcfg_hostid_exists : empty nodeid"
    return 1
  fi

  cfg=$(hostcfg_hostid_cfgfile $hostid)

  if [ -z "$cfg" ]; then
    return 1
  fi

  if [ -f $cfg ]; then
    echo -n
  else
    return 1
  fi
  return 0
}
