#!/bin/bash

if [ x$MODINFO_loaded_hoststat == "x" ]; then
  export MODINFO_loaded_hoststat="Y"
else
  return
fi
export MODINFO_msg_hoststat=2

#source ${MODINFO_modpath_hoststat}/pingpong.inc.bash

hoststat_CLIMENU_CMDS_LIST=" knownhost-identify"
hoststat_climenu_cmd_get_info_bypubkey(){ hoststat_get_info_bypubkey_cli $@; }
hoststat_climenu_cmd_knownhost_identify(){ hoststat_get_info_bypubkey_cli $@; }

################################


hoststat__iterate_hostid() { # [API]
  hostcfg_iterate_hostid $@
}



################################

hoststat_conf_vars() {
  echo hoststat_do_scan incoming_detect_type incoming_scanhst hoststat_isup_this_host
}


hoststat_installable_files() {
  echo "
[file entry begin]
module=hoststat
handler=system
op=config_sample_node
infile=hoststat.conf.sample
outfile=etc/hoststat.conf
[file entry end]
"
}

hoststat_envset_start() {
  # set configure variables that used DGRID_dir_nodelocal

  export HOSTSTAT_WDIR="${DGRID_dir_nodelocal}/hoststat/"
  export HOSTSTAT_WDIR_tmp="${DGRID_dir_nodelocal}/hoststat/tmp/"
  export HOSTSTAT_state_dir="${DGRID_dir_nodelocal}/hoststat/stat/"
  echo "export HOSTSTAT_WDIR=\"${HOSTSTAT_WDIR}\""
  echo "export HOSTSTAT_WDIR_tmp=${HOSTSTAT_WDIR_tmp}"
  echo "export HOSTSTAT_state_dir=${HOSTSTAT_state_dir}"
}

# define hook
#hoststat_hostid_vars() {
#  hoststat_conf_vars
#}


#hoststat_hostid_load_api() { # hook
# make no-hook version
hoststat_hostid_load_api_nohook() {
  # define function for hook hook_hostid_load_api()
  local _dir _hostid=$1
  dbg_echo hoststat 8 F "Start: $*"
  _dir=$(hostcfg_hostid_cfgdir ${_hostid})

  #cfg=${_dir}/etc/hoststat.conf
  #dbg_echo hoststat 3 "cfg=$cfg"

  source ${MODINFO_modpath_hoststat}/hoststat.conf.default
  cfgstack_load_byid etc/hoststat.conf ${_hostid}
  cfgstack_load_byid etc/connect.conf ${_hostid}

  export CONNECT_dnsname=$(generic_var_content_priority incoming_scanhst CONNECT_dnsname HOST_dnsname  )
  export incoming_scanhst=$CONNECT_dnsname

  #for var in $(hoststat_conf_vars); do
  #  echo "export $var=\"${!var}\" ;"
  #  dbg_echo hoststat 5 F ":  $var=\"${!var}\";"
  #done
  # load current host up/down state
  
  local _fstat="${HOSTSTAT_state_dir}/${_hostid}/last.vars"
  dbg_echo hoststat 7 " _fstat=\" ${_fstat}\""
  if [ -f ${_fstat} ]; then
    dbg_echo hoststat 5 F ": source ${_fstat}"
    source ${_fstat}
  fi
  dbg_echo hoststat 8 F "End"
}


###########

_hoststat_uphosts_hlpr() {
  hoststat_hostid_load_api_nohook $HOST_id

  local odir=${hoststat_outdir}/$HOST_id/
  mkdir_ifnot_q $odir
  local ofile=${odir}/${incoming_detect_type}.vars
  local ofile2=${odir}/last.vars
  

  echo "#--------------------------" | tee $ofile2
  echo "#--------------------------" | tee $ofile
  echo "" | tee -a $ofile
  echo "# scan hst=$HOST_id;" | tee -a $ofile
  echo "hoststat_scanned_hostid=$HOST_id;" | tee -a $ofile
  echo "hoststat_do_scan=$hoststat_do_scan" | tee -a $ofile
  echo "incoming_scanhst=$incoming_scanhst" | tee -a $ofile
  echo "incoming_detect_type=$incoming_detect_type" | tee -a $ofile
  echo "#CONNECT_sshport=\"${CONNECT_sshport}\"" | tee -a $ofile

  #
  dbg_echo hoststat 10 F "hoststat_do_scan=$hoststat_do_scan"
  if [ x$hoststat_do_scan == x"1" ]; then
    dbg_echo hoststat 10 F "hoststat_isup_one_host \"$incoming_scanhst\""
    hoststat_isup_one_host $incoming_scanhst
    if [ "$?" == "0" ]; then
      echo "# host online" | tee -a $ofile
      echo "#"$(hoststat_datemark) " Node with IP: $incoming_scanhst is up." | tee -a $ofile
      echo "hoststat_isup_this_host=1" | tee -a $ofile | tee -a $ofile2
    else
      echo "# host *not* online" | tee -a $ofile
      echo "hoststat_isup_this_host=0" | tee -a $ofile | tee -a $ofile2
    fi
  else
    dbg_echo hoststat 3 "not [ x$hoststat_do_scan == x\"1\" ], not scaning"
  fi

}

