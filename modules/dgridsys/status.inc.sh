#!/bin/bash

dgridsys_cli_help_status() {
  dgridsys_s
  echo "status"
  dgridsys_s
  echo "status full"

}

status_print_string_short() {
  status_version_str
}

status_version_str() {
  local v v2 dsysmark
  v=${dgrid_core_version}
  v2=${dgrid_core}
  echo "dgrid - $v [core - $v2]"
}

status_print() {
  local v v2 dsysmark
  #v=${dgrid_core_version}
  #v2=${dgrid_core}
  #dsysmark_str="'${DGRID_dgridname}' system, dgrid - $v [core - $v2]"
  dsysmark_verstr=$(status_version_str)

  #set|grep ^dgrid|grep core
  echo
  printf "%50s" " === status: $dsysmark_verstr  ==="
  echo
  echo
  printf "%15s" "dgrid name"
  echo "   | " $DGRID_dgridname
  printf "%15s" THIS_NODEID
  echo "   | " $THIS_NODEID
  status_print_cache

  #status_call_hook_print_status # echo ---
  status_call_hook_print_status | split_iterate_stream status_print_item "\|"
  #while read STR; do
  #printf "%15s" $STR ;
  #done
}

status_print_item() {
  echo -n
  printf "%15s" ${ARRAY[0]}
  echo "   | " ${ARRAY[1]}
}

status_print_cache() {
  printf "%15s" CACHE_TYPES
  echo -n "   | " $CACHE_TYPES
  echo "   [current type: $cache_type ]"
  cache_path_out=${cache_path/$HOME/\$HOME}
  printf "%15s" cache_path
  echo "   | " $cache_path_out
}
status_call_hook_print_status() {
  main_call_hook print_status $*
}

dgridsys_cli_status() {
  maincmd=$1
  cmd=$2

  if [ x$maincmd == x"status" ]; then
    status_print
    echo
    return
  fi
}
