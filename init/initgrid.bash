#!/bin/bash

if [ x$MODINFO_loaded_initgrid == "x" ]; then
  export MODINFO_loaded_initgrid="Y"
else
  return
fi

# functions for initgrid

initgrid_install_dgridbase_copy() {
  pushd $dgridpath/$dgridname >/dev/null
  initgrid_echo DGRIDDISTDIR=$DGRIDDISTDIR
  initgrid_echo cp -aR $DGRIDDISTDIR ./
  cp -aR $DGRIDDISTDIR ./
  popd >/dev/null
}

initgrid_install_dgridbase_hg2hg() {
  initgrid_hg_paths_default=$(initgrid_hg_get_uplink_repo)
  initgrid_hg_our_dgrid_path=$(initgrid_get_our_dgrid_path)

  if [ -z "$initgrid_hg_our_dgrid_path" ]; then
    initgrid_echo "initgrid_hg_our_dgrid_path == \"\" empty, aborting"
    exit
  fi
  if [ -z "$initgrid_hg_paths_default" ]; then
    initgrid_echo "initgrid_hg_paths_default == \"\" empty"
  else
    initgrid_echo "Use uplink initgrid_hg_paths_default as initgrid_hg_our_dgrid_path"
    initgrid_echo "initgrid_hg_our_dgrid_path=$initgrid_hg_paths_default"
    initgrid_hg_our_dgrid_path=$initgrid_hg_paths_default
  fi

  pushd $dgridpath/$dgridname >/dev/null
  #initgrid_echo hg clone $initgrid_hg_paths_default
  initgrid_echo -n pwd=$(pwd)
  initgrid_echo hg clone $initgrid_hg_our_dgrid_path dgrid
  hg clone $initgrid_hg_our_dgrid_path dgrid | initgrid_save_to_log
  initgrid_echo -n
  popd >/dev/null
}

install_dgridbase_src_type_GET() {
  pushd $initgrid_BASEDIR_DGRID >/dev/null

  if [ -d .hg/ ]; then
    echo "hg"
    return 0
  fi
  if [ -d .git/ ]; then
    echo "git"
    return 0
  fi

  echo "archive"
  return 0
  popd >/dev/null
}

initgrid_get_our_dgrid_path() {
  pushd $initgrid_BASEDIR_DGRID >/dev/null
  if [ -f ./.hg/store/00manifest.i ]; then
    echo $initgrid_BASEDIR_DGRID
  fi
  popd >/dev/null
}

#####

dgridbase_export_archive() {
  initgrid_echo "dgrid_base_export_archive()" 1>&2
  cp -aR $initgrid_BASEDIR_DGRID $dst
}

dgridbase_export_hg() {
  local dst=$1
  initgrid_echo "dgrid_base_export_hg() dst=$dst"
  mkdir -p $dst
  hg archive -t files $dst
}

dgridbase_export_git() {
  initgrid_echo "dgrid_base_export_git()  dst=$dst"
  initgrid_nogit_warn
  exit
}

dgridbase_export() {
  driverfunction2 dgridbase_export ${install_dgridbase_src_type} $*
}

###

install_dgridbase_createnew_hg() {
  echo -n

}
install_dgridbase_createnew_git() {
  initgrid_nogit_warn
  exit
}

install_dgridbase_createnew() {
  driverfunction2 install_dgridbase_createnew ${install_dgridbase_src_type} $*
}

################

initgrid_nogit_warn() {
  echo "Currently git not supported, aborted"
}

## save install parameters

initgrid_save_install_params() {
  out="$installvar_NEWDIR_DGRID/not-in-vcs/initgrid_this"
  mkdir -p $out
  out=${out}/installed_grid.conf

  cat /dev/null >${out}
  (
    set -o posix
    set
  ) | grep ^installvar_ >>${out}
  (
    set -o posix
    set
  ) | grep ^install_ >>${out}
#  (
#    set -o posix
#    set
#  ) | grep ^initgrid_ >>${out}
}

#######################################################

