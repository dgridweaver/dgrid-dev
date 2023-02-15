#!/bin/bash

hoststat_conf_vars()
{
echo hoststat_do_scan incoming_detect_type incoming_scanhst hoststat_isup_this_host
}

hoststat_installable_files()
{
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


# define hook
#hoststat_hostinfo_vars()
#{hoststat_conf_vars}

hoststat_envset_start()
{
# set configure variables that used DGRID_dir_nodelocal

export HOSTSTAT_WDIR="${DGRID_dir_nodelocal}hoststat/"
export HOSTSTAT_WDIR_tmp="${DGRID_dir_nodelocal}hoststat/tmp/"
export HOSTSTAT_state_dir="${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
echo "export HOSTSTAT_WDIR=\"${DGRID_dir_nodelocal}hoststat/\""
echo "export HOSTSTAT_WDIR_tmp=${DGRID_dir_nodelocal}hoststat/tmp/"
echo "export HOSTSTAT_state_dir=${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
}

# define hook
hoststat_hostid_vars()
{
hoststat_conf_vars
}


# hook
# hoststat_hostid_load_api()
hoststat_hostid_load_api()
{
local _dir _hostid
_hostid=$1
_dir=`hostcfg_hostid_cfgdir ${_hostid}`

# define function for hook hook_hostid_load_api()
#echo "[2] hoststat_hostid_load_api()" 1>&2

cfg=${_dir}/etc/hoststat.conf
dbg_echo hoststat 3 "cfg=$cfg"

cfgstack_load_byid etc/hoststat.conf ${_hostid}


if [ x$hoststat_do_scan == x"" ]; then
export hoststat_do_scan=1
fi
#echo [2] hoststat_hostid_load_api() incoming_scanhst=$incoming_scanhst 1>&2

if [ x$incoming_scanhst == x ]; then
incoming_scanhst=$HOST_dnsname ;
fi

for var in `hoststat_conf_vars`; do
echo "export $var=\"${!var}\" ;"
dbg_echo hoststat 5 "[2] hoststat_hostid_load_api():  $var=\"${!var}\";" 1>&2
done

# load current host up/down state
#local _fstat="${hoststat_outdir}/${_hostid}/last.vars"
local _fstat="${HOSTSTAT_state_dir}/${_hostid}/last.vars"
dbg_echo hoststat 7 "[7] _fstat=\" ${_fstat}\"" 1>&2
if [ -f ${_fstat} ] ; then
dbg_echo hoststat 5 "[5] hoststat_hostid_load_api(): source ${_fstat}" 1>&2
#echo "[2] hoststat_hostid_load_api(): source ${_fstat}" 1>&2
source ${_fstat}
fi

}


################################

source ${MODINFO_modpath_hoststat}/pingpong.inc.bash



###########

_hoststat_scanhosts_hlpr()
{
local odir=${hoststat_outdir}/$HOST_id/
mkdir_ifnot_q $odir
local ofile=${odir}/${incoming_detect_type}.vars
local ofile2=${odir}/last.vars

echo "#--------------------------" | tee $ofile2
echo "#--------------------------" | tee $ofile
echo "" | tee -a $ofile
echo "# scan hst=$HOST_id;" | tee -a $ofile
echo "scanned_hst=$HOST_id;" | tee -a $ofile
#echo "hoststat_isup_this_host=$incoming_scanhst"
echo "hoststat_do_scan=$hoststat_do_scan" | tee -a $ofile
echo "incoming_scanhst=$incoming_scanhst" | tee -a $ofile
echo "incoming_detect_type=$incoming_detect_type" | tee -a $ofile

#
if [ x$hoststat_do_scan == x"1" ]; then
hoststat_isup_one_host $incoming_scanhst
#echo -n "res="
#echo $?
    if [ $? == "0" ]; then
    echo "# host online" | tee -a $ofile
    echo "hoststat_isup_this_host=1" | tee -a $ofile | tee -a $ofile2 
    else
    echo "# host *not* online" | tee -a $ofile
    echo "hoststat_isup_this_host=0" | tee -a $ofile | tee -a $ofile2
    fi
else
dbg_echo hoststat 3 "not [ x$hoststat_do_scan == x\"1\" ], not scaning"
fi

}

hoststat_scanhosts()
{

mkdir -p "${GRIDBASEDIR}/not-in-vcs/hoststat"
export LOGFILE="${GRIDBASEDIR}/not-in-vcs/hoststat/misc.log"
export hoststat_outdir="${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
touch ${hoststat_outdir}/scan.timestamp
hostcfg_iterate_hostid _hoststat_scanhosts_hlpr
}


hoststat_scanhosts_cmd()
{
hoststat_scanhosts
}

##################################

# scan all using sshkeyscan mass scan mode. currently

hoststat_scan_all_at_once_sshkeyscan()
{
local _wdir=${DGRID_dir_nodelocal}/hoststat/scan_all_1/

mkdir_ifnot_q ${_wdir}
hoststat_listhosts > ${_wdir}/scan_ssh_inp.hostlist
ssh-keyscan -f ${_wdir}/scan_ssh_inp.hostlist > ${_wdir}/scan_ssh_out.data
echo -------------
cat ${_wdir}/scan_ssh_out.data| cut --delimiter=" " -f1

}



##################################

_hoststat_listhosts_printvars_hlpr()
{
echo "--------------------------"
echo -n "scan hst=$HOST_id; "
echo "incoming_scanhst=$incoming_scanhst"
echo "hoststat_isup_this_host=$hoststat_isup_this_host"
echo "hoststat_do_scan=$hoststat_do_scan"
echo "incoming_detect_type=$incoming_detect_type"
#set|grep incoming
}

hoststat_listhosts_printvars()
{
export hoststat_outdir="${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
hostcfg_iterate_hostid _hoststat_listhosts_printvars_hlpr
}


hoststat_isup_this_host_str_f()
{
local hoststat_isup_this_host=$1

hoststat_isup_this_host_str="- UNKNOWN -"
if [ x$hoststat_isup_this_host == "x1" ]; then
hoststat_isup_this_host_str="online"
fi
if [ x$hoststat_isup_this_host == "x0" ]; then
hoststat_isup_this_host_str="- OFFLINE -" ;
fi
#hoststat_isup_this_host_str="unknown";
#fi

}

_hoststat_listhosts_printnormal_hlpr()
{
hoststat_isup_this_host_str_f $hoststat_isup_this_host
printf "%15s" ${HOST_id}
echo -n " | "
echo -n "$hoststat_isup_this_host_str"
echo

}

hoststat_listhosts_printnormal()
{
export hoststat_outdir="${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
hostcfg_iterate_hostid _hoststat_listhosts_printnormal_hlpr
}


hoststat_listhosts_print_cmd()
{
if [ ! -z $hoststat_opt_v_set ];then
hoststat_listhosts_printvars
else
hoststat_listhosts_printnormal
fi
}

_hoststat_listhosts_hlpr()
{
echo "$incoming_scanhst"
}

hoststat_listhosts()
{
export hoststat_outdir="${GRIDBASEDIR}/not-in-vcs/hoststat/stat/"
hostcfg_iterate_hostid _hoststat_listhosts_hlpr
}

##################################
_hoststat_listnodes_print_hlpr()
{
hoststat_isup_this_host_str_f $hoststat_isup_this_host
printf "%35s" ${NODE_ID}
echo -n " | "
echo -n "$hoststat_isup_this_host_str"
echo
}


hoststat_listnodes_print()
{
echo -n
nodecfg_iterate_full_nodeid _hoststat_listnodes_print_hlpr
}

hoststat_listnodes_print_cmd()
{
hoststat_listnodes_print
}



##################################

hoststat_datemark()
{
LC_ALL=C date
}



hoststat_is_alive_ping()
{
  local i=$1
  local res
  
  if [ x$LOGFILE == x ]; then
     LOGFILE=/dev/null
  fi
  ping -c 1 $1 >> $LOGFILE
  res=$?
  echo "res=$res"
    if [ $res == "0" ]; then
      echo `hoststat_datemark`"  Node with IP: $i is up." | tee -a $LOGFILE
    else
      return 255
    fi
  #return $res
}


hoststat_is_alive_nmap()
{
  i=$1
  if [ x$LOGFILE == x ]; then
     LOGFILE=/dev/null
  fi

nmap -sP $1 >> $LOGFILE
    [ $? -eq 0 ] && echo `hoststat_datemark`  " Node with IP: $i is up." | tee -a $LOGFILE

}

hoststat_is_alive_sshkeyscan()
{
set +x
  local i=$1
  local _wd=${HOSTSTAT_WDIR}/ssh-keyscan-byhost/
  msg_echo hoststat 3 DGRID_dir_nodelocal=$DGRID_dir_nodelocal
  msg_echo hoststat 3 "_wd=${_wd}"
  #echo "_wd=${_wd}"
  #echo "HOSTSTAT_WDIR=$HOSTSTAT_WDIR"
  mkdir_ifnot_q ${_wd}
# exit
  if [ x$LOGFILE == x ]; then
     LOGFILE=/dev/null
  fi
  #ssh-keyscan $i >> $LOGFILE
  ssh-keyscan $i > ${_wd}/${i}.out
  grep $i ${_wd}/${i}.out
#nmap -sP $1 >> $LOGFILE
    [ $? -eq 0 ] && echo `hoststat_datemark`  " Node with IP: $i is up." | tee -a $LOGFILE
}

function hoststat_isup_one_host
{
local fTST F hst
hst=$1

if [ -z "$incoming_detect_type" ]; then
incoming_detect_type="nmap"
fi

F="hoststat_is_alive_$incoming_detect_type"
fTST=`type -t $F`
if [ x$fTST  == x"function"  ]; then
$F $hst
ret=$?
echo "pre ret=$ret"
return $ret
else
return 2
fi
#hoststat_is_alive_nmap $1

#echo
}


############ cli integration  ################

hoststat_cli_help()
{
dgridsys_s;echo "hoststat listhosts"
dgridsys_s;echo "		-v - print variables about hosts"
dgridsys_s;echo "hoststat scanhosts"
dgridsys_s;echo "hoststat listnodes"
}


hoststat_cli_run()
{
maincmd=$1
cmd=$2
name=$3
#echo $*
#exit

dbg_echo hoststat 5  x${maincmd} == x"module"
if [ x${maincmd} == x"hoststat"  ]; then
#dgridsys_cli_module $*
echo -n
else
return
fi

if [ x${cmd} == x""  ]; then
echo -n
hoststat_cli_help
fi


if [ x${cmd} == x"listhosts"  ]; then
echo -n
shift 2
#echo "\$*=$*"
system_parse_getopt hoststat "v" $*
#set|grep hoststat_opt #exit
hoststat_listhosts_print_cmd
fi

if [ x${cmd} == x"listnodes"  ]; then
echo -n
shift 2
#echo "\$*=$*"
system_parse_getopt hoststat "v" $*
#set|grep hoststat_opt #exit
hoststat_listnodes_print_cmd
fi



if [ x${cmd} == x"scanhosts"  ]; then
export MODINFO_dbg_hoststat=0
hoststat_scanhosts_cmd
fi


if [ x${cmd} == x"pingpong-node"  ]; then
echo -n
shift 2
#hoststat_pingpongsrv_simple $* # srv
echo hoststat_pingpong_cicle_simple $*
hoststat_pingpong_cicle_simple $*
fi

}


