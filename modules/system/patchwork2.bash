#!/bin/bash

# hacks & dirty stuff, stubs , etc.
# for needed when we dont have good api, or have it partial.
# But want to release new dgrid version.

function system_clear_list_vars_pref {
  echo DGRID MODINFO MODULE cache $MODULE_list_enabled
}

system_clear_list_vars_item() {
  #echo unset ${ARRAY[0]}
  for i in ${ARRAY[0]}; do
    echo -n "local $i ; ${i}=\"\" ;"
  done
}

function system_clear_list_vars {
  for pref in $(system_clear_list_vars_pref); do
    (
      set -o posix
      set
    ) | grep -i ^$pref | split_iterate_stream system_clear_list_vars_item "="
    #( set -o posix ; set ) | split_iterate_stream system_clear_list_vars_item "="
  done
}

system_f_cleanenv_do() { #
  pushd $DGRIDBASEDIR >/dev/null
  #echo DGRIDBASEDIR=$DGRIDBASEDIR
  local cmd=$1
  shift 1
  if [ -f "$cmd" ]; then
    echo -n
  else
    echo $cmd notfound
    exit
  fi

  # clear all dgrid variables
  eval $(system_clear_list_vars)
  #( set -o posix ; set ) #exit
  bash $cmd $*

  popd >/dev/null
}

system_f_cleanenv_othernode_do() { #
  local xdir=$1
  shift 1

  pushd $DGRIDBASEDIR >/dev/null
  #echo DGRIDBASEDIR=$DGRIDBASEDIR
  local cmd=$1
  shift 1
  if [ -f "$cmd" ]; then
    echo -n
  else
    echo $cmd notfound
    exit
  fi

  # clear all dgrid variables
  eval $(system_clear_list_vars)
  #( set -o posix ; set ) #exit
  cd $xdir
  bash $cmd $*

  popd >/dev/null
}

system_f_cleanenv() { # [API] [RECOMENDED]
  pushd $DGRIDBASEDIR >/dev/null
  ./dgrid/modules/system/system-runcleanenv $*
  #system_f_cleanenv_do $*
  popd >/dev/null
}

system_f_cleanenv_othernode() { # [API] [RECOMENDED]
  local xdir=$1
  shift 1
  pushd $DGRIDBASEDIR >/dev/null
  bash ./dgrid/modules/system/system-runcleanenv-othernode $xdir $*
  #system_f_cleanenv_do $*
  popd >/dev/null
}

#####################################


########################
