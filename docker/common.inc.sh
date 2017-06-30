#!/bin/sh
set -e -o pipefail
export TERM=xterm

WORKDIR="${WORKDIR:-$PWD}"

# import default variables
source $WORKDIR/docker/defaults.inc.sh

# include custom build config on demand
[ -e "$WORKDIR/docker/build.conf" ] && source $WORKDIR/docker/build.conf

ERROR_BKG=';41m' # background red
GREEN_BKG=';42m' # background green
BLUE_BKG='\e[44m' # background blue
YELLOW_BKG='\e[43m' # background yellow
MAGENTA_BKG='\e[45m' # background magenta

INFO_TEXT='\033[33' # yellow text
WHITE_TEXT='\e[97m' # text white
BLACK_TEXT='\033[30' # text black
RED_TEXT='\033[31' # text red
MAGENTA_TEXT='\e[35m'
NC='\033[0m' # reset


debugHead() {
  echo -e "${WHITE_TEXT}${MAGENTA_BKG}$*${NC}\n"
  echo -e "$*\n" >> $BUILD_LOG
}

debugText() {
  echo -e "${MAGENTA_TEXT}$*${NC}\n"
  echo -e "$*\n" >> $BUILD_LOG
}

warnText() {
  echo -e "\n${BLACK_TEXT}${YELLOW_BKG}*** ${1} ***${NC}\n"
  echo -e "\n*** $1 ***\n" >> $BUILD_LOG
}

errorText() {
  echo -e "\n${WHITE_TEXT}${ERROR_BKG}!!! ${1} !!!${NC}\n"
  echo -e "\n!!! $1 !!!\n" >> $BUILD_LOG
}

successText() {
  echo -e "\n${BLACK_TEXT}${GREEN_BKG}=> ${1} <=${NC}\n"
  echo -e "SUCCESS: $1" >> $BUILD_LOG
}

chapterHead() {
  echo -e "\n${BLUE_BKG}${WHITE_TEXT}::: ${1} :::${NC}\n"
  echo -e "\n::: $1 :::\n" >> $BUILD_LOG
}

sectionHead() {
  echo -e "\n${INFO_TEXT}m===> ${1} <===${NC}"
  echo -e "\n==> $1" >> $BUILD_LOG
}

sectionText() {
  echo -e "${INFO_TEXT}m-> ${1}${NC}"
  echo -e "-> $1" >> $BUILD_LOG
}

writeErrorMessage() {
  if [[ $? != 0 ]]; then
    errorText "${1}"
    errorText "Command FAILED"
    exit 1
  fi
}