hoststat_uphosts() {
  dbg_echo hoststat 6 F "Start"
  mkdir -p "${HOSTSTAT_WDIR}"
  export LOGFILE="${HOSTSTAT_WDIR}/misc.log"
  export hoststat_outdir="${HOSTSTAT_WDIR}/stat/"
  touch ${hoststat_outdir}/scan.timestamp
  hoststat__iterate_hostid _hoststat_uphosts_hlpr
  dbg_echo hoststat 6 F "End"
}

hoststat_uphosts_cli() {
  hoststat_uphosts
}

##################################

# scan all using sshkeyscan mass scan mode. currently

hoststat_scan_all_at_once_sshkeyscan() {
  dbg_echo hoststat 6 F "Start"
  local _wdir=${HOSTSTAT_WDIR}/scan_all_1/

  mkdir_ifnot_q ${_wdir}
  hoststat_listhosts >${_wdir}/scan_ssh_inp.hostlist
  ssh-keyscan -f ${_wdir}/scan_ssh_inp.hostlist >${_wdir}/scan_ssh_out.data
  echo -------------
  cat ${_wdir}/scan_ssh_out.data | cut --delimiter=" " -f1
  dbg_echo hoststat 6 F "End"
}

##################################

_hoststat_listhosts_printvars_hlpr() {
  echo "--------------------------"
  echo -n "scan hst=$HOST_id; "
  echo "incoming_scanhst=$incoming_scanhst"
  echo "hoststat_isup_this_host=$hoststat_isup_this_host"
  echo "hoststat_do_scan=$hoststat_do_scan"
  echo "incoming_detect_type=$incoming_detect_type"
  #set|grep incoming
}

hoststat_listhosts_printvars() {
  export hoststat_outdir="${HOSTSTAT_WDIR}/stat/"
  #hostcfg_iterate_hostid _hoststat_listhosts_printvars_hlpr
  hoststat__iterate_hostid _hoststat_listhosts_printvars_hlpr
}

hoststat_isup_this_host_str_f() {
  local hoststat_isup_this_host=$1

  hoststat_isup_this_host_str="- UNKNOWN -"
  if [ x$hoststat_isup_this_host == "x1" ]; then
    hoststat_isup_this_host_str="online"
  fi
  if [ x$hoststat_isup_this_host == "x0" ]; then
    hoststat_isup_this_host_str="- OFFLINE -"
  fi
  #hoststat_isup_this_host_str="unknown";
  #fi

}

_hoststat_listhosts_printnormal_hlpr() {
  hoststat_hostid_load_api_nohook $HOST_id
  
  hoststat_isup_this_host_str_f $hoststat_isup_this_host
  printf "%15s" ${HOST_id}
  echo -n " | "
  echo -n "$hoststat_isup_this_host_str"
  echo

}

hoststat_listhosts_printnormal() {
  export hoststat_outdir="${HOSTSTAT_WDIR}/stat/"
  #hostcfg_iterate_hostid _hoststat_listhosts_printnormal_hlpr
  hoststat__iterate_hostid _hoststat_listhosts_printnormal_hlpr
}

hoststat_listhosts_print_cmd() {
  if [ ! -z $hoststat_opt_v_set ]; then
    hoststat_listhosts_printvars
  else
    hoststat_listhosts_printnormal
  fi
}

_hoststat_listhosts_hlpr() {
  hoststat_hostid_load_api_nohook $HOST_id
  echo "$incoming_scanhst"
}

hoststat_listhosts() {
  export hoststat_outdir="${HOSTSTAT_WDIR}/stat/"
  #hostcfg_iterate_hostid _hoststat_listhosts_hlpr
  hoststat__iterate_hostid _hoststat_listhosts_hlpr
}