initgrid_hg_get_uplink_repo() {
  #cat ../.hg/hgrc
  local var

  var=$(hg showconfig | grep paths.default) 1>&2
  var=${var/paths./initgrid_hg_paths_}
  #echo $var 1>&2
  eval $var
  echo $initgrid_hg_paths_default
}

#############################################################

initgrid_dgridsys() {
  #echo "dgridsys $*"
  dbg_echo initgrid 5 F "dgridsys $*"
  distr_run_bash_clean NONE ./dgrid/modules/dgridsys/dgridsys $*
  #system_f_cleanenv ./dgrid/modules/dgridsys/dgridsys $*
  #dgridsys_cli_main $*
}



initgrid_timestamp() {
  date +%s
}

initgrid_echo() {
  local L="$*"
  echo "$L"
  if [ "x$DGRID_initgrid_log" == "x" ]; then exit; fi
  if [ ! -w "$DGRID_initgrid_log" ]; then return; fi
  echo "$L" >>$DGRID_initgrid_log
}

initgrid_echo_n() {
  local L="$*"
  echo -n "$L"
  if [ "x$DGRID_initgrid_log" == "x" ]; then exit; fi
  if [ ! -w "$DGRID_initgrid_log" ]; then return; fi
  echo -n "$L" >>$DGRID_initgrid_log
}

initgrid_installvar_exit() {
  local e=$1
  if [ x$installvar_exit == x$e ]; then
    initgrid_echo "=========>  installvar_exit == \"$e\", exit"
    exit
  fi
}

initgrid_parse_keyval_cli() {
  local _p="" _v _c 
  for _p in $*; do
    _v=""
    _c=""
    _v=$(generic_cut_param "=" 1 "${_p}")
    _c=$(generic_cut_param "=" 2 "${_p}")
    read installvar_${_v} <<<"${_c}"

    export installvar_${_v}
  done
  unset _p
  #( set -o posix ; set )|grep ^installvar_
}

initgrid_save_to_log() {
  if [ "x$DGRID_initgrid_log" == "x" ]; then exit; fi
  if [ ! -w "$DGRID_initgrid_log" ]; then return; fi
  tee -a $DGRID_initgrid_log
}

##########################################################################

initgrid_2stage_run() {

  #echo "Run all .initgrid scripts from all avaliable modules."
  #main_mod_runfunc 'run_mod_init $name $mod_dir stage1'

  # fix some 1st
  _distr_mkdir ./bynodes/
  touch ./bynodes/.keep_me

  # enable main CLI utility
  MODINFO_dbg_main=10
  echo "== enable main CLI utility: ./dgrid/main/modules-enable dgridsys"
  #system_f_cleanenv ./dgrid/main/modules-enable dgridsys
  ./dgrid/main/modules-enable dgridsys
  echo "== END (enable main CLI utility: ./dgrid/main/modules-enable dgridsys)"

  # system module funcs load (manual)
  echo "main_load_module_into_context dgridsys :"
  main_load_module_into_context dgridsys

  # clear cache
  initgrid_dgridsys module cache_clear
  #./dgrid/main/modules-cache-clear

  echo "add files from enabled dgridsys"
  cp -v ./dgrid/modules/dgridsys/dgridsys ./dgrid-site/bin/${DGRID_dgridname}-dgridsys
  cp -v ./dgrid/modules/dgridsys/libdgrid.sh ./dgrid-site/bin/

  # install CLI in ~/bin/ directory
  if [ -f $HOME/bin/${DGRID_dgridname}-dgridsys ]; then
    echo "ok, \$HOME/bin/${DGRID_dgridname}-dgridsys already installed"
  else
    ln -s $DGRIDBASEDIR/dgrid-site/bin/${DGRID_dgridname}-dgridsys $HOME/bin/
  fi

  # add this node
  #nodecfg_add_this_node
  mkdir -p ./not-in-vcs/attach/
  initgrid_dgridsys nodecfg addthis

  _distr_mkdir ./bynodes/
  cp -v -r ./not-in-vcs/attach//thisnode/cfg/* ./bynodes/

  #init dvcs (hg)
  hgone_initthisnodestorage_initgrid
  hgone_register_all_changes $(system_trans_genid)

  # clear cache, after finish
  initgrid_dgridsys module cache_clear

  # we should be ok now to run module supplied scripts
  #MODINFO_dbg_main=10
  # old way disabled
  #main_mod_runfunc 'run_mod_init $name $mod_dir stage3'
  
  hgone_register_all_changes $(system_trans_genid)
}



