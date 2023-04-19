#!/bin/bash

nodecfg_grp_vars_all() { nodecfg_grp_vars; }
nodecfg_grp_vars() { echo -n " " GRP_ID GRP_type GRP_groups" "; }

nodecfg_grp_nodelist(){ # [API] [RECOMENDED]
  local v=NODECFG_grp_nodelist_$1
  echo -n ${!v}
}

nodecfg_grp_groups(){ # [API] [RECOMENDED]
  local v=NODECFG_grp_groups_${1}
  echo -n ${!v}
}


nodecfg_grp_cfgfile() { # [API] [RECOMENDED]
  local vv v _id=$1
  vv=$(nodecfg_varid_from_nodeid ${_id})
  v=NODECFG_grp_cfgfile_${vv}
  echo -n ${!v}
}

nodecfg_grp_cfgdir() { # [API] [RECOMENDED]
  local vv v _id=$1
  vv=$(nodecfg_varid_from_nodeid ${_id})
  v=NODECFG_grp_cfgdir_${vv}
  echo -n ${!v}
}



##########

nodecfg_grp_load_stdout(){
  local _f eid=$1
  dbg_echo nodecfg 5 F start
  _f=`nodecfg_grp_cfgfile $eid`

  #params="output_mode=stdout _export=1 varprefix=${pref}"
  params="output_mode=stdout _export=1 varprefix=${pref}"
  
  generic_loadconf ${_f} nodecfg_grp_vars_all "$params"
  dbg_echo nodecfg 5 F End
}

nodecfg_grp_list_set() {
  local i var v NODECFG_grp_LIST cfgfile
  
  dbg_echo nodecfg 4 F "start"
  var=$(find $nodecfg_grppath -iname "*.grpconf" | xargs --no-run-if-empty -n 1 dirname)
  echo "export NODECFG_grp_dir_list=\"$var\" ; "
  dbg_echo nodecfg 12 "find : var=\"$var\""
  for i in $var ; do
    unset `nodecfg_grp_vars_all`

    cfgfile="$i/this.grpconf"
    source $cfgfile
    [ -z "$GRP_ID" ] && dbg_echo nodecfg 4 F "Error, GRP_ID not set in $cfgfile" && continue
    
    v=NODECFG_grp_cfgfile_${GRP_ID}
    echo "export $v=\"$cfgfile\" ;"
    v=NODECFG_grp_cfgdir_${GRP_ID}
    echo "export $v=\"$i\" ;"
    v=NODECFG_grp_ID_${GRP_ID}
    echo "export $v=\"${GRP_ID}\" ;"
    v=NODECFG_grp_groups_${GRP_ID}
    echo "export $v=\"${GRP_groups}\" ;"


    NODECFG_grp_LIST="$NODECFG_grp_LIST ${GRP_ID}"
  done
  echo "export NODECFG_grp_LIST=\"$NODECFG_grp_LIST\" ;"
  dbg_echo nodecfg 4 F "end"
}

###################################

_nodecfg_grp_nodeid_list_set_hlp(){
  local f v g
  f=`nodecfg_nodeid_cfgfile $NODE_ID`
  v=`grep NODE_GROUPS $f` > /dev/null
  [ -z "$v" ] && return
  eval "local $v"; unset v

  local tIFS="$IFS"; IFS="," 
  for g in $NODE_GROUPS ; do
    IFS="$tIFS"
    g=${g/ /};
    if nodecfg_grp_not_exists $g; then dbg_echo nodecfg 4 F "\"$g\" NO_GROUP"; continue; fi
    v="NODECFG_grp_nodelist_${g}"
    eval "$v=\"${!v} $NODE_ID\""
  done
}

nodecfg_grp_nodeid_list_set(){
  local g v v2
  dbg_echo nodecfg 4 F start
  unset grpid_list
  for g in $NODECFG_grp_LIST ; do local NODECFG_grp_nodelist_${g}; done
  unset g

  nodecfg_iterate_nodeid _nodecfg_grp_nodeid_list_set_hlp

  for g in $NODECFG_grp_LIST ; do
    v="NODECFG_grp_nodelist_${g}"
    v2=${!v};v2=`generic_trim $v2`
    echo "export ${v}=\"${v2}\" ;"
  done

  dbg_echo nodecfg 4 F end
}

#############################################

nodecfg_iterate_grp() { # [API] [RECOMENDED] var param: grpid_list=""
  local F varX hst code="$1"
  local grp_vars_list=$( nodecfg_grp_vars )
  dbg_echo nodecfg 2 F start
  #dbg_echo hostcfg 2 F hostinfo_vars_list=$hostinfo_vars_list
  [ -z "$grpid_list" ] && grpid_list="$NODECFG_grp_LIST"
  
  for eid in $grpid_list ; do
    unset $grp_vars_list
    
    varX=$(nodecfg_grp_load_stdout $eid) # 
    eval "$varX" ; unset varX

    dbg_echo nodecfg 8 F "Iterate eid=$eid"
    eval "$code"

  done
  unset $grp_vars_list
}



#############################################

nodecfg_grp_exists() { # [API] [RECOMENDED]
  local cfg eid=$1

  [ -z "$eid" ] && distr_error "empty nodeid" && return 1
  cfg=$(nodecfg_grp_cfgfile $eid)

  if [ -z "$cfg" ]; then return 1; fi
  if [ ! -f $cfg ]; then return 1; fi
  return 0
}
nodecfg_grp_not_exists() { # [API] [RECOMENDED]
  if nodecfg_grp_exists $@ ; then return 1; else return 0; fi
}