##################################
_hoststat_listnodes_print_hlpr() {
  hoststat_isup_this_host_str_f $hoststat_isup_this_host
  printf "%35s" ${NODE_ID}
  echo -n " | "
  echo -n "$hoststat_isup_this_host_str"
  echo
}

hoststat_listnodes_print() {
  echo -n
  nodecfg_iterate_full_nodeid _hoststat_listnodes_print_hlpr
}

hoststat_listnodes_print_cmd() {
  hoststat_listnodes_print
}

##################################

hoststat_datemark() {
  LC_ALL=C date
}

hoststat_is_alive_ping() {
  local i=$1
  local res

  if [ x$LOGFILE == x ]; then
    LOGFILE=/dev/null
  fi
  ping -c 1 $1 >>$LOGFILE
  res=$?
  echo "res=$res"
  if [ $res == "0" ]; then
    echo $(hoststat_datemark)"  Node with IP: $i is up." | tee -a $LOGFILE
    return 0
  else
    return 255
  fi
  #return $res
}


hoststat_is_alive_tcpport() {
  local i=$1 port out
  [ x$LOGFILE == x ] && LOGFILE=/dev/null
  port=$CONNECT_sshport
  [ x$CONNECT_sshport == x ] && port=22
  
  generic_check_host_port $i $port $hoststat_tcpport_timeout
  
  if [ $? -eq 0 ]; then
   echo $(hoststat_datemark) "Node with IP: $i is up." >> $LOGFILE
   return 0
  fi
  return 1
}


hoststat_is_alive_nmap() {
  local i=$1 ret
  if [ x$LOGFILE == x ]; then
    LOGFILE=/dev/null
  fi

  nmap -sP $1 >>$LOGFILE
  ret=$?
  [ $? -eq 0 ] && echo $(hoststat_datemark) " Node with IP: $i is up." | tee -a $LOGFILE
  return $ret
}




hoststat_is_alive_sshkeyscan() {
  #set +x
  local i=$1
  local _wd=${HOSTSTAT_WDIR}/ssh-keyscan-byhost/
  dbg_echo hoststat 3 HOSTSTAT_WDIR=${HOSTSTAT_WDIR}
  dbg_echo hoststat 3 "_wd=${_wd}"
  #echo "HOSTSTAT_WDIR=$HOSTSTAT_WDIR"
  mkdir_ifnot_q ${_wd}
  # exit
  if [ x$LOGFILE == x ]; then
    LOGFILE=/dev/null
  fi
  #ssh-keyscan $i >> $LOGFILE
  ssh-keyscan $i >${_wd}/${i}.out
  grep $i ${_wd}/${i}.out
  [ $? -eq 0 ] && echo $(hoststat_datemark) " Node with IP: $i is up." | tee -a $LOGFILE
}

function hoststat_isup_one_host {
  local fTST F hst=$1
  [ -z "$hst" ] && return 4
  #if [ -z "$incoming_detect_type" ]; then #incoming_detect_type="nmap"  #fi

  F="hoststat_is_alive_$incoming_detect_type"
  fTST=$(type -t $F)
  if [ x$fTST == x"function" ]; then
    $F $hst
    ret=$?
    dbg_echo hoststat 12 F "pre ret=$ret, call \"$F\""
    return $ret
  else
    return 2
  fi
}

##############################################

hoststat_scanhosts_cli() {
  hoststat_scanhosts
}

hoststat_cidr_to_ip()
{
  [ -z "$*" ] && ( distr_error "ERROR, no input parameters";exit)
  ${MODINFO_modpath_hoststat}/cidr-to-ip.sh $@ 2>/dev/null
}

hoststat__list_ip() {
  #local range=$@
  dbg_echo hoststat 6  "Start: params=$@"
  nmap -sL -n $@ | grep "Nmap scan report for" | cut -d " " -f 5
}




hoststat_scanhosts() {
  dbg_echo hoststat 6  "Start: params=$@"
  local pp _wdir="${HOSTSTAT_WDIR}/scan_around_1/"
  mkdir_ifnot_q ${_wdir}

  #local hoststat_scanhosts_range
  #local range_ip4="192.168.0.1/27"
  cfgstack_load_byid etc/hoststat.conf ${THIS_HOSTID}

  local range_ip4=$hoststat_scanhosts_range_ip4
  local range_ports="22 8022"
  msg_echo hoststat 2  "Range: $range_ip4"
  msg_echo hoststat 2  "Ports: $range_ports"
  #hoststat_cidr_to_ip $range_ip4

  hoststat__list_ip $range_ip4 > ${_wdir}/scan_ssh_inp.hostlist
  #msg_echo hoststat 2  "Hosts to scan: "
  echo -n "Hosts to scan: "
  cat ${_wdir}/scan_ssh_inp.hostlist| wc -l
  #cat ${_wdir}/scan_ssh_inp.hostlist
 
  cat /dev/null > ${_wdir}/scan_ssh_out.data
  for pp in $range_ports ; do
    ssh-keyscan -p $pp -f ${_wdir}/scan_ssh_inp.hostlist >> ${_wdir}/scan_ssh_out.data 2> /dev/null
    #&1 | tee ${_wdir}/scanlog
  done
  cat ${_wdir}/scan_ssh_out.data
}


