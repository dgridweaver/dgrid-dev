#!/bin/bash


mininode_op_dgrid_site_full(){
  if [ x$mininode_bv_dgrid_site_full == x1 ]; then
    msg_echo mininode 2 "DO: cp -aR dgrid-site/* \$mininode_buildroot/"
    mkdir -p $mininode_buildroot/dgrid-site/etc
    mkdir -p $mininode_buildroot/dgrid-site/modules
    cp -aR dgrid-site/etc $mininode_buildroot/dgrid-site/
  fi
}


mininode_op_force_THIS_NODEID(){
  local ddd="$mininode_buildroot/${DGRID_localdir}/THIS"
  dbg_echo mininode 4 "check force_THIS_NODEID"
  echo mininode_bv_force_THIS_NODEID=$mininode_bv_force_THIS_NODEID
  if [ x$mininode_bv_force_THIS_NODEID == x1 ]; then
    msg_echo mininode 2 "DO force_THIS_NODEID"
    mkdir -p $ddd 
    echo "THIS_NODEID=$NODE_ID" > $ddd/this-install.conf
  fi

}

mininode_op_this_enityid_configs(){
  local n=`nodecfg_nodeid_cfgdir $NODE_ID`
  local h=`hostcfg_hostid_cfgdir $HOST_id`
  echo n=$n h=$h
  ( find $n ; find $h ) > ${mininode_wdir}/list_this_enityid_configs
  mininode__copy_filelist_tar ${mininode_wdir}/list_this_enityid_configs $mininode_buildroot
}

##################################


mininode_f_setvar(){
  msg_echo mininode 4 "setvar var value (NOT IMPLEMENTED)"
}

mininode_f_base(){
  msg_echo mininode 4 "base enabled"
  export mininode_bv_base=1
  
  export mininode_bv_mod_main=1
  export mininode_bv_mod_nodecfg=1
  
  export mininode_bv_mod_distr=1
  export mininode_bv_mod_init=1
  export mininode_bv_mod_system=1
  
  export mininode_bv_all_mods="main nodecfg distr init system $mininode_bv_all_mods"
}


mininode_f_enable(){
  msg_echo mininode 4 "enable module $1"
  [ -z "$1" ] && msg_echo mininode 12 "enable module -- module not set"  && return
  read mininode_bv_mod_$1 <<< "1"
  export mininode_bv_all_mods="$mininode_bv_all_mods $1"
}

mininode_f_dgrid_site_full(){
export mininode_bv_dgrid_site_full=1
}


mininode_f_force_THIS_NODEID(){
  local v=$1; if [ -z "$v" ]; then v=1;  fi
  export mininode_bv_force_THIS_NODEID=$v;
  msg_echo mininode 4 F "v=$v"
}




##################################


mininode_modf_list_system(){
#./system-runcleanenv
#
echo "
./system.defaultvalues
./system.conf.SAMPLE
./system.bash
./system_initgrid.bash
./patchwork.bash
./hgone/hgignore.template
./hgone/hgone.bash
./system_installable.bash
./system.modinfo
./generic-code.bash
"
}


mininode_modf_list_main(){
echo "./cache/cache-dgrid.conf.SAMPLE
./cache/cache.inc.sh
./cache/README
./Changelog
./dgrid-structure.conf
./libdgrid.sh
./lib.sh
./loadconfigs1.sh
./loadconfigs.sh
./main.bash
./main.modinfo
./runtime.bash
"
}

mininode_modf_list_init(){
echo "./init
./init.modinfo
./init.bash
"
}










