#!/bin/bash

devhelper_tname="template_one"

devhelper_call_hook_print() { # [API]
  local hook params code funclist
  hook=$1
  shift 1
  funclist=$(cache_wrap_func hook_func_list_$hook _main_call_hook_list $hook)
  echo "Hook \"$hook\""
  for F in $funclist; do
    dbg_echo main 2 run ${F} $PARAMS 1>&2
    code="${F} $*"
    #eval $code
    echo "code: $code"
  done
}

_devhelper_newmod_file() {
  while read FILE; do
    FILENAME=$(basename $FILE)
    #${string/substring/replacement}
    FILENAME=${FILENAME/.TEMPREMOVE/}
    FILENAME=${FILENAME/TEMPLATE/$name}
    echo "cat $FILE | sed s/TEMPLATE/$name/g > $dst/$FILENAME"
    cat $FILE | sed s/TEMPLATE/$name/g >$dst/$FILENAME
    if [ -x $FILE ]; then
      chmod u+x,g+x,o+x $dst/$FILENAME
    fi
  done
}

devhelper_newmod() {
  name=$3
  #name=

  local src="${MODINFO_modpath_devhelper}/${devhelper_tname}/"
  local dst="./dgrid-site/modules/$name"

  if [ -a $dst ]; then
    echo "Abort - already exists!"
    return
  fi

  echo ------ create $name module --------------
  echo "mkdir -p $dst"
  mkdir -p $dst
  find $src -type f | _devhelper_newmod_file
  echo "cp dgrid/main/libdgrid/libdgrid.sh $dst/"
  cp dgrid/main/libdgrid/libdgrid.sh $dst/
  echo -------------------------------------------
}

####### hook ############

_devhelper_hook_list_var_hlp1() {
  find -iname \*.bash -exec egrep "^ *main_call_hook " \{\} \;
  find -iname \*.sh -exec egrep "^ *main_call_hook " \{\} \;
  #( find -iname *.bash -exec egrep "^ *main_call_hook " \{\} \; ; \
  #find -iname *.bash -exec egrep "\`main_call_hook " \{\} \; ) | while read A B C ;
  #find -iname \*.bash -iname \*.sh -exec egrep "^ *main_call_hook " \{\} \; | sort | while read A B C ;
}

devhelper_hook_list_var() {
  cd $DGRIDBASEDIR

  _devhelper_hook_list_var_hlp1 | sort | while read A B C; do
    #echo $A -- $B
    echo -n $B " "
  done
}
devhelper_hook_info() {
  local h v i
  h=$1
  v=$(_main_call_hook_list $1)
  for i in $v; do
    echo -n "$i "
  done

}

devhelper_hook_list() {
  local hooklistvar var
  cd $DGRIDBASEDIR

  hooklistvar=$(devhelper_hook_list_var)
  echo " -- List all bashengine hooks -- "
  for var in $hooklistvar; do
    echo hook_$var
  done
}

devhelper_hook_list_info() {
  local hooklistvar var hf
  cd $DGRIDBASEDIR

  hooklistvar=$(devhelper_hook_list_var | sort)
  #echo " -- List all hooks -- "
  for var in $hooklistvar; do
    hf="hook_$var"
    printf "%18s" "hook name: "
    printf "${hf}()"
    echo
    #echo "hook name: $hf"
    printf "%18s" "hooked func's: "
    devhelper_hook_info $var
    #
    echo
    echo ------------------
  done
  echo
}
###### api #########

_devhelper_api_list_hlp1() {
  dbg_echo devhelper 4 "F start"
  find ./dgrid -not -path ".hg/*" -iname \*.bash -exec grep "\[API\]" \{\} \;
  find ./dgrid-site -not -path ".hg/*" -iname \*.bash -exec grep "\[API\]" \{\} \;
  dbg_echo devhelper 4 "F end"
}

devhelper_api_list() {
  cd $DGRIDBASEDIR
  echo ""
  _devhelper_api_list_hlp1 | sort | uniq |  sed "s/^function //" | sort
  echo ""
}

devhelper_grepcode() {
  local s=$1
  cd $DGRIDBASEDIR
  echo ""
  find -iname \*.bash -exec grep -n -H "$s" \{\} \;
  find -iname \*.sh -exec grep -n -H "$s" \{\} \;
  echo ""
}

devhelper_varlist() {
  set | grep "^DGRID"
}
devhelper_vars() {
  dgridsys_vars_list
}

devhelper_callfunc() {
  local f=$1
  shift 1
  local argv=$*

  if [ x${f} == "x" ]; then
    echo "empty funcname, exiting"
    exit
  fi

  if is_function_exists $f; then
    $f $argv
  else
    echo "funcname \"$f\" not exists"
  fi
}

############ cli integration  ################

devhelper_cli_help() {
  dgridsys_s;  echo "devhelper newmod <name> <.... - create new module"
  dgridsys_s;  echo "devhelper hooklist - list hooks"
  dgridsys_s;  echo "devhelper hooklistinfo - list hooks with some info"
  dgridsys_s;  echo "devhelper apilist - api func list"
  dgridsys_s;  echo "devhelper apilist-generic - generic api func list"
  dgridsys_s;  echo "devhelper grepcode - grep str"
  dgridsys_s;  echo "devhelper varlist - list variables"
  dgridsys_s;  echo "devhelper vars - variables from modinfo sybsystem"
  dgridsys_s;  echo "devhelper callfunc [funcname] - call dgrid internal function"
}

devhelper_cli_run() {
  maincmd=$1
  cmd=$2
  name=$3

  dbg_echo devhelper 5 x${maincmd} == x"module"
  if [ x${maincmd} == x"devhelper" ]; then
    echo -n
  else
    return
  fi

  if [ x${cmd} == x"" ]; then
    echo -n
    devhelper_cli_help
  fi

  if [ x${cmd} == x"newmod" ]; then
    echo -n
    devhelper_newmod $*
  fi

  if [ x${cmd} == x"hooklist" ]; then
    echo -n
    devhelper_hook_list $*
  fi

  if [ x${cmd} == x"hooklistinfo" ]; then
    echo -n
    devhelper_hook_list_info $*
  fi

  if [ x${cmd} == x"apilist" ]; then
    echo -n
    devhelper_api_list $*
  fi

  if [ x${cmd} == x"vars" ]; then
    echo -n
    devhelper_vars $*
  fi

  if [ x${cmd} == x"apilist-generic" ]; then
    echo -n
    devhelper_api_list $* | grep "\[GENERIC\]"
  fi

  if [ x${cmd} == x"grepcode" ]; then
    echo -n
    shift 2
    devhelper_grepcode $*
  fi

  if [ x${cmd} == x"varlist" ]; then
    echo -n
    shift 2
    devhelper_varlist $*
  fi

  if [ x${cmd} == x"callfunc" ]; then
    echo -n
    shift 2
    devhelper_callfunc $*
  fi

}