##########################################################################

initgrid_actual_do_install() {
  initgrid_echo "Begin actual_do_install()"
  cd $installvar_NEWDIR_DGRID
  initgrid_echo "actual_do_install() : ./dgrid/init/initgrid-structure $dgridname"
  
  # exit:before-actual-do-install
  initgrid_installvar_exit before-actual-do-install
  #
  # 
  initgrid_echo "pushd into target directory $dgridpath/$dgridname "
  initgrid_echo "init grid sys directories : distr__en_create_dirs"

  pushd $dgridpath/$dgridname >/dev/null
  distr__en_create_dirs
  #exit
  echo "DGRID_dgridname=\"$dgridname\"" > ./dgrid-site/etc/dgrid.conf
  popd > /dev/null
  initgrid_echo "echo DGRID_dgridname=\"$dgridname\" \> ./dgrid-site/etc/dgrid.conf"
  export RUN_FROM_init_dgrid_structure=y

  # copy log file
  initgrid_echo cp $DGRID_initgrid_log $installvar_NEWDIR_DGRID/not-in-vcs/initgrid_this/
  cp $DGRID_initgrid_log $installvar_NEWDIR_DGRID/not-in-vcs/initgrid_this/
  
  # execute next stage of installations inside new empty node
  initgrid_echo "bash ./dgrid/init/initgrid-2nd-stage.bash"
  pushd $dgridpath/$dgridname >/dev/null
  distr_run_bash_clean RUN_FROM_init_dgrid_structure ./dgrid/init/initgrid-2nd-stage.bash
  #env -i RUN_FROM_init_dgrid_structure=y bash -l ./dgrid/init/initgrid-2nd-stage.bash
  exit
  popd > /dev/null

  initgrid_echo "End actual_do_install()"
}



#######################################################################