install_packages() {
  local INSTALL_FLAGS=""
  if [ -z "${APK_CACHE_REFRESHED}" ]; then
    sectionText "Refreshing apk cache initially"
    apk update >> $BUILD_LOG
    export APK_CACHE_REFRESHED=yes
  fi
  if [ "$1" = "--build" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --virtual .build_deps"
    shift
  fi

  local PKG_LIST="$*"
  if [ -n "$PKG_LIST" ]; then
    sectionText "Installing package(s): $PKG_LIST"
    apk add $INSTALL_FLAGS $PKG_LIST >> $BUILD_LOG
  fi
}

exec_console() {
  sectionText "Executing 'console $@'"
  vendor/bin/console $@
}

# uses the find & sort to select scripts in lexical order (alpine doesn't support `find -s`)
# sources those scripts to make build.conf and defaults.inc.sh vars available to them
exec_scripts() {
  local directory=$1
  local context=${2-"build"}
  
  if [ -d "$directory" ]; then
    
    # provide script counting to inform the user about how many steps are available
    local available_scripts=`find $directory -type f -name '*.sh' -or -name '*.php' | sort`
    local scripts_count=`echo "$available_scripts" | wc -l`
    local scripts_counter=1
    
    for f in $available_scripts; do
      local script_name=`basename $f`
      
      sectionHead "Executing $context step ($scripts_counter/$scripts_count): $script_name"
      cd $WORKDIR # ensure we are starting within $WORKDIR for all scripts
      source $f
      
      let "scripts_counter += 1"
    done
    
  fi
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_tcp_service() {
  until nc -z $1 $2; do
    sectionText "Waiting for tcp://$1:$2 to come up ..."
    sleep 1
  done
  
  sectionText "Success: tcp://$1:$2 seems to be up, port is open"
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_http_service() {
  url=$1; shift
  until curl -s -k  $url -o /dev/null -L --fail $*; do
    sectionText "Waiting for $url to come up ..."
    sleep 1
  done
  
  sectionText "Success: $1 seems to be up and running"
}

fail() {
  exit=$1; shift
  for line in "$@"; do
    errorText $line
  done
  exit $exit
}

retry() {
  if [ $# -lt 2 ] ; then
    fail 1 "Error: wrong number of arguments!" \
           "Usage: retry <max_retries> <command> [<param1> [<param2> [...] ] ]"
  fi

  retries=$1
  shift
  command=$@

  set +e
  echo "Running \`$command\` with $retries retries"
  n=0
  while true; do
    $command && break
    n=$(expr $n + 1)
    if [ $n -le $retries ] ; then
      echo "Retry # $n"
    else
      fail 2 "ERROR: Max retries. Unable to \`$command\`"
    fi
    sleep 2
  done
  set -e
}

# checks if the given value exists in the list (space separated string
# recommended) parameter $1 => value, $2 => stringified list to search in
is_in_list() {
  local VALUE="$1"
  local LIST="$2"
  
  for i in $LIST; do
    if [ "$VALUE" = "$i" ]; then
      return 0
    fi
  done
  
  return 1
}


is_true() {
  local val="$1"
  case $val in 
    [yY][eE][sS]|[tT][rR][uU][eE]|1)
      return 0
      ;;
  esac
  return 1
}


skip_cleanup() {
  if is_true $SKIP_CLEANUP; then
    sectionText "WARNING: Skipping cleanup as requested by build.conf (!!!)"
    return 0
  fi
  return 1
}


start_timer() {
  varname=${1:-'total'}
  now=$(date +%s)
  eval "export $varname=$now"
  echo $now > "/var/cache/docker-build-timer-$varname-start"
}

stop_timer() {
  varname=${1:-'total'}
  start="$( (cat /var/cache/docker-build-timer-$varname-start || /bin/true) 2> /dev/null)"
  [ -z $start ] && return 0
  end=${2:-$(date +%s)}
  echo $end > "/var/cache/docker-build-timer-$varname-end"
  let 'diff=end-start'
  rm /var/cache/docker-build-timer-$varname-start /var/cache/docker-build-timer-$varname-end || /bin/true
  perl -e 'use Time::Piece; use Time::Seconds; print Time::Seconds->new($ARGV[0])->pretty;' $diff
}

print_timer() {
    MSG="${1:-'Time taken'}"
    DIFF=$(stop_timer $2)
    [ -n "$DIFF" ] &&  debugText "$MSG: $DIFF"
}


build_exit() {
  rc=$?
  if [ "$rc" != "0" ]; then
    echo "BUILD LOG:"
    tail -n 20 $BUILD_LOG
    echo "BUILD FAILED!!!"
  fi
  exit $rc
}


build_start() {
  start_timer
}

build_base_layer() {
  trap build_exit EXIT
  start_timer base
  chapterHead "Building Base Layer"
  exec_scripts "$WORKDIR/docker/build.d/base/"
  print_timer "\nBase Layer Build Time" "base"
}

build_deps_layer() {
  trap build_exit EXIT
  start_timer deps
  chapterHead "Building Dependency Layer"
  exec_scripts "$WORKDIR/docker/build.d/deps/"
  print_timer "\nDependencies Layer Build Time" "deps"
}

build_shop_layer() {
  trap build_exit EXIT
  start_timer shop
  chapterHead "Building Shop Layer"
  exec_scripts "$WORKDIR/docker/build.d/shop/"
  print_timer "\nShop Layer Build Time" "shop"
}

build_end() {
  skip_cleanup && warnText "Do not publish this image, since it might contain sensitive data due to SKIP_CLEANUP has been enabled"
  print_timer "\nTOTAL Build Time"
  successText "Image BUILD successfully FINISHED"
}

build_image() {
  build_start
  build_base_layer
  build_deps_layer
  build_shop_layer
  build_end
}


init() {
  start_timer init
  exec_scripts "$WORKDIR/docker/init.d/"
  print_timer "\nInitialization Time" "init"
  successText "Setup INITIALIZATION successfully FINISHED"
}


deploy() {
  start_timer deploy
  exec_scripts "$WORKDIR/docker/deploy.d/"
  print_timer "\nDeployment Time" "deploy"
  successText "DEPLOYMENT successfully FINISHED"
}


run() {
  exec_scripts "$WORKDIR/docker/entry.d/" "container bootstrap"
}

run_codeception() {
  CODECEPTION_ARGS=$*
  exec_scripts "$WORKDIR/docker/test.d/codeception/"
}

help() {
  local ENTRYPOINT="$0"

  echo "
USAGE: $ENTRYPOINT COMMAND

COMMANDS:
  codeception [SUITE,...]     Runs the specified codeception test suite(s); or all suites, if nothing is specified.

"
}