hoststat_scan_identify_cli(){
  dbg_echo hoststat 6  "Start: params=$@"
  local var str sshkey hosturl hosturl1 pp wdir="${HOSTSTAT_WDIR}/scan_around_1/"
  local known_hosts_list="$HOME/.ssh/known_hosts"
  
  # 2 - keytype 3 - key
  IFS=$'\n'
  for str in $(cat ${wdir}/scan_ssh_out.data ) ; do
     IFS=" "
     sshkey=$( echo $str |cut -d " " -f 3 )
     hosturl=$(echo $str |cut -d " " -f 1 )
     [ ! "x$hosturl1" == "x$hosturl" ] && echo "------- Now: $hosturl -------"
     #var=$(grep $sshkey $known_hosts_list )   #echo res=$?     #echo $var 
     grep $sshkey $known_hosts_list | cut -d " " -f 1
     hosturl1=$hosturl
  done

}

hoststat_get_info_bypubkey_cli(){
  local wdir="${HOSTSTAT_WDIR}/scan_around_1/"
  dbg_echo hoststat 6  "Start: params=$@"

  local eid=$1 opt_p s
  [ ! -n "$1" ] && distr_error "ERROR, exit." && distr_error_echo "need parameter" && exit
  distr_is_not_entityid $eid > /dev/null &&  distr_error "ERROR, \"$eid\" not entityid" &&  exit
  
  #hostcfg_hostid_exists $eid;  #[ ! $? == 0 ] && msg_echo hoststat  1 "ERROR: eid=\"$eid\" not exist"  && exit
  hostcfg_hostid_load $eid
  local cfgdir=`distr_entityid_cfgdir $eid`
  [ -z "$cfgdir" ] && msg_echo sshenv 1 "ERROR: cfgdir == \"\" "  && exit
  dbg_echo hoststat 8 "cfgdir=$cfgdir"
  local sfile=${cfgdir}/etc/ssh_known_hosts
  [ ! -f $sfile ] && msg_echo hoststat 1 "No ssh_known_hosts for \"$eid\"" && return
  #cat $sfile

  msg_echo hoststat 2 "---------------- $eid ----------------"
  msg_echo hoststat 1 "searching \"$eid\" (nodeid/hostid) keys in .../scan_ssh_out.data "
  IFS=$'\n'
  for str in $(cat $sfile ) ; do
     IFS=" "
     sshkey=$( echo $str |cut -d " " -f 3 )
     hosturl=$(echo $str |cut -d " " -f 1 )
     grep $sshkey ${wdir}/scan_ssh_out.data | cut -d " " -f 1
  done


}

############ cli integration  ################

hoststat_cli_help() {
  dgridsys_s; echo "hoststat listhosts"
  dgridsys_s; echo "		-v - print variables about hosts"
  dgridsys_s; echo "hoststat scan-hosts"
  dgridsys_s; echo "hoststat up-hosts"
  dgridsys_s; echo "hoststat listnodes"
}

hoststat_cli_run() {
  local maincmd=$1 cmd=$2 name=$3

  dbg_echo hoststat 5 x${maincmd} == x"module"
  [ ! x${maincmd} == x"hoststat" ] && return

  if [ x${cmd} == x"" ]; then
    hoststat_cli_help
  fi

  if [ x${cmd} == x"listhosts" ]; then
    shift 2
    system_parse_getopt hoststat "v" $*
    hoststat_listhosts_print_cmd
  fi

  if [ x${cmd} == x"listnodes" ]; then
    shift 2
    system_parse_getopt hoststat "v" $*
    hoststat_listnodes_print_cmd
  fi

  if [ x${cmd} == x"up-hosts" ]; then
    export MODINFO_dbg_hoststat=0
    hoststat_uphosts_cli
  fi

  if [ x${cmd} == x"scan-hosts" ]; then
    export MODINFO_dbg_hoststat=0
    hoststat_scanhosts_cli
  fi


}
