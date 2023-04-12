#!/bin/bash


##### climenu intergation ####

sshenv_climenu_cmd_sshfs_mount(){
    sshenv_sshfs_mount_cli $@
}
sshenv_climenu_cmd_sshfs_umount(){
    sshenv_sshfs_umount_cli $@
}

sshenv_climenu_cmd_sshfs_list(){
    sshenv_sshfs_list_cli $@
}

##############################

sshenv_sshfs_list_cli(){
  dbg_echo sshenv 5 F "Begin"
  local mdir=${DGRID_dir_nodelocal}sshenv-sshfs
  dbg_echo sshenv 8 F  "mount|grep $mdir"
  echo "---- current sshfs list ----"
  mount|grep $mdir
}


sshenv_sshfs_get_mount_dir_main(){
  local eid=$1
  #DGRID_memdir #generic_listvars CACHE #generic_listvars cache_
  distr_is_not_entityid  "$eid" > /dev/null && distr_error "No \"$eid\" entity" && exit
  #echo $DGRID_dir_nodelocal/sshenv-sshfs/$eid/0
  echo $DGRID_dir_nodelocal/sshenv-sshfs/$eid/${eid}--0
  
}

  #${MODINFO_modpath_sshenv}/
sshenv_sshfs_mount_cli(){
  dbg_echo sshenv 5 F "Begin"
  local eid=$1
  distr_is_not_entityid  "$eid" > /dev/null && (msg_echo sshenv 1 "No \"$eid\" entity"; exit)
  msg_echo sshenv 2 "sshfs mounting \"$eid\""

  local dgssh=${DGRIDBASEDIR}/${MODINFO_modpath_sshenv}/ssh-dg
  local p=`sshenv_sshfs_get_mount_dir_main $eid`
  mkdir -p $p
  
  dbg_echo sshenv 2 F sshfs $eid:/ $p  -o ssh_command=$dgssh

  ##distr_run_bash_clean SSH_AGENT_PID,SSH_AUTH_SOCK,SSH_ASKPASS,PATH,HOME,LC_ALL,LC_CTYPE,LANG /usr/bin/sshfs $eid:/ $p/0/  -f -d -o ssh_command=$dgssh
  #distr_run_bash_clean HOME,LC_ALL,LC_CTYPE,LANG /usr/bin/sshfs $eid:/ $p/0/  -f -d -o ssh_command=$dgssh
  system_f_cleanenv sshfs $eid:/ $p  -o ssh_command=$dgssh ${SSHENV_SSHFS_opts}

  dbg_echo sshenv 5 F "End"
}

sshenv_sshfs_umount_cli(){
  dbg_echo sshenv 5 F "Begin"
  local eid=$1
  local p=`sshenv_sshfs_get_mount_dir_main $eid`
  msg_echo sshenv 2 "sshfs umounting \"$eid\""
  
  fusermount -u ${p}
  dbg_echo sshenv 5 F "End"
}



############ cli integration  ################

sshenv_cli_help_sshfs() {
  dgridsys_s;echo "sshenv sshfs-mount [entityid] - mount sshfs"
  dgridsys_s;echo "sshenv sshfs-umount [entityid] - umount sshfs"
  dgridsys_s;echo "sshenv sshfs-list - list of sshfs mounts (from this mod)"
}

sshenv_cli_run_sshfs() {
  maincmd=$1
  cmd=$2
  name=$3
  dbg_echo sshenv 5 F "Begin"
  
  if [ x${cmd} == x"sshfs-mount" ]; then
    shift 2
    sshenv_sshfs_mount_cli $*
    return 0
  fi

  if [ x${cmd} == x"sshfs-umount" ]; then
    shift 2
    sshenv_sshfs_umount_cli $*
    return 0
  fi

  if [ x${cmd} == x"sshfs-list" ]; then
    shift 2
    sshenv_sshfs_list_cli $*
    return 0
  fi


  dbg_echo sshenv 5 F "Cmd not found here, end"
  return 1
}