initgrid_install_dgrid() {
  #export dgridname=$1
  #export dgridpath=$2
  #export dgridconffile=$3

  #if [ x$dgridpath == x ]; then
  if [ x$1 == x ]; then
    echo "Usage: $0 name=<dgridname> dest=<dgridpath> [cfg=<dgridconffile> ....]"
    echo
    echo "   This script create new grid system in directory <dgridpath> with "
    echo "   name <dgridname>. Additional parameters can be added in optional"
    echo "   <dgridconffile> file in key-value format"
    echo
    exit
  fi

  ######### parse CLI arguments ########
  #
  # EXPECTED ./initgrid.bash arg1=value
  #
  ######################################
  initgrid_parse_keyval_cli $*
  #( set -o posix ; set )|grep ^installvar_

  # exit:cli-parse
  initgrid_installvar_exit cli-parse

  #####################################

  ########## temporary log ##############
  dgridtimestamp1=$(initgrid_timestamp)
  export installvar_dgridtimestamp1=$dgridtimestamp1

  export installvar_initgrid_log_filename=dgrid-initgrid-install-${dgridtimestamp1}.log
  export DGRID_initgrid_log=$HOME/${installvar_initgrid_log_filename}
  touch $DGRID_initgrid_log # echo "touch return=$?"
  export install_initgrid_log=$DGRID_initgrid_log
  export installvar_initgrid_log=$DGRID_initgrid_log

  initgrid_echo "============  Starting temporary log ================"
  initgrid_echo_n " date="
  LC_ALL=C date | initgrid_save_to_log
  initgrid_echo "=== LOG tmpl: \$HOME/dgrid-initgrid-install-${dgridtimestamp1}.log"
  initgrid_echo "=== LOG     : $DGRID_initgrid_log"
  ########################################

  ############# vars assigment ###########
  #export dgridname=$1
  #export dgridpath=$2
  #export dgridconffile=$3

  export dgridconffile=$installvar_cfg
  ########################################

  ########## cfg file load ###############
  if [ x$dgridconffile != x ]; then
    if [ -f $dgridconffile ]; then
      initgrid_echo "Ok, config file for installation found [$dgridconffile]"
      source $dgridconffile
    #@exit
    else
      initgrid_echo "NOT Ok, config file for installation [$dgridconffile] not found but cfg set, abort"
      echo
      exit
    fi
  fi
  ########################################

  ############# vars assigment ###########
  export dgridname=$installvar_name
  export dgridpath=$installvar_dest
  ########################################

  ########### checks #####################
  if [ x$dgridpath == x"" ]; then
    initgrid_echo "dgridpath not set, exiting"
    exit
  fi
  #echo "dgridpath=\"$dgridpath\""

  if [ ! -d $dgridpath ]; then
    initgrid_echo "$dgridpath not exists or not directory, exit"
    exit
  else
    initgrid_echo "Ok, $dgridpath is a directory, continue"
  fi
  if [ -w $dgridpath ]; then
    initgrid_echo "Ok, $dgridpath writable by you, continue"
  else
    initgrid_echo "$dgridpath not writable, exit"
    exit
  fi

  if [[ $dgridname =~ ^[A-Za-z0-9]+$ ]]; then
    initgrid_echo "Ok, grid name is alphabet letters or digits"
  else
    initgrid_echo "NOT Ok, grid name should be alphabet letters or digits"
    exit
  fi

  initgrid_echo
  initgrid_echo initgrid_BASEDIR_DGRID=$initgrid_BASEDIR_DGRID
  initgrid_echo installvar_dgridbase_driver=$installvar_dgridbase_driver
  initgrid_echo dgridname=$dgridname
  initgrid_echo dgridpath=$dgridpath
  initgrid_echo

  mkdir $dgridpath/$dgridname

  export installvar_NEWDIR_DGRID=$dgridpath/$dgridname
  export installvar_dgridname=$dgridname
  export installvar_dgridpath=$dgridpath

  initgrid_echo
  initgrid_echo installvar_NEWDIR_DGRID=$installvar_NEWDIR_DGRID

  # install_dgrid_base_src_type_GET
  export install_dgridbase_src_type=$(install_dgridbase_src_type_GET)

  initgrid_echo install_dgridbase_src_type=$install_dgridbase_src_type [autodetect]
  initgrid_echo install_dgridbase_dst_type=$install_dgridbase_dst_type [config]
  initgrid_echo install_dgridbase_dst_createnew=$install_dgridbase_dst_createnew [config]

  # exit:params-check
  initgrid_installvar_exit params-check

  ##

  # just copy driver
  if [ x"$installvar_dgridbase_driver" == x"copy" ]; then
    initgrid_echo "--------- installvar_dgridbase_driver == copy ------------"
    initgrid_install_dgridbase_copy
    initgrid_save_install_params
    initgrid_actual_do_install
    exit
  fi

  if [ x"$installvar_dgridbase_drive" == x"vcs1" ]; then
    if [ x"$install_dgridbase_dst_createnew" == x0 ]; then
      if [ x"$install_dgridbase_dst_type" == x"hg" ]; then
        initgrid_echo "run install_dgrid_base_hg2hg"
        initgrid_install_dgridbase_hg2hg
        initgrid_save_install_params
        initgrid_actual_do_install
        exit
      fi
    fi
  fi

  #

  if [ x"$installvar_dgridbase_drive" == x"vcs1" ]; then
  if [ x"$install_dgridbase_dst_createnew" == x1 ]; then
    dgridbase_export ${installvar_NEWDIR_DGRID}/dgrid
    install_dgridbase_createnew
    initgrid_save_install_params

    initgrid_actual_do_install
    initgrid_echo
    initgrid_echo
  else
    initgrid_echo " install_dgridbase_dst_createnew == 0 , but not found correct install procedure"
  fi
  fi

  initgrid_echo
  initgrid_echo
  exit
}
